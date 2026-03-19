-- =====================================================
-- SYNC ORDER STATUS WHEN DELIVERY ASSIGNMENT CHANGES
-- =====================================================
-- Automatically update orders.status when delivery_assignments.status changes
-- =====================================================

-- Function to sync order status when assignment status changes
CREATE OR REPLACE FUNCTION public.sync_order_status_on_assignment_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- When assignment is marked as 'delivered', update order status to 'completed'
  IF NEW.status = 'delivered' AND (OLD.status IS NULL OR OLD.status != 'delivered') THEN
    UPDATE public.orders
    SET 
      status = 'completed',
      updated_at = NOW()
    WHERE id = NEW.order_id;
    
    RAISE NOTICE 'Order % status updated to completed (assignment delivered)', NEW.order_id;
  END IF;
  
  -- When assignment is marked as 'picked_up', update order status to 'on_the_way'
  IF NEW.status = 'picked_up' AND (OLD.status IS NULL OR OLD.status != 'picked_up') THEN
    UPDATE public.orders
    SET 
      status = 'on_the_way',
      updated_at = NOW()
    WHERE id = NEW.order_id AND status != 'completed';
    
    RAISE NOTICE 'Order % status updated to on_the_way (assignment picked up)', NEW.order_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger
DROP TRIGGER IF EXISTS sync_order_status_on_assignment_update_trigger ON public.delivery_assignments;

CREATE TRIGGER sync_order_status_on_assignment_update_trigger
  AFTER UPDATE OF status ON public.delivery_assignments
  FOR EACH ROW
  WHEN (NEW.status IS DISTINCT FROM OLD.status)
  EXECUTE FUNCTION public.sync_order_status_on_assignment_update();

-- Add comment
COMMENT ON FUNCTION public.sync_order_status_on_assignment_update() IS 
  'Automatically syncs orders.status when delivery_assignments.status changes. Sets order to "completed" when delivered, and "on_the_way" when picked up.';

COMMENT ON TRIGGER sync_order_status_on_assignment_update_trigger ON public.delivery_assignments IS 
  'Triggers when assignment status changes to sync order status automatically.';


