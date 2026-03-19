-- Add Cafe Priority System for Featured Ordering
-- This migration adds a priority column to control cafe ordering on homepage and all cafes page

-- Add priority column to cafes table
ALTER TABLE public.cafes 
ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 999;

-- Create index for priority-based ordering
CREATE INDEX IF NOT EXISTS idx_cafes_priority ON public.cafes(priority ASC);

-- Set priority for featured cafes (lower number = higher priority)
-- Chatkara gets highest priority (1)
UPDATE public.cafes 
SET priority = 1 
WHERE name ILIKE '%chatkara%';

-- Food Court gets second priority (2)
UPDATE public.cafes 
SET priority = 2 
WHERE name ILIKE '%food court%';

-- Set default priority for all other cafes (999 = lowest priority)
UPDATE public.cafes 
SET priority = 999 
WHERE priority IS NULL OR priority > 10;

-- Create a function to get cafes in priority order
CREATE OR REPLACE FUNCTION get_cafes_ordered()
RETURNS TABLE (
    id UUID,
    name TEXT,
    type TEXT,
    description TEXT,
    location TEXT,
    phone TEXT,
    hours TEXT,
    image_url TEXT,
    rating DECIMAL(2,1),
    total_reviews INTEGER,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    average_rating DECIMAL(3,2),
    total_ratings INTEGER,
    cuisine_categories TEXT[],
    accepting_orders BOOLEAN,
    priority INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.type,
        c.description,
        c.location,
        c.phone,
        c.hours,
        c.image_url,
        c.rating,
        c.total_reviews,
        c.is_active,
        c.created_at,
        c.updated_at,
        c.average_rating,
        c.total_ratings,
        c.cuisine_categories,
        c.accepting_orders,
        c.priority
    FROM public.cafes c
    WHERE c.is_active = true
    ORDER BY 
        c.priority ASC,  -- Featured cafes first (priority 1, 2, 3...)
        c.average_rating DESC NULLS LAST,  -- Then by rating
        c.total_ratings DESC NULLS LAST,   -- Then by number of ratings
        c.name ASC;                        -- Finally alphabetically
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_cafes_ordered() TO authenticated;
GRANT EXECUTE ON FUNCTION get_cafes_ordered() TO anon;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Cafe priority system successfully implemented!';
    RAISE NOTICE 'Chatkara set to priority 1 (highest)';
    RAISE NOTICE 'Food Court set to priority 2 (second)';
    RAISE NOTICE 'All other cafes set to priority 999 (lowest)';
    RAISE NOTICE 'Use get_cafes_ordered() function for proper ordering';
END $$;
