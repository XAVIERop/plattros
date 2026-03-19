-- Fix Security Definer Views
-- Resolves the last 2 security issues related to SECURITY DEFINER views

-- ===========================================
-- FIX SECURITY DEFINER VIEWS
-- ===========================================

-- 1. Fix cafe_dashboard_view
-- Drop the existing SECURITY DEFINER view
DROP VIEW IF EXISTS public.cafe_dashboard_view;

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
    c.priority,
    c.slug,
    c.image_url,
    c.created_at,
    c.updated_at,
    COUNT(DISTINCT o.id) as total_orders,
    COUNT(DISTINCT CASE WHEN o.created_at >= CURRENT_DATE THEN o.id END) as today_orders,
    COALESCE(SUM(o.total_amount), 0) as total_revenue,
    COALESCE(SUM(CASE WHEN o.created_at >= CURRENT_DATE THEN o.total_amount ELSE 0 END), 0) as today_revenue,
    COUNT(DISTINCT mi.id) as menu_items_count,
    COUNT(DISTINCT CASE WHEN mi.is_available = true THEN mi.id END) as available_menu_items
FROM public.cafes c
LEFT JOIN public.orders o ON c.id = o.cafe_id
LEFT JOIN public.menu_items mi ON c.id = mi.cafe_id
GROUP BY c.id, c.name, c.type, c.description, c.location, c.phone, c.hours, 
         c.accepting_orders, c.average_rating, c.total_ratings, c.cuisine_categories, 
         c.priority, c.slug, c.image_url, c.created_at, c.updated_at;

-- 2. Fix order_queue_view
-- Drop the existing SECURITY DEFINER view
DROP VIEW IF EXISTS public.order_queue_view;

-- Recreate as a regular view (without SECURITY DEFINER)
CREATE VIEW public.order_queue_view AS
SELECT 
    o.id,
    o.order_number,
    o.status,
    o.total_amount,
    o.delivery_block,
    o.delivery_notes,
    o.payment_method,
    o.points_earned,
    o.estimated_delivery,
    o.created_at,
    o.status_updated_at,
    o.points_credited,
    o.accepted_at,
    o.preparing_at,
    o.out_for_delivery_at,
    o.completed_at,
    o.user_id,
    o.cafe_id,
    c.name as cafe_name,
    c.phone as cafe_phone,
    p.full_name as customer_name,
    p.phone as customer_phone,
    COUNT(oi.id) as item_count,
    COALESCE(SUM(oi.quantity), 0) as total_quantity
FROM public.orders o
LEFT JOIN public.cafes c ON o.cafe_id = c.id
LEFT JOIN public.profiles p ON o.user_id = p.id
LEFT JOIN public.order_items oi ON o.id = oi.order_id
GROUP BY o.id, o.order_number, o.status, o.total_amount, o.delivery_block, 
         o.delivery_notes, o.payment_method, o.points_earned, o.estimated_delivery, 
         o.created_at, o.status_updated_at, o.points_credited, o.accepted_at, 
         o.preparing_at, o.out_for_delivery_at, o.completed_at, o.user_id, o.cafe_id,
         c.name, c.phone, p.full_name, p.phone;

-- ===========================================
-- CREATE RLS POLICIES FOR THE VIEWS
-- ===========================================

-- Enable RLS on the views (if not already enabled)
ALTER VIEW public.cafe_dashboard_view SET (security_invoker = true);
ALTER VIEW public.order_queue_view SET (security_invoker = true);

-- Create policies for cafe_dashboard_view
-- Allow everyone to read cafe dashboard data (public information)
CREATE POLICY "Cafe dashboard view is viewable by everyone" ON public.cafe_dashboard_view
    FOR SELECT USING (true);

-- Create policies for order_queue_view
-- Allow users to view their own orders
CREATE POLICY "Users can view their own orders in queue" ON public.order_queue_view
    FOR SELECT USING (auth.uid() = user_id);

-- Allow cafe owners to view orders for their cafe
CREATE POLICY "Cafe owners can view their cafe orders in queue" ON public.order_queue_view
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- ===========================================
-- GRANT PERMISSIONS
-- ===========================================

-- Grant permissions for the views
GRANT SELECT ON public.cafe_dashboard_view TO authenticated;
GRANT SELECT ON public.order_queue_view TO authenticated;

-- ===========================================
-- COMMENTS AND DOCUMENTATION
-- ===========================================

COMMENT ON VIEW public.cafe_dashboard_view IS 'Cafe dashboard view with aggregated statistics - accessible to all users';
COMMENT ON VIEW public.order_queue_view IS 'Order queue view with order details - accessible to order owners and cafe owners';

COMMENT ON POLICY "Cafe dashboard view is viewable by everyone" ON public.cafe_dashboard_view IS 'Allows public read access to cafe dashboard data';
COMMENT ON POLICY "Users can view their own orders in queue" ON public.order_queue_view IS 'Allows users to view their own orders in the queue';
COMMENT ON POLICY "Cafe owners can view their cafe orders in queue" ON public.order_queue_view IS 'Allows cafe owners to view orders for their cafe in the queue';














