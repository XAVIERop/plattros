-- Fix Function Security Issues - Corrected
-- Addresses function_search_path_mutable warnings by setting secure search_path
-- Only fixes functions that actually exist in the database

-- ===========================================
-- FIX FUNCTION SEARCH PATH SECURITY
-- ===========================================

-- Set secure search_path for functions that actually exist
-- This prevents search path attacks by ensuring functions always use the intended schema

-- WhatsApp notification function (exists with correct signature)
ALTER FUNCTION public.send_whatsapp_notification(UUID, JSONB) SET search_path = public;

-- Printer configuration functions
ALTER FUNCTION public.get_cafe_printer_config(UUID) SET search_path = public;
ALTER FUNCTION public.get_cafe_name_for_formatting(UUID) SET search_path = public;

-- Table QR code functions
ALTER FUNCTION public.generate_table_qr_code() SET search_path = public;
ALTER FUNCTION public.update_cafe_tables_updated_at() SET search_path = public;

-- User management functions
ALTER FUNCTION public.update_updated_at_column() SET search_path = public;
ALTER FUNCTION public.handle_new_user(UUID) SET search_path = public;

-- Performance analysis functions
ALTER FUNCTION public.analyze_query_performance() SET search_path = public;
ALTER FUNCTION public.get_index_usage_stats() SET search_path = public;
ALTER FUNCTION public.refresh_analytics_views() SET search_path = public;
ALTER FUNCTION public.cleanup_old_notifications() SET search_path = public;
ALTER FUNCTION public.archive_old_orders() SET search_path = public;

-- ===========================================
-- VERIFICATION
-- ===========================================

-- Verify functions now have secure search_path
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments,
    p.prosecdef as security_definer,
    p.proconfig as config_settings
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
    AND p.proconfig IS NOT NULL
    AND 'search_path=public' = ANY(p.proconfig)
ORDER BY p.proname;














