-- Fix QR Code Update (Proper Migration)
-- This fixes the window function issue in UPDATE statements

-- 1. Create a sequence for generating unique 6-digit codes
CREATE SEQUENCE IF NOT EXISTS public.qr_code_sequence
    START WITH 100000
    INCREMENT BY 1
    MINVALUE 100000
    MAXVALUE 999999
    CYCLE;

-- 2. Create a function to generate unique 6-digit QR codes
CREATE OR REPLACE FUNCTION public.generate_short_qr_code()
RETURNS TEXT AS $$
DECLARE
    qr_code TEXT;
    counter INTEGER := 0;
    max_attempts INTEGER := 10;
BEGIN
    LOOP
        -- Generate a 6-digit code
        qr_code := 'QR' || nextval('public.qr_code_sequence')::TEXT;
        
        -- Check if this QR code already exists
        IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE qr_code = qr_code) THEN
            RETURN qr_code;
        END IF;
        
        -- Increment counter and try again
        counter := counter + 1;
        IF counter >= max_attempts THEN
            RAISE EXCEPTION 'Failed to generate unique QR code after % attempts', max_attempts;
        END IF;
        
        -- Small delay to ensure different sequence number
        PERFORM pg_sleep(0.001);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. Update existing users with short QR codes (proper method)
DO $$
DECLARE
    user_record RECORD;
    counter INTEGER := 100000;
BEGIN
    -- Loop through all users and update their QR codes
    FOR user_record IN 
        SELECT id, created_at 
        FROM public.profiles 
        WHERE qr_code LIKE 'QR_%' OR qr_code = '' OR qr_code IS NULL
        ORDER BY created_at
    LOOP
        UPDATE public.profiles 
        SET qr_code = 'QR' || counter::TEXT
        WHERE id = user_record.id;
        
        counter := counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Updated % users with short QR codes', counter - 100000;
END $$;

-- 4. Update the user profile trigger to use short QR codes
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
    public.generate_short_qr_code(),
    0,
    'foodie'::loyalty_tier,
    0,
    0.00
  );
  RETURN NEW;
END;
$$;

-- 5. Create a function to get student info by QR code
CREATE OR REPLACE FUNCTION public.get_student_by_qr(qr_code_input TEXT)
RETURNS TABLE(
  id UUID,
  full_name TEXT,
  email TEXT,
  block TEXT,
  phone TEXT,
  loyalty_points INTEGER,
  loyalty_tier TEXT,
  total_orders INTEGER,
  total_spent DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.full_name,
    p.email,
    p.block::TEXT,
    p.phone,
    p.loyalty_points,
    p.loyalty_tier::TEXT,
    p.total_orders,
    p.total_spent
  FROM public.profiles p
  WHERE p.qr_code = qr_code_input;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Add comments for documentation
COMMENT ON FUNCTION public.generate_short_qr_code() IS 'Generates unique 6-digit QR codes in format: QR123456';
COMMENT ON FUNCTION public.get_student_by_qr(TEXT) IS 'Retrieves student information by QR code for cafe staff';
COMMENT ON SEQUENCE public.qr_code_sequence IS 'Sequence for generating unique 6-digit QR codes';

-- 7. Verify the setup
DO $$
DECLARE
    user_count INTEGER;
    qr_count INTEGER;
    short_qr_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM public.profiles;
    SELECT COUNT(DISTINCT qr_code) INTO qr_count FROM public.profiles;
    SELECT COUNT(*) INTO short_qr_count FROM public.profiles WHERE qr_code LIKE 'QR%' AND length(qr_code) = 8;
    
    RAISE NOTICE 'QR code system updated successfully';
    RAISE NOTICE 'Total users: %, Unique QR codes: %, Short QR codes: %', user_count, qr_count, short_qr_count;
    RAISE NOTICE 'All users now have 6-digit QR codes (QR100000 - QR999999)';
END $$;
