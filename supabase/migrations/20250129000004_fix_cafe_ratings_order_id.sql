-- Fix cafe_ratings table - order_id should not be required
-- cafe_ratings stores one rating per user per cafe (not per order)
-- order_id belongs in order_ratings, not cafe_ratings

-- Check if order_id column exists and make it nullable if it does
DO $$
BEGIN
    -- Check if order_id column exists
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'cafe_ratings' 
        AND column_name = 'order_id'
    ) THEN
        -- Make order_id nullable (it shouldn't be required for cafe_ratings)
        ALTER TABLE public.cafe_ratings 
        ALTER COLUMN order_id DROP NOT NULL;
        
        RAISE NOTICE 'Made order_id column nullable in cafe_ratings table';
    ELSE
        RAISE NOTICE 'order_id column does not exist in cafe_ratings table - no action needed';
    END IF;
END $$;

-- Verify the fix
DO $$
DECLARE
    nullable_status TEXT;
BEGIN
    SELECT information_schema.columns.is_nullable INTO nullable_status
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'cafe_ratings' 
    AND column_name = 'order_id';
    
    IF nullable_status = 'YES' THEN
        RAISE NOTICE 'order_id is now nullable - fix successful!';
    ELSIF nullable_status = 'NO' THEN
        RAISE WARNING 'order_id is still NOT NULL - may need manual intervention';
    ELSE
        RAISE NOTICE 'order_id column does not exist - this is correct for cafe_ratings';
    END IF;
END $$;

