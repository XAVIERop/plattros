-- Fix cafe owner access to dashboard
-- Ensure proper profile linking and permissions

-- 1. CHECK IF CAFE OWNER PROFILE EXISTS
SELECT 'Checking cafe owner profile:' as status;
SELECT * FROM public.profiles WHERE email = 'cafe.owner@muj.manipal.edu';

-- 2. CHECK IF CAFE OWNER IS IN CAFE_STAFF
SELECT 'Checking cafe staff records:' as status;
SELECT cs.*, p.email, p.full_name, c.name as cafe_name 
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id
WHERE p.email = 'cafe.owner@muj.manipal.edu';

-- 3. GET THE AUTH USER ID FOR CAFE OWNER
SELECT 'Auth user ID for cafe owner:' as status;
SELECT id, email FROM auth.users WHERE email = 'cafe.owner@muj.manipal.edu';

-- 4. UPDATE PROFILE TO MATCH AUTH USER ID
DO $$
DECLARE
  auth_user_id UUID;
  profile_id UUID;
BEGIN
  -- Get auth user ID
  SELECT id INTO auth_user_id FROM auth.users WHERE email = 'cafe.owner@muj.manipal.edu';
  
  -- Get profile ID
  SELECT id INTO profile_id FROM public.profiles WHERE email = 'cafe.owner@muj.manipal.edu';
  
  -- Update profile to use auth user ID
  IF auth_user_id IS NOT NULL AND profile_id IS NOT NULL THEN
    UPDATE public.profiles 
    SET id = auth_user_id 
    WHERE email = 'cafe.owner@muj.manipal.edu';
    
    -- Update cafe_staff to use auth user ID
    UPDATE public.cafe_staff 
    SET user_id = auth_user_id 
    WHERE user_id = profile_id;
  END IF;
END $$;

-- 5. VERIFY THE FIX
SELECT 'Verifying cafe owner access:' as status;
SELECT cs.*, p.email, p.full_name, c.name as cafe_name 
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id
WHERE p.email = 'cafe.owner@muj.manipal.edu';

-- 6. TEST THE QUERY THAT CAFE DASHBOARD USES
SELECT 'Testing cafe dashboard query:' as status;
SELECT cs.cafe_id, p.email, c.name as cafe_name
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id
WHERE p.email = 'cafe.owner@muj.manipal.edu'
  AND cs.is_active = true;

-- 7. FINAL STATUS
SELECT 'Cafe owner access should now work! Try logging in again.' as status;
