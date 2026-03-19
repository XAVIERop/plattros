-- =====================================================
-- 📝 ADD MENU TYPE TO CAFE OFFERS
-- =====================================================
-- This migration adds menu_type column to cafe_offers table
-- to distinguish between regular menu and table menu offers
-- =====================================================

-- Add menu_type column to cafe_offers table
ALTER TABLE public.cafe_offers
ADD COLUMN IF NOT EXISTS menu_type TEXT DEFAULT 'both' CHECK (menu_type IN ('regular', 'table', 'both'));

-- Update existing offers to default to 'both' if they don't have a menu_type
UPDATE public.cafe_offers
SET menu_type = 'both'
WHERE menu_type IS NULL;

-- Add comment to explain the column
COMMENT ON COLUMN public.cafe_offers.menu_type IS 'Which menu this offer applies to: regular (regular menu only), table (table menu only), or both (both menus)';

-- Verify the update
SELECT 
  COUNT(*) as total_offers,
  COUNT(*) FILTER (WHERE menu_type = 'both') as both_menus,
  COUNT(*) FILTER (WHERE menu_type = 'regular') as regular_only,
  COUNT(*) FILTER (WHERE menu_type = 'table') as table_only
FROM public.cafe_offers;

SELECT '✅ menu_type column added to cafe_offers table!' as status;





