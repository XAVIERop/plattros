-- =====================================================
-- 🎉 ADD SWJ PRICE TO MENU ITEMS
-- =====================================================
-- This migration adds swj_price column for Startup Weekend Jaipur event
-- Allows cafes to set custom prices for SWJ event, or auto-calculate 10% markup
-- =====================================================

-- Add swj_price column to menu_items table
ALTER TABLE public.menu_items
ADD COLUMN IF NOT EXISTS swj_price DECIMAL(10,2) NULL;

-- Add comment explaining the column
COMMENT ON COLUMN public.menu_items.swj_price IS 
'Custom price for Startup Weekend Jaipur event. If NULL, price will be calculated as regular price * 1.30 (30% markup, rounded to nearest rupee). If set, this price will be used on /swj page.';

-- Create index for faster filtering (if needed)
CREATE INDEX IF NOT EXISTS idx_menu_items_swj_price ON public.menu_items(swj_price) WHERE swj_price IS NOT NULL;

-- Grant necessary permissions (should already exist via RLS, but ensuring)
GRANT SELECT, UPDATE ON public.menu_items TO authenticated;

SELECT '✅ SWJ price column added to menu_items table!' as status;

