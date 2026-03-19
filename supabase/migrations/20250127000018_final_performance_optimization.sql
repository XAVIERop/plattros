-- Final Performance Optimization
-- Fixes all remaining unindexed foreign keys and removes unused indexes
-- This completes the database optimization process

-- ===========================================
-- ADD MISSING FOREIGN KEY INDEXES
-- ===========================================

-- Add indexes for foreign key constraints that are missing covering indexes
-- This improves JOIN performance and foreign key constraint checks

-- cafe_loyalty_transactions table
CREATE INDEX IF NOT EXISTS idx_cafe_loyalty_transactions_cafe_id 
ON public.cafe_loyalty_transactions(cafe_id);

CREATE INDEX IF NOT EXISTS idx_cafe_loyalty_transactions_order_id 
ON public.cafe_loyalty_transactions(order_id);

-- cafe_monthly_maintenance table
CREATE INDEX IF NOT EXISTS idx_cafe_monthly_maintenance_cafe_id 
ON public.cafe_monthly_maintenance(cafe_id);

-- item_analytics table
CREATE INDEX IF NOT EXISTS idx_item_analytics_menu_item_id 
ON public.item_analytics(menu_item_id);

-- loyalty_transactions table
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_order_id 
ON public.loyalty_transactions(order_id);

-- order_notifications table
CREATE INDEX IF NOT EXISTS idx_order_notifications_order_id 
ON public.order_notifications(order_id);

-- order_queue table
CREATE INDEX IF NOT EXISTS idx_order_queue_cafe_id 
ON public.order_queue(cafe_id);

CREATE INDEX IF NOT EXISTS idx_order_queue_order_id 
ON public.order_queue(order_id);

-- orders table
CREATE INDEX IF NOT EXISTS idx_orders_table_id 
ON public.orders(table_id);

-- user_bonuses table
CREATE INDEX IF NOT EXISTS idx_user_bonuses_order_id 
ON public.user_bonuses(order_id);

-- ===========================================
-- REMOVE UNUSED INDEXES
-- ===========================================

-- Remove indexes that have never been used to reduce storage overhead
-- and improve write performance

-- orders table unused indexes
DROP INDEX IF EXISTS idx_orders_user_id;
DROP INDEX IF EXISTS idx_orders_cafe_id;
DROP INDEX IF EXISTS idx_orders_status;
DROP INDEX IF EXISTS idx_orders_created_at;
DROP INDEX IF EXISTS idx_orders_user_status;
DROP INDEX IF EXISTS idx_orders_cafe_status;
DROP INDEX IF EXISTS idx_orders_customer_phone;
DROP INDEX IF EXISTS idx_orders_table_number;
DROP INDEX IF EXISTS idx_orders_delivery_block;
DROP INDEX IF EXISTS idx_orders_estimated_delivery;
DROP INDEX IF EXISTS idx_orders_status_updated;
DROP INDEX IF EXISTS idx_orders_active;
DROP INDEX IF EXISTS idx_orders_has_rating;
DROP INDEX IF EXISTS idx_orders_phone_number;

-- menu_items table unused indexes
DROP INDEX IF EXISTS idx_menu_items_cafe_id;
DROP INDEX IF EXISTS idx_menu_items_is_available;
DROP INDEX IF EXISTS idx_menu_items_cafe_category;
DROP INDEX IF EXISTS idx_menu_items_price;

-- cafe_staff table unused indexes
DROP INDEX IF EXISTS idx_cafe_staff_cafe_id;
DROP INDEX IF EXISTS idx_cafe_staff_user_id;

-- cafe_tables table unused indexes
DROP INDEX IF EXISTS idx_cafe_tables_cafe_id;

-- cafe_order_sequences table unused indexes
DROP INDEX IF EXISTS idx_cafe_order_sequences_cafe_id;

-- loyalty_transactions table unused indexes
DROP INDEX IF EXISTS idx_loyalty_transactions_user_id;
DROP INDEX IF EXISTS idx_loyalty_transactions_created_at;

-- cafe_printer_configs table unused indexes
DROP INDEX IF EXISTS idx_cafe_printer_configs_active;
DROP INDEX IF EXISTS idx_cafe_printer_configs_default;
DROP INDEX IF EXISTS idx_cafe_printer_configs_printnode_id;

-- cafe_loyalty_points table unused indexes
DROP INDEX IF EXISTS idx_cafe_loyalty_points_cafe;

-- cafes table unused indexes
DROP INDEX IF EXISTS idx_cafes_active_orders;

-- maintenance_periods table unused indexes
DROP INDEX IF EXISTS idx_maintenance_periods_status;
DROP INDEX IF EXISTS idx_maintenance_periods_end_date;

-- profiles table unused indexes
DROP INDEX IF EXISTS idx_profiles_loyalty_tier;

-- order_ratings table unused indexes
DROP INDEX IF EXISTS idx_order_ratings_rating;

-- ===========================================
-- ANALYZE TABLES FOR OPTIMIZATION
-- ===========================================

-- Update table statistics for the query planner
ANALYZE public.cafe_loyalty_transactions;
ANALYZE public.cafe_monthly_maintenance;
ANALYZE public.item_analytics;
ANALYZE public.loyalty_transactions;
ANALYZE public.order_notifications;
ANALYZE public.order_queue;
ANALYZE public.orders;
ANALYZE public.user_bonuses;

-- ===========================================
-- VERIFICATION QUERIES
-- ===========================================

-- Verify foreign key indexes were created
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_%_cafe_id' 
    OR indexname LIKE 'idx_%_order_id'
    OR indexname LIKE 'idx_%_menu_item_id'
    OR indexname LIKE 'idx_%_table_id'
ORDER BY tablename, indexname;

-- Check for any remaining unused indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE schemaname = 'public' 
    AND idx_scan = 0
ORDER BY tablename, indexname;














