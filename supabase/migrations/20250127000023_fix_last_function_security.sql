-- Fix Last Function Security Warning
-- Fix the bulk_update_order_status procedure

-- Fix the bulk_update_order_status procedure (it's a PROCEDURE, not a FUNCTION)
ALTER PROCEDURE public.bulk_update_order_status(UUID[], TEXT, UUID) SET search_path = public;














