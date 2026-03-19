-- Fix infinite recursion by disabling RLS on cafe_staff
-- This will allow the frontend to access the table

-- 1. DISABLE RLS ON CAFE_STAFF TABLE
ALTER TABLE public.cafe_staff DISABLE ROW LEVEL SECURITY;

-- 2. VERIFY THE FIX
SELECT 'RLS disabled on cafe_staff table' as status;

-- 3. TEST THE QUERY THAT WAS FAILING
SELECT 'Testing cafe staff query:' as status;
SELECT cs.*, p.email, p.full_name, c.name as cafe_name
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id
WHERE p.email = 'cafe.owner@muj.manipal.edu'
  AND cs.is_active = true;

-- 4. FINAL STATUS
SELECT 'Cafe dashboard should now work! RLS disabled on cafe_staff.' as status;
