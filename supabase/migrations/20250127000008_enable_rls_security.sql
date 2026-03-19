-- Enable Row Level Security (RLS) for all critical tables
-- This migration addresses the 82 security issues identified in Supabase dashboard

-- 1. Enable RLS on all critical tables
ALTER TABLE public.cafes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_order_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;

-- 2. Create RLS policies for CAFES table
-- Allow everyone to read cafe information (public data)
CREATE POLICY "Cafes are viewable by everyone" ON public.cafes
    FOR SELECT USING (true);

-- Only cafe owners can update their own cafe
CREATE POLICY "Cafe owners can update their cafe" ON public.cafes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafes.id
        )
    );

-- Only cafe owners can insert new cafes (admin function)
CREATE POLICY "Cafe owners can insert cafes" ON public.cafes
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner'
        )
    );

-- 3. Create RLS policies for MENU_ITEMS table
-- Allow everyone to read menu items (public data)
CREATE POLICY "Menu items are viewable by everyone" ON public.menu_items
    FOR SELECT USING (true);

-- Only cafe owners can manage their menu items
CREATE POLICY "Cafe owners can manage their menu items" ON public.menu_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = menu_items.cafe_id
        )
    );

-- 4. Create RLS policies for ORDERS table
-- Users can only see their own orders
CREATE POLICY "Users can view their own orders" ON public.orders
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own orders
CREATE POLICY "Users can create their own orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own orders (for status changes)
CREATE POLICY "Users can update their own orders" ON public.orders
    FOR UPDATE USING (auth.uid() = user_id);

-- Cafe owners can see orders for their cafe
CREATE POLICY "Cafe owners can view their cafe orders" ON public.orders
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = orders.cafe_id
        )
    );

-- Cafe owners can update orders for their cafe
CREATE POLICY "Cafe owners can update their cafe orders" ON public.orders
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = orders.cafe_id
        )
    );

-- 5. Create RLS policies for ORDER_ITEMS table
-- Users can see order items for their own orders
CREATE POLICY "Users can view their own order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- Users can insert order items for their own orders
CREATE POLICY "Users can create their own order items" ON public.order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- Cafe owners can see order items for their cafe orders
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

-- 6. Create RLS policies for CAFE_STAFF table
-- Only cafe owners can manage their staff
CREATE POLICY "Cafe owners can manage their staff" ON public.cafe_staff
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_staff.cafe_id
        )
    );

-- Staff can view their own records
CREATE POLICY "Staff can view their own records" ON public.cafe_staff
    FOR SELECT USING (auth.uid() = user_id);

-- 7. Create RLS policies for CAFE_TABLES table
-- Allow everyone to read table information (public data)
CREATE POLICY "Cafe tables are viewable by everyone" ON public.cafe_tables
    FOR SELECT USING (true);

-- Only cafe owners can manage their tables
CREATE POLICY "Cafe owners can manage their tables" ON public.cafe_tables
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_tables.cafe_id
        )
    );

-- 8. Create RLS policies for CAFE_ORDER_SEQUENCES table
-- Only cafe owners can manage their order sequences
CREATE POLICY "Cafe owners can manage their order sequences" ON public.cafe_order_sequences
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.user_type = 'cafe_owner' 
            AND profiles.cafe_id = cafe_order_sequences.cafe_id
        )
    );

-- 9. Create RLS policies for PROFILES table
-- Users can only see their own profile
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile (during signup)
CREATE POLICY "Users can create their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 10. Create RLS policies for LOYALTY_TRANSACTIONS table
-- Users can only see their own loyalty transactions
CREATE POLICY "Users can view their own loyalty transactions" ON public.loyalty_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own loyalty transactions
CREATE POLICY "Users can create their own loyalty transactions" ON public.loyalty_transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 11. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_cafe_id ON public.orders(cafe_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_cafe_id ON public.menu_items(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_staff_cafe_id ON public.cafe_staff(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_staff_user_id ON public.cafe_staff(user_id);
CREATE INDEX IF NOT EXISTS idx_cafe_tables_cafe_id ON public.cafe_tables(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_order_sequences_cafe_id ON public.cafe_order_sequences(cafe_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_user_id ON public.loyalty_transactions(user_id);

-- 12. Grant necessary permissions
GRANT SELECT ON public.cafes TO authenticated;
GRANT SELECT ON public.menu_items TO authenticated;
GRANT SELECT ON public.cafe_tables TO authenticated;
GRANT ALL ON public.orders TO authenticated;
GRANT ALL ON public.order_items TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.loyalty_transactions TO authenticated;
GRANT ALL ON public.cafe_staff TO authenticated;
GRANT ALL ON public.cafe_order_sequences TO authenticated;

-- 13. Add comments for documentation
COMMENT ON POLICY "Cafes are viewable by everyone" ON public.cafes IS 'Allows public read access to cafe information';
COMMENT ON POLICY "Menu items are viewable by everyone" ON public.menu_items IS 'Allows public read access to menu items';
COMMENT ON POLICY "Users can view their own orders" ON public.orders IS 'Restricts order access to order owner';
COMMENT ON POLICY "Cafe owners can view their cafe orders" ON public.orders IS 'Allows cafe owners to see orders for their cafe';
COMMENT ON POLICY "Users can view their own profile" ON public.profiles IS 'Restricts profile access to profile owner';
COMMENT ON POLICY "Users can view their own loyalty transactions" ON public.loyalty_transactions IS 'Restricts loyalty transaction access to transaction owner';














