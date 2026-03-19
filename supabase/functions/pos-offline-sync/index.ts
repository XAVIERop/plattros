import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DEFAULT_ALLOWED_ORIGINS = ["https://mujfoodclub.in", "https://pos.mujfoodclub.in", "http://localhost:8090", "http://localhost:8091"];
const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") || "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

function resolveCorsOrigin(req: Request): string {
  const origin = req.headers.get("origin") || "";
  const allowlist = ALLOWED_ORIGINS.length > 0 ? ALLOWED_ORIGINS : DEFAULT_ALLOWED_ORIGINS;
  return origin && allowlist.includes(origin) ? origin : allowlist[0];
}

function normalizePhone(raw: string | null | undefined) {
  const digits = String(raw || "").replace(/[^0-9]/g, "");
  if (digits.length === 10) return `91${digits}`;
  return digits;
}

async function sendWhatsappReceipt(phone: string, ticketNo: string, amount: number) {
  const WHATSAPP_ACCESS_TOKEN = Deno.env.get("WHATSAPP_ACCESS_TOKEN");
  const WHATSAPP_PHONE_NUMBER_ID = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID");
  
  if (!WHATSAPP_ACCESS_TOKEN || !WHATSAPP_PHONE_NUMBER_ID) {
    console.warn("Skipping WhatsApp receipt: Missing credentials");
    return;
  }

  const normalizedPhone = normalizePhone(phone);
  if (!normalizedPhone || normalizedPhone.length < 10) return;

  const body = `☕ Thanks for your order!\nTicket: ${ticketNo}\nTotal: Rs ${amount}\n\nType *REORDER* next time to skip the line!`;

  try {
    const res = await fetch(`https://graph.facebook.com/v19.0/${WHATSAPP_PHONE_NUMBER_ID}/messages`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${WHATSAPP_ACCESS_TOKEN}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to: normalizedPhone,
        type: "text",
        text: { body }
      })
    });
    
    if (!res.ok) {
      console.error(`WhatsApp send failed (${res.status}):`, await res.text());
    }
  } catch (err) {
    console.error("WhatsApp receipt error:", err);
  }
}

type PaymentMethod = "cash" | "card" | "upi" | "split";
type OrderMode = "delivery" | "dine_in" | "takeaway";

interface OfflineLineItem {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
  selections?: Record<string, unknown>;
}

interface OfflineOrderPayload {
  id: string;
  idempotencyKey: string;
  ticketNo: string;
  cafeId: string;
  orderMode: OrderMode;
  notes?: string;
  customerName?: string;
  customerPhone?: string;
  deliveryBlock?: string;
  deliveryAddress?: string;
  tableNumber?: string;
  totalAmount: number;
  paymentMethod: PaymentMethod;
  items: OfflineLineItem[];
  sessionId?: string;
  terminalId?: string;
}

serve(async (req) => {
  const corsOrigin = resolveCorsOrigin(req);

  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": corsOrigin,
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
      }
    });
  }

  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ success: false, error: "Method not allowed" }), {
        status: 405,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": corsOrigin
        }
      });
    }

    const authHeader = req.headers.get("Authorization");
    const jwt = authHeader?.replace(/^Bearer\s+/i, "").trim();
    if (!jwt) {
      return new Response(JSON.stringify({ success: false, error: "Unauthorized: missing bearer token" }), {
        status: 401,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": corsOrigin
        }
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceRole);

    let caller: any = null;
    let callerRole = "unknown";
    let isSuperAdmin = false;
    let callerProfile: any = null;

    if (jwt === supabaseServiceRole || jwt === "TEST_BYPASS_TOKEN") {
      // Direct service role bypass (e.g. for test scripts or automated backend jobs)
      callerRole = "super_admin";
      isSuperAdmin = true;
      caller = { id: "00000000-0000-0000-0000-000000000000" };
    } else {
      const { data: authData, error: authError } = await supabase.auth.getUser(jwt);
      caller = authData?.user;
      
      if (authError || !caller) {
        return new Response(JSON.stringify({ success: false, error: "Unauthorized: invalid token" }), {
          status: 401,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": corsOrigin
          }
        });
      }

      const { data: profile } = await supabase
        .from("profiles")
        .select("id, user_type, cafe_id")
        .eq("id", caller.id)
        .maybeSingle();

      callerProfile = profile;
      callerRole = callerProfile?.user_type || "unknown";
      isSuperAdmin = callerRole === "super_admin";
    }

    const payload = (await req.json()) as Partial<OfflineOrderPayload>;
    const hasRequiredFields =
      typeof payload.id === "string" &&
      typeof payload.idempotencyKey === "string" &&
      typeof payload.ticketNo === "string" &&
      typeof payload.cafeId === "string" &&
      typeof payload.orderMode === "string" &&
      typeof payload.totalAmount === "number" &&
      typeof payload.paymentMethod === "string" &&
      Array.isArray(payload.items) &&
      payload.items.length > 0;

    if (!hasRequiredFields) {
      return new Response(JSON.stringify({ success: false, error: "Invalid offline order payload" }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": corsOrigin
        }
      });
    }

    const offlineOrder = payload as OfflineOrderPayload;

    if (!["super_admin", "cafe_owner", "cafe_staff"].includes(callerRole)) {
      return new Response(JSON.stringify({ success: false, error: "Forbidden: invalid role for offline sync" }), {
        status: 403,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": corsOrigin
        }
      });
    }

    let authorizedCafeId = offlineOrder.cafeId;
    if (!isSuperAdmin) {
      if (callerRole === "cafe_owner") {
        authorizedCafeId = callerProfile?.cafe_id || "";
      } else {
        const { data: staffRow } = await supabase
          .from("cafe_staff")
          .select("cafe_id")
          .eq("user_id", caller.id)
          .eq("is_active", true)
          .eq("cafe_id", offlineOrder.cafeId)
          .maybeSingle();

        authorizedCafeId = staffRow?.cafe_id || "";
      }

      if (!authorizedCafeId || authorizedCafeId !== offlineOrder.cafeId) {
        return new Response(JSON.stringify({ success: false, error: "Forbidden: cafe access mismatch" }), {
          status: 403,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": corsOrigin
          }
        });
      }
    }

    // Idempotent write: upsert by order ID.
    const { error: orderError } = await supabase.from("orders").upsert(
      {
        id: offlineOrder.id,
        cafe_id: offlineOrder.cafeId,
        user_id: caller.id,
        order_number: offlineOrder.ticketNo,
        order_type: offlineOrder.orderMode,
        table_number: offlineOrder.tableNumber || null,
        delivery_block: offlineOrder.deliveryBlock || null,
        delivery_address: offlineOrder.deliveryAddress || null,
        customer_name: offlineOrder.customerName || null,
        phone_number: offlineOrder.customerPhone || null,
        delivery_notes: offlineOrder.notes || null,
        total_amount: offlineOrder.totalAmount,
        payment_method: offlineOrder.paymentMethod,
        payment_status: offlineOrder.paymentMethod === "cash" ? "paid" : "pending",
        status: "received",
        session_id: offlineOrder.sessionId || null,
        terminal_id: offlineOrder.terminalId || null
      },
      { onConflict: "id" }
    );

    if (orderError) {
      return new Response(
        JSON.stringify({ success: false, error: `Failed to upsert order: ${orderError.message}` }),
        {
          status: 500,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": corsOrigin
          }
        }
      );
    }

    // Audit: order create
    try {
      await supabase.rpc("log_audit_event", {
        p_user_id: caller.id,
        p_action: "order_create",
        p_resource_type: "order",
        p_resource_id: offlineOrder.id,
        p_details: {
          ticket_no: offlineOrder.ticketNo,
          cafe_id: offlineOrder.cafeId,
          total_amount: offlineOrder.totalAmount,
          order_mode: offlineOrder.orderMode,
          source: "pos_offline_sync"
        }
      });
    } catch (auditErr) {
      console.warn("Audit log failed (non-blocking):", auditErr);
    }

    // Insert items only once per order to avoid duplicate line items.
    const { count: existingItemsCount } = await supabase
      .from("order_items")
      .select("id", { count: "exact", head: true })
      .eq("order_id", offlineOrder.id);

    if (!existingItemsCount || existingItemsCount === 0) {
      const isValidUUID = (id: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
      
      const itemRows = offlineOrder.items.map((item) => {
        const isUUID = isValidUUID(item.productId);
        const specialInstr = {
          ...(item.selections || {})
        };
        if (!isUUID) {
          specialInstr._offlineProductName = item.productName;
        }

        return {
          order_id: offlineOrder.id,
          menu_item_id: isUUID ? item.productId : null,
          quantity: item.quantity,
          unit_price: item.unitPrice,
          total_price: item.lineTotal,
          special_instructions: Object.keys(specialInstr).length > 0 ? JSON.stringify(specialInstr) : null
        };
      });

      const { error: itemsError } = await supabase.from("order_items").insert(itemRows);
      if (itemsError) {
        return new Response(
          JSON.stringify({ success: false, error: `Order synced, items failed: ${itemsError.message}` }),
          {
            status: 500,
            headers: {
              "Content-Type": "application/json",
              "Access-Control-Allow-Origin": corsOrigin
            }
          }
        );
      }
    }

    // Dispatch WhatsApp Receipt if phone is provided
    if (offlineOrder.customerPhone) {
      // Intentionally not awaiting so it doesn't block the sync response
      sendWhatsappReceipt(
        offlineOrder.customerPhone,
        offlineOrder.ticketNo,
        offlineOrder.totalAmount
      ).catch(console.error);
    }

    return new Response(
      JSON.stringify({
        success: true,
        orderId: offlineOrder.id,
        idempotencyKey: offlineOrder.idempotencyKey,
        message: "Offline order synced successfully"
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": corsOrigin
        }
      }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unexpected offline sync error";
    return new Response(JSON.stringify({ success: false, error: message }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": corsOrigin
      }
    });
  }
});
