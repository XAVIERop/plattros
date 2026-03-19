-- Create Cook House Staff Account
-- This migration creates a cafe staff account for Cook House

-- 1. Get Cook House cafe ID
DO $$
DECLARE
    cook_house_id UUID;
    owner_user_id UUID;
    owner_profile_id UUID;
BEGIN
    -- Get Cook House cafe ID
    SELECT id INTO cook_house_id FROM public.cafes WHERE name ILIKE '%cook house%';
    
    IF cook_house_id IS NULL THEN
        RAISE EXCEPTION 'Cook House cafe not found';
    END IF;
    
    RAISE NOTICE 'Cook House ID: %', cook_house_id;
    
    -- Generate UUIDs
    owner_user_id := gen_random_uuid();
    owner_profile_id := owner_user_id; -- Same ID for auth.users and profiles
    
    -- 2. Insert into auth.users (this will be handled by Supabase auth)
    -- We'll create the profile directly and let the system handle auth
    
    -- 3. Create profile for Cook House owner
    INSERT INTO public.profiles (
        id,
        email,
        full_name,
        block,
        phone,
        user_type,
        cafe_id,
        loyalty_points,
        loyalty_tier,
        qr_code,
        student_id,
        total_orders,
        total_spent,
        created_at,
        updated_at
    ) VALUES (
        owner_profile_id,
        'cookhouse.owner@muj.manipal.edu',
        'Cook House Owner',
        'B1',
        '+91-9876543210',
        'cafe_owner',
        cook_house_id,
        0,
        'foodie',
        'QR-COOKHOUSE-OWNER-' || extract(epoch from now())::text,
        'COOK001',
        0,
        0,
        NOW(),
        NOW()
    ) ON CONFLICT (email) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        user_type = EXCLUDED.user_type,
        cafe_id = EXCLUDED.cafe_id,
        updated_at = NOW();
    
    -- Get the actual profile ID (in case of conflict)
    SELECT id INTO owner_profile_id FROM public.profiles WHERE email = 'cookhouse.owner@muj.manipal.edu';
    
    -- 4. Create cafe staff record
    INSERT INTO public.cafe_staff (
        id,
        cafe_id,
        user_id,
        role,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        cook_house_id,
        owner_profile_id,
        'owner',
        true,
        NOW(),
        NOW()
    ) ON CONFLICT (cafe_id, user_id) DO UPDATE SET
        role = EXCLUDED.role,
        is_active = EXCLUDED.is_active,
        updated_at = NOW();
    
    RAISE NOTICE 'Cook House staff account created successfully!';
    RAISE NOTICE 'Profile ID: %', owner_profile_id;
    RAISE NOTICE 'Cafe ID: %', cook_house_id;
    
END $$;

-- 5. Verify the setup
SELECT 'Cook House Staff Setup Verification:' as status;
SELECT 
    cs.id as staff_id,
    cs.role,
    cs.is_active,
    p.email,
    p.full_name,
    p.user_type,
    c.name as cafe_name,
    c.priority,
    c.is_active as cafe_active
FROM public.cafe_staff cs
JOIN public.profiles p ON cs.user_id = p.id
JOIN public.cafes c ON cs.cafe_id = c.id
WHERE c.name ILIKE '%cook house%'
AND cs.is_active = true;

-- 6. Success message
DO $$
BEGIN
    RAISE NOTICE 'Cook House staff account setup completed!';
    RAISE NOTICE 'Login Details:';
    RAISE NOTICE '  Email: cookhouse.owner@muj.manipal.edu';
    RAISE NOTICE '  Role: Cafe Owner';
    RAISE NOTICE '  Cafe: COOK HOUSE';
    RAISE NOTICE '  Priority: 7';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Set up Ezeep integration for Xprinter';
    RAISE NOTICE '2. Test the complete system';
END $$;



