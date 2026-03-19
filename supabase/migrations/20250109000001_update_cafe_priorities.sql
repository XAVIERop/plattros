-- Update Cafe Priorities and Make Cook House Exclusive
-- This migration updates Cook House priority to 6, China Town to 7, and makes Cook House exclusive
-- NOTE: Run the add_is_exclusive_column migration first!

-- Update Cook House priority to 6 and make it exclusive
UPDATE public.cafes 
SET 
    priority = 6,
    is_exclusive = true,
    updated_at = NOW()
WHERE name ILIKE '%cook house%';

-- Update China Town priority to 7
UPDATE public.cafes 
SET 
    priority = 7,
    updated_at = NOW()
WHERE name ILIKE '%china town%';

-- Verify the changes
DO $$
DECLARE
    cook_house_record RECORD;
    china_town_record RECORD;
BEGIN
    -- Check Cook House
    SELECT name, priority, is_exclusive INTO cook_house_record
    FROM public.cafes 
    WHERE name ILIKE '%cook house%';
    
    IF cook_house_record.name IS NOT NULL THEN
        RAISE NOTICE 'Cook House updated: priority=%, is_exclusive=%', 
            cook_house_record.priority, cook_house_record.is_exclusive;
    ELSE
        RAISE NOTICE 'Cook House not found';
    END IF;
    
    -- Check China Town
    SELECT name, priority, is_exclusive INTO china_town_record
    FROM public.cafes 
    WHERE name ILIKE '%china town%';
    
    IF china_town_record.name IS NOT NULL THEN
        RAISE NOTICE 'China Town updated: priority=%, is_exclusive=%', 
            china_town_record.priority, china_town_record.is_exclusive;
    ELSE
        RAISE NOTICE 'China Town not found';
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
    RAISE NOTICE 'Cafe priorities and exclusivity updated successfully!';
    RAISE NOTICE 'Cook House: priority=6, is_exclusive=true';
    RAISE NOTICE 'China Town: priority=7';
END $$;
