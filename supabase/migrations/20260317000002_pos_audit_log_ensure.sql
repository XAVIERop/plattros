-- Ensure audit_log and log_audit_event exist for POS order audit (create, status, payment, cancel)
-- Idempotent: safe to run if already applied

CREATE TABLE IF NOT EXISTS public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  user_email TEXT,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON public.audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON public.audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_resource ON public.audit_log(resource_type, resource_id);

CREATE OR REPLACE FUNCTION public.log_audit_event(
  p_user_id UUID,
  p_action TEXT,
  p_resource_type TEXT,
  p_resource_id UUID DEFAULT NULL,
  p_details JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_email TEXT;
  v_audit_id UUID;
BEGIN
  SELECT email INTO v_user_email FROM public.profiles WHERE id = p_user_id;
  INSERT INTO public.audit_log (user_id, user_email, action, resource_type, resource_id, details)
  VALUES (p_user_id, v_user_email, p_action, p_resource_type, p_resource_id, p_details)
  RETURNING id INTO v_audit_id;
  RETURN v_audit_id;
END;
$$;

COMMENT ON FUNCTION public.log_audit_event IS 'Logs audit events for POS and admin actions (order create, status change, payment, cancel)';
