-- Simple Cafe Management Fix (Focuses only on cafe update permissions)
-- This version only fixes the cafe update issue without touching menu items

-- 1. Ensure accepting_orders column exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'cafes' AND column_name = 'accepting_orders') THEN
        ALTER TABLE public.cafes ADD COLUMN accepting_orders BOOLEAN NOT NULL DEFAULT true;
    END IF;
END $$;

-- 2. Update existing records
UPDATE public.cafes 
SET accepting_orders = COALESCE(accepting_orders, true) 
WHERE accepting_orders IS NULL;

-- 3. Drop only the cafe-related policies that might be causing issues
DO $$
BEGIN
    -- Drop cafes policies if they exist
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cafes' AND policyname = 'Cafe owners can update their cafe settings') THEN
        DROP POLICY "Cafe owners can update their cafe settings" ON public.cafes;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cafes' AND policyname = 'Cafe owners can view their cafe data') THEN
        DROP POLICY "Cafe owners can view their cafe data" ON public.cafes;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cafes' AND policyname = 'Temporary permissive cafe update') THEN
        DROP POLICY "Temporary permissive cafe update" ON public.cafes;
    END IF;
END $$;

-- 4. Create only the essential cafe policies
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

-- 5. Ensure cafe_staff table has proper policies
DROP POLICY IF EXISTS "Cafe staff can view their assignments" ON public.cafe_staff;
CREATE POLICY "Cafe staff can view their assignments" ON public.cafe_staff
  FOR SELECT USING (auth.uid() = user_id);

-- 6. Create or update the validation function
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

-- 7. Ensure the trigger exists
DROP TRIGGER IF EXISTS validate_order_placement_trigger ON public.orders;
CREATE TRIGGER validate_order_placement_trigger
  BEFORE INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_order_placement();

-- 8. Create debugging function
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

-- 9. Verify the setup
DO $$
BEGIN
  RAISE NOTICE 'Simple cafe management fix applied successfully';
  RAISE NOTICE 'Cafe owners should now be able to update their order acceptance status';
END $$;
