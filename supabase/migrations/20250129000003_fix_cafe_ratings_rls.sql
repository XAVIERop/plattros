-- Fix RLS Policies for cafe_ratings table
-- This ensures users can insert and update their own ratings

-- Drop all existing policies on cafe_ratings
DROP POLICY IF EXISTS "Users can view all ratings" ON public.cafe_ratings;
DROP POLICY IF EXISTS "Users can insert their own ratings" ON public.cafe_ratings;
DROP POLICY IF EXISTS "Users can update their own ratings" ON public.cafe_ratings;
DROP POLICY IF EXISTS "Users can delete their own ratings" ON public.cafe_ratings;
DROP POLICY IF EXISTS "public_view_cafe_ratings" ON public.cafe_ratings;
DROP POLICY IF EXISTS "users_insert_own_cafe_ratings" ON public.cafe_ratings;
DROP POLICY IF EXISTS "users_update_own_cafe_ratings" ON public.cafe_ratings;
DROP POLICY IF EXISTS "cafe_ratings_comprehensive" ON public.cafe_ratings;

-- Create clean, working policies

-- 1. SELECT: Anyone can view all ratings (public read)
CREATE POLICY "cafe_ratings_select_all" ON public.cafe_ratings
    FOR SELECT
    USING (true);

-- 2. INSERT: Users can insert their own ratings
CREATE POLICY "cafe_ratings_insert_own" ON public.cafe_ratings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 3. UPDATE: Users can update their own ratings
CREATE POLICY "cafe_ratings_update_own" ON public.cafe_ratings
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 4. DELETE: Users can delete their own ratings
CREATE POLICY "cafe_ratings_delete_own" ON public.cafe_ratings
    FOR DELETE
    USING (auth.uid() = user_id);

-- Verify policies were created
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'cafe_ratings';
    
    IF policy_count >= 4 THEN
        RAISE NOTICE 'Successfully created % policies for cafe_ratings table', policy_count;
    ELSE
        RAISE WARNING 'Expected 4 policies but found %', policy_count;
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cafe_ratings TO authenticated;
GRANT SELECT ON public.cafe_ratings TO anon;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'RLS policies for cafe_ratings table have been fixed!';
    RAISE NOTICE 'Users can now insert and update their own ratings.';
END $$;




