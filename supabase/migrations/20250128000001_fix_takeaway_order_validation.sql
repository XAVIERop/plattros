-- Fix validate_order_placement trigger to handle TAKEAWAY orders correctly
-- TAKEAWAY orders should check if EITHER accept_delivery_orders OR accept_table_orders is true
-- This matches the frontend logic where takeaway orders are flexible

CREATE OR REPLACE FUNCTION public.validate_order_placement()
RETURNS TRIGGER AS $$
DECLARE
  order_type_check TEXT;
  is_takeaway BOOLEAN;
BEGIN
  -- Check if this is a takeaway order
  is_takeaway := (NEW.delivery_block::TEXT = 'TAKEAWAY');
  
  -- Determine order type based on delivery_block and table_number
  IF NEW.delivery_block::TEXT = 'DINE_IN' OR NEW.table_number IS NOT NULL THEN
    order_type_check := 'table';
  ELSIF is_takeaway THEN
    order_type_check := NULL; -- NULL means check if EITHER delivery OR table is available
  ELSE
    order_type_check := 'delivery';
  END IF;
  
  -- Check if cafe is accepting this type of order
  -- For takeaway (order_type_check = NULL), is_cafe_accepting_orders checks if EITHER flag is true
  IF NOT public.is_cafe_accepting_orders(NEW.cafe_id, order_type_check) THEN
    IF order_type_check = 'table' THEN
      RAISE EXCEPTION 'Cafe is not currently accepting table orders';
    ELSIF is_takeaway THEN
      RAISE EXCEPTION 'Cafe is not currently accepting takeaway orders';
    ELSE
      RAISE EXCEPTION 'Cafe is not currently accepting delivery orders';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Verify the trigger exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'validate_order_placement_trigger'
  ) THEN
    -- Create the trigger if it doesn't exist
    CREATE TRIGGER validate_order_placement_trigger
      BEFORE INSERT ON public.orders
      FOR EACH ROW
      EXECUTE FUNCTION public.validate_order_placement();
    RAISE NOTICE '✅ Created validate_order_placement_trigger';
  ELSE
    RAISE NOTICE '✅ Trigger validate_order_placement_trigger already exists and has been updated';
  END IF;
END $$;

SELECT '✅ Takeaway order validation fixed - now checks if EITHER delivery OR table orders are accepted' as status;




