-- =====================================================
-- 📝 ADD ORDER OFFER TRACKING
-- =====================================================
-- This migration adds fields to track applied offers in orders
-- and creates a table to track offer usage
-- =====================================================

-- Add discount fields to orders table
DO $$
BEGIN
  -- Add discount_amount column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'discount_amount'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN discount_amount DECIMAL(10,2) DEFAULT 0;
  END IF;

  -- Add original_total_amount column if it doesn't exist (before discount)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'original_total_amount'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN original_total_amount DECIMAL(10,2);
  END IF;
END $$;

-- Create table to track which offers were applied to orders
CREATE TABLE IF NOT EXISTS public.order_applied_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  offer_id UUID NOT NULL REFERENCES public.cafe_offers(id) ON DELETE RESTRICT,
  discount_amount DECIMAL(10,2) NOT NULL, -- Amount saved from this offer
  offer_name TEXT, -- Store offer name at time of application
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Ensure an offer can only be applied once per order
  UNIQUE(order_id, offer_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_order_applied_offers_order_id ON public.order_applied_offers(order_id);
CREATE INDEX IF NOT EXISTS idx_order_applied_offers_offer_id ON public.order_applied_offers(offer_id);

-- Enable RLS
ALTER TABLE public.order_applied_offers ENABLE ROW LEVEL SECURITY;

-- RLS Policies for order_applied_offers
-- Policy 1: Users can view applied offers for their own orders
CREATE POLICY "Users can view their order applied offers"
  ON public.order_applied_offers
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders 
      WHERE orders.id = order_applied_offers.order_id 
      AND orders.user_id = auth.uid()
    )
  );

-- Policy 2: Cafe owners can view applied offers for their cafe's orders
CREATE POLICY "Cafe owners can view their cafe order applied offers"
  ON public.order_applied_offers
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders 
      JOIN public.profiles ON profiles.id = auth.uid()
      WHERE orders.id = order_applied_offers.order_id 
      AND orders.cafe_id = profiles.cafe_id
      AND profiles.user_type = 'cafe_owner'
    )
  );

-- Policy 3: Admins can view all applied offers
CREATE POLICY "Admins can view all order applied offers"
  ON public.order_applied_offers
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'super_admin'
    )
  );

-- Policy 4: System can insert applied offers (for order creation)
CREATE POLICY "Authenticated users can insert order applied offers"
  ON public.order_applied_offers
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Trigger to update offer usage count when order is completed
CREATE OR REPLACE FUNCTION update_offer_usage_on_order_complete()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update when order status changes to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Increment current_uses for all offers applied to this order
    UPDATE public.cafe_offers
    SET current_uses = current_uses + 1
    WHERE id IN (
      SELECT offer_id 
      FROM public.order_applied_offers 
      WHERE order_id = NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_offer_usage
  AFTER UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION update_offer_usage_on_order_complete();

-- Comments
COMMENT ON COLUMN public.orders.discount_amount IS 'Total discount amount applied to the order';
COMMENT ON COLUMN public.orders.original_total_amount IS 'Order total before discounts were applied';
COMMENT ON TABLE public.order_applied_offers IS 'Tracks which offers were applied to which orders';



