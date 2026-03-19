-- Ensure existing profiles have residency_scope populated
UPDATE public.profiles
SET residency_scope = 'ghs'
WHERE residency_scope IS NULL;

-- Auto-classify cafe location scope based on stored location (fallback logic)
UPDATE public.cafes
SET location_scope = CASE
  WHEN location ILIKE '%GHS%' THEN 'ghs'
  ELSE 'off_campus'
END
WHERE location_scope IS NULL;

-- Refresh get_cafes_ordered with safer residency fallback
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

-- Update cafe RLS to treat NULL residency as GHS
DROP POLICY IF EXISTS "View cafes by scope" ON public.cafes;

CREATE POLICY "View cafes by scope" ON public.cafes
  FOR SELECT
  USING (
    is_active = true
    AND (
      auth.uid() IS NULL
      OR location_scope = 'off_campus'
      OR EXISTS (
           SELECT 1 FROM public.profiles p
           WHERE p.id = auth.uid()
             AND COALESCE(p.residency_scope, 'ghs') = 'ghs'
         )
    )
  );

-- Update menu items policy accordingly
DROP POLICY IF EXISTS "View menu items by scope" ON public.menu_items;

CREATE POLICY "View menu items by scope" ON public.menu_items
  FOR SELECT
  USING (
    is_available = true
    AND EXISTS (
      SELECT 1
      FROM public.cafes c
      WHERE c.id = menu_items.cafe_id
        AND (
          auth.uid() IS NULL
          OR c.location_scope = 'off_campus'
          OR EXISTS (
            SELECT 1
            FROM public.profiles p
            WHERE p.id = auth.uid()
              AND COALESCE(p.residency_scope, 'ghs') = 'ghs'
          )
        )
    )
  );

-- Update order creation guard with same fallback
DROP POLICY IF EXISTS "Create orders within scope" ON public.orders;

CREATE POLICY "Create orders within scope" ON public.orders
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      JOIN public.cafes c ON c.id = orders.cafe_id
      WHERE p.id = auth.uid()
        AND (
          COALESCE(p.residency_scope, 'ghs') = 'ghs'
          OR c.location_scope = 'off_campus'
        )
    )
  );


