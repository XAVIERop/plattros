-- =====================================================
-- LOYALTY LOOP: Campaigns, Rewards, Settings
-- =====================================================

-- 1. loyalty_campaigns
CREATE TABLE IF NOT EXISTS public.loyalty_campaigns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('promo', 'birthday', 'winback')),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('active', 'draft', 'completed')),
    sent INTEGER NOT NULL DEFAULT 0,
    opened INTEGER NOT NULL DEFAULT 0,
    revenue DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loyalty_campaigns_cafe ON public.loyalty_campaigns(cafe_id);

ALTER TABLE public.loyalty_campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cafe_staff_manage_campaigns" ON public.loyalty_campaigns
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.cafe_staff cs WHERE cs.cafe_id = loyalty_campaigns.cafe_id AND cs.user_id = auth.uid() AND cs.is_active = true)
        OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.cafe_id = loyalty_campaigns.cafe_id)
    );

-- 2. loyalty_rewards
CREATE TABLE IF NOT EXISTS public.loyalty_rewards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    points_cost INTEGER NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('free_item', 'discount', 'voucher')),
    redemptions INTEGER NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loyalty_rewards_cafe ON public.loyalty_rewards(cafe_id);

ALTER TABLE public.loyalty_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cafe_staff_manage_rewards" ON public.loyalty_rewards
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.cafe_staff cs WHERE cs.cafe_id = loyalty_rewards.cafe_id AND cs.user_id = auth.uid() AND cs.is_active = true)
        OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.cafe_id = loyalty_rewards.cafe_id)
    );

-- 3. loyalty_settings (one row per cafe)
-- spend_amount: every ₹X spent; points_awarded: awards Y points
CREATE TABLE IF NOT EXISTS public.loyalty_settings (
    cafe_id UUID PRIMARY KEY REFERENCES public.cafes(id) ON DELETE CASCADE,
    spend_amount INTEGER NOT NULL DEFAULT 100,
    points_awarded INTEGER NOT NULL DEFAULT 10,
    welcome_points INTEGER NOT NULL DEFAULT 50,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.loyalty_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cafe_staff_manage_settings" ON public.loyalty_settings
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.cafe_staff cs WHERE cs.cafe_id = loyalty_settings.cafe_id AND cs.user_id = auth.uid() AND cs.is_active = true)
        OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.cafe_id = loyalty_settings.cafe_id)
    );
