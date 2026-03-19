-- Add residency scope enum types
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'residency_scope') THEN
    CREATE TYPE residency_scope AS ENUM ('ghs', 'off_campus');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cafe_scope') THEN
    CREATE TYPE cafe_scope AS ENUM ('ghs', 'off_campus');
  END IF;
END$$;

-- Extend existing block enum to support off-campus users
ALTER TYPE block_type ADD VALUE IF NOT EXISTS 'OFF_CAMPUS';
ALTER TYPE block_type ADD VALUE IF NOT EXISTS 'PG';
ALTER TYPE block_type ADD VALUE IF NOT EXISTS 'GHS_GATE';

-- Add location scope to cafes
ALTER TABLE public.cafes
ADD COLUMN IF NOT EXISTS location_scope cafe_scope NOT NULL DEFAULT 'ghs';

-- Add residency scope to profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS residency_scope residency_scope NOT NULL DEFAULT 'ghs';

-- Backfill defaults for existing rows
UPDATE public.cafes
SET location_scope = 'ghs'
WHERE location_scope IS NULL;

UPDATE public.profiles
SET residency_scope = 'ghs'
WHERE residency_scope IS NULL;

-- Update signup trigger function to capture residency scope
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  resolved_block block_type;
  resolved_residency residency_scope;
BEGIN
  resolved_block := COALESCE((NEW.raw_user_meta_data->>'block')::block_type, 'B1');
  resolved_residency := COALESCE((NEW.raw_user_meta_data->>'residency_scope')::residency_scope, 'ghs');

  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    block,
    qr_code,
    residency_scope
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    resolved_block,
    'QR_' || NEW.id::text,
    resolved_residency
  );
  RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Recreate cafe listing function with scope filtering
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
    user_scope residency_scope := 'off_campus';
BEGIN
    IF auth.uid() IS NOT NULL THEN
        SELECT residency_scope
        INTO user_scope
        FROM public.profiles
        WHERE id = auth.uid();

        IF NOT FOUND THEN
            user_scope := 'off_campus';
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

-- Update RLS policy for cafes to respect scope
DROP POLICY IF EXISTS "Anyone can view active cafes" ON public.cafes;

CREATE POLICY "View cafes by scope" ON public.cafes
  FOR SELECT
  USING (
    is_active = true
    AND (
      (auth.uid() IS NULL AND location_scope = 'off_campus')
      OR
      (auth.uid() IS NOT NULL AND (
         location_scope = 'off_campus' OR
         EXISTS (
           SELECT 1 FROM public.profiles p
           WHERE p.id = auth.uid()
             AND p.residency_scope = 'ghs'
         )
      ))
    )
  );

-- Tighten order creation policy to prevent cross-scope orders
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;

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
          p.residency_scope = 'ghs'
          OR c.location_scope = 'off_campus'
        )
    )
  );

-- Restrict menu item visibility by cafe scope
DROP POLICY IF EXISTS "Anyone can view available menu items" ON public.menu_items;

CREATE POLICY "View menu items by scope" ON public.menu_items
  FOR SELECT
  USING (
    is_available = true
    AND EXISTS (
      SELECT 1
      FROM public.cafes c
      WHERE c.id = menu_items.cafe_id
        AND (
          c.location_scope = 'off_campus'
          OR EXISTS (
            SELECT 1
            FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.residency_scope = 'ghs'
          )
        )
    )
  );


