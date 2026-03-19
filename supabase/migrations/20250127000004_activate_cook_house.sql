-- Activate Cook House Cafe - Set Priority to 7
-- This migration activates Cook House and sets its priority to 7

-- 1. Check current Cook House status
SELECT 'Current Cook House Status:' as status;
SELECT 
    id, 
    name, 
    priority, 
    is_active, 
    accepting_orders,
    created_at
FROM public.cafes 
WHERE name ILIKE '%cook house%';

-- 2. Update Cook House priority to 7
UPDATE public.cafes 
SET 
    priority = 7,
    is_active = true,
    accepting_orders = true,
    updated_at = NOW()
WHERE name ILIKE '%cook house%';

-- 3. Verify the update
SELECT 'Updated Cook House Status:' as status;
SELECT 
    id, 
    name, 
    priority, 
    is_active, 
    accepting_orders,
    updated_at
FROM public.cafes 
WHERE name ILIKE '%cook house%';

-- 4. Check current cafe priorities to see where Cook House fits
SELECT 'Current Cafe Priorities:' as status;
SELECT 
    name,
    priority,
    is_active,
    accepting_orders
FROM public.cafes 
WHERE is_active = true
ORDER BY priority ASC, name ASC;

-- 5. Success message
DO $$
BEGIN
    RAISE NOTICE 'Cook House activated successfully!';
    RAISE NOTICE 'Priority set to 7';
    RAISE NOTICE 'Cafe is now active and accepting orders';
    RAISE NOTICE 'Next step: Create cafe staff account for Cook House';
END $$;



