-- Add separate controls for delivery and table orders
-- This allows cafes to accept delivery orders but not table orders, or vice versa

-- Step 1: Add new columns
ALTER TABLE public.cafes 
ADD COLUMN IF NOT EXISTS accept_delivery_orders BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN IF NOT EXISTS accept_table_orders BOOLEAN NOT NULL DEFAULT true;

-- Step 2: Migrate existing data
-- If accepting_orders = true, set both to true
-- If accepting_orders = false, set both to false
UPDATE public.cafes 
SET 
  accept_delivery_orders = COALESCE(accepting_orders, true),
  accept_table_orders = COALESCE(accepting_orders, true)
WHERE accept_delivery_orders IS NULL OR accept_table_orders IS NULL;

-- Step 3: Update the validation function to check order type
CREATE OR REPLACE FUNCTION public.is_cafe_accepting_orders(cafe_uuid UUID, order_type TEXT DEFAULT 'delivery')
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.cafes 
    WHERE id = cafe_uuid 
    AND is_active = true 
    AND (
      (order_type = 'delivery' AND accept_delivery_orders = true)
      OR
      (order_type = 'table' AND accept_table_orders = true)
      OR
      (order_type IS NULL AND (accept_delivery_orders = true OR accept_table_orders = true))
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Update the order validation trigger to check order type
CREATE OR REPLACE FUNCTION public.validate_order_placement()
RETURNS TRIGGER AS $$
DECLARE
  order_type_check TEXT;
BEGIN
  -- Determine order type based on delivery_block and table_number
  IF NEW.delivery_block::TEXT = 'DINE_IN' OR NEW.table_number IS NOT NULL THEN
    order_type_check := 'table';
  ELSE
    order_type_check := 'delivery';
  END IF;
  
  -- Check if cafe is accepting this type of order
  IF NOT public.is_cafe_accepting_orders(NEW.cafe_id, order_type_check) THEN
    IF order_type_check = 'table' THEN
      RAISE EXCEPTION 'Cafe is not currently accepting table orders';
    ELSE
      RAISE EXCEPTION 'Cafe is not currently accepting delivery orders';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Add comments for clarity
COMMENT ON COLUMN public.cafes.accept_delivery_orders IS 'Whether the cafe accepts delivery orders (delivery to blocks or addresses)';
COMMENT ON COLUMN public.cafes.accept_table_orders IS 'Whether the cafe accepts table/dine-in orders';

-- Step 6: Verify migration
SELECT 
  'Migration Complete' as status,
  COUNT(*) as total_cafes,
  COUNT(CASE WHEN accept_delivery_orders = true THEN 1 END) as accepting_delivery,
  COUNT(CASE WHEN accept_table_orders = true THEN 1 END) as accepting_table,
  COUNT(CASE WHEN accept_delivery_orders = true AND accept_table_orders = true THEN 1 END) as accepting_both,
  COUNT(CASE WHEN accept_delivery_orders = false AND accept_table_orders = false THEN 1 END) as accepting_none
FROM public.cafes;

SELECT '✅ Delivery and Table Order Controls Added!' as status;









