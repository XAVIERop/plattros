-- Enable Mini Meals to accept orders
-- This migration will set Mini Meals to accepting_orders = true
-- while keeping other cafes (except Chatkara and Cook House) restricted

-- First, let's see the current status
SELECT 'BEFORE UPDATE - Current Status:' as status;
SELECT 
  name,
  priority,
  is_active,
  accepting_orders,
  CASE 
    WHEN accepting_orders = true THEN '✅ ORDER NOW'
    ELSE '⏳ COMING SOON'
  END as button_status
FROM public.cafes 
WHERE name IN ('CHATKARA', 'COOK HOUSE', 'Mini Meals', 'FOOD COURT', 'Punjabi Tadka', 'Munch Box')
ORDER BY 
  CASE name 
    WHEN 'CHATKARA' THEN 1
    WHEN 'COOK HOUSE' THEN 2
    WHEN 'Mini Meals' THEN 3
    WHEN 'FOOD COURT' THEN 4
    WHEN 'Punjabi Tadka' THEN 5
    WHEN 'Munch Box' THEN 6
    ELSE 7
  END;

-- Update Mini Meals to accept orders
UPDATE public.cafes 
SET 
  accepting_orders = true,
  updated_at = NOW()
WHERE name = 'Mini Meals';

-- Verify the update
SELECT 'AFTER UPDATE - New Status:' as status;
SELECT 
  name,
  priority,
  is_active,
  accepting_orders,
  CASE 
    WHEN accepting_orders = true THEN '✅ ORDER NOW'
    ELSE '⏳ COMING SOON'
  END as button_status
FROM public.cafes 
WHERE name IN ('CHATKARA', 'COOK HOUSE', 'Mini Meals', 'FOOD COURT', 'Punjabi Tadka', 'Munch Box')
ORDER BY 
  CASE name 
    WHEN 'CHATKARA' THEN 1
    WHEN 'COOK HOUSE' THEN 2
    WHEN 'Mini Meals' THEN 3
    WHEN 'FOOD COURT' THEN 4
    WHEN 'Punjabi Tadka' THEN 5
    WHEN 'Munch Box' THEN 6
    ELSE 7
  END;

-- Show summary of accepting orders cafes
SELECT 
  'SUMMARY' as section,
  COUNT(*) as total_cafes,
  COUNT(CASE WHEN accepting_orders = true THEN 1 END) as accepting_orders_cafes,
  COUNT(CASE WHEN accepting_orders = false THEN 1 END) as coming_soon_cafes
FROM public.cafes 
WHERE name IN ('CHATKARA', 'COOK HOUSE', 'Mini Meals', 'FOOD COURT', 'Punjabi Tadka', 'Munch Box');

-- Show which cafes are now accepting orders
SELECT 
  'CAFES ACCEPTING ORDERS:' as section,
  name,
  '✅ Ready for orders' as status
FROM public.cafes 
WHERE accepting_orders = true 
AND name IN ('CHATKARA', 'COOK HOUSE', 'Mini Meals', 'FOOD COURT', 'Punjabi Tadka', 'Munch Box')
ORDER BY name;
