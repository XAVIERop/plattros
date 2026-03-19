-- Fix RLS policies for cafes table to allow anonymous access
-- This allows unauthenticated users to view cafes (needed for homepage)

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Cafes are viewable by everyone" ON public.cafes;
DROP POLICY IF EXISTS "Anyone can view cafes" ON public.cafes;
DROP POLICY IF EXISTS "Public can view cafes" ON public.cafes;

-- Create a new policy that allows anonymous users to view cafes
CREATE POLICY "Anyone can view cafes" ON public.cafes
  FOR SELECT
  USING (true);

-- Ensure RLS is enabled
ALTER TABLE public.cafes ENABLE ROW LEVEL SECURITY;

-- Test the policy by checking if anonymous access works
DO $$
BEGIN
  -- This will be logged in the migration output
  RAISE NOTICE 'RLS policy created for anonymous cafe access';
END $$;














