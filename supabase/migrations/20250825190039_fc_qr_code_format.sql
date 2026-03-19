-- Update QR code format to FC + 6 digits + 3 random alphabets
-- Drop the old sequence and create new one
DROP SEQUENCE IF EXISTS public.qr_code_sequence;

-- Create new sequence for 6-digit numbers (100000-999999)
CREATE SEQUENCE IF NOT EXISTS public.qr_code_sequence 
    START WITH 100000 
    INCREMENT BY 1 
    MINVALUE 100000 
    MAXVALUE 999999 
    CYCLE;

-- Function to generate random alphabets
CREATE OR REPLACE FUNCTION public.generate_random_alphabets() 
RETURNS TEXT AS $$
DECLARE
    result TEXT := '';
    i INTEGER;
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
BEGIN
    FOR i IN 1..3 LOOP
        result := result || substr(chars, floor(random() * length(chars))::integer + 1, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to generate FC format QR codes
CREATE OR REPLACE FUNCTION public.generate_fc_qr_code() 
RETURNS TEXT AS $$
DECLARE
    qr_code TEXT;
    counter INTEGER := 0;
    max_attempts INTEGER := 10;
    digits TEXT;
    alphabets TEXT;
BEGIN
    LOOP
        -- Generate 6 digits
        digits := nextval('public.qr_code_sequence')::TEXT;
        
        -- Generate 3 random alphabets
        alphabets := public.generate_random_alphabets();
        
        -- Combine: FC + 6 digits + 3 alphabets
        qr_code := 'FC' || digits || alphabets;
        
        -- Check if this QR code is unique
        IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE qr_code = qr_code) THEN
            RETURN qr_code;
        END IF;
        
        counter := counter + 1;
        IF counter >= max_attempts THEN
            RAISE EXCEPTION 'Failed to generate unique QR code after % attempts', max_attempts;
        END IF;
        
        -- Small delay to avoid conflicts
        PERFORM pg_sleep(0.001);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Update existing users to new FC format
DO $$
DECLARE
    user_record RECORD;
    counter INTEGER := 100000;
    alphabets TEXT;
BEGIN
    FOR user_record IN
        SELECT id, created_at
        FROM public.profiles
        WHERE qr_code LIKE 'QR%' OR qr_code = '' OR qr_code IS NULL
        ORDER BY created_at
    LOOP
        -- Generate 3 random alphabets for this user
        alphabets := public.generate_random_alphabets();
        
        -- Update with new FC format
        UPDATE public.profiles
        SET qr_code = 'FC' || counter::TEXT || alphabets
        WHERE id = user_record.id;
        
        counter := counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Updated % users with FC format QR codes', counter - 100000;
END $$;

-- Update the handle_new_user function to use new format
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    -- Insert profile with new FC QR code format
    INSERT INTO public.profiles (
        id, 
        email, 
        full_name, 
        qr_code,
        loyalty_points,
        loyalty_tier,
        total_orders,
        total_spent,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        public.generate_fc_qr_code(),
        0,
        'foodie'::loyalty_tier,
        0,
        0,
        NOW(),
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to get student info by FC QR code
CREATE OR REPLACE FUNCTION public.get_student_by_fc_qr(qr_code_input TEXT)
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    email TEXT,
    block TEXT,
    phone TEXT,
    loyalty_points INTEGER,
    loyalty_tier TEXT,
    total_orders INTEGER,
    total_spent NUMERIC,
    qr_code TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.full_name,
        p.email,
        p.block,
        p.phone,
        p.loyalty_points,
        p.loyalty_tier,
        p.total_orders,
        p.total_spent,
        p.qr_code
    FROM public.profiles p
    WHERE p.qr_code = qr_code_input;
END;
$$ LANGUAGE plpgsql;

-- Test the new format
SELECT 'FC format QR codes updated successfully' as status;
