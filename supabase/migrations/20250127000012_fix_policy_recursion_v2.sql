-- Fix Policy Recursion Issue v2
-- Resolves infinite recursion in cafe_staff policies
-- Handles existing policies properly

-- Drop ALL existing policies that might cause recursion
DROP POLICY IF EXISTS "Cafe owners can manage their staff" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe owners can manage staff" ON public.cafe_staff;
DROP POLICY IF EXISTS "Staff can view their own records" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can view their own records" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can update their own records" ON public.cafe_staff;

-- Drop other potentially problematic policies
DROP POLICY IF EXISTS "Cafe owners can view their cafe order items" ON public.order_items;
DROP POLICY IF EXISTS "Cafe owners can manage their tables" ON public.cafe_tables;
DROP POLICY IF EXISTS "Cafe owners can manage their order sequences" ON public.cafe_order_sequences;
DROP POLICY IF EXISTS "Cafe owners can manage their menu items" ON public.menu_items;
DROP POLICY IF EXISTS "Cafe owners can view their cafe orders" ON public.orders;
DROP POLICY IF EXISTS "Cafe owners can update their cafe orders" ON public.orders;
DROP POLICY IF EXISTS "Cafe owners can update their cafe" ON public.cafes;
DROP POLICY IF EXISTS "Cafe owners can insert cafes" ON public.cafes;

-- Create simplified, non-recursive policies for cafe_staff
CREATE POLICY "Cafe staff can view their own records" ON public.cafe_staff
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Cafe staff can update their own records" ON public.cafe_staff
    FOR UPDATE USING (auth.uid() = user_id);

-- Create a separate policy for cafe owners to manage staff
-- This avoids recursion by not referencing profiles table in the policy
CREATE POLICY "Cafe owners can manage staff" ON public.cafe_staff
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.cafes 
            WHERE cafes.id = cafe_staff.cafe_id
            AND EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.user_type = 'cafe_owner' 
                AND profiles.cafe_id = cafes.id
            )
        )
    );

-- Recreate order_items policies to avoid recursion
CREATE POLICY "Cafe owners can view their cafe order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND EXISTS (
                SELECT 1 FROM public.cafes 
                WHERE cafes.id = orders.cafe_id
                AND EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE profiles.id = auth.uid() 
                    AND profiles.user_type = 'cafe_owner' 
                    AND profiles.cafe_id = cafes.id
                )
            )
        )
    );

-- Recreate cafe_tables policies
CREATE POLICY "Cafe owners can manage their tables" ON public.cafe_tables
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.cafes 
            WHERE cafes.id = cafe_tables.cafe_id
            AND EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.user_type = 'cafe_owner' 
                AND profiles.cafe_id = cafes.id
            )
        )
    );

-- Recreate cafe_order_sequences policies
CREATE POLICY "Cafe owners can manage their order sequences" ON public.cafe_order_sequences
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.cafes 
            WHERE cafes.id = cafe_order_sequences.cafe_id
            AND EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.user_type = 'cafe_owner' 
                AND profiles.cafe_id = cafes.id
            )
        )
    );

-- Recreate menu_items policies
CREATE POLICY "Cafe owners can manage their menu items" ON public.menu_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.cafes 
            WHERE cafes.id = menu_items.cafe_id
            AND EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.user_type = 'cafe_owner' 
                AND profiles.cafe_id = cafes.id
            )
        )
    );

-- Recreate orders policies
CREATE POLICY "Cafe owners can view their cafe orders" ON public.orders
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.cafes 
            WHERE cafes.id = orders.cafe_id
            AND EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.user_type = 'cafe_owner' 
                AND profiles.cafe_id = cafes.id
            )
        )
    );

CREATE POLICY "Cafe owners can update their cafe orders" ON public.orders
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.cafes 
            WHERE cafes.id = orders.cafe_id
            AND EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.user_type = 'cafe_owner' 
                AND profiles.cafe_id = cafes.id
            )
        )
    );

-- Recreate cafes policies
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

-- Add comments for documentation
COMMENT ON POLICY "Cafe staff can view their own records" ON public.cafe_staff IS 'Allows staff to view their own records';
COMMENT ON POLICY "Cafe staff can update their own records" ON public.cafe_staff IS 'Allows staff to update their own records';
COMMENT ON POLICY "Cafe owners can manage staff" ON public.cafe_staff IS 'Allows cafe owners to manage their staff';














