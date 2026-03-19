-- Minimal Function Security Fix
-- Only fixes functions we know exist with correct signatures

-- Fix the main functions that definitely exist
ALTER FUNCTION public.send_whatsapp_notification(UUID, JSONB) SET search_path = public;
ALTER FUNCTION public.generate_table_qr_code() SET search_path = public;
ALTER FUNCTION public.update_updated_at_column() SET search_path = public;
ALTER FUNCTION public.handle_new_user() SET search_path = public;
ALTER FUNCTION public.analyze_query_performance() SET search_path = public;
ALTER FUNCTION public.get_index_usage_stats() SET search_path = public;
ALTER FUNCTION public.refresh_analytics_views() SET search_path = public;
ALTER FUNCTION public.cleanup_old_notifications() SET search_path = public;
ALTER FUNCTION public.archive_old_orders() SET search_path = public;
ALTER FUNCTION public.audit_security_policies() SET search_path = public;
ALTER FUNCTION public.check_security_status() SET search_path = public;
ALTER FUNCTION public.handle_new_order() SET search_path = public;
ALTER FUNCTION public.handle_order_status_update() SET search_path = public;














