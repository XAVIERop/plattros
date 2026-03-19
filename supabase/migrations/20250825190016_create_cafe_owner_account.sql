-- Create proper cafe owner account
-- Set up a dedicated cafe owner instead of using student ID

-- 1. CREATE CAFE OWNER PROFILE
INSERT INTO public.profiles (
  id,
  email,
  full_name,
  phone,
  block,
  loyalty_points,
  total_orders,
  total_spent,
  loyalty_tier,
  qr_code,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'cafe.owner@muj.manipal.edu',
  'Cafe Manager',
  '+91-9876543210',
  'Admin',
  0,
  0,
  0,
  'bronze'::loyalty_tier,
  'CAFE-OWNER-001',
  now(),
  now()
) ON CONFLICT (email) DO NOTHING;

-- 2. GET THE CAFE OWNER PROFILE ID
DO $$
DECLARE
  cafe_owner_id UUID;
BEGIN
  SELECT id INTO cafe_owner_id 
  FROM public.profiles 
  WHERE email = 'cafe.owner@muj.manipal.edu';
  
  -- 3. ADD CAFE OWNER TO CAFE_STAFF
  INSERT INTO public.cafe_staff (cafe_id, user_id, role, is_active)
  SELECT 
    c.id as cafe_id,
    cafe_owner_id as user_id,
    'owner' as role,
    true as is_active
  FROM public.cafes c
  WHERE c.name = 'Mini Meals'
  ON CONFLICT (cafe_id, user_id) DO UPDATE SET
    role = 'owner',
    is_active = true,
    updated_at = now();
    
  -- 4. ALSO ADD PULKIT AS STAFF (NOT OWNER)
  INSERT INTO public.cafe_staff (cafe_id, user_id, role, is_active)
  SELECT 
    c.id as cafe_id,
    p.id as user_id,
    'staff' as role,
    true as is_active
  FROM public.cafes c
  CROSS JOIN public.profiles p
  WHERE p.email = 'pulkit.229302047@muj.manipal.edu'
    AND c.name = 'Mini Meals'
  ON CONFLICT (cafe_id, user_id) DO UPDATE SET
    role = 'staff',
    is_active = true,
    updated_at = now();
END $$;

-- 5. VERIFY THE SETUP
SELECT 'Cafe owner setup:' as status;
SELECT cs.*, p.email, p.full_name, c.name as cafe_name 
FROM public.cafe_staff cs 
JOIN public.profiles p ON cs.user_id = p.id 
JOIN public.cafes c ON cs.cafe_id = c.id
ORDER BY cs.role DESC, p.email;

-- 6. CREATE AUTH USER FOR CAFE OWNER (if needed)
-- Note: This would need to be done manually in Supabase Auth dashboard
-- Email: cafe.owner@muj.manipal.edu
-- Password: (set manually)

-- 7. FINAL STATUS
SELECT 'Cafe owner account created! Use cafe.owner@muj.manipal.edu to access cafe dashboard.' as status;
