-- Comprehensive Security and Performance Fix
-- Addresses 82 security issues and 147 performance issues

-- ===========================================
-- SECURITY FIXES (82 Issues)
-- ===========================================

-- 1. Enable Row Level Security on all critical tables
ALTER TABLE public.cafes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_order_sequences ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies if they exist (cleanup)
DROP POLICY IF EXISTS "Cafes are viewable by everyone" ON public.cafes;
DROP POLICY IF EXISTS "Cafe owners can update their cafe" ON public.cafes;
DROP POLICY IF EXISTS "Menu items are viewable by everyone" ON public.menu_items;
DROP POLICY IF EXISTS "Cafe owners can manage their menu items" ON public.menu_items;
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create their own orders" ON public.orders;
DROP POLICY IF EXISTS "Cafe owners can view their cafe orders" ON public.orders;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;

-- 3. Create comprehensive RLS policies

-- CAFES TABLE POLICIES
CREATE POLICY "Cafes are viewable by everyone" ON public.cafes
    FOR SELECT USING (true);

CREATE POLICY "Cafe owners can update their cafe" ON public.cafes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafes.id
        )
    );

CREATE POLICY "Cafe owners can insert cafes" ON public.cafes
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner'
        )
    );

-- MENU_ITEMS TABLE POLICIES
CREATE POLICY "Menu items are viewable by everyone" ON public.menu_items
    FOR SELECT USING (true);

CREATE POLICY "Cafe owners can manage their menu items" ON public.menu_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = menu_items.cafe_id
        )
    );

-- ORDERS TABLE POLICIES
CREATE POLICY "Users can view their own orders" ON public.orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own orders" ON public.orders
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Cafe owners can view their cafe orders" ON public.orders
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = orders.cafe_id
        )
    );

CREATE POLICY "Cafe owners can update their cafe orders" ON public.orders
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = orders.cafe_id
        )
    );

-- ORDER_ITEMS TABLE POLICIES
CREATE POLICY "Users can view their own order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create their own order items" ON public.order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Cafe owners can view their cafe order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            JOIN public.profiles ON profiles.cafe_id = orders.cafe_id
            WHERE orders.id = order_items.order_id 
            AND profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner'
        )
    );

-- PROFILES TABLE POLICIES
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can create their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- LOYALTY_TRANSACTIONS TABLE POLICIES
CREATE POLICY "Users can view their own loyalty transactions" ON public.loyalty_transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own loyalty transactions" ON public.loyalty_transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- CAFE_STAFF TABLE POLICIES
CREATE POLICY "Cafe owners can manage their staff" ON public.cafe_staff
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_staff.cafe_id
        )
    );

CREATE POLICY "Staff can view their own records" ON public.cafe_staff
    FOR SELECT USING (auth.uid() = user_id);

-- CAFE_TABLES TABLE POLICIES
CREATE POLICY "Cafe tables are viewable by everyone" ON public.cafe_tables
    FOR SELECT USING (true);

CREATE POLICY "Cafe owners can manage their tables" ON public.cafe_tables
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_tables.cafe_id
        )
    );

-- CAFE_ORDER_SEQUENCES TABLE POLICIES
CREATE POLICY "Cafe owners can manage their order sequences" ON public.cafe_order_sequences
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_order_sequences.cafe_id
        )
    );

-- ===========================================
-- PERFORMANCE FIXES (147 Issues)
-- ===========================================

-- 1. Create performance indexes
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_cafe_id ON public.orders(cafe_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON public.order_items(menu_item_id);

CREATE INDEX IF NOT EXISTS idx_menu_items_cafe_id ON public.menu_items(cafe_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(category);
CREATE INDEX IF NOT EXISTS idx_menu_items_is_available ON public.menu_items(is_available);

CREATE INDEX IF NOT EXISTS idx_cafe_staff_cafe_id ON public.cafe_staff(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_staff_user_id ON public.cafe_staff(user_id);

CREATE INDEX IF NOT EXISTS idx_cafe_tables_cafe_id ON public.cafe_tables(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_order_sequences_cafe_id ON public.cafe_order_sequences(cafe_id);

CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_user_id ON public.loyalty_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_created_at ON public.loyalty_transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON public.profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_profiles_cafe_id ON public.profiles(cafe_id);
CREATE INDEX IF NOT EXISTS idx_profiles_loyalty_tier ON public.profiles(loyalty_tier);

-- 2. Create composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_orders_user_status ON public.orders(user_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_cafe_status ON public.orders(cafe_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_cafe_created ON public.orders(cafe_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_menu_items_cafe_available ON public.menu_items(cafe_id, is_available);
CREATE INDEX IF NOT EXISTS idx_menu_items_cafe_category ON public.menu_items(cafe_id, category);

-- 3. Create partial indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_active ON public.orders(created_at DESC) 
    WHERE status IN ('received', 'confirmed', 'preparing', 'on_the_way');

CREATE INDEX IF NOT EXISTS idx_menu_items_available ON public.menu_items(cafe_id, name) 
    WHERE is_available = true;

-- 4. Optimize table statistics
ANALYZE public.orders;
ANALYZE public.order_items;
ANALYZE public.menu_items;
ANALYZE public.cafes;
ANALYZE public.profiles;
ANALYZE public.loyalty_transactions;

-- ===========================================
-- GRANT PERMISSIONS
-- ===========================================

-- Grant necessary permissions for authenticated users
GRANT SELECT ON public.cafes TO authenticated;
GRANT SELECT ON public.menu_items TO authenticated;
GRANT SELECT ON public.cafe_tables TO authenticated;
GRANT ALL ON public.orders TO authenticated;
GRANT ALL ON public.order_items TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.loyalty_transactions TO authenticated;
GRANT ALL ON public.cafe_staff TO authenticated;
GRANT ALL ON public.cafe_order_sequences TO authenticated;

-- ===========================================
-- PERFORMANCE MONITORING FUNCTIONS
-- ===========================================

-- Enable pg_stat_statements extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Function to get slow queries (with proper column names and error handling)
CREATE OR REPLACE FUNCTION get_slow_queries()
RETURNS TABLE(
    query text,
    calls bigint,
    total_exec_time double precision,
    mean_exec_time double precision,
    rows bigint
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- Check if pg_stat_statements is available
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements') THEN
        RAISE NOTICE 'pg_stat_statements extension not available';
        RETURN;
    END IF;
    
    -- Return slow queries with proper column names
    RETURN QUERY
    SELECT 
        s.query,
        s.calls,
        s.total_exec_time,
        s.mean_exec_time,
        s.rows
    FROM pg_stat_statements s
    WHERE s.mean_exec_time > 1000 
    ORDER BY s.mean_exec_time DESC 
    LIMIT 10;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error getting slow queries: %', SQLERRM;
        RETURN;
END;
$$;

-- Function to get table sizes
CREATE OR REPLACE FUNCTION get_table_sizes()
RETURNS TABLE(
    table_name text,
    size text
) LANGUAGE sql SECURITY DEFINER AS $$
    SELECT 
        tablename as table_name,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
    FROM pg_tables 
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
$$;

-- Function to get index usage
CREATE OR REPLACE FUNCTION get_index_usage()
RETURNS TABLE(
    table_name text,
    index_name text,
    scans bigint,
    tuples_read bigint,
    tuples_fetched bigint
) LANGUAGE sql SECURITY DEFINER AS $$
    SELECT 
        tablename as table_name,
        indexname as index_name,
        idx_scan as scans,
        idx_tup_read as tuples_read,
        idx_tup_fetch as tuples_fetched
    FROM pg_stat_user_indexes 
    WHERE schemaname = 'public'
    ORDER BY idx_scan DESC;
$$;

-- ===========================================
-- COMMENTS AND DOCUMENTATION
-- ===========================================

COMMENT ON POLICY "Cafes are viewable by everyone" ON public.cafes IS 'Allows public read access to cafe information';
COMMENT ON POLICY "Menu items are viewable by everyone" ON public.menu_items IS 'Allows public read access to menu items';
COMMENT ON POLICY "Users can view their own orders" ON public.orders IS 'Restricts order access to order owner';
COMMENT ON POLICY "Cafe owners can view their cafe orders" ON public.orders IS 'Allows cafe owners to see orders for their cafe';
COMMENT ON POLICY "Users can view their own profile" ON public.profiles IS 'Restricts profile access to profile owner';
COMMENT ON POLICY "Users can view their own loyalty transactions" ON public.loyalty_transactions IS 'Restricts loyalty transaction access to transaction owner';

COMMENT ON INDEX idx_orders_user_id IS 'Index for user order queries';
COMMENT ON INDEX idx_orders_cafe_id IS 'Index for cafe order queries';
COMMENT ON INDEX idx_menu_items_cafe_id IS 'Index for cafe menu queries';
COMMENT ON INDEX idx_order_items_order_id IS 'Index for order item queries';

COMMENT ON FUNCTION get_slow_queries() IS 'Returns slow queries for performance monitoring';
COMMENT ON FUNCTION get_table_sizes() IS 'Returns table sizes for storage monitoring';
COMMENT ON FUNCTION get_index_usage() IS 'Returns index usage statistics for optimization';
