-- Final Performance Cleanup
-- Fixes all remaining auth_rls_initplan warnings and multiple permissive policies
-- This is the comprehensive final cleanup to achieve 0 issues

-- ===========================================
-- FIX REMAINING AUTH RLS INITPLAN WARNINGS
-- ===========================================

-- Fix cafe_ratings table policies
DROP POLICY IF EXISTS "Users can insert their own ratings" ON public.cafe_ratings;
CREATE POLICY "Users can insert their own ratings" ON public.cafe_ratings
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own ratings" ON public.cafe_ratings;
CREATE POLICY "Users can update their own ratings" ON public.cafe_ratings
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete their own ratings" ON public.cafe_ratings;
CREATE POLICY "Users can delete their own ratings" ON public.cafe_ratings
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Fix cafe_staff table policies
DROP POLICY IF EXISTS "Cafe staff can view their own records" ON public.cafe_staff;
CREATE POLICY "Cafe staff can view their own records" ON public.cafe_staff
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Cafe staff can update their own records" ON public.cafe_staff;
CREATE POLICY "Cafe staff can update their own records" ON public.cafe_staff
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Cafe staff can view their assignments" ON public.cafe_staff;
CREATE POLICY "Cafe staff can view their assignments" ON public.cafe_staff
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Cafe owners can manage staff" ON public.cafe_staff;
CREATE POLICY "Cafe owners can manage staff" ON public.cafe_staff
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Fix order_notifications table policies
DROP POLICY IF EXISTS "Cafe staff can view cafe notifications" ON public.order_notifications;
CREATE POLICY "Cafe staff can view cafe notifications" ON public.order_notifications
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.cafe_staff 
            WHERE cafe_staff.user_id = (SELECT auth.uid()) 
            AND cafe_staff.cafe_id = (
                SELECT cafe_id FROM public.orders WHERE id = order_id
            )
        )
    );

-- Fix tier_maintenance table policies
DROP POLICY IF EXISTS "Users can view their own tier maintenance" ON public.tier_maintenance;
CREATE POLICY "Users can view their own tier maintenance" ON public.tier_maintenance
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert their own tier maintenance" ON public.tier_maintenance;
CREATE POLICY "Users can insert their own tier maintenance" ON public.tier_maintenance
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own tier maintenance" ON public.tier_maintenance;
CREATE POLICY "Users can update their own tier maintenance" ON public.tier_maintenance
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- Fix user_bonuses table policies
DROP POLICY IF EXISTS "Users can view their own bonuses" ON public.user_bonuses;
CREATE POLICY "Users can view their own bonuses" ON public.user_bonuses
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert their own bonuses" ON public.user_bonuses;
CREATE POLICY "Users can insert their own bonuses" ON public.user_bonuses
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

-- Fix maintenance_periods table policies
DROP POLICY IF EXISTS "Users can view their own maintenance periods" ON public.maintenance_periods;
CREATE POLICY "Users can view their own maintenance periods" ON public.maintenance_periods
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert their own maintenance periods" ON public.maintenance_periods;
CREATE POLICY "Users can insert their own maintenance periods" ON public.maintenance_periods
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own maintenance periods" ON public.maintenance_periods;
CREATE POLICY "Users can update their own maintenance periods" ON public.maintenance_periods
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- Fix cafe_tables table policies
DROP POLICY IF EXISTS "Cafe owners can manage their tables" ON public.cafe_tables;
CREATE POLICY "Cafe owners can manage their tables" ON public.cafe_tables
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Fix cafe_order_sequences table policies
DROP POLICY IF EXISTS "Cafe owners can manage their order sequences" ON public.cafe_order_sequences;
CREATE POLICY "Cafe owners can manage their order sequences" ON public.cafe_order_sequences
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Fix cafe_printer_configs table policies
DROP POLICY IF EXISTS "Cafe owners can view their printer configs" ON public.cafe_printer_configs;
CREATE POLICY "Cafe owners can view their printer configs" ON public.cafe_printer_configs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

DROP POLICY IF EXISTS "Cafe owners can insert their printer configs" ON public.cafe_printer_configs;
CREATE POLICY "Cafe owners can insert their printer configs" ON public.cafe_printer_configs
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

DROP POLICY IF EXISTS "Cafe owners can update their printer configs" ON public.cafe_printer_configs;
CREATE POLICY "Cafe owners can update their printer configs" ON public.cafe_printer_configs
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

DROP POLICY IF EXISTS "Cafe owners can delete their printer configs" ON public.cafe_printer_configs;
CREATE POLICY "Cafe owners can delete their printer configs" ON public.cafe_printer_configs
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Fix order_ratings table policies
DROP POLICY IF EXISTS "Users can view ratings for their own orders" ON public.order_ratings;
CREATE POLICY "Users can view ratings for their own orders" ON public.order_ratings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_id 
            AND orders.user_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can insert ratings for their own completed orders" ON public.order_ratings;
CREATE POLICY "Users can insert ratings for their own completed orders" ON public.order_ratings
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_id 
            AND orders.user_id = (SELECT auth.uid())
            AND orders.status = 'completed'
        )
    );

DROP POLICY IF EXISTS "Users can update their own ratings" ON public.order_ratings;
CREATE POLICY "Users can update their own ratings" ON public.order_ratings
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_id 
            AND orders.user_id = (SELECT auth.uid())
        )
    );

-- Fix user_favorites table policies
DROP POLICY IF EXISTS "Users can view their own favorites" ON public.user_favorites;
CREATE POLICY "Users can view their own favorites" ON public.user_favorites
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert their own favorites" ON public.user_favorites;
CREATE POLICY "Users can insert their own favorites" ON public.user_favorites
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete their own favorites" ON public.user_favorites;
CREATE POLICY "Users can delete their own favorites" ON public.user_favorites
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Fix cafe_loyalty_points table policies
DROP POLICY IF EXISTS "Users can view their own cafe loyalty points" ON public.cafe_loyalty_points;
CREATE POLICY "Users can view their own cafe loyalty points" ON public.cafe_loyalty_points
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Fix cafe_loyalty_transactions table policies
DROP POLICY IF EXISTS "Users can view their own cafe loyalty transactions" ON public.cafe_loyalty_transactions;
CREATE POLICY "Users can view their own cafe loyalty transactions" ON public.cafe_loyalty_transactions
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Fix cafe_monthly_maintenance table policies
DROP POLICY IF EXISTS "Users can view their own monthly maintenance" ON public.cafe_monthly_maintenance;
CREATE POLICY "Users can view their own monthly maintenance" ON public.cafe_monthly_maintenance
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- ===========================================
-- REMOVE ALL DUPLICATE POLICIES
-- ===========================================

-- Remove all old policies that are causing multiple permissive policy warnings
-- Keep only the optimized ones

-- Remove old profiles policies
DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;

-- Remove old cafes policies
DROP POLICY IF EXISTS "Cafe owners can insert cafes" ON public.cafes;
DROP POLICY IF EXISTS "Cafe owners can update their cafe" ON public.cafes;
DROP POLICY IF EXISTS "Cafe owners can update their cafe settings" ON public.cafes;
DROP POLICY IF EXISTS "Cafe owners can view their cafe data" ON public.cafes;

-- Remove old menu_items policies
DROP POLICY IF EXISTS "Cafe owners can manage their menu items" ON public.menu_items;
DROP POLICY IF EXISTS "Cafe owners can update their menu items" ON public.menu_items;
DROP POLICY IF EXISTS "Cafe owners can view their menu items" ON public.menu_items;

-- Remove old orders policies
DROP POLICY IF EXISTS "Cafe owners can update their cafe orders" ON public.orders;
DROP POLICY IF EXISTS "Cafe owners can view their cafe orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;

-- Remove old order_items policies
DROP POLICY IF EXISTS "Cafe owners can view their cafe order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can create order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can create their own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can view their order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can view their own order items" ON public.order_items;

-- Remove old loyalty_transactions policies
DROP POLICY IF EXISTS "Users can create their own loyalty transactions" ON public.loyalty_transactions;
DROP POLICY IF EXISTS "Users can insert their loyalty transactions" ON public.loyalty_transactions;
DROP POLICY IF EXISTS "Users can view their loyalty transactions" ON public.loyalty_transactions;
DROP POLICY IF EXISTS "Users can view their own loyalty transactions" ON public.loyalty_transactions;

-- ===========================================
-- CREATE FINAL OPTIMIZED POLICIES
-- ===========================================

-- Create single, comprehensive policies for each table

-- Cafe staff: Single comprehensive policy
DROP POLICY IF EXISTS "Cafe staff can view their own records" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can update their own records" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can view their assignments" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe owners can manage staff" ON public.cafe_staff;

CREATE POLICY "cafe_staff_comprehensive" ON public.cafe_staff
    FOR ALL USING (
        (SELECT auth.uid()) = user_id OR
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Order notifications: Single comprehensive policy
DROP POLICY IF EXISTS "Cafe staff can view cafe notifications" ON public.order_notifications;

CREATE POLICY "order_notifications_comprehensive" ON public.order_notifications
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.cafe_staff 
            WHERE cafe_staff.user_id = (SELECT auth.uid()) 
            AND cafe_staff.cafe_id = (
                SELECT cafe_id FROM public.orders WHERE id = order_id
            )
        )
    );

-- Tier maintenance: Single comprehensive policy
DROP POLICY IF EXISTS "Users can view their own tier maintenance" ON public.tier_maintenance;
DROP POLICY IF EXISTS "Users can insert their own tier maintenance" ON public.tier_maintenance;
DROP POLICY IF EXISTS "Users can update their own tier maintenance" ON public.tier_maintenance;

CREATE POLICY "tier_maintenance_comprehensive" ON public.tier_maintenance
    FOR ALL USING ((SELECT auth.uid()) = user_id);

-- User bonuses: Single comprehensive policy
DROP POLICY IF EXISTS "Users can view their own bonuses" ON public.user_bonuses;
DROP POLICY IF EXISTS "Users can insert their own bonuses" ON public.user_bonuses;

CREATE POLICY "user_bonuses_comprehensive" ON public.user_bonuses
    FOR ALL USING ((SELECT auth.uid()) = user_id);

-- Maintenance periods: Single comprehensive policy
DROP POLICY IF EXISTS "Users can view their own maintenance periods" ON public.maintenance_periods;
DROP POLICY IF EXISTS "Users can insert their own maintenance periods" ON public.maintenance_periods;
DROP POLICY IF EXISTS "Users can update their own maintenance periods" ON public.maintenance_periods;

CREATE POLICY "maintenance_periods_comprehensive" ON public.maintenance_periods
    FOR ALL USING ((SELECT auth.uid()) = user_id);

-- Cafe tables: Single comprehensive policy
DROP POLICY IF EXISTS "Cafe owners can manage their tables" ON public.cafe_tables;

CREATE POLICY "cafe_tables_comprehensive" ON public.cafe_tables
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Cafe order sequences: Single comprehensive policy
DROP POLICY IF EXISTS "Cafe owners can manage their order sequences" ON public.cafe_order_sequences;

CREATE POLICY "cafe_order_sequences_comprehensive" ON public.cafe_order_sequences
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Cafe printer configs: Single comprehensive policy
DROP POLICY IF EXISTS "Cafe owners can view their printer configs" ON public.cafe_printer_configs;
DROP POLICY IF EXISTS "Cafe owners can insert their printer configs" ON public.cafe_printer_configs;
DROP POLICY IF EXISTS "Cafe owners can update their printer configs" ON public.cafe_printer_configs;
DROP POLICY IF EXISTS "Cafe owners can delete their printer configs" ON public.cafe_printer_configs;

CREATE POLICY "cafe_printer_configs_comprehensive" ON public.cafe_printer_configs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_id
        )
    );

-- Order ratings: Single comprehensive policy
DROP POLICY IF EXISTS "Users can view ratings for their own orders" ON public.order_ratings;
DROP POLICY IF EXISTS "Users can insert ratings for their own completed orders" ON public.order_ratings;
DROP POLICY IF EXISTS "Users can update their own ratings" ON public.order_ratings;

CREATE POLICY "order_ratings_comprehensive" ON public.order_ratings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_id 
            AND orders.user_id = (SELECT auth.uid())
        )
    );

-- User favorites: Single comprehensive policy
DROP POLICY IF EXISTS "Users can view their own favorites" ON public.user_favorites;
DROP POLICY IF EXISTS "Users can insert their own favorites" ON public.user_favorites;
DROP POLICY IF EXISTS "Users can delete their own favorites" ON public.user_favorites;

CREATE POLICY "user_favorites_comprehensive" ON public.user_favorites
    FOR ALL USING ((SELECT auth.uid()) = user_id);

-- Cafe loyalty points: Single comprehensive policy
DROP POLICY IF EXISTS "Users can view their own cafe loyalty points" ON public.cafe_loyalty_points;

CREATE POLICY "cafe_loyalty_points_comprehensive" ON public.cafe_loyalty_points
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Cafe loyalty transactions: Single comprehensive policy
DROP POLICY IF EXISTS "Users can view their own cafe loyalty transactions" ON public.cafe_loyalty_transactions;

CREATE POLICY "cafe_loyalty_transactions_comprehensive" ON public.cafe_loyalty_transactions
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Cafe monthly maintenance: Single comprehensive policy
DROP POLICY IF EXISTS "Users can view their own monthly maintenance" ON public.cafe_monthly_maintenance;

CREATE POLICY "cafe_monthly_maintenance_comprehensive" ON public.cafe_monthly_maintenance
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Cafe ratings: Single comprehensive policy
DROP POLICY IF EXISTS "Users can insert their own ratings" ON public.cafe_ratings;
DROP POLICY IF EXISTS "Users can update their own ratings" ON public.cafe_ratings;
DROP POLICY IF EXISTS "Users can delete their own ratings" ON public.cafe_ratings;

CREATE POLICY "cafe_ratings_comprehensive" ON public.cafe_ratings
    FOR ALL USING ((SELECT auth.uid()) = user_id);

-- ===========================================
-- COMMENTS AND DOCUMENTATION
-- ===========================================

COMMENT ON POLICY "cafe_staff_comprehensive" ON public.cafe_staff IS 'Comprehensive policy for cafe staff - users can manage their own records, cafe owners can manage their staff';
COMMENT ON POLICY "order_notifications_comprehensive" ON public.order_notifications IS 'Comprehensive policy for order notifications - cafe staff can view notifications for their cafe';
COMMENT ON POLICY "tier_maintenance_comprehensive" ON public.tier_maintenance IS 'Comprehensive policy for tier maintenance - users can manage their own records';
COMMENT ON POLICY "user_bonuses_comprehensive" ON public.user_bonuses IS 'Comprehensive policy for user bonuses - users can manage their own records';
COMMENT ON POLICY "maintenance_periods_comprehensive" ON public.maintenance_periods IS 'Comprehensive policy for maintenance periods - users can manage their own records';
COMMENT ON POLICY "cafe_tables_comprehensive" ON public.cafe_tables IS 'Comprehensive policy for cafe tables - cafe owners can manage their tables';
COMMENT ON POLICY "cafe_order_sequences_comprehensive" ON public.cafe_order_sequences IS 'Comprehensive policy for cafe order sequences - cafe owners can manage their sequences';
COMMENT ON POLICY "cafe_printer_configs_comprehensive" ON public.cafe_printer_configs IS 'Comprehensive policy for cafe printer configs - cafe owners can manage their printer configs';
COMMENT ON POLICY "order_ratings_comprehensive" ON public.order_ratings IS 'Comprehensive policy for order ratings - users can manage ratings for their own orders';
COMMENT ON POLICY "user_favorites_comprehensive" ON public.user_favorites IS 'Comprehensive policy for user favorites - users can manage their own favorites';
COMMENT ON POLICY "cafe_loyalty_points_comprehensive" ON public.cafe_loyalty_points IS 'Comprehensive policy for cafe loyalty points - users can view their own points';
COMMENT ON POLICY "cafe_loyalty_transactions_comprehensive" ON public.cafe_loyalty_transactions IS 'Comprehensive policy for cafe loyalty transactions - users can view their own transactions';
COMMENT ON POLICY "cafe_monthly_maintenance_comprehensive" ON public.cafe_monthly_maintenance IS 'Comprehensive policy for cafe monthly maintenance - users can view their own maintenance';
COMMENT ON POLICY "cafe_ratings_comprehensive" ON public.cafe_ratings IS 'Comprehensive policy for cafe ratings - users can manage their own ratings';














