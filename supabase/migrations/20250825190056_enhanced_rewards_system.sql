-- Enhanced Rewards System Migration
-- This migration implements the comprehensive loyalty program with tier-based benefits,
-- maintenance requirements, and new user bonuses

-- 1. Create new tables for enhanced rewards system

-- Table to track tier maintenance requirements
CREATE TABLE IF NOT EXISTS public.tier_maintenance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    tier VARCHAR(20) NOT NULL,
    maintenance_amount DECIMAL(10,2) NOT NULL,
    current_spent DECIMAL(10,2) DEFAULT 0,
    period_start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    period_end_date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
    is_completed BOOLEAN DEFAULT FALSE,
    warning_sent BOOLEAN DEFAULT FALSE,
    grace_period_start TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table to track user bonuses
CREATE TABLE IF NOT EXISTS public.user_bonuses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    bonus_type VARCHAR(50) NOT NULL, -- 'welcome', 'maintenance_completion', 'monthly', 'quarterly'
    points_awarded INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table to track maintenance periods
CREATE TABLE IF NOT EXISTS public.maintenance_periods (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    tier VARCHAR(20) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    period_end_date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
    required_amount DECIMAL(10,2) NOT NULL,
    actual_spent DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'failed', 'grace_period'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Add new columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS tier_expiry_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS maintenance_spent DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS new_user_orders_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_new_user BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS first_order_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS tier_warning_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS last_maintenance_check TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. Create enhanced point calculation function
CREATE OR REPLACE FUNCTION calculate_enhanced_points(
    order_amount DECIMAL(10,2),
    user_id UUID,
    is_new_user BOOLEAN,
    new_user_orders_count INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_tier VARCHAR(20);
    tier_multiplier DECIMAL(3,2);
    new_user_multiplier DECIMAL(3,2);
    base_points INTEGER;
    final_points INTEGER;
BEGIN
    -- Get user's current tier
    SELECT loyalty_tier INTO user_tier
    FROM public.profiles
    WHERE id = user_id;
    
    -- Set tier multiplier
    CASE user_tier
        WHEN 'connoisseur' THEN tier_multiplier := 1.5;
        WHEN 'gourmet' THEN tier_multiplier := 1.2;
        ELSE tier_multiplier := 1.0;
    END CASE;
    
    -- Set new user multiplier
    IF is_new_user AND new_user_orders_count <= 20 THEN
        IF new_user_orders_count = 1 THEN
            new_user_multiplier := 1.5; -- 50% extra for first order
        ELSE
            new_user_multiplier := 1.25; -- 25% extra for orders 2-20
        END IF;
    ELSE
        new_user_multiplier := 1.0;
    END IF;
    
    -- Calculate base points (10 points per ₹100)
    base_points := FLOOR((order_amount / 100) * 10);
    
    -- Calculate final points
    final_points := FLOOR(base_points * tier_multiplier * new_user_multiplier);
    
    RETURN final_points;
END;
$$;

-- 4. Create function to handle new user first order
CREATE OR REPLACE FUNCTION handle_new_user_first_order(user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Award welcome bonus points
    INSERT INTO public.user_bonuses (user_id, bonus_type, points_awarded, description)
    VALUES (user_id, 'welcome', 50, 'Welcome bonus for first order');
    
    -- Update user's points
    UPDATE public.profiles
    SET loyalty_points = loyalty_points + 50,
        new_user_orders_count = 1,
        first_order_date = NOW()
    WHERE id = user_id;
END;
$$;

-- 5. Create function to track maintenance spending
CREATE OR REPLACE FUNCTION track_maintenance_spending(user_id UUID, order_amount DECIMAL(10,2))
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_tier VARCHAR(20);
    maintenance_required BOOLEAN;
    current_period_id UUID;
BEGIN
    -- Get current tier
    SELECT loyalty_tier INTO current_tier
    FROM public.profiles
    WHERE id = user_id;
    
    -- Check if maintenance is required for this tier
    IF current_tier IN ('gourmet', 'connoisseur') THEN
        maintenance_required := TRUE;
    ELSE
        maintenance_required := FALSE;
    END IF;
    
    IF maintenance_required THEN
        -- Get current active maintenance period
        SELECT id INTO current_period_id
        FROM public.maintenance_periods
        WHERE user_id = user_id 
        AND status = 'active'
        AND period_end_date > NOW();
        
        IF current_period_id IS NOT NULL THEN
            -- Update current period spending
            UPDATE public.maintenance_periods
            SET actual_spent = actual_spent + order_amount,
                updated_at = NOW()
            WHERE id = current_period_id;
            
            -- Check if maintenance is completed
            UPDATE public.maintenance_periods
            SET status = 'completed'
            WHERE id = current_period_id 
            AND actual_spent >= required_amount;
            
            -- Award completion bonus if just completed
            IF (SELECT status FROM public.maintenance_periods WHERE id = current_period_id) = 'completed' THEN
                INSERT INTO public.user_bonuses (user_id, bonus_type, points_awarded, description)
                VALUES (user_id, 'maintenance_completion', 200, 'Maintenance requirement completed');
                
                UPDATE public.profiles
                SET loyalty_points = loyalty_points + 200
                WHERE id = user_id;
            END IF;
        END IF;
    END IF;
END;
$$;

-- 6. Create function to update enhanced loyalty tier
CREATE OR REPLACE FUNCTION update_enhanced_loyalty_tier()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_tier VARCHAR(20);
    old_tier VARCHAR(20);
BEGIN
    old_tier := OLD.loyalty_tier;
    
    -- Determine new tier based on points
    IF NEW.loyalty_points >= 501 THEN
        new_tier := 'connoisseur';
    ELSIF NEW.loyalty_points >= 151 THEN
        new_tier := 'gourmet';
    ELSE
        new_tier := 'foodie';
    END IF;
    
    -- Update tier if changed
    IF new_tier != old_tier THEN
        NEW.loyalty_tier := new_tier;
        
        -- Create new maintenance period if required
        IF new_tier IN ('gourmet', 'connoisseur') THEN
            INSERT INTO public.maintenance_periods (user_id, tier, required_amount)
            VALUES (
                NEW.id, 
                new_tier, 
                CASE new_tier 
                    WHEN 'gourmet' THEN 2000 
                    WHEN 'connoisseur' THEN 5000 
                END
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- 7. Create trigger for automatic tier updates
DROP TRIGGER IF EXISTS trigger_update_enhanced_loyalty_tier ON public.profiles;
CREATE TRIGGER trigger_update_enhanced_loyalty_tier
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_enhanced_loyalty_tier();

-- 8. Create function to check and handle maintenance expiry
CREATE OR REPLACE FUNCTION check_maintenance_expiry()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    expired_user RECORD;
BEGIN
    -- Find users whose maintenance period has expired
    FOR expired_user IN
        SELECT mp.user_id, mp.tier, mp.required_amount, mp.actual_spent
        FROM public.maintenance_periods mp
        WHERE mp.status = 'active' 
        AND mp.period_end_date < NOW()
        AND mp.actual_spent < mp.required_amount
    LOOP
        -- Update maintenance period status
        UPDATE public.maintenance_periods
        SET status = 'failed'
        WHERE user_id = expired_user.user_id AND status = 'active';
        
        -- Downgrade user tier
        UPDATE public.profiles
        SET loyalty_tier = CASE expired_user.tier
            WHEN 'connoisseur' THEN 'gourmet'
            WHEN 'gourmet' THEN 'foodie'
            ELSE 'foodie'
        END,
        tier_warning_sent = FALSE
        WHERE id = expired_user.user_id;
    END LOOP;
END;
$$;

-- 9. Create RLS policies for new tables
ALTER TABLE public.tier_maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_periods ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY "Users can view own tier maintenance" ON public.tier_maintenance
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own bonuses" ON public.user_bonuses
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own maintenance periods" ON public.maintenance_periods
    FOR SELECT USING (auth.uid() = user_id);

-- 10. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_tier_maintenance_user_id ON public.tier_maintenance(user_id);
CREATE INDEX IF NOT EXISTS idx_user_bonuses_user_id ON public.user_bonuses(user_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_periods_user_id ON public.maintenance_periods(user_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_periods_status ON public.maintenance_periods(status);
CREATE INDEX IF NOT EXISTS idx_maintenance_periods_end_date ON public.maintenance_periods(period_end_date);

-- 11. Update existing users to have proper tier based on current points
UPDATE public.profiles
SET loyalty_tier = CASE
    WHEN loyalty_points >= 501 THEN 'connoisseur'
    WHEN loyalty_points >= 151 THEN 'gourmet'
    ELSE 'foodie'
END
WHERE loyalty_tier IS NULL OR loyalty_tier NOT IN ('foodie', 'gourmet', 'connoisseur');

-- 12. Create maintenance periods for existing users with required tiers
INSERT INTO public.maintenance_periods (user_id, tier, required_amount, start_date, period_end_date)
SELECT 
    id,
    loyalty_tier,
    CASE loyalty_tier
        WHEN 'gourmet' THEN 2000
        WHEN 'connoisseur' THEN 5000
    END,
    NOW(),
    NOW() + INTERVAL '30 days'
FROM public.profiles
WHERE loyalty_tier IN ('gourmet', 'connoisseur')
AND id NOT IN (SELECT user_id FROM public.maintenance_periods WHERE status = 'active');

-- 13. Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.tier_maintenance TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.user_bonuses TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.maintenance_periods TO authenticated;

-- 14. Create a function to get user's enhanced rewards summary
CREATE OR REPLACE FUNCTION get_user_enhanced_rewards_summary(user_id UUID)
RETURNS TABLE(
    current_tier VARCHAR(20),
    current_points INTEGER,
    tier_discount INTEGER,
    next_tier VARCHAR(20),
    points_to_next_tier INTEGER,
    maintenance_required BOOLEAN,
    maintenance_amount DECIMAL(10,2),
    maintenance_spent DECIMAL(10,2),
    maintenance_progress INTEGER,
    days_until_expiry INTEGER,
    is_new_user BOOLEAN,
    new_user_orders_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.loyalty_tier,
        p.loyalty_points,
        CASE p.loyalty_tier
            WHEN 'connoisseur' THEN 20
            WHEN 'gourmet' THEN 10
            ELSE 5
        END,
        CASE p.loyalty_tier
            WHEN 'foodie' THEN 'gourmet'
            WHEN 'gourmet' THEN 'connoisseur'
            ELSE NULL
        END,
        CASE p.loyalty_tier
            WHEN 'foodie' THEN 151 - p.loyalty_points
            WHEN 'gourmet' THEN 501 - p.loyalty_points
            ELSE 0
        END,
        p.loyalty_tier IN ('gourmet', 'connoisseur'),
        CASE p.loyalty_tier
            WHEN 'gourmet' THEN 2000
            WHEN 'connoisseur' THEN 5000
            ELSE 0
        END,
        COALESCE(mp.actual_spent, 0),
        CASE 
            WHEN mp.required_amount > 0 THEN 
                LEAST(100, (mp.actual_spent / mp.required_amount) * 100)
            ELSE 0
        END,
        CASE 
            WHEN mp.period_end_date IS NOT NULL THEN 
                EXTRACT(DAY FROM (mp.period_end_date - NOW()))
            ELSE 0
        END,
        p.is_new_user,
        p.new_user_orders_count
    FROM public.profiles p
    LEFT JOIN public.maintenance_periods mp ON p.id = mp.user_id AND mp.status = 'active'
    WHERE p.id = user_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_enhanced_rewards_summary(UUID) TO authenticated;

COMMENT ON TABLE public.tier_maintenance IS 'Tracks tier maintenance requirements for users';
COMMENT ON TABLE public.user_bonuses IS 'Tracks bonus points awarded to users';
COMMENT ON TABLE public.maintenance_periods IS 'Tracks maintenance periods and spending requirements';
COMMENT ON FUNCTION calculate_enhanced_points IS 'Calculates points with tier multipliers and new user bonuses';
COMMENT ON FUNCTION handle_new_user_first_order IS 'Handles welcome bonus for new users first order';
COMMENT ON FUNCTION track_maintenance_spending IS 'Tracks spending for maintenance requirements';
COMMENT ON FUNCTION update_enhanced_loyalty_tier IS 'Automatically updates user loyalty tier based on points';
COMMENT ON FUNCTION check_maintenance_expiry IS 'Checks and handles expired maintenance periods';
COMMENT ON FUNCTION get_user_enhanced_rewards_summary IS 'Gets comprehensive rewards summary for a user';
