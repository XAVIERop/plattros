-- Production Performance Optimization Migration
-- This migration adds critical indexes and optimizations for high-volume production use

-- 1. CRITICAL INDEXES FOR HIGH-VOLUME QUERIES
-- Orders table indexes (most critical for performance)
CREATE INDEX IF NOT EXISTS idx_orders_user_id_created_at_desc ON public.orders(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_cafe_id_created_at_desc ON public.orders(cafe_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status_created_at_desc ON public.orders(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_order_number_unique ON public.orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_phone_number ON public.orders(phone_number) WHERE phone_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_delivery_block ON public.orders(delivery_block);
CREATE INDEX IF NOT EXISTS idx_orders_payment_method ON public.orders(payment_method);
CREATE INDEX IF NOT EXISTS idx_orders_points_credited ON public.orders(points_credited) WHERE points_credited = false;

-- Order items indexes
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON public.order_items(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_order_items_quantity ON public.order_items(quantity);

-- Menu items indexes
CREATE INDEX IF NOT EXISTS idx_menu_items_cafe_id_available ON public.menu_items(cafe_id, is_available) WHERE is_available = true;
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(category);
CREATE INDEX IF NOT EXISTS idx_menu_items_price ON public.menu_items(price);
CREATE INDEX IF NOT EXISTS idx_menu_items_name_gin ON public.menu_items USING gin(to_tsvector('english', name));

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email_unique ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_block ON public.profiles(block);
CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON public.profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_profiles_loyalty_tier ON public.profiles(loyalty_tier);
CREATE INDEX IF NOT EXISTS idx_profiles_loyalty_points ON public.profiles(loyalty_points DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_total_orders ON public.profiles(total_orders DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_total_spent ON public.profiles(total_spent DESC);

-- Cafe staff indexes
CREATE INDEX IF NOT EXISTS idx_cafe_staff_user_id_active ON public.cafe_staff(user_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_cafe_staff_cafe_id_active ON public.cafe_staff(cafe_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_cafe_staff_role ON public.cafe_staff(role);

-- Cafes indexes
CREATE INDEX IF NOT EXISTS idx_cafes_active ON public.cafes(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_cafes_type ON public.cafes(type);
CREATE INDEX IF NOT EXISTS idx_cafes_location ON public.cafes(location);
CREATE INDEX IF NOT EXISTS idx_cafes_priority ON public.cafes(priority DESC) WHERE priority IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cafes_rating ON public.cafes(average_rating DESC) WHERE average_rating IS NOT NULL;

-- Loyalty transactions indexes
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_user_id_created_at ON public.loyalty_transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_order_id ON public.loyalty_transactions(order_id) WHERE order_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_type ON public.loyalty_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_points_change ON public.loyalty_transactions(points_change);

-- Cafe ratings indexes
CREATE INDEX IF NOT EXISTS idx_cafe_ratings_cafe_id_rating ON public.cafe_ratings(cafe_id, rating);
CREATE INDEX IF NOT EXISTS idx_cafe_ratings_user_id ON public.cafe_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_cafe_ratings_created_at ON public.cafe_ratings(created_at DESC);

-- User favorites indexes
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON public.user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_cafe_id ON public.user_favorites(cafe_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_cafe ON public.user_favorites(user_id, cafe_id);

-- Order notifications indexes
CREATE INDEX IF NOT EXISTS idx_order_notifications_cafe_id_created_at ON public.order_notifications(cafe_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_notifications_order_id ON public.order_notifications(order_id);
CREATE INDEX IF NOT EXISTS idx_order_notifications_is_read ON public.order_notifications(is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_order_notifications_type ON public.order_notifications(notification_type);

-- 2. COMPOSITE INDEXES FOR COMPLEX QUERIES
-- Orders with cafe and user info
CREATE INDEX IF NOT EXISTS idx_orders_cafe_user_status ON public.orders(cafe_id, user_id, status, created_at DESC);

-- Menu items with cafe and availability
CREATE INDEX IF NOT EXISTS idx_menu_items_cafe_category_available ON public.menu_items(cafe_id, category, is_available) WHERE is_available = true;

-- Profiles with loyalty info
CREATE INDEX IF NOT EXISTS idx_profiles_tier_points ON public.profiles(loyalty_tier, loyalty_points DESC);

-- 3. PARTIAL INDEXES FOR COMMON FILTERS
-- Active orders only
CREATE INDEX IF NOT EXISTS idx_orders_active_status ON public.orders(status, created_at DESC) 
WHERE status IN ('received', 'confirmed', 'preparing', 'on_the_way');

-- Available menu items only
CREATE INDEX IF NOT EXISTS idx_menu_items_available_price ON public.menu_items(price) 
WHERE is_available = true;

-- Active cafe staff only
CREATE INDEX IF NOT EXISTS idx_cafe_staff_active_role ON public.cafe_staff(role, cafe_id) 
WHERE is_active = true;

-- 4. TEXT SEARCH INDEXES
-- Full-text search on menu items
CREATE INDEX IF NOT EXISTS idx_menu_items_search ON public.menu_items 
USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- Full-text search on cafes
CREATE INDEX IF NOT EXISTS idx_cafes_search ON public.cafes 
USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '') || ' ' || location));

-- 5. STATISTICS AND ANALYTICS INDEXES
-- Order analytics
CREATE INDEX IF NOT EXISTS idx_orders_analytics_date ON public.orders(DATE(created_at), cafe_id);
CREATE INDEX IF NOT EXISTS idx_orders_analytics_hour ON public.orders(EXTRACT(hour FROM created_at), cafe_id);

-- Revenue analytics
CREATE INDEX IF NOT EXISTS idx_orders_revenue_date ON public.orders(DATE(created_at), total_amount, cafe_id);

-- 6. PERFORMANCE MONITORING FUNCTIONS
-- Function to analyze query performance
CREATE OR REPLACE FUNCTION public.analyze_query_performance()
RETURNS TABLE (
  query_text text,
  calls bigint,
  total_time double precision,
  mean_time double precision,
  rows bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
  FROM pg_stat_statements 
  ORDER BY mean_time DESC 
  LIMIT 20;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get index usage statistics
CREATE OR REPLACE FUNCTION public.get_index_usage_stats()
RETURNS TABLE (
  schemaname text,
  tablename text,
  indexname text,
  idx_tup_read bigint,
  idx_tup_fetch bigint,
  idx_scan bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.schemaname,
    s.tablename,
    s.indexname,
    s.idx_tup_read,
    s.idx_tup_fetch,
    s.idx_scan
  FROM pg_stat_user_indexes s
  ORDER BY s.idx_scan DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. MATERIALIZED VIEWS FOR ANALYTICS
-- Daily order summary
CREATE MATERIALIZED VIEW IF NOT EXISTS public.daily_order_summary AS
SELECT 
  DATE(created_at) as order_date,
  cafe_id,
  COUNT(*) as total_orders,
  SUM(total_amount) as total_revenue,
  AVG(total_amount) as avg_order_value,
  COUNT(DISTINCT user_id) as unique_customers
FROM public.orders
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at), cafe_id
ORDER BY order_date DESC, total_revenue DESC;

-- Create index on materialized view
CREATE INDEX IF NOT EXISTS idx_daily_order_summary_date_cafe ON public.daily_order_summary(order_date, cafe_id);

-- Cafe performance summary
CREATE MATERIALIZED VIEW IF NOT EXISTS public.cafe_performance_summary AS
SELECT 
  c.id as cafe_id,
  c.name as cafe_name,
  c.type as cafe_type,
  COUNT(o.id) as total_orders,
  SUM(o.total_amount) as total_revenue,
  AVG(o.total_amount) as avg_order_value,
  COUNT(DISTINCT o.user_id) as unique_customers,
  AVG(cr.rating) as avg_rating,
  COUNT(cr.id) as total_ratings
FROM public.cafes c
LEFT JOIN public.orders o ON c.id = o.cafe_id AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN public.cafe_ratings cr ON c.id = cr.cafe_id
WHERE c.is_active = true
GROUP BY c.id, c.name, c.type
ORDER BY total_revenue DESC;

-- Create index on materialized view
CREATE INDEX IF NOT EXISTS idx_cafe_performance_summary_revenue ON public.cafe_performance_summary(total_revenue DESC);

-- 8. REFRESH FUNCTIONS FOR MATERIALIZED VIEWS
CREATE OR REPLACE FUNCTION public.refresh_analytics_views()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW public.daily_order_summary;
  REFRESH MATERIALIZED VIEW public.cafe_performance_summary;
  
  -- Log the refresh
  INSERT INTO public.system_events (event_type, description, created_at)
  VALUES ('analytics_refresh', 'Analytics views refreshed successfully', now());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. AUTOMATED MAINTENANCE FUNCTIONS
-- Function to clean up old notifications
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM public.order_notifications 
  WHERE created_at < CURRENT_DATE - INTERVAL '30 days'
  AND is_read = true;
  
  -- Log the cleanup
  INSERT INTO public.system_events (event_type, description, created_at)
  VALUES ('cleanup_notifications', 'Old notifications cleaned up', now());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to archive old orders
CREATE OR REPLACE FUNCTION public.archive_old_orders()
RETURNS void AS $$
BEGIN
  -- Create archive table if it doesn't exist
  CREATE TABLE IF NOT EXISTS public.orders_archive (LIKE public.orders INCLUDING ALL);
  
  -- Move old completed orders to archive
  INSERT INTO public.orders_archive 
  SELECT * FROM public.orders 
  WHERE status = 'completed' 
  AND created_at < CURRENT_DATE - INTERVAL '90 days';
  
  -- Delete archived orders from main table
  DELETE FROM public.orders 
  WHERE status = 'completed' 
  AND created_at < CURRENT_DATE - INTERVAL '90 days';
  
  -- Log the archive
  INSERT INTO public.system_events (event_type, description, created_at)
  VALUES ('archive_orders', 'Old orders archived', now());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. PERFORMANCE MONITORING VIEW
CREATE OR REPLACE VIEW public.performance_monitoring AS
SELECT 
  'Database Size' as metric,
  pg_size_pretty(pg_database_size(current_database())) as value,
  'info' as level
UNION ALL
SELECT 
  'Total Tables',
  count(*)::text,
  'info'
FROM information_schema.tables 
WHERE table_schema = 'public'
UNION ALL
SELECT 
  'Total Indexes',
  count(*)::text,
  'info'
FROM pg_indexes 
WHERE schemaname = 'public'
UNION ALL
SELECT 
  'Active Connections',
  count(*)::text,
  CASE WHEN count(*) > 50 THEN 'warning' ELSE 'info' END
FROM pg_stat_activity 
WHERE state = 'active'
UNION ALL
SELECT 
  'Cache Hit Ratio',
  round(
    (sum(blks_hit) * 100.0 / (sum(blks_hit) + sum(blks_read)))::numeric, 2
  )::text || '%',
  CASE 
    WHEN (sum(blks_hit) * 100.0 / (sum(blks_hit) + sum(blks_read))) < 90 
    THEN 'warning' 
    ELSE 'info' 
  END
FROM pg_stat_database 
WHERE datname = current_database();

-- 11. GRANT PERMISSIONS
GRANT SELECT ON public.performance_monitoring TO authenticated;
GRANT SELECT ON public.daily_order_summary TO authenticated;
GRANT SELECT ON public.cafe_performance_summary TO authenticated;
GRANT EXECUTE ON FUNCTION public.analyze_query_performance() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_index_usage_stats() TO authenticated;

-- 12. CREATE SYSTEM EVENTS TABLE FOR LOGGING
CREATE TABLE IF NOT EXISTS public.system_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_type TEXT NOT NULL,
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_system_events_type_created_at ON public.system_events(event_type, created_at DESC);

-- 13. ENABLE EXTENSIONS FOR PERFORMANCE MONITORING
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 14. CONFIGURE AUTOVACUUM FOR BETTER PERFORMANCE
-- These settings will be applied to the database
-- (Note: Some settings may require superuser privileges)

-- 15. TEST PERFORMANCE OPTIMIZATIONS
SELECT 'Performance optimization migration completed successfully!' as status;

-- Test critical indexes
SELECT 'Testing critical indexes...' as status;
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM public.orders 
WHERE user_id = '00000000-0000-0000-0000-000000000000' 
ORDER BY created_at DESC 
LIMIT 10;

-- Test materialized views
SELECT 'Testing materialized views...' as status;
SELECT COUNT(*) as daily_summary_count FROM public.daily_order_summary;
SELECT COUNT(*) as cafe_performance_count FROM public.cafe_performance_summary;

-- Test performance monitoring
SELECT 'Performance monitoring status:' as status;
SELECT * FROM public.performance_monitoring;


