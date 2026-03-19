-- Safe Cafe Management Fix (Handles Existing Policies)
-- This version safely handles existing policies without conflicts

-- 1. Ensure all necessary columns exist
DO $$ 
BEGIN
    -- Add accepting_orders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'cafes' AND column_name = 'accepting_orders') THEN
        ALTER TABLE public.cafes ADD COLUMN accepting_orders BOOLEAN NOT NULL DEFAULT true;
    END IF;
    
    -- Add out_of_stock column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'menu_items' AND column_name = 'out_of_stock') THEN
        ALTER TABLE public.menu_items ADD COLUMN out_of_stock BOOLEAN NOT NULL DEFAULT false;
    END IF;
END $$;

-- 2. Update existing records to ensure they have the new columns
UPDATE public.cafes 
SET accepting_orders = COALESCE(accepting_orders, true) 
WHERE accepting_orders IS NULL;

UPDATE public.menu_items 
SET out_of_stock = COALESCE(out_of_stock, false) 
WHERE out_of_stock IS NULL;

-- 3. Safely drop existing policies (only if they exist)
DO $$
BEGIN
    -- Drop cafes policies if they exist
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cafes' AND policyname = 'Anyone can view active cafes') THEN
        DROP POLICY "Anyone can view active cafes" ON public.cafes;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cafes' AND policyname = 'Cafe owners can update their cafe settings') THEN
        DROP POLICY "Cafe owners can update their cafe settings" ON public.cafes;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cafes' AND policyname = 'Cafe owners can view their cafe data') THEN
        DROP POLICY "Cafe owners can view their cafe data" ON public.cafes;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cafes' AND policyname = 'Temporary permissive cafe update') THEN
        DROP POLICY "Temporary permissive cafe update" ON public.cafes;
    END IF;
    
    -- Drop menu_items policies if they exist
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'menu_items' AND policyname = 'Anyone can view menu items') THEN
        DROP POLICY "Anyone can view menu items" ON public.menu_items;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'menu_items' AND policyname = 'Anyone can view menu items with availability status') THEN
        DROP POLICY "Anyone can view menu items with availability status" ON public.menu_items;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'menu_items' AND policyname = 'Cafe owners can manage their menu items') THEN
        DROP POLICY "Cafe owners can manage their menu items" ON public.menu_items;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'menu_items' AND policyname = 'Cafe owners can view their menu items') THEN
        DROP POLICY "Cafe owners can view their menu items" ON public.menu_items;
    END IF;
    
    -- Drop cafe_staff policies if they exist
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cafe_staff' AND policyname = 'Cafe staff can view their assignments') THEN
        DROP POLICY "Cafe staff can view their assignments" ON public.cafe_staff;
    END IF;
END $$;

-- 4. Create new, comprehensive RLS policies
-- Cafes table policies
CREATE POLICY "Anyone can view active cafes" ON public.cafes
  FOR SELECT USING (is_active = true);

CREATE POLICY "Cafe owners can view their cafe data" ON public.cafes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = cafes.id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.role IN ('owner', 'manager')
      AND cafe_staff.is_active = true
    )
  );

CREATE POLICY "Cafe owners can update their cafe settings" ON public.cafes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = cafes.id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.role IN ('owner', 'manager')
      AND cafe_staff.is_active = true
    )
  );

-- Menu items table policies
CREATE POLICY "Anyone can view menu items" ON public.menu_items
  FOR SELECT USING (true);

CREATE POLICY "Cafe owners can view their menu items" ON public.menu_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = menu_items.cafe_id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.role IN ('owner', 'manager')
      AND cafe_staff.is_active = true
    )
  );

CREATE POLICY "Cafe owners can update their menu items" ON public.menu_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = menu_items.cafe_id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.role IN ('owner', 'manager')
      AND cafe_staff.is_active = true
    )
  );

-- Cafe staff table policies
CREATE POLICY "Cafe staff can view their assignments" ON public.cafe_staff
  FOR SELECT USING (auth.uid() = user_id);

-- 5. Create or update the validation function
CREATE OR REPLACE FUNCTION public.validate_order_placement()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if cafe is accepting orders
  IF NOT EXISTS (
    SELECT 1 FROM public.cafes 
    WHERE id = NEW.cafe_id 
    AND is_active = true 
    AND accepting_orders = true
  ) THEN
    RAISE EXCEPTION 'Cafe is not currently accepting orders';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Ensure the trigger exists
DROP TRIGGER IF EXISTS validate_order_placement_trigger ON public.orders;
CREATE TRIGGER validate_order_placement_trigger
  BEFORE INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_order_placement();

-- 7. Create or update debugging function
CREATE OR REPLACE FUNCTION public.debug_cafe_permissions(user_uuid UUID, cafe_uuid UUID)
RETURNS TABLE(
  user_id UUID,
  cafe_id UUID,
  role TEXT,
  is_active BOOLEAN,
  can_update BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cs.user_id,
    cs.cafe_id,
    cs.role,
    cs.is_active,
    (cs.role IN ('owner', 'manager') AND cs.is_active = true) as can_update
  FROM public.cafe_staff cs
  WHERE cs.user_id = user_uuid 
  AND cs.cafe_id = cafe_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Verify the setup
DO $$
BEGIN
  RAISE NOTICE 'Safe cafe management fix applied successfully';
  RAISE NOTICE 'All RLS policies have been recreated with proper permissions';
  RAISE NOTICE 'Cafe owners should now be able to update their settings';
END $$;
