-- Final Comprehensive Fix
-- Addresses all remaining security and performance issues

-- ===========================================
-- PERFORMANCE OPTIMIZATION FOR SLOW QUERIES
-- ===========================================

-- Create additional indexes for common query patterns
-- These will help optimize the slow queries we identified

-- Index for order queries with status filtering
CREATE INDEX IF NOT EXISTS idx_orders_status_created_at 
ON public.orders(status, created_at DESC);

-- Index for cafe queries with active orders
CREATE INDEX IF NOT EXISTS idx_cafes_accepting_orders 
ON public.cafes(accepting_orders) WHERE accepting_orders = true;

-- Index for menu items with availability
CREATE INDEX IF NOT EXISTS idx_menu_items_available_cafe 
ON public.menu_items(cafe_id, is_available) WHERE is_available = true;

-- Index for order notifications with user and read status
CREATE INDEX IF NOT EXISTS idx_order_notifications_user_read 
ON public.order_notifications(user_id, is_read, created_at DESC);

-- Index for profiles with loyalty tier
CREATE INDEX IF NOT EXISTS idx_profiles_loyalty_tier_active 
ON public.profiles(loyalty_tier) WHERE loyalty_tier IS NOT NULL;

-- Composite index for order analytics
CREATE INDEX IF NOT EXISTS idx_orders_cafe_status_amount 
ON public.orders(cafe_id, status, total_amount, created_at);

-- Note: realtime.subscription table is owned by Supabase
-- Index creation not possible on system tables

-- ===========================================
-- QUERY OPTIMIZATION FUNCTIONS
-- ===========================================

-- Create optimized function for cafe dashboard queries
CREATE OR REPLACE FUNCTION public.get_cafe_dashboard_optimized(cafe_uuid UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    total_orders BIGINT,
    total_revenue NUMERIC,
    average_rating NUMERIC,
    total_ratings BIGINT,
    active_orders BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        COALESCE(COUNT(o.id), 0) as total_orders,
        COALESCE(SUM(o.total_amount), 0) as total_revenue,
        c.average_rating,
        c.total_ratings,
        COUNT(CASE WHEN o.status IN ('received', 'confirmed', 'preparing', 'on_the_way') THEN 1 END) as active_orders
    FROM public.cafes c
    LEFT JOIN public.orders o ON c.id = o.cafe_id
    WHERE c.id = cafe_uuid
    GROUP BY c.id, c.name, c.average_rating, c.total_ratings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create optimized function for order queue
CREATE OR REPLACE FUNCTION public.get_order_queue_optimized(cafe_uuid UUID)
RETURNS TABLE (
    id UUID,
    order_number TEXT,
    customer_name TEXT,
    status order_status,
    total_amount NUMERIC,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.id,
        o.order_number,
        p.full_name,
        o.status,
        o.total_amount,
        o.created_at
    FROM public.orders o
    JOIN public.profiles p ON o.user_id = p.id
    WHERE o.cafe_id = cafe_uuid
        AND o.status IN ('received', 'confirmed', 'preparing', 'on_the_way')
    ORDER BY o.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- CLEANUP AND MAINTENANCE
-- ===========================================

-- Create function to clean up old data
CREATE OR REPLACE FUNCTION public.cleanup_old_data()
RETURNS VOID AS $$
BEGIN
    -- Clean up old notifications (older than 30 days)
    DELETE FROM public.order_notifications 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- Clean up old audit logs (older than 90 days)
    DELETE FROM public.audit_log_entries 
    WHERE created_at < NOW() - INTERVAL '90 days';
    
    -- Note: realtime.subscription cleanup handled by Supabase automatically
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- ANALYZE TABLES FOR OPTIMIZATION
-- ===========================================

-- Update statistics for all tables
ANALYZE public.orders;
ANALYZE public.cafes;
ANALYZE public.menu_items;
ANALYZE public.profiles;
ANALYZE public.order_notifications;
ANALYZE public.loyalty_transactions;
ANALYZE public.cafe_staff;
ANALYZE public.cafe_tables;

-- ===========================================
-- VERIFICATION QUERIES
-- ===========================================

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
