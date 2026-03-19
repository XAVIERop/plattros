-- Update Cafe Priorities - Version 2
-- This migration updates cafe priorities and makes Havmor exclusive

-- Update Cook House priority to 5
UPDATE public.cafes 
SET 
    priority = 5,
    updated_at = NOW()
WHERE name ILIKE '%cook house%';

-- Update Havmor priority to 6 and make it exclusive
UPDATE public.cafes 
SET 
    priority = 6,
    is_exclusive = true,
    updated_at = NOW()
WHERE name ILIKE '%havmor%';

-- Update Mini Meals priority to 8
UPDATE public.cafes 
SET 
    priority = 8,
    updated_at = NOW()
WHERE name ILIKE '%mini meals%';

-- Update China Town priority to 7 (keeping it in the same position)
UPDATE public.cafes 
SET 
    priority = 7,
    updated_at = NOW()
WHERE name ILIKE '%china town%';

-- Verify the changes
DO $$
DECLARE
    cook_house_record RECORD;
    havmor_record RECORD;
    mini_meals_record RECORD;
    china_town_record RECORD;
BEGIN
    -- Check Cook House
    SELECT name, priority, is_exclusive INTO cook_house_record
    FROM public.cafes 
    WHERE name ILIKE '%cook house%';
    
    IF cook_house_record.name IS NOT NULL THEN
        RAISE NOTICE 'Cook House updated: priority=%, is_exclusive=%', 
            cook_house_record.priority, cook_house_record.is_exclusive;
    END IF;
    
    -- Check Havmor
    SELECT name, priority, is_exclusive INTO havmor_record
    FROM public.cafes 
    WHERE name ILIKE '%havmor%';
    
    IF havmor_record.name IS NOT NULL THEN
        RAISE NOTICE 'Havmor updated: priority=%, is_exclusive=%', 
            havmor_record.priority, havmor_record.is_exclusive;
    END IF;
    
    -- Check Mini Meals
    SELECT name, priority, is_exclusive INTO mini_meals_record
    FROM public.cafes 
    WHERE name ILIKE '%mini meals%';
    
    IF mini_meals_record.name IS NOT NULL THEN
        RAISE NOTICE 'Mini Meals updated: priority=%, is_exclusive=%', 
            mini_meals_record.priority, mini_meals_record.is_exclusive;
    END IF;
    
    -- Check China Town
    SELECT name, priority, is_exclusive INTO china_town_record
    FROM public.cafes 
    WHERE name ILIKE '%china town%';
    
    IF china_town_record.name IS NOT NULL THEN
        RAISE NOTICE 'China Town updated: priority=%, is_exclusive=%', 
            china_town_record.priority, china_town_record.is_exclusive;
    END IF;
END $$;

-- Show current priority order
SELECT 
    name,
    priority,
    is_exclusive,
    average_rating,
    total_ratings
FROM public.cafes 
WHERE is_active = true
ORDER BY priority ASC, average_rating DESC NULLS LAST;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Cafe priorities updated successfully!';
    RAISE NOTICE 'Cook House: priority=5';
    RAISE NOTICE 'Havmor: priority=6, is_exclusive=true';
    RAISE NOTICE 'China Town: priority=7';
    RAISE NOTICE 'Mini Meals: priority=8';
END $$;
