-- =====================================================
-- 🎁 CREATE CAFE OFFERS SYSTEM
-- =====================================================
-- This migration creates the cafe_offers table and related structures
-- for managing discounts and offers for cafes
-- =====================================================

-- Create cafe_offers table
CREATE TABLE IF NOT EXISTS public.cafe_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  
  -- Basic Info
  name TEXT NOT NULL,
  description TEXT,
  offer_type TEXT NOT NULL, -- 'flat_item', 'flat_category', 'bogo', 'min_order', 'combination'
  
  -- Discount Details
  discount_type TEXT NOT NULL, -- 'percentage', 'fixed_amount'
  discount_value DECIMAL(10,2) NOT NULL, -- percentage (10.00) or amount (50.00)
  
  -- Applicability
  applicable_to_type TEXT, -- 'item', 'category', 'all', 'min_order'
  applicable_to_ids UUID[], -- Array of menu_item IDs (for items)
  applicable_to_categories TEXT[], -- Array of category names (for categories)
  
  -- BOGO Specific
  bogo_buy_quantity INTEGER, -- Buy X
  bogo_get_quantity INTEGER, -- Get Y free
  bogo_cheapest_free BOOLEAN DEFAULT true, -- Apply discount to cheapest items
  
  -- Minimum Order
  min_order_amount DECIMAL(10,2),
  
  -- Validity
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  start_time TIME, -- Optional time restriction (e.g., 10:00:00)
  end_time TIME,
  
  -- Usage Limits
  max_uses_per_customer INTEGER, -- NULL = unlimited
  max_total_uses INTEGER, -- NULL = unlimited
  current_uses INTEGER DEFAULT 0,
  
  -- Status
  is_active BOOLEAN NOT NULL DEFAULT true,
  priority INTEGER DEFAULT 0, -- Higher priority shows first/gets applied first
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Constraints
  CONSTRAINT check_discount_value CHECK (discount_value > 0),
  CONSTRAINT check_dates CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date),
  CONSTRAINT check_bogo_quantities CHECK (
    (offer_type != 'bogo') OR 
    (bogo_buy_quantity IS NOT NULL AND bogo_buy_quantity > 0 AND bogo_get_quantity IS NOT NULL AND bogo_get_quantity > 0)
  ),
  CONSTRAINT check_min_order CHECK (
    (offer_type != 'min_order') OR (min_order_amount IS NOT NULL AND min_order_amount > 0)
  ),
  CONSTRAINT check_discount_type CHECK (discount_type IN ('percentage', 'fixed_amount')),
  CONSTRAINT check_offer_type CHECK (offer_type IN ('flat_item', 'flat_category', 'bogo', 'min_order', 'combination')),
  CONSTRAINT check_applicable_type CHECK (applicable_to_type IN ('item', 'category', 'all', 'min_order') OR applicable_to_type IS NULL)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_cafe_offers_cafe_id ON public.cafe_offers(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_offers_active ON public.cafe_offers(is_active, cafe_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_cafe_offers_dates ON public.cafe_offers(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_cafe_offers_priority ON public.cafe_offers(priority DESC, cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_offers_type ON public.cafe_offers(offer_type, cafe_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cafe_offers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_cafe_offers_updated_at
  BEFORE UPDATE ON public.cafe_offers
  FOR EACH ROW
  EXECUTE FUNCTION update_cafe_offers_updated_at();

-- Enable Row Level Security
ALTER TABLE public.cafe_offers ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Policy 1: Anyone can view active offers for active cafes
CREATE POLICY "Anyone can view active cafe offers"
  ON public.cafe_offers
  FOR SELECT
  USING (
    is_active = true 
    AND (start_date IS NULL OR start_date <= now())
    AND (end_date IS NULL OR end_date >= now())
    AND EXISTS (
      SELECT 1 FROM public.cafes 
      WHERE cafes.id = cafe_offers.cafe_id 
      AND cafes.is_active = true
    )
  );

-- Policy 2: Cafe owners and admins can view all offers for their cafes
CREATE POLICY "Cafe owners and admins can view their cafe offers"
  ON public.cafe_offers
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid()
      AND (
        profiles.user_type = 'super_admin'
        OR (
          profiles.user_type = 'cafe_owner' 
          AND profiles.cafe_id = cafe_offers.cafe_id
        )
      )
    )
  );

-- Policy 3: Cafe owners and admins can insert offers for their cafes
CREATE POLICY "Cafe owners and admins can create offers"
  ON public.cafe_offers
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid()
      AND (
        profiles.user_type = 'super_admin'
        OR (
          profiles.user_type = 'cafe_owner' 
          AND profiles.cafe_id = cafe_offers.cafe_id
        )
      )
    )
  );

-- Policy 4: Cafe owners and admins can update offers for their cafes
CREATE POLICY "Cafe owners and admins can update their offers"
  ON public.cafe_offers
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid()
      AND (
        profiles.user_type = 'super_admin'
        OR (
          profiles.user_type = 'cafe_owner' 
          AND profiles.cafe_id = cafe_offers.cafe_id
        )
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid()
      AND (
        profiles.user_type = 'super_admin'
        OR (
          profiles.user_type = 'cafe_owner' 
          AND profiles.cafe_id = cafe_offers.cafe_id
        )
      )
    )
  );

-- Policy 5: Cafe owners and admins can delete offers for their cafes
CREATE POLICY "Cafe owners and admins can delete their offers"
  ON public.cafe_offers
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid()
      AND (
        profiles.user_type = 'super_admin'
        OR (
          profiles.user_type = 'cafe_owner' 
          AND profiles.cafe_id = cafe_offers.cafe_id
        )
      )
    )
  );

-- Helper function: Check if offer is currently valid
CREATE OR REPLACE FUNCTION is_offer_valid(offer_record public.cafe_offers)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  current_timestamp TIMESTAMPTZ := now();
  current_time_only TIME := current_timestamp::TIME;
BEGIN
  -- Check if offer is active
  IF NOT offer_record.is_active THEN
    RETURN false;
  END IF;
  
  -- Check date range
  IF offer_record.start_date IS NOT NULL AND current_timestamp < offer_record.start_date THEN
    RETURN false;
  END IF;
  
  IF offer_record.end_date IS NOT NULL AND current_timestamp > offer_record.end_date THEN
    RETURN false;
  END IF;
  
  -- Check time range (if specified)
  IF offer_record.start_time IS NOT NULL AND offer_record.end_time IS NOT NULL THEN
    IF NOT (current_time_only >= offer_record.start_time AND current_time_only <= offer_record.end_time) THEN
      RETURN false;
    END IF;
  END IF;
  
  -- Check usage limits
  IF offer_record.max_total_uses IS NOT NULL AND offer_record.current_uses >= offer_record.max_total_uses THEN
    RETURN false;
  END IF;
  
  RETURN true;
END;
$$;

-- Helper function: Get active offers for a cafe
CREATE OR REPLACE FUNCTION get_active_cafe_offers(target_cafe_id UUID)
RETURNS SETOF public.cafe_offers
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.cafe_offers
  WHERE cafe_id = target_cafe_id
    AND is_active = true
    AND (start_date IS NULL OR start_date <= now())
    AND (end_date IS NULL OR end_date >= now())
    AND (max_total_uses IS NULL OR current_uses < max_total_uses)
  ORDER BY priority DESC, created_at DESC;
END;
$$;

-- Grant necessary permissions
GRANT SELECT ON public.cafe_offers TO authenticated;
GRANT SELECT ON public.cafe_offers TO anon;
GRANT ALL ON public.cafe_offers TO authenticated;

-- Comments for documentation
COMMENT ON TABLE public.cafe_offers IS 'Stores discount offers and promotions for cafes';
COMMENT ON COLUMN public.cafe_offers.offer_type IS 'Type of offer: flat_item, flat_category, bogo, min_order, combination';
COMMENT ON COLUMN public.cafe_offers.discount_type IS 'Type of discount: percentage or fixed_amount';
COMMENT ON COLUMN public.cafe_offers.applicable_to_type IS 'What the offer applies to: item, category, all, or min_order';
COMMENT ON COLUMN public.cafe_offers.applicable_to_ids IS 'Array of menu_item UUIDs when applicable_to_type is item';
COMMENT ON COLUMN public.cafe_offers.applicable_to_categories IS 'Array of category names when applicable_to_type is category';
COMMENT ON COLUMN public.cafe_offers.priority IS 'Higher priority offers are displayed/applied first';



