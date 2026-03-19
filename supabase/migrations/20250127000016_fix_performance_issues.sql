-- Fix Performance Issues
-- Resolves auth_rls_initplan warnings and multiple permissive policies
-- This will optimize RLS policy performance and clean up duplicate policies

-- ===========================================
-- FIX AUTH RLS INITPLAN WARNINGS
-- ===========================================

-- The issue: auth.uid() calls in RLS policies are re-evaluated for each row
-- Solution: Wrap auth.uid() calls in (SELECT auth.uid()) to evaluate once per query

-- Fix profiles table policies
DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;
CREATE POLICY "Users can create their own profile" ON public.profiles
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING ((SELECT auth.uid()) = id);

-- Fix cafes table policies
DROP POLICY IF EXISTS "Cafe owners can insert cafes" ON public.cafes;
CREATE POLICY "Cafe owners can insert cafes" ON public.cafes
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner'
        )
    );

DROP POLICY IF EXISTS "Cafe owners can update their cafe" ON public.cafes;
CREATE POLICY "Cafe owners can update their cafe" ON public.cafes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = id
        )
    );

DROP POLICY IF EXISTS "Cafe owners can update their cafe settings" ON public.cafes;
CREATE POLICY "Cafe owners can update their cafe settings" ON public.cafes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = id
        )
    );

DROP POLICY IF EXISTS "Cafe owners can view their cafe data" ON public.cafes;
CREATE POLICY "Cafe owners can view their cafe data" ON public.cafes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = id
        )
    );

-- Fix menu_items table policies
DROP POLICY IF EXISTS "Cafe owners can manage their menu items" ON public.menu_items;
CREATE POLICY "Cafe owners can manage their menu items" ON public.menu_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

DROP POLICY IF EXISTS "Cafe owners can update their menu items" ON public.menu_items;
CREATE POLICY "Cafe owners can update their menu items" ON public.menu_items
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

DROP POLICY IF EXISTS "Cafe owners can view their menu items" ON public.menu_items;
CREATE POLICY "Cafe owners can view their menu items" ON public.menu_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Fix orders table policies
DROP POLICY IF EXISTS "Cafe owners can update their cafe orders" ON public.orders;
CREATE POLICY "Cafe owners can update their cafe orders" ON public.orders
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

DROP POLICY IF EXISTS "Cafe owners can view their cafe orders" ON public.orders;
CREATE POLICY "Cafe owners can view their cafe orders" ON public.orders
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

DROP POLICY IF EXISTS "Users can create their own orders" ON public.orders;
CREATE POLICY "Users can create their own orders" ON public.orders
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own orders" ON public.orders;
CREATE POLICY "Users can update their own orders" ON public.orders
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
CREATE POLICY "Users can view their own orders" ON public.orders
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Fix order_items table policies
DROP POLICY IF EXISTS "Cafe owners can view their cafe order items" ON public.order_items;
CREATE POLICY "Cafe owners can view their cafe order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = (
                SELECT cafe_id FROM public.orders WHERE id = order_id
            )
        )
    );

DROP POLICY IF EXISTS "Users can create order items" ON public.order_items;
CREATE POLICY "Users can create order items" ON public.order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_id 
            AND orders.user_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can create their own order items" ON public.order_items;
CREATE POLICY "Users can create their own order items" ON public.order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_id 
            AND orders.user_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can view their order items" ON public.order_items;
CREATE POLICY "Users can view their order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_id 
            AND orders.user_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can view their own order items" ON public.order_items;
CREATE POLICY "Users can view their own order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_id 
            AND orders.user_id = (SELECT auth.uid())
        )
    );

-- Fix loyalty_transactions table policies
DROP POLICY IF EXISTS "Users can create their own loyalty transactions" ON public.loyalty_transactions;
CREATE POLICY "Users can create their own loyalty transactions" ON public.loyalty_transactions
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert their loyalty transactions" ON public.loyalty_transactions;
CREATE POLICY "Users can insert their loyalty transactions" ON public.loyalty_transactions
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view their loyalty transactions" ON public.loyalty_transactions;
CREATE POLICY "Users can view their loyalty transactions" ON public.loyalty_transactions
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view their own loyalty transactions" ON public.loyalty_transactions;
CREATE POLICY "Users can view their own loyalty transactions" ON public.loyalty_transactions
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- ===========================================
-- CLEAN UP DUPLICATE POLICIES
-- ===========================================

-- Remove duplicate policies that are causing multiple permissive policy warnings
-- Keep the most specific/restrictive policies and remove redundant ones

-- Clean up profiles table
DROP POLICY IF EXISTS "profiles_allow_all" ON public.profiles;

-- Clean up cafes table  
DROP POLICY IF EXISTS "Anyone can view active cafes" ON public.cafes;
DROP POLICY IF EXISTS "Cafes are viewable by everyone" ON public.cafes;
DROP POLICY IF EXISTS "Cafe owners can update their cafe" ON public.cafes;

-- Clean up menu_items table
DROP POLICY IF EXISTS "Anyone can view available menu items" ON public.menu_items;
DROP POLICY IF EXISTS "Anyone can view menu items" ON public.menu_items;
DROP POLICY IF EXISTS "Menu items are viewable by everyone" ON public.menu_items;
DROP POLICY IF EXISTS "menu_items_allow_all" ON public.menu_items;

-- Clean up orders table
DROP POLICY IF EXISTS "Allow cafe owners to update orders" ON public.orders;
DROP POLICY IF EXISTS "Allow updates" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_simple" ON public.orders;

-- Clean up order_items table
DROP POLICY IF EXISTS "order_items_allow_all" ON public.order_items;

-- Clean up loyalty_transactions table
DROP POLICY IF EXISTS "Users can create their own loyalty transactions" ON public.loyalty_transactions;
DROP POLICY IF EXISTS "Users can view their loyalty transactions" ON public.loyalty_transactions;

-- Clean up cafe_staff table
DROP POLICY IF EXISTS "cafe_staff_allow_all" ON public.cafe_staff;
DROP POLICY IF EXISTS "cafe_staff_final" ON public.cafe_staff;
DROP POLICY IF EXISTS "cafe_staff_public_read" ON public.cafe_staff;
DROP POLICY IF EXISTS "cafe_staff_authenticated_update" ON public.cafe_staff;

-- Clean up cafe_tables table
DROP POLICY IF EXISTS "Cafe tables are viewable by everyone" ON public.cafe_tables;

-- Clean up order_notifications table
DROP POLICY IF EXISTS "notifications_final" ON public.order_notifications;

-- Clean up order_ratings table
DROP POLICY IF EXISTS "Allow authenticated users to insert ratings" ON public.order_ratings;

-- Clean up user_bonuses table
DROP POLICY IF EXISTS "Allow cafe owners to manage user_bonuses" ON public.user_bonuses;
DROP POLICY IF EXISTS "Allow users to read own bonuses" ON public.user_bonuses;
DROP POLICY IF EXISTS "Users can view own bonuses" ON public.user_bonuses;

-- Clean up maintenance_periods table
DROP POLICY IF EXISTS "Users can view own maintenance periods" ON public.maintenance_periods;

-- Clean up tier_maintenance table
DROP POLICY IF EXISTS "Users can view own tier maintenance" ON public.tier_maintenance;

-- ===========================================
-- REMOVE DUPLICATE INDEXES
-- ===========================================

-- Remove duplicate indexes to improve performance
DROP INDEX IF EXISTS idx_menu_items_cafe_available;
DROP INDEX IF EXISTS idx_orders_cafe_created;
DROP INDEX IF EXISTS idx_orders_cafe_id_status;
DROP INDEX IF EXISTS idx_orders_user_id_status;

-- ===========================================
-- CREATE OPTIMIZED POLICIES
-- ===========================================

-- Create single, optimized policies for each table/action combination

-- Profiles: Single policy for each action
CREATE POLICY "profiles_insert_optimized" ON public.profiles
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = id);

CREATE POLICY "profiles_select_optimized" ON public.profiles
    FOR SELECT USING ((SELECT auth.uid()) = id);

CREATE POLICY "profiles_update_optimized" ON public.profiles
    FOR UPDATE USING ((SELECT auth.uid()) = id);

-- Cafes: Single policy for each action
CREATE POLICY "cafes_select_optimized" ON public.cafes
    FOR SELECT USING (true); -- Public read access

CREATE POLICY "cafes_insert_optimized" ON public.cafes
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner'
        )
    );

CREATE POLICY "cafes_update_optimized" ON public.cafes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = id
        )
    );

-- Menu items: Single policy for each action
CREATE POLICY "menu_items_select_optimized" ON public.menu_items
    FOR SELECT USING (true); -- Public read access

CREATE POLICY "menu_items_insert_optimized" ON public.menu_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

CREATE POLICY "menu_items_update_optimized" ON public.menu_items
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

CREATE POLICY "menu_items_delete_optimized" ON public.menu_items
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Orders: Single policy for each action
CREATE POLICY "orders_select_optimized" ON public.orders
    FOR SELECT USING (
        (SELECT auth.uid()) = user_id OR
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

CREATE POLICY "orders_insert_optimized" ON public.orders
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "orders_update_optimized" ON public.orders
    FOR UPDATE USING (
        (SELECT auth.uid()) = user_id OR
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Order items: Single policy for each action
CREATE POLICY "order_items_select_optimized" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_id 
            AND (
                orders.user_id = (SELECT auth.uid()) OR
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE profiles.id = (SELECT auth.uid()) 
                    AND profiles.user_type = 'cafe_owner' 
                    AND profiles.cafe_id = orders.cafe_id
                )
            )
        )
    );

CREATE POLICY "order_items_insert_optimized" ON public.order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_id 
            AND orders.user_id = (SELECT auth.uid())
        )
    );

-- Loyalty transactions: Single policy for each action
CREATE POLICY "loyalty_transactions_select_optimized" ON public.loyalty_transactions
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "loyalty_transactions_insert_optimized" ON public.loyalty_transactions
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

-- ===========================================
-- COMMENTS AND DOCUMENTATION
-- ===========================================

COMMENT ON POLICY "profiles_insert_optimized" ON public.profiles IS 'Optimized policy for profile creation with single auth.uid() evaluation';
COMMENT ON POLICY "profiles_select_optimized" ON public.profiles IS 'Optimized policy for profile viewing with single auth.uid() evaluation';
COMMENT ON POLICY "profiles_update_optimized" ON public.profiles IS 'Optimized policy for profile updates with single auth.uid() evaluation';

COMMENT ON POLICY "cafes_select_optimized" ON public.cafes IS 'Optimized policy for cafe viewing - public access';
COMMENT ON POLICY "cafes_insert_optimized" ON public.cafes IS 'Optimized policy for cafe creation with single auth.uid() evaluation';
COMMENT ON POLICY "cafes_update_optimized" ON public.cafes IS 'Optimized policy for cafe updates with single auth.uid() evaluation';

COMMENT ON POLICY "menu_items_select_optimized" ON public.menu_items IS 'Optimized policy for menu item viewing - public access';
COMMENT ON POLICY "menu_items_insert_optimized" ON public.menu_items IS 'Optimized policy for menu item creation with single auth.uid() evaluation';
COMMENT ON POLICY "menu_items_update_optimized" ON public.menu_items IS 'Optimized policy for menu item updates with single auth.uid() evaluation';
COMMENT ON POLICY "menu_items_delete_optimized" ON public.menu_items IS 'Optimized policy for menu item deletion with single auth.uid() evaluation';

COMMENT ON POLICY "orders_select_optimized" ON public.orders IS 'Optimized policy for order viewing with single auth.uid() evaluation';
COMMENT ON POLICY "orders_insert_optimized" ON public.orders IS 'Optimized policy for order creation with single auth.uid() evaluation';
COMMENT ON POLICY "orders_update_optimized" ON public.orders IS 'Optimized policy for order updates with single auth.uid() evaluation';

COMMENT ON POLICY "order_items_select_optimized" ON public.order_items IS 'Optimized policy for order item viewing with single auth.uid() evaluation';
COMMENT ON POLICY "order_items_insert_optimized" ON public.order_items IS 'Optimized policy for order item creation with single auth.uid() evaluation';

COMMENT ON POLICY "loyalty_transactions_select_optimized" ON public.loyalty_transactions IS 'Optimized policy for loyalty transaction viewing with single auth.uid() evaluation';
COMMENT ON POLICY "loyalty_transactions_insert_optimized" ON public.loyalty_transactions IS 'Optimized policy for loyalty transaction creation with single auth.uid() evaluation';














