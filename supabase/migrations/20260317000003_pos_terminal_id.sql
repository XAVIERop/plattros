-- Add terminal_id to orders for multi-terminal support
-- Identifies which POS terminal created the order (e.g. "A", "1", "Counter-1")

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS terminal_id TEXT;

COMMENT ON COLUMN public.orders.terminal_id IS 'POS terminal identifier when order was created (multi-device per cafe)';
