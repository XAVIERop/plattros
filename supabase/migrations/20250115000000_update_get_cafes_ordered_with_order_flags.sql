-- Update get_cafes_ordered function to include accept_delivery_orders and accept_table_orders
-- This allows the homepage to show "closed" effect when both delivery and table orders are disabled

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
    location_scope cafe_scope
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
        c.location_scope
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

