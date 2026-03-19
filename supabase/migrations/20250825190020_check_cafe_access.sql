-- Check cafe owner access without recreating policies
-- Just verify the current state and test the query

-- 1. CHECK CURRENT STATE
SELECT 'Current cafe owner profile:' as status;
SELECT * FROM public.profiles WHERE email = 'cafe.owner@muj.manipal.edu';

-- 2. CHECK CAFE STAFF RECORDS
SELECT 'Current cafe staff records:' as status;
SELECT cs.*, p.email, p.full_name, c.name as cafe_name 
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id
ORDER BY cs.role DESC, p.email;

-- 3. CHECK AUTH USER
SELECT 'Auth user for cafe owner:' as status;
SELECT id, email FROM auth.users WHERE email = 'cafe.owner@muj.manipal.edu';

-- 4. TEST THE EXACT QUERY CAFE DASHBOARD USES
SELECT 'Testing cafe dashboard query:' as status;
SELECT cs.cafe_id, p.email, c.name as cafe_name
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id
WHERE p.email = 'cafe.owner@muj.manipal.edu'
  AND cs.is_active = true;

-- 5. CHECK IF RLS IS ENABLED
SELECT 'RLS status for cafe_staff:' as status;
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'cafe_staff';

-- 6. LIST ALL POLICIES ON CAFE_STAFF
SELECT 'Policies on cafe_staff:' as status;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'cafe_staff';

-- 7. FINAL STATUS
SELECT 'Check complete! Look at the results above.' as status;
