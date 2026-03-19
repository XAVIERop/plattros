-- =====================================================
-- LOYALTY LOOP: Reelo-style features
-- =====================================================

-- 1. loyalty_campaign_sends - track WhatsApp sends per campaign
CREATE TABLE IF NOT EXISTS public.loyalty_campaign_sends (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    campaign_id UUID NOT NULL REFERENCES public.loyalty_campaigns(id) ON DELETE CASCADE,
    phone TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'failed', 'opened'))
);

CREATE INDEX IF NOT EXISTS idx_loyalty_campaign_sends_campaign ON public.loyalty_campaign_sends(campaign_id);

ALTER TABLE public.loyalty_campaign_sends ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cafe_staff_view_campaign_sends" ON public.loyalty_campaign_sends
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.loyalty_campaigns lc
            JOIN public.cafe_staff cs ON cs.cafe_id = lc.cafe_id AND cs.user_id = auth.uid() AND cs.is_active = true
            WHERE lc.id = loyalty_campaign_sends.campaign_id
        )
        OR EXISTS (
            SELECT 1 FROM public.loyalty_campaigns lc
            JOIN public.profiles p ON p.cafe_id = lc.cafe_id AND p.id = auth.uid()
            WHERE lc.id = loyalty_campaign_sends.campaign_id
        )
    );

-- 2. Add message_body to loyalty_campaigns (for WhatsApp campaign content)
ALTER TABLE public.loyalty_campaigns ADD COLUMN IF NOT EXISTS message_body TEXT;

-- 3. Add birthday to loyalty_customers (for birthday campaigns)
ALTER TABLE public.loyalty_customers ADD COLUMN IF NOT EXISTS birthday DATE;

-- 4. loyalty_referrals - referral program
CREATE TABLE IF NOT EXISTS public.loyalty_referrals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    referrer_phone TEXT NOT NULL,
    referred_phone TEXT NOT NULL,
    referrer_points_awarded INTEGER DEFAULT 0,
    referred_points_awarded INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(cafe_id, referrer_phone, referred_phone)
);

CREATE INDEX IF NOT EXISTS idx_loyalty_referrals_cafe ON public.loyalty_referrals(cafe_id);

ALTER TABLE public.loyalty_referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cafe_staff_manage_referrals" ON public.loyalty_referrals
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.cafe_staff cs WHERE cs.cafe_id = loyalty_referrals.cafe_id AND cs.user_id = auth.uid() AND cs.is_active = true)
        OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.cafe_id = loyalty_referrals.cafe_id)
    );

-- 5. loyalty_settings: add referral points, review link
ALTER TABLE public.loyalty_settings ADD COLUMN IF NOT EXISTS referral_points INTEGER DEFAULT 50;
ALTER TABLE public.loyalty_settings ADD COLUMN IF NOT EXISTS google_review_url TEXT;
ALTER TABLE public.loyalty_settings ADD COLUMN IF NOT EXISTS zomato_review_url TEXT;

-- 5b. Add review URLs to cafes for public check-in flow
ALTER TABLE public.cafes ADD COLUMN IF NOT EXISTS google_review_url TEXT;
ALTER TABLE public.cafes ADD COLUMN IF NOT EXISTS zomato_review_url TEXT;

-- 6. Update loyalty_check_in to use welcome_points from loyalty_settings
CREATE OR REPLACE FUNCTION public.loyalty_check_in(
    p_cafe_id UUID,
    p_phone TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_points INTEGER;
BEGIN
    SELECT COALESCE((SELECT welcome_points FROM public.loyalty_settings WHERE cafe_id = p_cafe_id), 50)
    INTO v_points;

    p_phone := regexp_replace(trim(p_phone), '\s', '', 'g');
    IF length(p_phone) < 10 THEN
        RAISE EXCEPTION 'Invalid phone number';
    END IF;

    INSERT INTO public.loyalty_customers (cafe_id, phone, points, total_check_ins, last_check_in_at, updated_at)
    VALUES (p_cafe_id, p_phone, v_points, 1, NOW(), NOW())
    ON CONFLICT (cafe_id, phone) DO UPDATE SET
        points = loyalty_customers.points + v_points,
        total_check_ins = loyalty_customers.total_check_ins + 1,
        last_check_in_at = NOW(),
        updated_at = NOW();

    INSERT INTO public.loyalty_check_ins (cafe_id, phone, points_awarded)
    VALUES (p_cafe_id, p_phone, v_points);

    RETURN jsonb_build_object(
        'success', true,
        'points_awarded', v_points,
        'phone', p_phone
    );
END;
$$;

-- 7. loyalty_check_in with referral support (overload)
CREATE OR REPLACE FUNCTION public.loyalty_check_in(
    p_cafe_id UUID,
    p_phone TEXT,
    p_referrer_phone TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_points INTEGER;
    v_referral_points INTEGER;
    v_is_new BOOLEAN;
BEGIN
    SELECT COALESCE((SELECT welcome_points FROM public.loyalty_settings WHERE cafe_id = p_cafe_id), 50)
    INTO v_points;
    SELECT COALESCE((SELECT referral_points FROM public.loyalty_settings WHERE cafe_id = p_cafe_id), 50)
    INTO v_referral_points;

    p_phone := regexp_replace(trim(p_phone), '\s', '', 'g');
    IF length(p_phone) < 10 THEN
        RAISE EXCEPTION 'Invalid phone number';
    END IF;

    SELECT NOT EXISTS (SELECT 1 FROM public.loyalty_customers WHERE cafe_id = p_cafe_id AND phone = p_phone)
    INTO v_is_new;

    INSERT INTO public.loyalty_customers (cafe_id, phone, points, total_check_ins, last_check_in_at, updated_at)
    VALUES (p_cafe_id, p_phone, v_points, 1, NOW(), NOW())
    ON CONFLICT (cafe_id, phone) DO UPDATE SET
        points = loyalty_customers.points + v_points,
        total_check_ins = loyalty_customers.total_check_ins + 1,
        last_check_in_at = NOW(),
        updated_at = NOW();

    INSERT INTO public.loyalty_check_ins (cafe_id, phone, points_awarded)
    VALUES (p_cafe_id, p_phone, v_points);

    IF p_referrer_phone IS NOT NULL AND length(regexp_replace(trim(p_referrer_phone), '\s', '', 'g')) >= 10 AND v_is_new THEN
        p_referrer_phone := regexp_replace(trim(p_referrer_phone), '\s', '', 'g');
        IF p_referrer_phone <> p_phone THEN
            INSERT INTO public.loyalty_referrals (cafe_id, referrer_phone, referred_phone, referrer_points_awarded, referred_points_awarded)
            VALUES (p_cafe_id, p_referrer_phone, p_phone, v_referral_points, v_referral_points)
            ON CONFLICT (cafe_id, referrer_phone, referred_phone) DO NOTHING;
            UPDATE public.loyalty_customers SET points = points + v_referral_points, updated_at = NOW()
            WHERE cafe_id = p_cafe_id AND phone = p_referrer_phone;
            UPDATE public.loyalty_customers SET points = points + v_referral_points, updated_at = NOW()
            WHERE cafe_id = p_cafe_id AND phone = p_phone;
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'points_awarded', v_points,
        'phone', p_phone
    );
END;
$$;

-- Drop old 2-arg version to avoid ambiguity; the 3-arg version has default for 3rd param
DROP FUNCTION IF EXISTS public.loyalty_check_in(UUID, TEXT);

GRANT EXECUTE ON FUNCTION public.loyalty_check_in(UUID, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.loyalty_check_in(UUID, TEXT, TEXT) TO authenticated;
