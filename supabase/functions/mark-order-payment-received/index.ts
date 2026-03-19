import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface MarkPaymentRequest {
  orderId?: string;
}

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

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: authData, error: authError } = await supabase.auth.getUser(jwt);
    const caller = authData?.user;
    if (authError || !caller) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized: invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const payload = await req.json() as MarkPaymentRequest;
    if (!payload.orderId) {
      return new Response(
        JSON.stringify({ success: false, error: 'orderId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const { data: callerProfile } = await supabase
      .from('profiles')
      .select('id, user_type, cafe_id')
      .eq('id', caller.id)
      .single();
    const callerRole = callerProfile?.user_type || 'unknown';

    const { data: orderRow, error: orderErr } = await supabase
      .from('orders')
      .select('id, cafe_id, status, payment_status, payment_method')
      .eq('id', payload.orderId)
      .single();

    if (orderErr || !orderRow) {
      return new Response(
        JSON.stringify({ success: false, error: 'Order not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const isSuperAdmin = callerRole === 'super_admin';
    const isCafeOwner = callerRole === 'cafe_owner' && callerProfile?.cafe_id === orderRow.cafe_id;
    let isCafeStaff = false;
    if (!isSuperAdmin && !isCafeOwner) {
      const { data: staffRow } = await supabase
        .from('cafe_staff')
        .select('id')
        .eq('user_id', caller.id)
        .eq('cafe_id', orderRow.cafe_id)
        .eq('is_active', true)
        .maybeSingle();
      isCafeStaff = !!staffRow;
    }

    if (!isSuperAdmin && !isCafeOwner && !isCafeStaff) {
      return new Response(
        JSON.stringify({ success: false, error: 'Forbidden: not authorized for this cafe order' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (orderRow.status === 'cancelled' || orderRow.status === 'completed') {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Cannot mark payment for ${orderRow.status} order`,
        }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (orderRow.payment_status === 'paid') {
      return new Response(
        JSON.stringify({ success: true, already_paid: true }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // For online methods, allow manual force-confirm only to super admins.
    const paymentMethod = String(orderRow.payment_method || '').toLowerCase();
    const isCashLike = paymentMethod === 'cash' || paymentMethod === 'cod' || paymentMethod === 'cash_on_delivery';
    if (!isCashLike && !isSuperAdmin) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Only super_admin can manually confirm online payments',
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const { error: updateErr } = await supabase
      .from('orders')
      .update({
        payment_status: 'paid',
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderRow.id);

    if (updateErr) {
      return new Response(
        JSON.stringify({ success: false, error: updateErr.message || 'Failed to update payment status' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Audit: order payment received
    try {
      await supabase.rpc('log_audit_event', {
        p_user_id: caller.id,
        p_action: 'order_payment_received',
        p_resource_type: 'order',
        p_resource_id: orderRow.id,
        p_details: {
          payment_method: orderRow.payment_method,
          manual_confirm: true,
        },
      });
    } catch (auditErr) {
      console.warn('Audit log failed (non-blocking):', auditErr);
    }

    return new Response(
      JSON.stringify({
        success: true,
        order_id: orderRow.id,
        payment_status: 'paid',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    console.error('❌ mark-order-payment-received error:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});

