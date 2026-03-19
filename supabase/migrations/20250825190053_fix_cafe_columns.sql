-- Fix cafe columns for existing cafes
-- This migration ensures all existing cafes have the required columns

-- Add missing columns if they don't exist
DO $$
BEGIN
    -- Add accepting_orders column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cafes' AND column_name = 'accepting_orders'
    ) THEN
        ALTER TABLE public.cafes ADD COLUMN accepting_orders BOOLEAN DEFAULT true;
    END IF;

    -- Add average_rating column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cafes' AND column_name = 'average_rating'
    ) THEN
        ALTER TABLE public.cafes ADD COLUMN average_rating DECIMAL(3,2) DEFAULT 0.00;
    END IF;

    -- Add total_ratings column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cafes' AND column_name = 'total_ratings'
    ) THEN
        ALTER TABLE public.cafes ADD COLUMN total_ratings INTEGER DEFAULT 0;
    END IF;

    -- Add cuisine_categories column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cafes' AND column_name = 'cuisine_categories'
    ) THEN
        ALTER TABLE public.cafes ADD COLUMN cuisine_categories TEXT[] DEFAULT ARRAY['Multi-Cuisine'];
    END IF;

    RAISE NOTICE 'Cafe columns checked and added if needed.';
END $$;

-- Update existing cafes to have default values
UPDATE public.cafes 
SET 
    accepting_orders = COALESCE(accepting_orders, true),
    average_rating = COALESCE(average_rating, 0.00),
    total_ratings = COALESCE(total_ratings, 0),
    cuisine_categories = COALESCE(cuisine_categories, ARRAY['Multi-Cuisine'])
WHERE 
    accepting_orders IS NULL 
    OR average_rating IS NULL 
    OR total_ratings IS NULL 
    OR cuisine_categories IS NULL;

-- Set default cuisine categories for existing cafes if not set
UPDATE public.cafes 
SET cuisine_categories = ARRAY['Multi-Cuisine']
WHERE cuisine_categories IS NULL OR array_length(cuisine_categories, 1) = 0;

-- Ensure all cafes are accepting orders by default
UPDATE public.cafes 
SET accepting_orders = true 
WHERE accepting_orders IS NULL;

-- Final confirmation
SELECT 'Cafe columns fixed successfully. All existing cafes now have required columns.' as status;
