-- Make Havmor Open
-- This migration updates Havmor's accepting_orders status to true

-- Update Havmor to accept orders
UPDATE public.cafes 
SET 
    accepting_orders = true,
    updated_at = NOW()
WHERE name ILIKE '%havmor%';

-- Verify the change
DO $$
DECLARE
    havmor_record RECORD;
BEGIN
    -- Check Havmor status
    SELECT name, accepting_orders, priority, is_exclusive INTO havmor_record
    FROM public.cafes 
    WHERE name ILIKE '%havmor%';
    
    IF havmor_record.name IS NOT NULL THEN
        RAISE NOTICE 'Havmor updated: accepting_orders=%, priority=%, is_exclusive=%', 
            havmor_record.accepting_orders, havmor_record.priority, havmor_record.is_exclusive;
    ELSE
        RAISE NOTICE 'Havmor not found';
    END IF;
END $$;

-- Show all exclusive cafes and their status
SELECT 
    name,
    accepting_orders,
    priority,
    is_exclusive
FROM public.cafes 
WHERE is_exclusive = true
ORDER BY priority ASC;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Havmor is now open and accepting orders!';
END $$;
