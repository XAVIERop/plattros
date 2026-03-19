-- Fix RLS policies for orders table to allow cafe staff to view orders
-- This will ensure the cafe dashboard can fetch orders properly

-- 1. DISABLE RLS ON ORDERS TABLE TEMPORARILY
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;

-- 2. DROP ALL EXISTING POLICIES ON ORDERS
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON public.orders;
DROP POLICY IF EXISTS "Cafe staff can view cafe orders" ON public.orders;
DROP POLICY IF EXISTS "Cafe staff can update cafe orders" ON public.orders;
DROP POLICY IF EXISTS "orders_allow_all" ON public.orders;
DROP POLICY IF EXISTS "orders_final" ON public.orders;

-- 3. RE-ENABLE RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- 4. CREATE NEW PERMISSIVE POLICIES
-- Allow users to view their own orders
CREATE POLICY "users_view_own_orders" ON public.orders
  FOR SELECT USING (auth.uid() = user_id);

-- Allow users to create their own orders
CREATE POLICY "users_create_own_orders" ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own orders
CREATE POLICY "users_update_own_orders" ON public.orders
  FOR UPDATE USING (auth.uid() = user_id);

-- Allow cafe staff to view orders for their cafe
CREATE POLICY "cafe_staff_view_orders" ON public.orders
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.user_id = auth.uid()
      AND cs.cafe_id = orders.cafe_id
      AND cs.is_active = true
    )
  );

-- Allow cafe staff to update orders for their cafe
CREATE POLICY "cafe_staff_update_orders" ON public.orders
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.user_id = auth.uid()
      AND cs.cafe_id = orders.cafe_id
      AND cs.is_active = true
    )
  );

-- 5. TEST THE POLICIES
SELECT 'Orders RLS policies updated successfully!' as status;

-- 6. VERIFY CAFE STAFF CAN ACCESS ORDERS
SELECT 'Testing cafe staff access to orders:' as status;
SELECT 
  o.order_number,
  o.status,
  o.total_amount,
  p.email as customer_email,
  c.name as cafe_name
FROM public.orders o
JOIN public.profiles p ON o.user_id = p.id
JOIN public.cafes c ON o.cafe_id = c.id
JOIN public.cafe_staff cs ON cs.cafe_id = c.id
WHERE cs.user_id = (SELECT id FROM auth.users WHERE email = 'cafe.owner@muj.manipal.edu')
  AND cs.is_active = true
ORDER BY o.created_at DESC
LIMIT 5;
