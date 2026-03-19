-- =====================================================
-- CRM Foundation + WhatsApp Outbox
-- =====================================================
-- Unified customer view and message queue for dry-run / automation.

-- 1. Helper: normalize phone to 10 digits (India), strip 91 prefix
CREATE OR REPLACE FUNCTION public.normalize_phone_for_crm(raw TEXT)
RETURNS TEXT
LANGUAGE sql IMMUTABLE
AS $$
  SELECT regexp_replace(
    regexp_replace(COALESCE(raw, ''), '[^0-9]', '', 'g'),
    '^91', '', 'g'
  );
$$;

-- 2. crm_customers: unified customer view per cafe (orders + loyalty)
CREATE OR REPLACE VIEW public.crm_customers AS
WITH order_agg AS (
  SELECT
    o.cafe_id,
    public.normalize_phone_for_crm(o.phone_number) AS phone_normalized,
    MAX(o.customer_name) AS name,
    COUNT(*)::INT AS order_count,
    COALESCE(SUM(o.total_amount), 0)::NUMERIC AS total_spend,
    MAX(o.created_at) AS last_order_at
  FROM public.orders o
  WHERE o.phone_number IS NOT NULL
    AND public.normalize_phone_for_crm(o.phone_number) ~ '^[0-9]{10}$'
  GROUP BY o.cafe_id, public.normalize_phone_for_crm(o.phone_number)
),
loyalty_agg AS (
  SELECT
    lc.cafe_id,
    public.normalize_phone_for_crm(lc.phone) AS phone_normalized,
    lc.name,
    lc.points,
    lc.total_check_ins,
    lc.last_check_in_at
  FROM public.loyalty_customers lc
  WHERE public.normalize_phone_for_crm(lc.phone) ~ '^[0-9]{10}$'
)
SELECT
  COALESCE(o.cafe_id, l.cafe_id) AS cafe_id,
  COALESCE(o.phone_normalized, l.phone_normalized) AS phone_normalized,
  COALESCE(o.name, l.name, 'Guest') AS name,
  COALESCE(o.order_count, 0) AS order_count,
  COALESCE(o.total_spend, 0) AS total_spend,
  o.last_order_at,
  COALESCE(l.points, 0) AS loyalty_points,
  COALESCE(l.total_check_ins, 0) AS check_in_count,
  l.last_check_in_at,
  -- Segment: VIP (10+ visits), Regular (3+), New (<=1), At Risk (>30d since last activity)
  CASE
    WHEN COALESCE(l.total_check_ins, 0) + COALESCE(o.order_count, 0) >= 10 THEN 'VIP'
    WHEN COALESCE(l.total_check_ins, 0) + COALESCE(o.order_count, 0) >= 3 THEN 'Regular'
    WHEN COALESCE(l.total_check_ins, 0) + COALESCE(o.order_count, 0) <= 1 THEN 'New'
    WHEN GREATEST(o.last_order_at, l.last_check_in_at) IS NOT NULL
         AND (NOW() - GREATEST(o.last_order_at, l.last_check_in_at)) > INTERVAL '30 days' THEN 'At Risk'
    ELSE 'Regular'
  END AS segment
FROM order_agg o
FULL OUTER JOIN loyalty_agg l
  ON o.cafe_id = l.cafe_id AND o.phone_normalized = l.phone_normalized
WHERE COALESCE(o.cafe_id, l.cafe_id) IS NOT NULL;

COMMENT ON VIEW public.crm_customers IS 'Unified customer view per cafe: orders + loyalty. Use for segmentation and WhatsApp targeting.';

-- 3. whatsapp_outbox: queue for pending WhatsApp messages (processed by cron or on-demand)
CREATE TABLE IF NOT EXISTS public.whatsapp_outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id UUID REFERENCES public.cafes(id) ON DELETE CASCADE,
  phone TEXT NOT NULL,
  event_type TEXT NOT NULL,
  message_body TEXT,
  template_name TEXT,
  template_params JSONB DEFAULT '[]'::jsonb,
  payload_json JSONB DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'skipped')),
  attempts INT NOT NULL DEFAULT 0,
  max_attempts INT NOT NULL DEFAULT 3,
  last_error TEXT,
  scheduled_for TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_whatsapp_outbox_status_scheduled
  ON public.whatsapp_outbox(status, scheduled_for)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_whatsapp_outbox_cafe
  ON public.whatsapp_outbox(cafe_id);

ALTER TABLE public.whatsapp_outbox ENABLE ROW LEVEL SECURITY;

-- RLS: cafe staff can manage their outbox
CREATE POLICY "cafe_staff_whatsapp_outbox" ON public.whatsapp_outbox
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.cafe_staff cs WHERE cs.cafe_id = whatsapp_outbox.cafe_id AND cs.user_id = auth.uid() AND cs.is_active = true)
    OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.cafe_id = whatsapp_outbox.cafe_id)
  );

COMMENT ON TABLE public.whatsapp_outbox IS 'Queue for WhatsApp messages. Process with WHATSAPP_DRY_RUN=true to log without sending.';
