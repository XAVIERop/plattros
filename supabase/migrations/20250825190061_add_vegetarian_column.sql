-- Add is_vegetarian column to menu_items table for veg/non-veg segregation
-- This migration adds the is_vegetarian boolean column to enable proper filtering

-- Add the is_vegetarian column to menu_items table
ALTER TABLE public.menu_items 
ADD COLUMN IF NOT EXISTS is_vegetarian BOOLEAN DEFAULT true;

-- Add a comment to explain the column
COMMENT ON COLUMN public.menu_items.is_vegetarian IS 'Indicates if the menu item is vegetarian (true) or non-vegetarian (false)';

-- Update existing items to have proper vegetarian status based on their names
-- This is a general update - the specific Food Court items will be updated by the main script

-- Set non-vegetarian items based on common non-veg keywords
UPDATE public.menu_items 
SET is_vegetarian = false 
WHERE name ILIKE '%chicken%' 
   OR name ILIKE '%fish%' 
   OR name ILIKE '%prawn%' 
   OR name ILIKE '%mutton%' 
   OR name ILIKE '%lamb%' 
   OR name ILIKE '%beef%' 
   OR name ILIKE '%pork%' 
   OR name ILIKE '%egg%'
   OR name ILIKE '%non-veg%'
   OR name ILIKE '%non veg%';

-- Set vegetarian items based on common veg keywords (these will override non-veg if both match)
UPDATE public.menu_items 
SET is_vegetarian = true 
WHERE name ILIKE '%veg%' 
   OR name ILIKE '%paneer%' 
   OR name ILIKE '%cheese%' 
   OR name ILIKE '%corn%' 
   OR name ILIKE '%aloo%' 
   OR name ILIKE '%dal%' 
   OR name ILIKE '%rajma%' 
   OR name ILIKE '%chola%' 
   OR name ILIKE '%biryani%' 
   OR name ILIKE '%pasta%' 
   OR name ILIKE '%lemonade%' 
   OR name ILIKE '%mojito%' 
   OR name ILIKE '%shake%' 
   OR name ILIKE '%coffee%' 
   OR name ILIKE '%tea%'
   OR name ILIKE '%water%'
   OR name ILIKE '%juice%';

-- Create an index on the is_vegetarian column for better query performance
CREATE INDEX IF NOT EXISTS idx_menu_items_is_vegetarian ON public.menu_items(is_vegetarian);

-- Add RLS policy for the new column (if RLS is enabled)
-- This ensures the column follows the same access patterns as other menu_item columns
-- (The existing RLS policies should already cover this column)

RAISE NOTICE '✅ Added is_vegetarian column to menu_items table';
RAISE NOTICE '✅ Updated existing items with vegetarian status based on names';
RAISE NOTICE '✅ Created index for better query performance';
