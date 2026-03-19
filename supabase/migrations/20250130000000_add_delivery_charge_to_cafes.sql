-- Add delivery_charge column to cafes table
-- This allows managing delivery charges per cafe via SQL

-- Add delivery_charge column if it doesn't exist
ALTER TABLE public.cafes
ADD COLUMN IF NOT EXISTS delivery_charge NUMERIC(10,2) DEFAULT NULL;

-- Add comment explaining the column
COMMENT ON COLUMN public.cafes.delivery_charge IS 'Delivery charge in rupees. If NULL, uses default based on location_scope (GHS: ₹10, Off-campus: ₹25)';

-- Update get_cafes_ordered function to include delivery_charge
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
    accept_delivery_orders BOOLEAN,
    accept_table_orders BOOLEAN,
    priority INTEGER,
    slug TEXT,
    location_scope cafe_scope,
    delivery_charge NUMERIC(10,2)
) AS $$
DECLARE
    user_scope residency_scope := 'ghs';
BEGIN
    IF auth.uid() IS NOT NULL THEN
        SELECT CASE 
                 WHEN residency_scope = 'off_campus' THEN 'off_campus'
                 ELSE 'ghs'
               END
        INTO user_scope
        FROM public.profiles
        WHERE id = auth.uid();

        IF NOT FOUND THEN
            user_scope := 'ghs';
        END IF;
    END IF;

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
        c.accept_delivery_orders,
        c.accept_table_orders,
        c.priority,
        c.slug,
        c.location_scope,
        c.delivery_charge
    FROM public.cafes c
    WHERE 
        c.is_active = true
        AND (
            user_scope = 'ghs'
            OR c.location_scope = 'off_campus'
        )
    ORDER BY 
        c.priority ASC,
        c.average_rating DESC NULLS LAST,
        c.total_ratings DESC NULLS LAST,
        c.name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION get_cafes_ordered() SET search_path = public;

GRANT EXECUTE ON FUNCTION get_cafes_ordered() TO authenticated;
GRANT EXECUTE ON FUNCTION get_cafes_ordered() TO anon;

-- Set default delivery charges based on location_scope (only if NULL)
-- GHS cafes: ₹10
UPDATE public.cafes
SET delivery_charge = 10
WHERE (location_scope = 'ghs' OR location_scope IS NULL)
  AND delivery_charge IS NULL
  AND is_active = true;

-- Off-campus cafes: ₹25
UPDATE public.cafes
SET delivery_charge = 25
WHERE location_scope = 'off_campus'
  AND delivery_charge IS NULL
  AND is_active = true;

-- Verify the updates
SELECT 
  name,
  location_scope,
  delivery_charge,
  CASE 
    WHEN delivery_charge IS NULL THEN '⚠️ NULL (will use default)'
    ELSE '✅ Set'
  END as status
FROM public.cafes
WHERE is_active = true
ORDER BY location_scope, name;





