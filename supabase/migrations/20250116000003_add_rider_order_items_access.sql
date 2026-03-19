-- =====================================================
-- ADD RLS POLICY FOR RIDERS TO VIEW ORDER ITEMS
-- =====================================================
-- Riders need to view order items for orders assigned to them
-- =====================================================

-- Add policy for riders to view order items for their assigned orders
DROP POLICY IF EXISTS "Riders can view order items for assigned orders" ON public.order_items;

CREATE POLICY "Riders can view order items for assigned orders"
  ON public.order_items FOR SELECT
  USING (
    -- Allow if the order is assigned to the rider
    EXISTS (
      SELECT 1 FROM public.delivery_assignments
      WHERE delivery_assignments.order_id = order_items.order_id
      AND delivery_assignments.rider_id IN (
        SELECT id FROM public.delivery_riders
        WHERE user_id = auth.uid()
        AND is_active = true
      )
    )
    OR
    -- Allow if user is super admin
    public.is_super_admin()
  );

COMMENT ON POLICY "Riders can view order items for assigned orders" ON public.order_items IS 
  'Allows delivery riders to view order items for orders that are assigned to them. Also allows super admins to view all order items.';


