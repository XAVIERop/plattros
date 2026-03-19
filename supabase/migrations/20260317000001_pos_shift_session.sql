-- Add session_id to orders for shift/session tracking
-- Optional: links orders to a POS shift for reporting and accountability

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS session_id TEXT;

COMMENT ON COLUMN public.orders.session_id IS 'POS shift/session ID when order was created (for reporting)';
