-- =====================================================
-- CAFE-SPECIFIC LOYALTY SYSTEM MIGRATION
-- =====================================================
-- This migration implements a new cafe-specific loyalty system
-- where each cafe has its own points and loyalty tiers

-- 1. Create cafe-specific loyalty points table
CREATE TABLE IF NOT EXISTS public.cafe_loyalty_points (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    points INTEGER NOT NULL DEFAULT 0,
    total_spent DECIMAL(10,2) NOT NULL DEFAULT 0,
    loyalty_level INTEGER NOT NULL DEFAULT 1, -- 1, 2, or 3
    first_order_bonus_awarded BOOLEAN DEFAULT FALSE,
    monthly_maintenance_spent DECIMAL(10,2) DEFAULT 0,
    monthly_maintenance_start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure one record per user per cafe
    UNIQUE(user_id, cafe_id)
);

-- 2. Create cafe-specific loyalty transactions table
CREATE TABLE IF NOT EXISTS public.cafe_loyalty_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    points_change INTEGER NOT NULL,
    transaction_type TEXT NOT NULL, -- 'earned', 'redeemed', 'first_order_bonus', 'level_up_bonus'
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create monthly maintenance tracking table
CREATE TABLE IF NOT EXISTS public.cafe_monthly_maintenance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    month_year TEXT NOT NULL, -- Format: '2024-01'
    required_spending DECIMAL(10,2) NOT NULL DEFAULT 10000, -- Level 3 maintenance
    actual_spending DECIMAL(10,2) DEFAULT 0,
    maintenance_met BOOLEAN DEFAULT FALSE,
    downgrade_warning_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure one record per user per cafe per month
    UNIQUE(user_id, cafe_id, month_year)
);

-- 4. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_cafe_loyalty_points_user_cafe ON public.cafe_loyalty_points(user_id, cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_loyalty_points_cafe ON public.cafe_loyalty_points(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_loyalty_transactions_user_cafe ON public.cafe_loyalty_transactions(user_id, cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_monthly_maintenance_user_cafe ON public.cafe_monthly_maintenance(user_id, cafe_id);

-- 5. Create function to calculate cafe-specific loyalty level
CREATE OR REPLACE FUNCTION calculate_cafe_loyalty_level(total_spent DECIMAL(10,2))
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    -- Level 1: 0-2,500 points (5% discount)
    -- Level 2: 2,501-6,000 points (7.5% discount)
    -- Level 3: 6,001+ points (10% discount)
    
    IF total_spent >= 6001 THEN
        RETURN 3;
    ELSIF total_spent >= 2501 THEN
        RETURN 2;
    ELSE
        RETURN 1;
    END IF;
END;
$$;

-- 6. Create function to get loyalty discount percentage
CREATE OR REPLACE FUNCTION get_cafe_loyalty_discount(loyalty_level INTEGER)
RETURNS DECIMAL(3,1)
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    CASE loyalty_level
        WHEN 3 THEN RETURN 10.0; -- 10% discount
        WHEN 2 THEN RETURN 7.5;  -- 7.5% discount
        WHEN 1 THEN RETURN 5.0;  -- 5% discount
        ELSE RETURN 0.0;
    END CASE;
END;
$$;

-- 7. Create function to award first order bonus
CREATE OR REPLACE FUNCTION award_first_order_bonus(
    p_user_id UUID,
    p_cafe_id UUID,
    p_order_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    existing_record RECORD;
BEGIN
    -- Check if user already has points for this cafe
    SELECT * INTO existing_record
    FROM public.cafe_loyalty_points
    WHERE user_id = p_user_id AND cafe_id = p_cafe_id;
    
    -- If no existing record, create one and award first order bonus
    IF NOT FOUND THEN
        INSERT INTO public.cafe_loyalty_points (
            user_id, cafe_id, points, total_spent, loyalty_level, first_order_bonus_awarded
        ) VALUES (
            p_user_id, p_cafe_id, 50, 0, 1, TRUE
        );
        
        -- Record the transaction
        INSERT INTO public.cafe_loyalty_transactions (
            user_id, cafe_id, order_id, points_change, transaction_type, description
        ) VALUES (
            p_user_id, p_cafe_id, p_order_id, 50, 'first_order_bonus', 'First order bonus - 50 points'
        );
    END IF;
END;
$$;

-- 8. Create function to update cafe loyalty points after order
CREATE OR REPLACE FUNCTION update_cafe_loyalty_points(
    p_user_id UUID,
    p_cafe_id UUID,
    p_order_id UUID,
    p_order_amount DECIMAL(10,2)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_points INTEGER;
    current_spent DECIMAL(10,2);
    current_level INTEGER;
    new_level INTEGER;
    points_earned INTEGER;
    level_up_bonus INTEGER := 0;
BEGIN
    -- Award first order bonus if applicable
    PERFORM award_first_order_bonus(p_user_id, p_cafe_id, p_order_id);
    
    -- Get current loyalty data
    SELECT points, total_spent, loyalty_level
    INTO current_points, current_spent, current_level
    FROM public.cafe_loyalty_points
    WHERE user_id = p_user_id AND cafe_id = p_cafe_id;
    
    -- Calculate points earned (1 point per ₹1 spent)
    points_earned := FLOOR(p_order_amount);
    
    -- Update total spent and calculate new level
    current_spent := current_spent + p_order_amount;
    new_level := calculate_cafe_loyalty_level(current_spent);
    
    -- Check for level up bonus
    IF new_level > current_level THEN
        level_up_bonus := (new_level - current_level) * 100; -- 100 points per level up
    END IF;
    
    -- Update loyalty points
    UPDATE public.cafe_loyalty_points
    SET 
        points = points + points_earned + level_up_bonus,
        total_spent = current_spent,
        loyalty_level = new_level,
        updated_at = NOW()
    WHERE user_id = p_user_id AND cafe_id = p_cafe_id;
    
    -- Record points earned transaction
    INSERT INTO public.cafe_loyalty_transactions (
        user_id, cafe_id, order_id, points_change, transaction_type, description
    ) VALUES (
        p_user_id, p_cafe_id, p_order_id, points_earned, 'earned', 
        'Points earned from order: ₹' || p_order_amount
    );
    
    -- Record level up bonus if applicable
    IF level_up_bonus > 0 THEN
        INSERT INTO public.cafe_loyalty_transactions (
            user_id, cafe_id, order_id, points_change, transaction_type, description
        ) VALUES (
            p_user_id, p_cafe_id, p_order_id, level_up_bonus, 'level_up_bonus', 
            'Level up bonus: Level ' || current_level || ' → ' || new_level
        );
    END IF;
    
    -- Update monthly maintenance spending
    PERFORM update_monthly_maintenance_spending(p_user_id, p_cafe_id, p_order_amount);
END;
$$;

-- 9. Create function to update monthly maintenance spending
CREATE OR REPLACE FUNCTION update_monthly_maintenance_spending(
    p_user_id UUID,
    p_cafe_id UUID,
    p_order_amount DECIMAL(10,2)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_month TEXT;
    maintenance_record RECORD;
BEGIN
    -- Get current month in YYYY-MM format
    current_month := TO_CHAR(NOW(), 'YYYY-MM');
    
    -- Check if maintenance record exists for this month
    SELECT * INTO maintenance_record
    FROM public.cafe_monthly_maintenance
    WHERE user_id = p_user_id AND cafe_id = p_cafe_id AND month_year = current_month;
    
    -- If no record exists, create one
    IF NOT FOUND THEN
        INSERT INTO public.cafe_monthly_maintenance (
            user_id, cafe_id, month_year, actual_spending
        ) VALUES (
            p_user_id, p_cafe_id, current_month, p_order_amount
        );
    ELSE
        -- Update existing record
        UPDATE public.cafe_monthly_maintenance
        SET 
            actual_spending = actual_spending + p_order_amount,
            maintenance_met = (actual_spending + p_order_amount) >= required_spending,
            updated_at = NOW()
        WHERE user_id = p_user_id AND cafe_id = p_cafe_id AND month_year = current_month;
    END IF;
END;
$$;

-- 10. Create function to check and handle monthly maintenance
CREATE OR REPLACE FUNCTION check_monthly_maintenance()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    maintenance_record RECORD;
    current_month TEXT;
BEGIN
    current_month := TO_CHAR(NOW(), 'YYYY-MM');
    
    -- Find users who didn't meet maintenance requirements
    FOR maintenance_record IN
        SELECT user_id, cafe_id, actual_spending, required_spending
        FROM public.cafe_monthly_maintenance
        WHERE month_year = current_month 
        AND maintenance_met = FALSE
        AND downgrade_warning_sent = FALSE
    LOOP
        -- Send warning (in real implementation, this would trigger email/notification)
        UPDATE public.cafe_monthly_maintenance
        SET downgrade_warning_sent = TRUE
        WHERE user_id = maintenance_record.user_id 
        AND cafe_id = maintenance_record.cafe_id 
        AND month_year = current_month;
        
        -- Log the warning
        RAISE NOTICE 'Maintenance warning sent for user % at cafe %', 
            maintenance_record.user_id, maintenance_record.cafe_id;
    END LOOP;
END;
$$;

-- 11. Create function to get user's cafe loyalty summary
CREATE OR REPLACE FUNCTION get_user_cafe_loyalty_summary(p_user_id UUID)
RETURNS TABLE (
    cafe_id UUID,
    cafe_name TEXT,
    points INTEGER,
    total_spent DECIMAL(10,2),
    loyalty_level INTEGER,
    discount_percentage DECIMAL(3,1),
    monthly_maintenance_spent DECIMAL(10,2),
    monthly_maintenance_required DECIMAL(10,2),
    maintenance_met BOOLEAN,
    days_until_month_end INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        clp.cafe_id,
        c.name as cafe_name,
        clp.points,
        clp.total_spent,
        clp.loyalty_level,
        get_cafe_loyalty_discount(clp.loyalty_level) as discount_percentage,
        COALESCE(m.actual_spending, 0) as monthly_maintenance_spent,
        CASE 
            WHEN clp.loyalty_level = 3 THEN 10000.0
            ELSE 0.0
        END as monthly_maintenance_required,
        COALESCE(m.maintenance_met, TRUE) as maintenance_met,
        EXTRACT(DAY FROM (DATE_TRUNC('month', NOW()) + INTERVAL '1 month' - INTERVAL '1 day' - NOW()))::INTEGER as days_until_month_end
    FROM public.cafe_loyalty_points clp
    JOIN public.cafes c ON clp.cafe_id = c.id
    LEFT JOIN public.cafe_monthly_maintenance m ON clp.user_id = m.user_id 
        AND clp.cafe_id = m.cafe_id 
        AND m.month_year = TO_CHAR(NOW(), 'YYYY-MM')
    WHERE clp.user_id = p_user_id
    ORDER BY clp.total_spent DESC;
END;
$$;

-- 12. Enable Row Level Security
ALTER TABLE public.cafe_loyalty_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_monthly_maintenance ENABLE ROW LEVEL SECURITY;

-- 13. Create RLS policies
CREATE POLICY "Users can view their own cafe loyalty points" ON public.cafe_loyalty_points
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own cafe loyalty transactions" ON public.cafe_loyalty_transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own monthly maintenance" ON public.cafe_monthly_maintenance
    FOR SELECT USING (auth.uid() = user_id);

-- 14. Grant permissions
GRANT SELECT ON public.cafe_loyalty_points TO authenticated;
GRANT SELECT ON public.cafe_loyalty_transactions TO authenticated;
GRANT SELECT ON public.cafe_monthly_maintenance TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_cafe_loyalty_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cafe_loyalty_discount(INTEGER) TO authenticated;

-- 15. Add comments
COMMENT ON TABLE public.cafe_loyalty_points IS 'Cafe-specific loyalty points for each user';
COMMENT ON TABLE public.cafe_loyalty_transactions IS 'Transaction history for cafe-specific loyalty points';
COMMENT ON TABLE public.cafe_monthly_maintenance IS 'Monthly maintenance tracking for Level 3 loyalty';
COMMENT ON FUNCTION calculate_cafe_loyalty_level IS 'Calculates loyalty level based on total spending';
COMMENT ON FUNCTION get_cafe_loyalty_discount IS 'Returns discount percentage for loyalty level';
COMMENT ON FUNCTION award_first_order_bonus IS 'Awards 50 points for first order at a cafe';
COMMENT ON FUNCTION update_cafe_loyalty_points IS 'Updates loyalty points after order completion';
COMMENT ON FUNCTION get_user_cafe_loyalty_summary IS 'Gets comprehensive loyalty summary for a user across all cafes';
