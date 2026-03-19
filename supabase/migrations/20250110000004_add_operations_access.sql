-- Add RLS policies for Operations Team to view all orders
-- This allows operations interns to monitor all orders in the dashboard

-- 1. Allow operations team (super_admin) to view all orders
-- (This policy should already exist, but we'll ensure it's there)
DROP POLICY IF EXISTS "Operations team can view all orders" ON public.orders;

CREATE POLICY "Operations team can view all orders" ON public.orders
  FOR SELECT
  TO authenticated
  USING (
    -- Users can always view their own orders
    auth.uid() = user_id
    OR
    -- Cafe staff can view their cafe's orders
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.cafe_id = orders.cafe_id
      AND cs.user_id = auth.uid()
      AND cs.is_active = true
    )
    OR
    -- Super admin / Operations team can view all orders
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'super_admin'
    )
  );

-- 2. Allow operations team to view all order items
DROP POLICY IF EXISTS "Operations team can view all order items" ON public.order_items;

CREATE POLICY "Operations team can view all order items" ON public.order_items
  FOR SELECT
  TO authenticated
  USING (
    -- Users can view their own order items
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_items.order_id
      AND o.user_id = auth.uid()
    )
    OR
    -- Cafe staff can view their cafe's order items
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.cafe_staff cs ON cs.cafe_id = o.cafe_id
      WHERE o.id = order_items.order_id
      AND cs.user_id = auth.uid()
      AND cs.is_active = true
    )
    OR
    -- Super admin / Operations team can view all order items
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'super_admin'
    )
  );

-- 3. Allow operations team to view all cafes (for filtering)
DROP POLICY IF EXISTS "Operations team can view all cafes" ON public.cafes;

CREATE POLICY "Operations team can view all cafes" ON public.cafes
  FOR SELECT
  TO authenticated
  USING (
    -- Everyone can view cafes (public information)
    true
    OR
    -- Super admin / Operations team can view all cafes
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'super_admin'
    )
  );

-- 4. Allow operations team to view all profiles (for customer info)
-- Note: This should be limited to basic info only
DROP POLICY IF EXISTS "Operations team can view customer profiles" ON public.profiles;

CREATE POLICY "Operations team can view customer profiles" ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can view their own profile
    auth.uid() = id
    OR
    -- Super admin / Operations team can view customer profiles (for order management)
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.user_type = 'super_admin'
    )
  );

SELECT '✅ Operations Team Access Policies Added!' as status;









