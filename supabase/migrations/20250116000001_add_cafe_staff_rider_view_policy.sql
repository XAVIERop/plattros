-- =====================================================
-- ADD RLS POLICY FOR CAFE STAFF TO VIEW RIDERS
-- =====================================================
-- Cafe staff need to view all riders to assign them to orders
-- =====================================================

-- Add policy for cafe staff and owners to view all active riders
DROP POLICY IF EXISTS "Cafe staff can view all active riders" ON public.delivery_riders;

CREATE POLICY "Cafe staff can view all active riders"
  ON public.delivery_riders FOR SELECT
  USING (
    -- Allow if user is cafe staff
    EXISTS (
      SELECT 1 FROM public.cafe_staff
      WHERE cafe_staff.user_id = auth.uid()
      AND cafe_staff.is_active = true
    )
    OR
    -- Allow if user is a cafe owner (has cafe_id in profile)
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.cafe_id IS NOT NULL
    )
    OR
    -- Allow if user is super admin
    public.is_super_admin()
    OR
    -- Allow if user is a rider viewing their own profile
    auth.uid() = user_id
  );

COMMENT ON POLICY "Cafe staff can view all active riders" ON public.delivery_riders IS 
  'Allows cafe staff to view all active riders for assignment purposes. Also allows super admins and riders to view their own profile.';

