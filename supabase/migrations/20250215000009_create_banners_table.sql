-- =====================================================
-- 🎨 CREATE BANNERS TABLE
-- =====================================================
-- This migration creates a banners table for managing
-- hero banners, promotional cards, and mobile banners
-- All banner management can be done via SQL queries
-- =====================================================

-- Create banners table
CREATE TABLE IF NOT EXISTS public.banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Banner Identity
  banner_type TEXT NOT NULL, -- 'hero', 'promotional_card', 'mobile'
  view_type TEXT NOT NULL DEFAULT 'both', -- 'desktop', 'mobile', 'both'
  display_order INTEGER NOT NULL DEFAULT 0, -- Order of display (lower = first)
  
  -- Content
  title TEXT,
  subtitle TEXT,
  description TEXT,
  button_text TEXT DEFAULT 'Order Now',
  button_action TEXT, -- e.g., 'menu_chatkara', 'menu_48cabbce-6b24-4be6-8be6-f2f01f21752b', 'scroll_to_cafes'
  
  -- Visual
  image_url TEXT, -- ImageKit URL or full URL (null = placeholder/gradient)
  background_color TEXT DEFAULT 'bg-gradient-to-r from-blue-600 to-purple-700', -- Tailwind classes
  text_color TEXT DEFAULT 'text-white', -- Tailwind classes
  
  -- Badge (for mobile banners)
  badge_text TEXT,
  badge_icon TEXT, -- Emoji or icon name
  
  -- Cafe Association (optional)
  cafe_id UUID REFERENCES public.cafes(id) ON DELETE SET NULL,
  cafe_slug TEXT, -- Alternative: cafe slug/identifier
  
  -- Targeting
  location_scope TEXT, -- 'ghs', 'off_campus', 'all' (null = all)
  is_active BOOLEAN NOT NULL DEFAULT true,
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Constraints
  CONSTRAINT check_banner_type CHECK (banner_type IN ('hero', 'promotional_card', 'mobile')),
  CONSTRAINT check_view_type CHECK (view_type IN ('desktop', 'mobile', 'both')),
  CONSTRAINT check_location_scope CHECK (location_scope IN ('ghs', 'off_campus', 'all') OR location_scope IS NULL)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_banners_type_active ON public.banners(banner_type, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_banners_display_order ON public.banners(banner_type, display_order, is_active);
CREATE INDEX IF NOT EXISTS idx_banners_view_type ON public.banners(view_type, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_banners_cafe_id ON public.banners(cafe_id) WHERE cafe_id IS NOT NULL;

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_banners_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_banners_updated_at
  BEFORE UPDATE ON public.banners
  FOR EACH ROW
  EXECUTE FUNCTION update_banners_updated_at();

-- Enable Row Level Security
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Allow authenticated users to view active banners
CREATE POLICY "Allow authenticated users to view active banners" ON public.banners
  FOR SELECT TO authenticated
  USING (is_active = true);

-- Allow anonymous users to view active banners (for public homepage)
CREATE POLICY "Allow anonymous users to view active banners" ON public.banners
  FOR SELECT TO anon
  USING (is_active = true);

-- Allow super admins to manage all banners
CREATE POLICY "Super admins can manage all banners" ON public.banners
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND user_type = 'super_admin'
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND user_type = 'super_admin'
    )
  );

-- Helper function to get banners by type and view
CREATE OR REPLACE FUNCTION public.get_banners(
  p_banner_type TEXT DEFAULT NULL,
  p_view_type TEXT DEFAULT NULL,
  p_location_scope TEXT DEFAULT NULL
)
RETURNS SETOF public.banners
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.banners
  WHERE 
    is_active = TRUE
    AND (p_banner_type IS NULL OR banner_type = p_banner_type)
    AND (p_view_type IS NULL OR view_type = p_view_type OR view_type = 'both')
    AND (p_location_scope IS NULL OR location_scope IS NULL OR location_scope = p_location_scope OR location_scope = 'all')
  ORDER BY display_order ASC, created_at ASC;
END;
$$;

COMMENT ON TABLE public.banners IS 'Stores all banner configurations (hero, promotional cards, mobile banners)';
COMMENT ON COLUMN public.banners.banner_type IS 'Type of banner: hero (main large), promotional_card (small desktop), mobile (mobile view)';
COMMENT ON COLUMN public.banners.view_type IS 'Where banner appears: desktop, mobile, or both';
COMMENT ON COLUMN public.banners.display_order IS 'Order of display - lower numbers appear first';
COMMENT ON COLUMN public.banners.image_url IS 'ImageKit URL or full URL. If NULL, shows gradient placeholder';
COMMENT ON COLUMN public.banners.button_action IS 'Action when clicked: menu_<cafeId>, menu_<slug>, scroll_to_cafes, or custom URL';



