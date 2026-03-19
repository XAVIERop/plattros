import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  try {
    const { cafeId } = (await req.json()) as { cafeId?: string };
    if (!cafeId) {
      return new Response(JSON.stringify({ success: false, error: "cafeId is required" }), {
        status: 400,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" }
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { data: staffRows, error: staffError } = await supabase
      .from("cafe_staff")
      .select("id, user_id, role")
      .eq("cafe_id", cafeId)
      .eq("is_active", true)
      .order("created_at", { ascending: true });

    if (staffError) {
      return new Response(JSON.stringify({ success: false, error: staffError.message }), {
        status: 500,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" }
      });
    }

    const userIds = (staffRows || []).map((row) => row.user_id).filter(Boolean);
    const { data: profiles } = userIds.length
      ? await supabase
          .from("profiles")
          .select("id, full_name, email")
          .in("id", userIds)
      : { data: [] as Array<{ id: string; full_name: string | null; email: string | null }> };
    const profileById = new Map((profiles || []).map((profile) => [profile.id, profile]));

    const staff = (staffRows || []).map((row) => {
      const profile = profileById.get(row.user_id);
      return {
        id: row.id,
        name: profile?.full_name || "Staff",
        shift: row.role ? `${row.role.toUpperCase()} shift` : "Shift not configured",
        email: profile?.email || ""
      };
    });

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const { data: todayOrders } = await supabase
      .from("orders")
      .select("id, order_number, order_type, customer_name, status, total_amount, payment_status")
      .eq("cafe_id", cafeId)
      .gte("created_at", todayStart.toISOString())
      .order("created_at", { ascending: false })
      .limit(50);

    const inProgress = (todayOrders || []).filter((order) => ["received", "confirmed", "preparing", "on_the_way"].includes(order.status)).length;
    const readyToServe = (todayOrders || []).filter((order) => order.status === "completed").length;
    const totalEarning = (todayOrders || [])
      .filter((order) => order.payment_status === "paid")
      .reduce((sum, order) => sum + Number(order.total_amount || 0), 0);
    const recentOrders = (todayOrders || []).slice(0, 3).map((order) => ({
      order_number: order.order_number,
      order_type: order.order_type,
      customer_name: order.customer_name
    }));

    return new Response(
      JSON.stringify({
        success: true,
        staff,
        preview: {
          totalEarning,
          inProgress,
          readyToServe,
          recentOrders
        }
      }),
      { headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unexpected bootstrap error";
    return new Response(JSON.stringify({ success: false, error: message }), {
      status: 500,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" }
    });
  }
});
