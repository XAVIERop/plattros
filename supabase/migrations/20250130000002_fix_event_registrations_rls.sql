-- Fix RLS policies for event_registrations
-- This allows anyone (including anonymous users) to register for events

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can register for events" ON public.event_registrations;
DROP POLICY IF EXISTS "Users can view their own registrations" ON public.event_registrations;
DROP POLICY IF EXISTS "Admins can manage registrations" ON public.event_registrations;
DROP POLICY IF EXISTS "Admins can delete registrations" ON public.event_registrations;

-- Recreate INSERT policy - Allow anyone (including anonymous) to register
CREATE POLICY "Anyone can register for events"
  ON public.event_registrations
  FOR INSERT
  TO authenticated, anon
  WITH CHECK (true);

-- SELECT policy - Users can view their own registrations, admins can view all
CREATE POLICY "Users can view their own registrations"
  ON public.event_registrations
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type IN ('super_admin', 'admin')
    )
  );

-- UPDATE policy - Only admins can update registrations
CREATE POLICY "Admins can update registrations"
  ON public.event_registrations
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type IN ('super_admin', 'admin')
    )
  );

-- DELETE policy - Only admins can delete registrations
CREATE POLICY "Admins can delete registrations"
  ON public.event_registrations
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type IN ('super_admin', 'admin')
    )
  );

-- Verify policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'event_registrations'
ORDER BY policyname;

SELECT '✅ RLS policies fixed for event_registrations!' as status;





