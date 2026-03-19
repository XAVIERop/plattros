-- =====================================================
-- 🔧 FIX OFFER DELETE CONSTRAINT
-- =====================================================
-- This migration fixes the foreign key constraint to allow
-- offer deletion while preserving historical order records
-- =====================================================

-- Drop the existing foreign key constraint
ALTER TABLE public.order_applied_offers
  DROP CONSTRAINT IF EXISTS order_applied_offers_offer_id_fkey;

-- Make offer_id nullable (since we store offer_name for historical reference)
ALTER TABLE public.order_applied_offers
  ALTER COLUMN offer_id DROP NOT NULL;

-- Recreate the foreign key constraint with ON DELETE SET NULL
-- This allows offer deletion while keeping historical records
ALTER TABLE public.order_applied_offers
  ADD CONSTRAINT order_applied_offers_offer_id_fkey
  FOREIGN KEY (offer_id)
  REFERENCES public.cafe_offers(id)
  ON DELETE SET NULL;

-- Add comment explaining the behavior
COMMENT ON COLUMN public.order_applied_offers.offer_id IS 
  'Reference to cafe_offers. Set to NULL when offer is deleted, but offer_name is preserved for historical records.';


