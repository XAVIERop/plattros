import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface UpdateOrderStatusRequest {
  orderId?: string;
  newStatus?: 'received' | 'confirmed' | 'preparing' | 'on_the_way' | 'completed' | 'cancelled';
}

const allowedStatuses = new Set(['received', 'confirmed', 'preparing', 'on_the_way', 'completed', 'cancelled']);

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    const jwt = authHeader?.replace(/^Bearer\s+/i, '').trim();
    if (!jwt) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized: missing bearer token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const sb = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: authData, error: authError } = await sb.auth.getUser(jwt);
    const caller = authData?.user;
    if (authError || !caller) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized: invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const body = await req.json() as UpdateOrderStatusRequest;
    const orderId = body.orderId;
    const newStatus = body.newStatus;
    if (!orderId || !newStatus || !allowedStatuses.has(newStatus)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid request: orderId/newStatus required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const { data: callerProfile } = await sb
      .from('profiles')
      .select('id, user_type, cafe_id')
      .eq('id', caller.id)
      .single();

    const callerRole = callerProfile?.user_type || 'unknown';
    const isSuperAdmin = callerRole === 'super_admin';

    const { data: orderRow, error: orderErr } = await sb
      .from('orders')
      .select('id, cafe_id, status, payment_status, payment_method, order_type')
      .eq('id', orderId)
      .single();

    if (orderErr || !orderRow) {
      return new Response(
        JSON.stringify({ success: false, error: 'Order not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    let isCafeAuthorized = false;
    if (isSuperAdmin) {
      isCafeAuthorized = true;
    } else if (callerProfile?.user_type === 'cafe_owner' && callerProfile?.cafe_id === orderRow.cafe_id) {
      isCafeAuthorized = true;
    } else {
      const { data: staffRow } = await sb
        .from('cafe_staff')
        .select('id')
        .eq('user_id', caller.id)
        .eq('cafe_id', orderRow.cafe_id)
        .eq('is_active', true)
        .maybeSingle();
      isCafeAuthorized = !!staffRow;
    }

    if (!isCafeAuthorized) {
      return new Response(
        JSON.stringify({ success: false, error: 'Forbidden: not authorized for this cafe order' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (orderRow.status === 'cancelled' || orderRow.status === 'completed') {
      return new Response(
        JSON.stringify({ success: false, error: `Cannot update ${orderRow.status} orders` }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Mirror POS guard: don't allow processing with pending payment (except received/dine-in).
    const isDineIn = orderRow.order_type === 'dine_in' || orderRow.order_type === 'table_order';
    if (orderRow.payment_status === 'pending' && newStatus !== 'received' && !isDineIn) {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Payment pending for order (${orderRow.payment_method || 'unknown'})`,
        }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const nowIso = new Date().toISOString();
    const updateData: Record<string, unknown> = {
      status: newStatus,
      status_updated_at: nowIso,
    };

    if (newStatus === 'confirmed') updateData.accepted_at = nowIso;
    if (newStatus === 'preparing') updateData.preparing_at = nowIso;
    if (newStatus === 'on_the_way') updateData.out_for_delivery_at = nowIso;
    if (newStatus === 'completed') {
      updateData.completed_at = nowIso;
      updateData.points_credited = true;
    }

    const { data: updatedOrder, error: updateErr } = await sb
      .from('orders')
      .update(updateData)
      .eq('id', orderId)
      .select('*')
      .single();

    if (updateErr || !updatedOrder) {
      return new Response(
        JSON.stringify({ success: false, error: updateErr?.message || 'Failed to update order status' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Audit: order status change or cancel
    try {
      const auditAction = newStatus === 'cancelled' ? 'order_cancel' : 'order_status_change';
      await sb.rpc('log_audit_event', {
        p_user_id: caller.id,
        p_action: auditAction,
        p_resource_type: 'order',
        p_resource_id: orderId,
        p_details: {
          old_status: orderRow.status,
          new_status: newStatus,
        },
      });
    } catch (auditErr) {
      console.warn('Audit log failed (non-blocking):', auditErr);
    }

    return new Response(
      JSON.stringify({ success: true, order: updatedOrder }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    console.error('❌ update-order-status-secure error:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});

