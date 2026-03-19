-- Create Munch Box Cafe Owner Account
-- This migration creates a complete setup for Munch Box cafe owner

-- Step 1: Create the profile for the cafe owner
-- Note: This requires the auth user to be created first in Supabase Dashboard
-- Email: munchbox.owner@mujfoodclub.in
-- Password: MunchBox1203!@#

-- The profile will be created manually after auth user creation
-- This migration serves as documentation and verification

-- Step 2: Verify Munch Box cafe exists and has correct settings
DO $$
DECLARE
    munchbox_cafe RECORD;
    munchbox_menu_count INTEGER;
BEGIN
    -- Check if Munch Box cafe exists
    SELECT * INTO munchbox_cafe 
    FROM public.cafes 
    WHERE name = 'Munch Box';
    
    IF munchbox_cafe.name IS NOT NULL THEN
        RAISE NOTICE 'Munch Box cafe found: ID=%, accepting_orders=%, priority=%, is_exclusive=%', 
            munchbox_cafe.id, munchbox_cafe.accepting_orders, munchbox_cafe.priority, munchbox_cafe.is_exclusive;
    ELSE
        RAISE NOTICE 'Munch Box cafe not found!';
    END IF;
    
    -- Count menu items
    SELECT COUNT(*) INTO munchbox_menu_count
    FROM public.menu_items mi
    JOIN public.cafes c ON mi.cafe_id = c.id
    WHERE c.name = 'Munch Box';
    
    RAISE NOTICE 'Munch Box has % menu items', munchbox_menu_count;
END $$;

-- Step 3: Show Munch Box cafe details
SELECT 
  name,
  type,
  description,
  location,
  phone,
  hours,
  accepting_orders,
  priority,
  is_exclusive,
  average_rating,
  total_ratings
FROM public.cafes 
WHERE name = 'Munch Box';

-- Step 4: Show Munch Box menu items
SELECT 
  mi.name,
  mi.description,
  mi.price,
  mi.category,
  mi.is_available
FROM public.menu_items mi
JOIN public.cafes c ON mi.cafe_id = c.id
WHERE c.name = 'Munch Box'
ORDER BY mi.category, mi.name;

-- Step 5: Show all cafe owner accounts
SELECT 
  p.email,
  p.full_name,
  p.user_type,
  c.name as cafe_name,
  c.accepting_orders,
  c.priority,
  c.is_exclusive
FROM public.profiles p
LEFT JOIN public.cafes c ON p.cafe_id = c.id
WHERE p.user_type = 'cafe_owner'
ORDER BY c.priority ASC;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Munch Box cafe owner account setup ready!';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Create auth user in Supabase Dashboard';
    RAISE NOTICE '2. Run the profile creation script with the user ID';
    RAISE NOTICE '3. Test login with munchbox.owner@mujfoodclub.in';
END $$;
