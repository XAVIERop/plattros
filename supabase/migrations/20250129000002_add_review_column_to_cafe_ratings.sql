-- Add review column to cafe_ratings if it doesn't exist
-- This fixes the "Could not find the 'review' column" error

ALTER TABLE public.cafe_ratings 
ADD COLUMN IF NOT EXISTS review TEXT;

-- Verify the column was added
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'cafe_ratings' 
        AND column_name = 'review'
    ) THEN
        RAISE NOTICE 'Review column exists in cafe_ratings table';
    ELSE
        RAISE EXCEPTION 'Review column was not added to cafe_ratings table';
    END IF;
END $$;




