-- =====================================================
-- ADD DELIVERY GOOGLE MAPS LINK FIELD
-- =====================================================
-- Add a dedicated field to store Google Maps links for delivery locations
-- This can be set by cafes when manually assigning riders, or by customers when placing orders
-- =====================================================

-- Add delivery_maps_link column to orders table
ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS delivery_maps_link TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.orders.delivery_maps_link IS 'Google Maps link for customer delivery location. Can be set by cafe during manual rider assignment or by customer during order placement.';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_orders_delivery_maps_link ON public.orders(delivery_maps_link) WHERE delivery_maps_link IS NOT NULL;


