import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { PDFDocument, rgb, StandardFonts } from "https://esm.sh/pdf-lib@1.17.1";

const WHATSAPP_ACCESS_TOKEN = Deno.env.get("WHATSAPP_ACCESS_TOKEN") || "";
const WHATSAPP_PHONE_NUMBER_ID = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID") || "";
const WHATSAPP_DRY_RUN = Deno.env.get("WHATSAPP_DRY_RUN") === "true";
const PUBLIC_APP_URL = Deno.env.get("PUBLIC_APP_URL") || "https://mujfoodclub.in";

const CORS_HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};

type EventType =
  | "order_status_changed"
  | "payment_recovery"
  | "order_completed"
  | "reorder_nudge"
  | "reservation_confirmation"
  | "send_digital_receipt"
  | "win_back_campaign";

interface AutomationRequest {
  eventType: EventType;
  orderId?: string;
  cafeId?: string;
  phone?: string;
  metadata?: Record<string, unknown>;
}

function normalizePhone(raw: string | null | undefined): string {
  const digits = String(raw || "").replace(/[^0-9]/g, "");
  if (digits.length === 10) return `91${digits}`;
  return digits;
}

function isWithinQuietHours(nowHour: number, quietStart: number, quietEnd: number) {
  if (quietStart === quietEnd) return false;
  if (quietStart < quietEnd) return nowHour >= quietStart && nowHour < quietEnd;
  return nowHour >= quietStart || nowHour < quietEnd;
}

async function sendTextMessage(toPhone: string, body: string) {
  if (WHATSAPP_DRY_RUN) {
    console.log("[DRY RUN] Would send WhatsApp to", toPhone.slice(-4), ":", body.slice(0, 80) + "...");
    return "dry-run-" + Date.now();
  }
  if (!WHATSAPP_ACCESS_TOKEN || !WHATSAPP_PHONE_NUMBER_ID) {
    throw new Error("Missing WHATSAPP_ACCESS_TOKEN or WHATSAPP_PHONE_NUMBER_ID");
  }
  const res = await fetch(`https://graph.facebook.com/v19.0/${WHATSAPP_PHONE_NUMBER_ID}/messages`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${WHATSAPP_ACCESS_TOKEN}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to: toPhone,
      type: "text",
      text: { body: body.slice(0, 4096) }
    })
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`WhatsApp send failed (${res.status}): ${text}`);
  try {
    const parsed = JSON.parse(text);
    return String(parsed?.messages?.[0]?.id || "");
  } catch {
    return "";
  }
}

async function uploadMedia(pdfBytes: Uint8Array, filename: string): Promise<string> {
  if (WHATSAPP_DRY_RUN) {
    console.log("[DRY RUN] Would upload media:", filename);
    return "dry-run-media";
  }
  const formData = new FormData();
  const blob = new Blob([pdfBytes], { type: "application/pdf" });
  formData.append("file", blob, filename);
  formData.append("type", "application/pdf");
  formData.append("messaging_product", "whatsapp");

  const res = await fetch(`https://graph.facebook.com/v19.0/${WHATSAPP_PHONE_NUMBER_ID}/media`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${WHATSAPP_ACCESS_TOKEN}`
    },
    body: formData
  });
  const data = await res.json();
  if (!res.ok) throw new Error(`Media upload failed: ${JSON.stringify(data)}`);
  return data.id;
}

async function sendDocumentMessage(toPhone: string, mediaId: string, filename: string, caption: string) {
  if (WHATSAPP_DRY_RUN) {
    console.log("[DRY RUN] Would send document to", toPhone.slice(-4), ":", filename);
    return "dry-run-doc-" + Date.now();
  }
  const res = await fetch(`https://graph.facebook.com/v19.0/${WHATSAPP_PHONE_NUMBER_ID}/messages`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${WHATSAPP_ACCESS_TOKEN}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to: toPhone,
      type: "document",
      document: {
        id: mediaId,
        filename,
        caption
      }
    })
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`WhatsApp send document failed: ${text}`);
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
    return new Response(JSON.stringify({ success: false, error: "Method not allowed" }), { status: 405, headers: CORS_HEADERS });
  }

  const sb = createClient(
    Deno.env.get("SUPABASE_URL") || "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""
  );

  try {
    const body = await req.json() as AutomationRequest;
    if (!body.eventType) {
      return new Response(JSON.stringify({ success: false, error: "eventType is required" }), { status: 400, headers: CORS_HEADERS });
    }

    let targetPhone = normalizePhone(body.phone);
    let order: any = null;
    let cafeName = "FoodClub Cafe";
    let eventOrderId: string | null = null;
    let eventCafeId: string | null = body.cafeId || null;

    if (body.orderId) {
      const { data } = await sb
        .from("orders")
        .select("id, order_number, status, payment_status, total_amount, customer_name, phone_number, delivery_notes, cafe_id, created_at")
        .eq("id", body.orderId)
        .maybeSingle();
      order = data;
      eventOrderId = data?.id || null;
      eventCafeId = data?.cafe_id || eventCafeId;
      if (!targetPhone) targetPhone = normalizePhone(data?.phone_number);
    }

    if (eventCafeId) {
      const { data: cafe } = await sb.from("cafes").select("id, name").eq("id", eventCafeId).maybeSingle();
      if (cafe?.name) cafeName = cafe.name;
    }

    if (!targetPhone) {
      return new Response(JSON.stringify({ success: false, error: "No target phone found" }), { status: 400, headers: CORS_HEADERS });
    }

    const { data: preference } = await sb
      .from("whatsapp_bot_preferences")
      .select("opted_out, quiet_hours_start, quiet_hours_end")
      .eq("phone", targetPhone)
      .maybeSingle();

    if (preference?.opted_out) {
      await sb.from("whatsapp_bot_events").insert({
        event_type: body.eventType,
        phone: targetPhone,
        cafe_id: eventCafeId,
        order_id: eventOrderId,
        payload_json: { reason: "opted_out", metadata: body.metadata || {} },
        status: "skipped",
        processed_at: new Date().toISOString()
      });
      return new Response(JSON.stringify({ success: true, skipped: "opted_out" }), { headers: CORS_HEADERS });
    }

    const nowHour = new Date().getHours();
    const quietStart = Number(preference?.quiet_hours_start ?? 22);
    const quietEnd = Number(preference?.quiet_hours_end ?? 8);
    if (isWithinQuietHours(nowHour, quietStart, quietEnd) && body.eventType !== "payment_recovery") {
      await sb.from("whatsapp_bot_events").insert({
        event_type: body.eventType,
        phone: targetPhone,
        cafe_id: eventCafeId,
        order_id: eventOrderId,
        payload_json: { reason: "quiet_hours", metadata: body.metadata || {} },
        status: "skipped",
        processed_at: new Date().toISOString()
      });
      return new Response(JSON.stringify({ success: true, skipped: "quiet_hours" }), { headers: CORS_HEADERS });
    }

    const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
    const { data: recentOutbound } = await sb
      .from("whatsapp_messages")
      .select("id")
      .eq("phone", targetPhone)
      .eq("direction", "outbound")
      .gte("created_at", fiveMinAgo)
      .limit(1);
    if ((recentOutbound || []).length > 0 && body.eventType !== "payment_recovery" && body.eventType !== "send_digital_receipt" && body.eventType !== "win_back_campaign") {
      await sb.from("whatsapp_bot_events").insert({
        event_type: body.eventType,
        phone: targetPhone,
        cafe_id: eventCafeId,
        order_id: eventOrderId,
        payload_json: { reason: "throttled", metadata: body.metadata || {} },
        status: "skipped",
        processed_at: new Date().toISOString()
      });
      return new Response(JSON.stringify({ success: true, skipped: "throttled" }), { headers: CORS_HEADERS });
    }

    const orderNo = order?.order_number || body.metadata?.orderNo || "your order";
    const total = Math.round(Number(order?.total_amount || body.metadata?.total || 0));
    const paymentLink = String(order?.delivery_notes || "").match(/https?:\/\/\S+/i)?.[0] || `${PUBLIC_APP_URL}/checkout`;
    const currentStatus = String(order?.status || "").replaceAll("_", " ");

    let message = "";
    let waMessageId = "";
    switch (body.eventType) {
      case "order_status_changed":
        message = `Update from ${cafeName}: ${orderNo} is now ${currentStatus}. Track with: TRACK ${orderNo}`;
        break;
      case "payment_recovery":
        message = `Payment pending for ${orderNo} (Rs ${total}). Complete here: ${paymentLink}`;
        break;
      case "order_completed":
        message = `Your order ${orderNo} is completed. Reply RATE 1-5 to share feedback. Reply REORDER to order again.`;
        break;
      case "reorder_nudge":
        message = `Missed us? Reorder your favorites from ${cafeName}: ${PUBLIC_APP_URL}/checkout?reorder=${order?.id || ""}`;
        break;
      case "reservation_confirmation":
        message = `Your table reservation is confirmed at ${cafeName}. Need changes? Reply RESERVE TABLE <no> <time>.`;
        break;
      case "send_digital_receipt": {
        const paymentMethod = body.metadata?.paymentMethod || "paid";
        const items = Array.isArray(body.metadata?.items) ? body.metadata.items : [];
        let itemsText = items.map((i: any) => `${i.quantity}x ${i.name}`).join(", ");
        if (itemsText) itemsText = `\n\nItems:\n${itemsText}`;
        message = `🧾 *Digital Receipt - ${cafeName}*\nOrder No: ${orderNo}\nTotal: Rs ${total}\nPayment: ${String(paymentMethod).toUpperCase()}${itemsText}\n\nThank you for visiting!`;
        
        try {
          const pdfDoc = await PDFDocument.create();
          const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
          const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
          const obliqueFont = await pdfDoc.embedFont(StandardFonts.HelveticaOblique);

          const itemsHeight = items.length * 20;
          const extraInfoHeight = (body.metadata?.discount ? 15 : 0) + (body.metadata?.serviceCharge ? 15 : 0) + 40;
          const pageHeight = 300 + itemsHeight + extraInfoHeight; 
          const pageWidth = 300;
          const page = pdfDoc.addPage([pageWidth, pageHeight]);

          const centerText = (text: string, yPos: number, f: any, size: number) => {
            const width = f.widthOfTextAtSize(text, size);
            page.drawText(text, { x: (pageWidth - width) / 2, y: yPos, size, font: f });
          };

          const rightAlignText = (text: string, yPos: number, f: any, size: number, rightMargin = 20) => {
            const width = f.widthOfTextAtSize(text, size);
            page.drawText(text, { x: pageWidth - width - rightMargin, y: yPos, size, font: f });
          };

          const drawDashedLine = (yPos: number) => {
             page.drawText("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -", { x: 20, y: yPos, size: 10, font, color: rgb(0.6, 0.6, 0.6) });
          }

          let y = pageHeight - 40;
          
          centerText(cafeName.toUpperCase(), y, boldFont, 18);
          y -= 15;
          centerText("TAX INVOICE / RECEIPT", y, obliqueFont, 10);
          
          y -= 25;
          page.drawText(`Order No: ${orderNo}`, { x: 20, y, size: 10, font: boldFont });
          rightAlignText(new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata', dateStyle: 'short', timeStyle: 'short' }), y, font, 10);

          y -= 15;
          drawDashedLine(y);
          
          y -= 20;
          page.drawText("Qty", { x: 20, y, size: 10, font: boldFont });
          page.drawText("Item", { x: 50, y, size: 10, font: boldFont });
          rightAlignText("Rate", y, boldFont, 10, 70);
          rightAlignText("Amount", y, boldFont, 10, 20);
          
          y -= 10;
          drawDashedLine(y);
          y -= 20;

          for (const item of items) {
            const qty = String(item.quantity || 1);
            const name = String(item.name || "Item").substring(0, 22);
            const price = Number(item.price || 0);
            const amount = Number(item.amount || (price * Number(qty)));

            page.drawText(qty, { x: 20, y, size: 10, font });
            page.drawText(name, { x: 50, y, size: 10, font });
            
            if (price > 0) rightAlignText(price.toFixed(2), y, font, 10, 70);
            rightAlignText(amount.toFixed(2), y, font, 10, 20);
            
            y -= 20;
          }

          drawDashedLine(y);
          y -= 20;

          const subtotal = Number(body.metadata?.subtotal || total);
          const discount = Number(body.metadata?.discount || 0);
          const serviceCharge = Number(body.metadata?.serviceCharge || 0);

          if (discount > 0 || serviceCharge > 0) {
            page.drawText("Subtotal", { x: 50, y, size: 10, font });
            rightAlignText(subtotal.toFixed(2), y, font, 10, 20);
            y -= 15;

            if (discount > 0) {
              page.drawText("Discount", { x: 50, y, size: 10, font });
              rightAlignText("-" + discount.toFixed(2), y, font, 10, 20);
              y -= 15;
            }

            if (serviceCharge > 0) {
              page.drawText("Service Charge", { x: 50, y, size: 10, font });
              rightAlignText("+" + serviceCharge.toFixed(2), y, font, 10, 20);
              y -= 15;
            }
            
            drawDashedLine(y);
            y -= 20;
          }

          page.drawText("TOTAL", { x: 50, y, size: 14, font: boldFont });
          rightAlignText(`Rs ${total}`, y, boldFont, 14, 20);
          
          y -= 20;
          page.drawText(`Payment: ${String(paymentMethod).toUpperCase()}`, { x: 50, y, size: 10, font });

          y -= 40;
          centerText("Thank you for visiting!", y, boldFont, 12);
          y -= 15;
          centerText("Have a great day ahead.", y, font, 10);

          const pdfBytes = await pdfDoc.save();
          const mediaId = await uploadMedia(pdfBytes, `Receipt_${orderNo}.pdf`);
          waMessageId = await sendDocumentMessage(targetPhone, mediaId, `Receipt_${orderNo}.pdf`, `🧾 Here is your digital receipt for ${orderNo}.`);
        } catch (pdfErr) {
          console.error("PDF gen/upload error", pdfErr);
        }
        break;
      }
      case "win_back_campaign": {
        const customerName = body.metadata?.customerName || "there";
        const topItem = body.metadata?.topItem || "your favorites";
        const discountCode = body.metadata?.discountCode || "WELCOMEBACK";
        message = `Hey ${customerName}! 👋 We noticed it's been a while since you visited ${cafeName}. We miss you! Come grab ${topItem} and use code ${discountCode} for 15% off your next order.`;
        break;
      }
      default:
        message = `Update from ${cafeName}.`;
    }

    if (!waMessageId && message) {
      waMessageId = await sendTextMessage(targetPhone, message);
    }
    await sb.from("whatsapp_messages").insert({
      phone: targetPhone,
      direction: "outbound",
      message_text: message,
      wa_message_id: waMessageId || null,
      payload_json: {
        source: "automation_runner",
        eventType: body.eventType,
        metadata: body.metadata || {}
      }
    });

    await sb.from("whatsapp_bot_events").insert({
      event_type: body.eventType,
      phone: targetPhone,
      cafe_id: eventCafeId,
      order_id: eventOrderId,
      payload_json: body.metadata || {},
      status: "processed",
      processed_at: new Date().toISOString()
    });

    return new Response(JSON.stringify({ success: true }), { headers: CORS_HEADERS });
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Automation failed"
      }),
      { status: 500, headers: CORS_HEADERS }
    );
  }
});
