-- Comprehensive Final Security Fix
-- Addresses all remaining security issues from the dashboard

-- ===========================================
-- FIX SECURITY DEFINER VIEWS (2 ERRORS)
-- ===========================================

-- Fix cafe_dashboard_view
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'cafe_dashboard_view' AND table_schema = 'public') THEN
        DROP VIEW public.cafe_dashboard_view;
    END IF;
END $$;

-- Recreate as a regular view (without SECURITY DEFINER)
CREATE VIEW public.cafe_dashboard_view AS
SELECT 
    c.id,
    c.name,
    c.type,
    c.description,
    c.location,
    c.phone,
    c.hours,
    c.accepting_orders,
    c.average_rating,
    c.total_ratings,
    c.cuisine_categories,
    c.image_url,
    c.whatsapp_phone,
    c.whatsapp_enabled,
    c.whatsapp_notifications,
    c.created_at,
    c.updated_at,
    COUNT(o.id) as total_orders,
    COALESCE(SUM(o.total_amount), 0) as total_revenue
FROM public.cafes c
LEFT JOIN public.orders o ON c.id = o.cafe_id
GROUP BY c.id, c.name, c.type, c.description, c.location, c.phone, c.hours, 
         c.accepting_orders, c.average_rating, c.total_ratings, c.cuisine_categories, 
         c.image_url, c.whatsapp_phone, c.whatsapp_enabled, c.whatsapp_notifications, 
         c.created_at, c.updated_at;

-- Fix order_queue_view
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'order_queue_view' AND table_schema = 'public') THEN
        DROP VIEW public.order_queue_view;
    END IF;
END $$;

-- Recreate as a regular view (without SECURITY DEFINER)
CREATE VIEW public.order_queue_view AS
SELECT 
    o.id,
    o.order_number,
    o.user_id,
    o.cafe_id,
    o.status,
    o.total_amount,
    o.created_at,
    o.updated_at,
    o.accepted_at,
    o.preparing_at,
    o.out_for_delivery_at,
    o.completed_at,
    c.name as cafe_name,
    p.full_name as customer_name,
    p.phone as customer_phone
FROM public.orders o
JOIN public.cafes c ON o.cafe_id = c.id
JOIN public.profiles p ON o.user_id = p.id
WHERE o.status IN ('received', 'confirmed', 'preparing', 'on_the_way');

-- ===========================================
-- FIX FUNCTION SECURITY (REMAINING WARNINGS)
-- ===========================================

-- Fix the bulk_update_order_status procedure
ALTER PROCEDURE public.bulk_update_order_status(UUID[], TEXT, UUID) SET search_path = public;

-- ===========================================
-- ADD RLS POLICIES FOR VIEWS
-- ===========================================

-- Enable RLS on views (if not already enabled)
ALTER VIEW public.cafe_dashboard_view SET (security_invoker = true);
ALTER VIEW public.order_queue_view SET (security_invoker = true);

-- ===========================================
-- VERIFICATION
-- ===========================================

-- Check that views are now regular views (not SECURITY DEFINER)
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public' 
    AND viewname IN ('cafe_dashboard_view', 'order_queue_view');

-- Check that procedure has secure search_path
SELECT 
    n.nspname as schema_name,
    p.proname as procedure_name,
    pg_get_function_identity_arguments(p.oid) as arguments,
    p.proconfig as config_settings
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
    AND p.proname = 'bulk_update_order_status'
    AND p.proconfig IS NOT NULL;
