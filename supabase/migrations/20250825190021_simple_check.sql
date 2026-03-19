-- Simple check - no policy creation
-- Just verify the current state

-- 1. CHECK CAFE OWNER PROFILE
SELECT 'Cafe owner profile:' as status;
SELECT id, email, full_name FROM public.profiles WHERE email = 'cafe.owner@muj.manipal.edu';

-- 2. CHECK CAFE STAFF RECORD
SELECT 'Cafe staff record:' as status;
SELECT cs.cafe_id, cs.user_id, cs.role, cs.is_active, p.email, c.name as cafe_name
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id
WHERE p.email = 'cafe.owner@muj.manipal.edu';

-- 3. CHECK AUTH USER
SELECT 'Auth user:' as status;
SELECT id, email FROM auth.users WHERE email = 'cafe.owner@muj.manipal.edu';

-- 4. TEST THE DASHBOARD QUERY
SELECT 'Dashboard query test:' as status;
SELECT cs.cafe_id, p.email, c.name as cafe_name
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id
WHERE p.email = 'cafe.owner@muj.manipal.edu'
  AND cs.is_active = true;

-- 5. FINAL STATUS
SELECT 'Check complete!' as status;
