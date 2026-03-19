-- Fix Function Security Issues
-- Addresses function_search_path_mutable warnings by setting secure search_path
-- This fixes the remaining security warnings

-- ===========================================
-- FIX FUNCTION SEARCH PATH SECURITY
-- ===========================================

-- Set secure search_path for all functions to prevent search path attacks
-- This ensures functions always use the intended schema

-- Core functions
ALTER FUNCTION public.get_cafe_by_slug(text) SET search_path = public;
ALTER FUNCTION public.send_whatsapp_notification(text, text, text) SET search_path = public;
ALTER FUNCTION public.update_cafe_average_rating(uuid) SET search_path = public;
ALTER FUNCTION public.generate_slug(text) SET search_path = public;
ALTER FUNCTION public.check_maintenance_expiry() SET search_path = public;
ALTER FUNCTION public.calculate_new_points(numeric, text, uuid) SET search_path = public;
ALTER FUNCTION public.update_cafe_rating(uuid, numeric) SET search_path = public;
ALTER FUNCTION public.get_order_queue_status(uuid) SET search_path = public;
ALTER FUNCTION public.update_order_status_with_queue(uuid, text) SET search_path = public;
ALTER FUNCTION public.handle_order_completion_simple(uuid) SET search_path = public;
ALTER FUNCTION public.calculate_cafe_loyalty_level(uuid, uuid) SET search_path = public;
ALTER FUNCTION public.award_first_order_bonus(uuid, uuid) SET search_path = public;
ALTER FUNCTION public.update_cafe_loyalty_points(uuid, uuid, numeric) SET search_path = public;
ALTER FUNCTION public.set_clean_order_id(uuid) SET search_path = public;
ALTER FUNCTION public.update_monthly_maintenance_spending(uuid, numeric) SET search_path = public;
ALTER FUNCTION public.update_item_analytics(uuid) SET search_path = public;
ALTER FUNCTION public.bulk_update_order_status(uuid[], text) SET search_path = public;
ALTER FUNCTION public.manage_order_queue(uuid) SET search_path = public;
ALTER FUNCTION public.update_enhanced_loyalty_tier(uuid) SET search_path = public;
ALTER FUNCTION public.check_monthly_maintenance() SET search_path = public;
ALTER FUNCTION public.get_user_cafe_loyalty_summary(uuid, uuid) SET search_path = public;
ALTER FUNCTION public.get_cafe_loyalty_discount(uuid, uuid) SET search_path = public;
ALTER FUNCTION public.handle_multiple_orders(uuid[]) SET search_path = public;
ALTER FUNCTION public.update_order_analytics(uuid) SET search_path = public;
ALTER FUNCTION public.calculate_processing_time(uuid) SET search_path = public;
ALTER FUNCTION public.calculate_enhanced_points(numeric, text, uuid) SET search_path = public;
ALTER FUNCTION public.handle_new_user_first_order(uuid, uuid) SET search_path = public;
ALTER FUNCTION public.track_maintenance_spending(uuid, numeric) SET search_path = public;
ALTER FUNCTION public.get_user_enhanced_rewards_summary(uuid) SET search_path = public;
ALTER FUNCTION public.can_accept_order(uuid) SET search_path = public;
ALTER FUNCTION public.create_profile_for_user(uuid, text, text, text) SET search_path = public;
ALTER FUNCTION public.add_user_to_cafe_staff(uuid, uuid, text) SET search_path = public;
ALTER FUNCTION public.create_cafe_owner_user(text, text, text, text, text) SET search_path = public;
ALTER FUNCTION public.get_order_rating_summary(uuid) SET search_path = public;
ALTER FUNCTION public.handle_order_update_consolidated(uuid, text) SET search_path = public;
ALTER FUNCTION public.handle_cafe_loyalty_order_completion(uuid, uuid) SET search_path = public;
ALTER FUNCTION public.validate_order_placement(uuid, uuid, text) SET search_path = public;
ALTER FUNCTION public.debug_cafe_permissions(uuid) SET search_path = public;
ALTER FUNCTION public.initialize_cafe_loyalty_for_existing_users() SET search_path = public;
ALTER FUNCTION public.migrate_existing_loyalty_to_cafe_specific() SET search_path = public;
ALTER FUNCTION public.handle_order_operations(uuid, text) SET search_path = public;
ALTER FUNCTION public.handle_new_user(uuid) SET search_path = public;
ALTER FUNCTION public.get_system_performance_metrics() SET search_path = public;
ALTER FUNCTION public.handle_order_operations_clean(uuid, text) SET search_path = public;
ALTER FUNCTION public.handle_new_order_notification_clean(uuid) SET search_path = public;
ALTER FUNCTION public.handle_status_update_notification_clean(uuid, text) SET search_path = public;
ALTER FUNCTION public.generate_short_qr_code(uuid) SET search_path = public;
ALTER FUNCTION public.get_student_by_qr(text) SET search_path = public;
ALTER FUNCTION public.handle_order_operations_final(uuid, text) SET search_path = public;
ALTER FUNCTION public.handle_new_order_notification_final(uuid) SET search_path = public;
ALTER FUNCTION public.handle_status_update_notification_final(uuid, text) SET search_path = public;
ALTER FUNCTION public.handle_new_order_notification(uuid) SET search_path = public;
ALTER FUNCTION public.update_loyalty_tier(uuid) SET search_path = public;
ALTER FUNCTION public.generate_unique_order_number() SET search_path = public;
ALTER FUNCTION public.generate_random_alphabets(integer) SET search_path = public;
ALTER FUNCTION public.set_default_printer_config(uuid) SET search_path = public;
ALTER FUNCTION public.get_student_by_fc_qr(text) SET search_path = public;
ALTER FUNCTION public.generate_fc_qr_code(uuid) SET search_path = public;
ALTER FUNCTION public.trigger_update_cafe_rating_stats() SET search_path = public;
ALTER FUNCTION public.update_cafe_rating_stats(uuid) SET search_path = public;
ALTER FUNCTION public.get_cafe_rating_summary(uuid) SET search_path = public;
ALTER FUNCTION public.get_cafes_ordered(uuid) SET search_path = public;

-- ===========================================
-- VERIFICATION
-- ===========================================

-- Verify all functions now have secure search_path
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














