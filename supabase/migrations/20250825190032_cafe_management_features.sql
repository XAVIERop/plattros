-- Cafe Management Features: Order Acceptance and Out-of-Stock Management

-- Add order acceptance column to cafes table
ALTER TABLE public.cafes 
ADD COLUMN accepting_orders BOOLEAN NOT NULL DEFAULT true;

-- Add out_of_stock column to menu_items table
ALTER TABLE public.menu_items 
ADD COLUMN out_of_stock BOOLEAN NOT NULL DEFAULT false;

-- Update the existing menu items to ensure they have the new column
UPDATE public.menu_items 
SET out_of_stock = false 
WHERE out_of_stock IS NULL;

-- Create a function to check if cafe is accepting orders
CREATE OR REPLACE FUNCTION public.is_cafe_accepting_orders(cafe_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.cafes 
    WHERE id = cafe_uuid 
    AND is_active = true 
    AND accepting_orders = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to check if menu item is available
CREATE OR REPLACE FUNCTION public.is_menu_item_available(item_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.menu_items 
    WHERE id = item_uuid 
    AND is_available = true 
    AND out_of_stock = false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the order creation trigger to check cafe order acceptance
CREATE OR REPLACE FUNCTION public.validate_order_placement()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if cafe is accepting orders
  IF NOT public.is_cafe_accepting_orders(NEW.cafe_id) THEN
    RAISE EXCEPTION 'Cafe is not currently accepting orders';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate order placement
DROP TRIGGER IF EXISTS validate_order_placement_trigger ON public.orders;
CREATE TRIGGER validate_order_placement_trigger
  BEFORE INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_order_placement();

-- Update RLS policies to allow cafe owners to manage their cafe settings
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

-- Update RLS policies to allow cafe owners to manage their menu items
CREATE POLICY "Cafe owners can manage their menu items" ON public.menu_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = menu_items.cafe_id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.role IN ('owner', 'manager')
      AND cafe_staff.is_active = true
    )
  );

-- Update the menu items select policy to show out-of-stock status
DROP POLICY IF EXISTS "Anyone can view available menu items" ON public.menu_items;
CREATE POLICY "Anyone can view menu items with availability status" ON public.menu_items
  FOR SELECT USING (true);

-- Add comments for documentation
COMMENT ON COLUMN public.cafes.accepting_orders IS 'Whether the cafe is currently accepting new orders';
COMMENT ON COLUMN public.menu_items.out_of_stock IS 'Whether the menu item is temporarily out of stock';
COMMENT ON FUNCTION public.is_cafe_accepting_orders(UUID) IS 'Check if a cafe is currently accepting orders';
COMMENT ON FUNCTION public.is_menu_item_available(UUID) IS 'Check if a menu item is available for ordering';
