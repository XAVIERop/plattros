-- Add user_type and cafe_id fields to profiles table
-- This enables cafe owners to have their own profiles with cafe associations

-- Add user_type column with default value 'student'
ALTER TABLE public.profiles 
ADD COLUMN user_type TEXT DEFAULT 'student' CHECK (user_type IN ('student', 'cafe_owner', 'cafe_staff'));

-- Add cafe_id column (nullable for students)
ALTER TABLE public.profiles 
ADD COLUMN cafe_id UUID REFERENCES public.cafes(id);

-- Create index on user_type for better query performance
CREATE INDEX idx_profiles_user_type ON public.profiles(user_type);

-- Create index on cafe_id for better query performance
CREATE INDEX idx_profiles_cafe_id ON public.profiles(cafe_id);

-- Update existing profiles to have user_type = 'student'
UPDATE public.profiles SET user_type = 'student' WHERE user_type IS NULL;

-- Add comment to explain the new fields
COMMENT ON COLUMN public.profiles.user_type IS 'Type of user: student, cafe_owner, or cafe_staff';
COMMENT ON COLUMN public.profiles.cafe_id IS 'Associated cafe ID for cafe owners and staff';
