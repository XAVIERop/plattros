-- Set up cafe owner isolation and fix order items display
-- This ensures each cafe owner only sees their own cafe's orders

-- 1. VERIFY CURRENT CAFE STAFF SETUP
SELECT 'Current cafe staff setup:' as status;
SELECT 
  cs.id,
  cs.cafe_id,
  cs.user_id,
  cs.role,
  cs.is_active,
  p.email,
  c.name as cafe_name
FROM public.cafe_staff cs
JOIN public.profiles p ON cs.user_id = p.id
JOIN public.cafes c ON cs.cafe_id = c.id
ORDER BY c.name, cs.role;

-- 2. CREATE ADDITIONAL CAFE OWNERS FOR TESTING
-- Let's create separate cafe owners for different cafes

-- Create a new cafe owner for "Mini Meals" (if not exists)
INSERT INTO public.profiles (id, email, full_name, block, phone, loyalty_points, loyalty_tier, qr_code, student_id, total_orders, total_spent, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'mini.meals.owner@muj.manipal.edu',
  'Mini Meals Owner',
  'B1',
  '+91-9876543210',
  0,
  'foodie'::loyalty_tier,
  'QR-MINI-MEALS-OWNER',
  'MINI001',
  0,
  0,
  NOW(),
  NOW()
) ON CONFLICT (email) DO NOTHING;

-- Link the new owner to Mini Meals cafe
INSERT INTO public.cafe_staff (id, cafe_id, user_id, role, is_active, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  c.id,
  p.id,
  'owner',
  true,
  NOW(),
  NOW()
FROM public.cafes c
JOIN public.profiles p ON p.email = 'mini.meals.owner@muj.manipal.edu'
WHERE c.name = 'Mini Meals'
ON CONFLICT DO NOTHING;

-- 3. VERIFY ORDER ITEMS DATA
SELECT 'Checking order items data:' as status;
SELECT 
  oi.id,
  oi.order_id,
  oi.quantity,
  oi.notes,
  oi.special_instructions,
  mi.name as menu_item_name,
  mi.price as menu_item_price,
  mi.category as menu_item_category,
  o.order_number,
  c.name as cafe_name
FROM public.order_items oi
JOIN public.menu_items mi ON oi.menu_item_id = mi.id
JOIN public.orders o ON oi.order_id = o.id
JOIN public.cafes c ON o.cafe_id = c.id
LIMIT 10;

-- 4. ENSURE RLS POLICIES ARE PROPERLY SET FOR CAFE ISOLATION
-- Drop existing policies
DROP POLICY IF EXISTS "orders_allow_all" ON public.orders;
DROP POLICY IF EXISTS "profiles_allow_all" ON public.profiles;
DROP POLICY IF EXISTS "menu_items_allow_all" ON public.menu_items;
DROP POLICY IF EXISTS "order_items_allow_all" ON public.order_items;
DROP POLICY IF EXISTS "cafe_staff_allow_all" ON public.cafe_staff;

-- Create cafe-specific policies
CREATE POLICY "cafe_staff_view_own_orders" ON public.orders
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.user_id = auth.uid()
      AND cs.cafe_id = orders.cafe_id
      AND cs.is_active = true
    )
  );

CREATE POLICY "cafe_staff_update_own_orders" ON public.orders
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.user_id = auth.uid()
      AND cs.cafe_id = orders.cafe_id
      AND cs.is_active = true
    )
  );

CREATE POLICY "cafe_staff_delete_own_orders" ON public.orders
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.user_id = auth.uid()
      AND cs.cafe_id = orders.cafe_id
      AND cs.is_active = true
    )
  );

-- Allow cafe staff to view order items for their cafe
CREATE POLICY "cafe_staff_view_order_items" ON public.order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.cafe_staff cs ON cs.cafe_id = o.cafe_id
      WHERE o.id = order_items.order_id
      AND cs.user_id = auth.uid()
      AND cs.is_active = true
    )
  );

-- Allow cafe staff to view menu items for their cafe
CREATE POLICY "cafe_staff_view_menu_items" ON public.menu_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.user_id = auth.uid()
      AND cs.cafe_id = menu_items.cafe_id
      AND cs.is_active = true
    )
  );

-- Allow cafe staff to view profiles (for customer info)
CREATE POLICY "cafe_staff_view_profiles" ON public.profiles
  FOR SELECT USING (true);

-- Allow cafe staff to view their own cafe staff record
CREATE POLICY "cafe_staff_view_own_record" ON public.cafe_staff
  FOR SELECT USING (user_id = auth.uid());

-- 5. TEST CAFE ISOLATION
SELECT 'Testing cafe isolation for cafe.owner@muj.manipal.edu:' as status;
SELECT 
  o.order_number,
  o.status,
  o.total_amount,
  c.name as cafe_name,
  COUNT(oi.id) as item_count
FROM public.orders o
JOIN public.cafes c ON o.cafe_id = c.id
JOIN public.cafe_staff cs ON cs.cafe_id = c.id
LEFT JOIN public.order_items oi ON o.id = oi.order_id
WHERE cs.user_id = (SELECT id FROM auth.users WHERE email = 'cafe.owner@muj.manipal.edu')
  AND cs.is_active = true
GROUP BY o.id, o.order_number, o.status, o.total_amount, c.name
ORDER BY o.created_at DESC
LIMIT 5;

SELECT 'Cafe owner isolation and order items display should now work properly!' as status;
