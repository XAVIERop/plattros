-- Fix QR codes for existing users and improve points system

-- Update existing users who don't have QR codes
UPDATE public.profiles 
SET qr_code = 'QR_' || id::text 
WHERE qr_code IS NULL OR qr_code = '';

-- Ensure all users have proper QR codes
UPDATE public.profiles 
SET qr_code = 'QR_' || id::text 
WHERE qr_code NOT LIKE 'QR_%';

-- Update the user profile trigger to generate better QR codes
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id, 
    email, 
    full_name,
    block,
    qr_code,
    loyalty_points,
    loyalty_tier,
    total_orders,
    total_spent
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'block')::block_type, 'B1'),
    'QR_' || substr(md5(random()::text), 1, 8) || '_' || NEW.id::text,
    0,
    'foodie'::loyalty_tier,
    0,
    0.00
  );
  RETURN NEW;
END;
$$;

-- Create a function to update loyalty tier based on points
CREATE OR REPLACE FUNCTION public.update_loyalty_tier()
RETURNS TRIGGER AS $$
BEGIN
  -- Update loyalty tier based on points
  IF NEW.loyalty_points >= 300 THEN
    NEW.loyalty_tier = 'connoisseur'::loyalty_tier;
  ELSIF NEW.loyalty_points >= 100 THEN
    NEW.loyalty_tier = 'gourmet'::loyalty_tier;
  ELSE
    NEW.loyalty_tier = 'foodie'::loyalty_tier;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update loyalty tier
DROP TRIGGER IF EXISTS update_loyalty_tier_trigger ON public.profiles;
CREATE TRIGGER update_loyalty_tier_trigger
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_loyalty_tier();

-- Ensure your specific user has proper data
UPDATE public.profiles 
SET 
  loyalty_points = COALESCE(loyalty_points, 0),
  loyalty_tier = CASE 
    WHEN COALESCE(loyalty_points, 0) >= 300 THEN 'connoisseur'::loyalty_tier
    WHEN COALESCE(loyalty_points, 0) >= 100 THEN 'gourmet'::loyalty_tier
    ELSE 'foodie'::loyalty_tier
  END,
  total_orders = COALESCE(total_orders, 0),
  total_spent = COALESCE(total_spent, 0.00)
WHERE email = 'pulkit.229302047@muj.manipal.edu';
