-- WhatsApp bot MVP schema: session state + message logs + order source tagging

CREATE TABLE IF NOT EXISTS public.whatsapp_sessions (
  phone TEXT PRIMARY KEY,
  current_step TEXT NOT NULL DEFAULT 'CAFE_SELECT',
  selected_cafe_id UUID REFERENCES public.cafes(id) ON DELETE SET NULL,
  cart_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  customer_name TEXT,
  delivery_address TEXT,
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  message_text TEXT,
  wa_message_id TEXT,
  payload_json JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_phone_created_at
  ON public.whatsapp_messages(phone, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_whatsapp_sessions_last_active_at
  ON public.whatsapp_sessions(last_active_at DESC);

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS order_source TEXT NOT NULL DEFAULT 'app';

-- Helpful trigger for session timestamps if shared trigger exists.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_proc
    WHERE proname = 'update_updated_at_column'
  ) THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_trigger
      WHERE tgname = 'update_whatsapp_sessions_updated_at'
    ) THEN
      CREATE TRIGGER update_whatsapp_sessions_updated_at
        BEFORE UPDATE ON public.whatsapp_sessions
        FOR EACH ROW
        EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
  END IF;
END $$;
