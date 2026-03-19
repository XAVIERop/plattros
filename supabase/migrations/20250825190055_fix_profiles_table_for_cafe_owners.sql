-- Fix profiles table for cafe owners - only add what's missing
-- This migration handles the case where some fields already exist

-- Check if user_type column exists, if not add it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'user_type') THEN
        ALTER TABLE public.profiles ADD COLUMN user_type TEXT DEFAULT 'student' CHECK (user_type IN ('student', 'cafe_owner', 'cafe_staff'));
    END IF;
END $$;

-- Check if cafe_id column exists, if not add it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'cafe_id') THEN
        ALTER TABLE public.profiles ADD COLUMN cafe_id UUID REFERENCES public.cafes(id);
    END IF;
END $$;

-- Make block column nullable (since cafe owners don't have blocks)
ALTER TABLE public.profiles ALTER COLUMN block DROP NOT NULL;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON public.profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_profiles_cafe_id ON public.profiles(cafe_id);

-- Update existing profiles to have user_type = 'student' if not set
UPDATE public.profiles SET user_type = 'student' WHERE user_type IS NULL;

-- Add comments if they don't exist
COMMENT ON COLUMN public.profiles.user_type IS 'Type of user: student, cafe_owner, or cafe_staff';
COMMENT ON COLUMN public.profiles.cafe_id IS 'Associated cafe ID for cafe owners and staff';

-- Verify the current table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;
