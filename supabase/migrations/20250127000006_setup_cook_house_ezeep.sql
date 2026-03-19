-- Setup Cook House Ezeep Configuration
-- This migration sets up Ezeep printing configuration for Cook House

-- 1. Get Cook House cafe ID
DO $$
DECLARE
    cook_house_id UUID;
BEGIN
    -- Get Cook House cafe ID
    SELECT id INTO cook_house_id FROM public.cafes WHERE name ILIKE '%cook house%';
    
    IF cook_house_id IS NULL THEN
        RAISE EXCEPTION 'Cook House cafe not found';
    END IF;
    
    RAISE NOTICE 'Cook House ID: %', cook_house_id;
    
    -- 2. Insert Ezeep printer configuration for Cook House
    INSERT INTO public.cafe_printer_configs (
        id,
        cafe_id,
        printer_name,
        printer_type,
        connection_type,
        ezeep_printer_id,
        ezeep_api_key,
        paper_width,
        print_density,
        auto_cut,
        is_active,
        is_default,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        cook_house_id,
        'Cook House Xprinter',
        'xprinter_thermal',
        'ezeep_cloud',
        'COOKHOUSE_XPRINTER_001', -- Placeholder - will be updated with actual Ezeep printer ID
        'COOKHOUSE_EZEEP_API_KEY', -- Placeholder - will be updated with actual Ezeep API key
        80, -- 80mm paper width
        8,  -- Print density
        true, -- Auto cut
        true, -- Active
        true, -- Default
        NOW(),
        NOW()
    ) ON CONFLICT (cafe_id, is_default) WHERE is_default = true DO UPDATE SET
        printer_name = EXCLUDED.printer_name,
        printer_type = EXCLUDED.printer_type,
        connection_type = EXCLUDED.connection_type,
        ezeep_printer_id = EXCLUDED.ezeep_printer_id,
        ezeep_api_key = EXCLUDED.ezeep_api_key,
        updated_at = NOW();
    
    RAISE NOTICE 'Cook House Ezeep configuration created successfully!';
    
END $$;

-- 3. Verify the configuration
SELECT 'Cook House Ezeep Configuration:' as status;
SELECT 
    cpc.id,
    cpc.printer_name,
    cpc.printer_type,
    cpc.connection_type,
    cpc.ezeep_printer_id,
    cpc.ezeep_api_key,
    cpc.is_active,
    cpc.is_default,
    c.name as cafe_name,
    c.priority
FROM public.cafe_printer_configs cpc
JOIN public.cafes c ON cpc.cafe_id = c.id
WHERE c.name ILIKE '%cook house%'
AND cpc.is_active = true;

-- 4. Success message
DO $$
BEGIN
    RAISE NOTICE 'Cook House Ezeep setup completed!';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Create Ezeep account for Cook House';
    RAISE NOTICE '2. Get Ezeep API key and printer ID';
    RAISE NOTICE '3. Update the configuration with real values';
    RAISE NOTICE '4. Test printing with sample receipts';
END $$;



