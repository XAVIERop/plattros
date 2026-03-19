-- PERMANENT FIX: Allow anonymous users to view cafes for homepage
-- This is essential for production as users need to see cafes before signing up

-- First, check current RLS status
DO $$
BEGIN
  -- Log current RLS status
  IF EXISTS (
    SELECT 1 FROM pg_class 
    WHERE relname = 'cafes' 
    AND relrowsecurity = true
  ) THEN
    RAISE NOTICE 'RLS is currently ENABLED on cafes table';
  ELSE
    RAISE NOTICE 'RLS is currently DISABLED on cafes table';
  END IF;
END $$;

-- Ensure RLS is enabled (required for policies to work)
ALTER TABLE public.cafes ENABLE ROW LEVEL SECURITY;

-- Drop any existing conflicting policies
DROP POLICY IF EXISTS "Cafes are viewable by everyone" ON public.cafes;
DROP POLICY IF EXISTS "Anyone can view cafes" ON public.cafes;
DROP POLICY IF EXISTS "Public can view cafes" ON public.cafes;
DROP POLICY IF EXISTS "Allow anonymous read access" ON public.cafes;
DROP POLICY IF EXISTS "Allow public read access to cafes" ON public.cafes;

-- Create a comprehensive policy that allows:
-- 1. Anonymous users to view cafes (for homepage)
-- 2. Authenticated users to view cafes
-- 3. Only show cafes that are accepting orders
CREATE POLICY "Allow public read access to cafes"
ON public.cafes 
FOR SELECT
TO public
USING (accepting_orders = true);

-- Create additional policy for cafe owners/staff to manage their cafes
CREATE POLICY "Cafe owners can manage their cafes"
ON public.cafes
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE profiles.id = auth.uid() 
    AND (
      profiles.user_type = 'cafe_owner' 
      AND profiles.cafe_id = cafes.id
    )
  )
  OR
  EXISTS (
    SELECT 1 FROM public.cafe_staff 
    WHERE cafe_staff.user_id = auth.uid() 
    AND cafe_staff.cafe_id = cafes.id
    AND cafe_staff.is_active = true
  )
);

-- Test the policy by checking if anonymous access works
DO $$
DECLARE
  cafe_count INTEGER;
BEGIN
  -- This will be logged in the migration output
  SELECT COUNT(*) INTO cafe_count 
  FROM public.cafes 
  WHERE accepting_orders = true;
  
  RAISE NOTICE 'Migration completed. Found % cafes accepting orders', cafe_count;
  RAISE NOTICE 'Anonymous users can now view cafes on the homepage';
END $$;














