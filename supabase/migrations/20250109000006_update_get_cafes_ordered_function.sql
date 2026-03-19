-- Update get_cafes_ordered function to include menu_pdf_url
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
    priority INTEGER,
    menu_pdf_url TEXT
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
        c.priority,
        c.menu_pdf_url
    FROM public.cafes c
    ORDER BY 
        COALESCE(c.priority, 999) ASC,
        COALESCE(c.average_rating, 0) DESC,
        c.name ASC;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_cafes_ordered() TO authenticated;
GRANT EXECUTE ON FUNCTION get_cafes_ordered() TO anon;
