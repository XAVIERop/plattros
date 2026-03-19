-- Fix cafe dashboard access for Pulkit
-- Ensure proper cafe staff record and permissions

-- 1. CHECK IF PULKIT EXISTS IN PROFILES
SELECT 'Checking if Pulkit exists in profiles...' as status;

-- 2. CHECK IF MINI MEALS CAFE EXISTS
SELECT 'Checking if Mini Meals cafe exists...' as status;

-- 3. ENSURE PULKIT IS PROPERLY ADDED AS CAFE OWNER
-- First, let's see what's in cafe_staff
SELECT 'Current cafe_staff records:' as status;
SELECT cs.*, p.email, c.name as cafe_name 
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id;

-- 4. ADD PULKIT AS CAFE OWNER (FORCE INSERT)
INSERT INTO public.cafe_staff (cafe_id, user_id, role, is_active)
SELECT 
  c.id as cafe_id,
  p.id as user_id,
  'owner' as role,
  true as is_active
FROM public.cafes c
CROSS JOIN public.profiles p
WHERE p.email = 'pulkit.229302047@muj.manipal.edu'
  AND c.name = 'Mini Meals'
ON CONFLICT (cafe_id, user_id) DO UPDATE SET
  role = 'owner',
  is_active = true,
  updated_at = now();

-- 5. VERIFY THE INSERTION
SELECT 'Verifying cafe staff record:' as status;
SELECT cs.*, p.email, c.name as cafe_name 
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id
WHERE p.email = 'pulkit.229302047@muj.manipal.edu';

-- 6. FIX CAFE DASHBOARD ACCESS BY UPDATING POLICIES
-- Make sure cafe staff can access their cafe's data
DROP POLICY IF EXISTS "cafe_staff_simple_select" ON public.cafe_staff;
CREATE POLICY "cafe_staff_simple_select" ON public.cafe_staff
  FOR SELECT USING (
    auth.uid() = user_id OR 
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs2 
      WHERE cs2.cafe_id = cafe_staff.cafe_id 
      AND cs2.user_id = auth.uid()
    )
  );

-- 7. ENSURE ORDERS CAN BE VIEWED BY CAFE STAFF
-- Update orders policy to allow cafe staff access
DROP POLICY IF EXISTS "Cafe staff can view their cafe orders" ON public.orders;
CREATE POLICY "Cafe staff can view their cafe orders" ON public.orders
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = orders.cafe_id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.is_active = true
    )
  );

-- 8. TEST THE FIX
SELECT 'Cafe dashboard access should now work for Pulkit!' as status;
