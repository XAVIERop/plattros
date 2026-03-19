// Send Loyalty Loop campaign via WhatsApp to loyalty_customers
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WHATSAPP_ACCESS_TOKEN = Deno.env.get("WHATSAPP_ACCESS_TOKEN") || "";
const WHATSAPP_PHONE_NUMBER_ID = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID") || "";
const WHATSAPP_DRY_RUN = Deno.env.get("WHATSAPP_DRY_RUN") === "true";
const LOYALTY_APP_URL = Deno.env.get("LOYALTY_APP_URL") || "https://loyalty.plattrtechnologies.com";

const CORS_HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function normalizePhone(raw: string | null | undefined): string {
  const digits = String(raw || "").replace(/[^0-9]/g, "");
  if (digits.length === 10) return `91${digits}`;
  return digits;
}

async function sendTextMessage(toPhone: string, body: string): Promise<string> {
  if (WHATSAPP_DRY_RUN) {
    console.log("[DRY RUN] Would send WhatsApp to", toPhone.slice(-4), ":", body.slice(0, 60) + "...");
    return "dry-run-" + Date.now();
  }
  if (!WHATSAPP_ACCESS_TOKEN || !WHATSAPP_PHONE_NUMBER_ID) {
    throw new Error("WhatsApp not configured");
  }
  const res = await fetch(`https://graph.facebook.com/v19.0/${WHATSAPP_PHONE_NUMBER_ID}/messages`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${WHATSAPP_ACCESS_TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to: toPhone.replace(/^91/, ""),
      type: "text",
      text: { body: body.slice(0, 4096) },
    }),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`WhatsApp send failed: ${text}`);
  try {
    const parsed = JSON.parse(text);
    return String(parsed?.messages?.[0]?.id || "");
  } catch {
    return "";
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ success: false, error: "Method not allowed" }), {
      status: 405,
      headers: CORS_HEADERS,
    });
  }

  const sb = createClient(
    Deno.env.get("SUPABASE_URL") || "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""
  );

  try {
    const authHeader = req.headers.get("Authorization");
    const jwt = authHeader?.replace(/^Bearer\s+/i, "").trim();
    if (!jwt) {
      return new Response(JSON.stringify({ success: false, error: "Unauthorized" }), {
        status: 401,
        headers: CORS_HEADERS,
      });
    }

    const { data: { user } } = await sb.auth.getUser(jwt);
    if (!user) {
      return new Response(JSON.stringify({ success: false, error: "Invalid token" }), {
        status: 401,
        headers: CORS_HEADERS,
      });
    }

    const body = await req.json() as { campaign_id: string; cafe_id: string; message?: string; segment?: string };
    const { campaign_id, cafe_id, message: messageOverride, segment } = body;
    if (!campaign_id || !cafe_id) {
      return new Response(JSON.stringify({ success: false, error: "campaign_id and cafe_id required" }), {
        status: 400,
        headers: CORS_HEADERS,
      });
    }

    const { data: profile } = await sb.from("profiles").select("cafe_id").eq("id", user.id).maybeSingle();
    const { data: staff } = await sb.from("cafe_staff").select("cafe_id").eq("user_id", user.id).eq("is_active", true).limit(1).maybeSingle();
    const userCafeId = profile?.cafe_id || staff?.cafe_id;
    if (userCafeId !== cafe_id) {
      return new Response(JSON.stringify({ success: false, error: "Forbidden" }), {
        status: 403,
        headers: CORS_HEADERS,
      });
    }

    const { data: campaign, error: campErr } = await sb
      .from("loyalty_campaigns")
      .select("id, name, message_body, cafe_id")
      .eq("id", campaign_id)
      .eq("cafe_id", cafe_id)
      .single();

    if (campErr || !campaign) {
      return new Response(JSON.stringify({ success: false, error: "Campaign not found" }), {
        status: 404,
        headers: CORS_HEADERS,
      });
    }

    const { data: cafe } = await sb.from("cafes").select("name, slug").eq("id", cafe_id).single();
    const cafeName = cafe?.name || "Our Restaurant";
    const checkinUrl = cafe?.slug ? `${LOYALTY_APP_URL}/checkin/${cafe.slug}` : "";

    const messageBody =
      messageOverride?.trim() ||
      campaign.message_body?.trim() ||
      `Hi! 👋 ${cafeName} here. Thanks for being a loyal customer! Check in next time for more points: ${checkinUrl}`;

    let customersQuery = sb.from("loyalty_customers").select("phone, total_check_ins, last_check_in_at, birthday").eq("cafe_id", cafe_id);
    const { data: customersRaw } = await customersQuery;
    let customers = customersRaw || [];

    // Filter by segment
    if (segment && segment !== "all") {
      const now = new Date();
      const todayStr = `${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
      const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

      customers = customers.filter((c) => {
        const lastCheckIn = c.last_check_in_at ? new Date(c.last_check_in_at) : null;
        const totalVisits = (c.total_check_ins ?? 0);
        const birthDate = c.birthday ? String(c.birthday).slice(5) : null; // MM-DD

        if (segment === "at_risk") return !lastCheckIn || lastCheckIn < thirtyDaysAgo;
        if (segment === "birthday") return birthDate === todayStr;
        if (segment === "vip") return totalVisits >= 10;
        if (segment === "new") return totalVisits <= 1;
        if (segment === "regular") return totalVisits >= 3 && totalVisits < 10;
        return true;
      });
    }

    if (customers.length === 0) {
      return new Response(JSON.stringify({ success: true, sent: 0, message: "No customers to send to" }), {
        headers: CORS_HEADERS,
      });
    }

    const phones = [...new Set(customers.map((c) => normalizePhone(c.phone)).filter((p) => p.length >= 10))];
    let sent = 0;

    for (const phone of phones) {
      try {
        const { data: pref } = await sb
          .from("whatsapp_bot_preferences")
          .select("opted_out")
          .eq("phone", phone)
          .maybeSingle();
        if (pref?.opted_out) continue;

        await sendTextMessage(phone, messageBody);
        await sb.from("loyalty_campaign_sends").insert({
          campaign_id,
          phone,
          status: "sent",
        });
        sent++;
        await new Promise((r) => setTimeout(r, 500));
      } catch (e) {
        console.error("Send failed for", phone, e);
        await sb.from("loyalty_campaign_sends").insert({
          campaign_id,
          phone,
          status: "failed",
        });
      }
    }

    const { data: current } = await sb.from("loyalty_campaigns").select("sent").eq("id", campaign_id).single();
    const newSent = (current?.sent ?? 0) + sent;
    await sb.from("loyalty_campaigns").update({ sent: newSent }).eq("id", campaign_id);

    return new Response(JSON.stringify({ success: true, sent }), {
      headers: CORS_HEADERS,
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Send failed",
      }),
      { status: 500, headers: CORS_HEADERS }
    );
  }
});
