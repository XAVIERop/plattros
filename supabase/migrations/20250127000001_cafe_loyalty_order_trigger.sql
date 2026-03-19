-- =====================================================
-- CAFE LOYALTY ORDER COMPLETION TRIGGER
-- =====================================================
-- This trigger automatically updates cafe loyalty points when orders are completed

-- 1. Create function to handle order completion for cafe loyalty
CREATE OR REPLACE FUNCTION handle_cafe_loyalty_order_completion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only process when order status changes to 'completed'
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        -- Update cafe loyalty points
        PERFORM update_cafe_loyalty_points(
            NEW.user_id,
            NEW.cafe_id,
            NEW.id,
            NEW.total_amount
        );
        
        RAISE NOTICE 'Cafe loyalty points updated for order %: user %, cafe %, amount %', 
            NEW.id, NEW.user_id, NEW.cafe_id, NEW.total_amount;
    END IF;
    
    RETURN NEW;
END;
$$;

-- 2. Create trigger on orders table
DROP TRIGGER IF EXISTS cafe_loyalty_order_completion_trigger ON public.orders;
CREATE TRIGGER cafe_loyalty_order_completion_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION handle_cafe_loyalty_order_completion();

-- 3. Create function to initialize cafe loyalty for existing users
CREATE OR REPLACE FUNCTION initialize_cafe_loyalty_for_existing_users()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_record RECORD;
    cafe_record RECORD;
    order_record RECORD;
    total_spent DECIMAL(10,2);
    first_order_date TIMESTAMP WITH TIME ZONE;
BEGIN
    -- For each user
    FOR user_record IN SELECT id FROM auth.users LOOP
        -- For each cafe
        FOR cafe_record IN SELECT id FROM public.cafes WHERE is_active = true LOOP
            -- Check if user has any orders at this cafe
            SELECT 
                COUNT(*) as order_count,
                SUM(total_amount) as total_amount,
                MIN(created_at) as first_order
            INTO order_record
            FROM public.orders
            WHERE user_id = user_record.id 
            AND cafe_id = cafe_record.id 
            AND status = 'completed';
            
            -- If user has orders at this cafe, create loyalty record
            IF order_record.order_count > 0 THEN
                total_spent := COALESCE(order_record.total_amount, 0);
                first_order_date := order_record.first_order;
                
                -- Insert loyalty points record
                INSERT INTO public.cafe_loyalty_points (
                    user_id, 
                    cafe_id, 
                    points, 
                    total_spent, 
                    loyalty_level,
                    first_order_bonus_awarded,
                    created_at
                ) VALUES (
                    user_record.id,
                    cafe_record.id,
                    FLOOR(total_spent) + 50, -- Points from spending + first order bonus
                    total_spent,
                    calculate_cafe_loyalty_level(total_spent),
                    TRUE, -- Assume first order bonus was awarded
                    first_order_date
                ) ON CONFLICT (user_id, cafe_id) DO NOTHING;
                
                -- Record first order bonus transaction
                INSERT INTO public.cafe_loyalty_transactions (
                    user_id, cafe_id, points_change, transaction_type, description, created_at
                ) VALUES (
                    user_record.id, cafe_record.id, 50, 'first_order_bonus', 
                    'First order bonus - 50 points (migrated)', first_order_date
                );
                
                -- Record spending transaction
                INSERT INTO public.cafe_loyalty_transactions (
                    user_id, cafe_id, points_change, transaction_type, description, created_at
                ) VALUES (
                    user_record.id, cafe_record.id, FLOOR(total_spent), 'earned', 
                    'Points from completed orders: ₹' || total_spent, first_order_date
                );
                
                RAISE NOTICE 'Initialized cafe loyalty for user % at cafe %: % points, ₹% spent', 
                    user_record.id, cafe_record.id, FLOOR(total_spent) + 50, total_spent;
            END IF;
        END LOOP;
    END LOOP;
END;
$$;

-- 4. Create function to migrate existing loyalty points to cafe-specific system
CREATE OR REPLACE FUNCTION migrate_existing_loyalty_to_cafe_specific()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    profile_record RECORD;
    cafe_record RECORD;
    total_cafes INTEGER;
    points_per_cafe INTEGER;
BEGIN
    -- Get total number of active cafes
    SELECT COUNT(*) INTO total_cafes FROM public.cafes WHERE is_active = true;
    
    -- For each user with existing loyalty points
    FOR profile_record IN 
        SELECT id, loyalty_points, total_spent 
        FROM public.profiles 
        WHERE loyalty_points > 0 OR total_spent > 0
    LOOP
        -- Distribute points equally among all cafes
        points_per_cafe := FLOOR(profile_record.loyalty_points / total_cafes);
        
        -- For each cafe, create loyalty record
        FOR cafe_record IN SELECT id FROM public.cafes WHERE is_active = true LOOP
            INSERT INTO public.cafe_loyalty_points (
                user_id, 
                cafe_id, 
                points, 
                total_spent, 
                loyalty_level,
                first_order_bonus_awarded
            ) VALUES (
                profile_record.id,
                cafe_record.id,
                points_per_cafe,
                FLOOR(profile_record.total_spent / total_cafes),
                calculate_cafe_loyalty_level(FLOOR(profile_record.total_spent / total_cafes)),
                TRUE -- Assume first order bonus was awarded
            ) ON CONFLICT (user_id, cafe_id) DO NOTHING;
        END LOOP;
        
        RAISE NOTICE 'Migrated loyalty for user %: % total points distributed among % cafes', 
            profile_record.id, profile_record.loyalty_points, total_cafes;
    END LOOP;
END;
$$;

-- 5. Grant execute permissions
GRANT EXECUTE ON FUNCTION handle_cafe_loyalty_order_completion() TO authenticated;
GRANT EXECUTE ON FUNCTION initialize_cafe_loyalty_for_existing_users() TO authenticated;
GRANT EXECUTE ON FUNCTION migrate_existing_loyalty_to_cafe_specific() TO authenticated;

-- 6. Add comments
COMMENT ON FUNCTION handle_cafe_loyalty_order_completion IS 'Trigger function to update cafe loyalty points when orders are completed';
COMMENT ON FUNCTION initialize_cafe_loyalty_for_existing_users IS 'Initializes cafe loyalty records for existing users based on their order history';
COMMENT ON FUNCTION migrate_existing_loyalty_to_cafe_specific IS 'Migrates existing global loyalty points to cafe-specific system';
