-- Create cuisine_categories table for managing category images from Supabase Storage
CREATE TABLE IF NOT EXISTS public.cuisine_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  image_url TEXT NOT NULL, -- Supabase Storage URL
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0, -- For ordering categories
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_name ON public.cuisine_categories(name);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_active ON public.cuisine_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_display_order ON public.cuisine_categories(display_order);

-- Enable Row Level Security
ALTER TABLE public.cuisine_categories ENABLE ROW LEVEL SECURITY;

-- Create RLS policies - allow public read access
CREATE POLICY "Anyone can view active cuisine categories" ON public.cuisine_categories
  FOR SELECT USING (is_active = true);

-- Allow authenticated users to view all (including inactive for admin)
CREATE POLICY "Authenticated users can view all categories" ON public.cuisine_categories
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cuisine_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_cuisine_categories_updated_at
  BEFORE UPDATE ON public.cuisine_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_cuisine_categories_updated_at();

-- Insert initial categories (you'll need to update image_urls after uploading to Supabase Storage)
INSERT INTO public.cuisine_categories (name, display_name, image_url, display_order) VALUES
  ('Pizza', 'Pizza', '', 1),
  ('North Indian', 'North Indian', '', 2),
  ('Chinese', 'Chinese', '', 3),
  ('Desserts', 'Desserts', '', 4),
  ('Chaap', 'Chaap', '', 5),
  ('Multi-Cuisine', 'Multi-Cuisine', '', 6),
  ('Waffles', 'Waffles', '', 7),
  ('Ice Cream', 'Ice Cream', '', 8),
  ('Beverages', 'Beverages', '', 9),
  ('Fast Food', 'Fast Food', '', 10)
ON CONFLICT (name) DO NOTHING;

-- Add comment
COMMENT ON TABLE public.cuisine_categories IS 'Stores cuisine category information with Supabase Storage image URLs';










CREATE TABLE IF NOT EXISTS public.cuisine_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  image_url TEXT NOT NULL, -- Supabase Storage URL
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0, -- For ordering categories
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_name ON public.cuisine_categories(name);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_active ON public.cuisine_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_display_order ON public.cuisine_categories(display_order);

-- Enable Row Level Security
ALTER TABLE public.cuisine_categories ENABLE ROW LEVEL SECURITY;

-- Create RLS policies - allow public read access
CREATE POLICY "Anyone can view active cuisine categories" ON public.cuisine_categories
  FOR SELECT USING (is_active = true);

-- Allow authenticated users to view all (including inactive for admin)
CREATE POLICY "Authenticated users can view all categories" ON public.cuisine_categories
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cuisine_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_cuisine_categories_updated_at
  BEFORE UPDATE ON public.cuisine_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_cuisine_categories_updated_at();

-- Insert initial categories (you'll need to update image_urls after uploading to Supabase Storage)
INSERT INTO public.cuisine_categories (name, display_name, image_url, display_order) VALUES
  ('Pizza', 'Pizza', '', 1),
  ('North Indian', 'North Indian', '', 2),
  ('Chinese', 'Chinese', '', 3),
  ('Desserts', 'Desserts', '', 4),
  ('Chaap', 'Chaap', '', 5),
  ('Multi-Cuisine', 'Multi-Cuisine', '', 6),
  ('Waffles', 'Waffles', '', 7),
  ('Ice Cream', 'Ice Cream', '', 8),
  ('Beverages', 'Beverages', '', 9),
  ('Fast Food', 'Fast Food', '', 10)
ON CONFLICT (name) DO NOTHING;

-- Add comment
COMMENT ON TABLE public.cuisine_categories IS 'Stores cuisine category information with Supabase Storage image URLs';









CREATE TABLE IF NOT EXISTS public.cuisine_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  image_url TEXT NOT NULL, -- Supabase Storage URL
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0, -- For ordering categories
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_name ON public.cuisine_categories(name);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_active ON public.cuisine_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_display_order ON public.cuisine_categories(display_order);

-- Enable Row Level Security
ALTER TABLE public.cuisine_categories ENABLE ROW LEVEL SECURITY;

-- Create RLS policies - allow public read access
CREATE POLICY "Anyone can view active cuisine categories" ON public.cuisine_categories
  FOR SELECT USING (is_active = true);

-- Allow authenticated users to view all (including inactive for admin)
CREATE POLICY "Authenticated users can view all categories" ON public.cuisine_categories
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cuisine_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_cuisine_categories_updated_at
  BEFORE UPDATE ON public.cuisine_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_cuisine_categories_updated_at();

-- Insert initial categories (you'll need to update image_urls after uploading to Supabase Storage)
INSERT INTO public.cuisine_categories (name, display_name, image_url, display_order) VALUES
  ('Pizza', 'Pizza', '', 1),
  ('North Indian', 'North Indian', '', 2),
  ('Chinese', 'Chinese', '', 3),
  ('Desserts', 'Desserts', '', 4),
  ('Chaap', 'Chaap', '', 5),
  ('Multi-Cuisine', 'Multi-Cuisine', '', 6),
  ('Waffles', 'Waffles', '', 7),
  ('Ice Cream', 'Ice Cream', '', 8),
  ('Beverages', 'Beverages', '', 9),
  ('Fast Food', 'Fast Food', '', 10)
ON CONFLICT (name) DO NOTHING;

-- Add comment
COMMENT ON TABLE public.cuisine_categories IS 'Stores cuisine category information with Supabase Storage image URLs';










CREATE TABLE IF NOT EXISTS public.cuisine_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  image_url TEXT NOT NULL, -- Supabase Storage URL
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0, -- For ordering categories
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_name ON public.cuisine_categories(name);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_active ON public.cuisine_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_display_order ON public.cuisine_categories(display_order);

-- Enable Row Level Security
ALTER TABLE public.cuisine_categories ENABLE ROW LEVEL SECURITY;

-- Create RLS policies - allow public read access
CREATE POLICY "Anyone can view active cuisine categories" ON public.cuisine_categories
  FOR SELECT USING (is_active = true);

-- Allow authenticated users to view all (including inactive for admin)
CREATE POLICY "Authenticated users can view all categories" ON public.cuisine_categories
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cuisine_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_cuisine_categories_updated_at
  BEFORE UPDATE ON public.cuisine_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_cuisine_categories_updated_at();

-- Insert initial categories (you'll need to update image_urls after uploading to Supabase Storage)
INSERT INTO public.cuisine_categories (name, display_name, image_url, display_order) VALUES
  ('Pizza', 'Pizza', '', 1),
  ('North Indian', 'North Indian', '', 2),
  ('Chinese', 'Chinese', '', 3),
  ('Desserts', 'Desserts', '', 4),
  ('Chaap', 'Chaap', '', 5),
  ('Multi-Cuisine', 'Multi-Cuisine', '', 6),
  ('Waffles', 'Waffles', '', 7),
  ('Ice Cream', 'Ice Cream', '', 8),
  ('Beverages', 'Beverages', '', 9),
  ('Fast Food', 'Fast Food', '', 10)
ON CONFLICT (name) DO NOTHING;

-- Add comment
COMMENT ON TABLE public.cuisine_categories IS 'Stores cuisine category information with Supabase Storage image URLs';









CREATE TABLE IF NOT EXISTS public.cuisine_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  image_url TEXT NOT NULL, -- Supabase Storage URL
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0, -- For ordering categories
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_name ON public.cuisine_categories(name);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_active ON public.cuisine_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_display_order ON public.cuisine_categories(display_order);

-- Enable Row Level Security
ALTER TABLE public.cuisine_categories ENABLE ROW LEVEL SECURITY;

-- Create RLS policies - allow public read access
CREATE POLICY "Anyone can view active cuisine categories" ON public.cuisine_categories
  FOR SELECT USING (is_active = true);

-- Allow authenticated users to view all (including inactive for admin)
CREATE POLICY "Authenticated users can view all categories" ON public.cuisine_categories
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cuisine_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_cuisine_categories_updated_at
  BEFORE UPDATE ON public.cuisine_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_cuisine_categories_updated_at();

-- Insert initial categories (you'll need to update image_urls after uploading to Supabase Storage)
INSERT INTO public.cuisine_categories (name, display_name, image_url, display_order) VALUES
  ('Pizza', 'Pizza', '', 1),
  ('North Indian', 'North Indian', '', 2),
  ('Chinese', 'Chinese', '', 3),
  ('Desserts', 'Desserts', '', 4),
  ('Chaap', 'Chaap', '', 5),
  ('Multi-Cuisine', 'Multi-Cuisine', '', 6),
  ('Waffles', 'Waffles', '', 7),
  ('Ice Cream', 'Ice Cream', '', 8),
  ('Beverages', 'Beverages', '', 9),
  ('Fast Food', 'Fast Food', '', 10)
ON CONFLICT (name) DO NOTHING;

-- Add comment
COMMENT ON TABLE public.cuisine_categories IS 'Stores cuisine category information with Supabase Storage image URLs';










CREATE TABLE IF NOT EXISTS public.cuisine_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  image_url TEXT NOT NULL, -- Supabase Storage URL
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0, -- For ordering categories
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_name ON public.cuisine_categories(name);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_active ON public.cuisine_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_cuisine_categories_display_order ON public.cuisine_categories(display_order);

-- Enable Row Level Security
ALTER TABLE public.cuisine_categories ENABLE ROW LEVEL SECURITY;

-- Create RLS policies - allow public read access
CREATE POLICY "Anyone can view active cuisine categories" ON public.cuisine_categories
  FOR SELECT USING (is_active = true);

-- Allow authenticated users to view all (including inactive for admin)
CREATE POLICY "Authenticated users can view all categories" ON public.cuisine_categories
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cuisine_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_cuisine_categories_updated_at
  BEFORE UPDATE ON public.cuisine_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_cuisine_categories_updated_at();

-- Insert initial categories (you'll need to update image_urls after uploading to Supabase Storage)
INSERT INTO public.cuisine_categories (name, display_name, image_url, display_order) VALUES
  ('Pizza', 'Pizza', '', 1),
  ('North Indian', 'North Indian', '', 2),
  ('Chinese', 'Chinese', '', 3),
  ('Desserts', 'Desserts', '', 4),
  ('Chaap', 'Chaap', '', 5),
  ('Multi-Cuisine', 'Multi-Cuisine', '', 6),
  ('Waffles', 'Waffles', '', 7),
  ('Ice Cream', 'Ice Cream', '', 8),
  ('Beverages', 'Beverages', '', 9),
  ('Fast Food', 'Fast Food', '', 10)
ON CONFLICT (name) DO NOTHING;

-- Add comment
COMMENT ON TABLE public.cuisine_categories IS 'Stores cuisine category information with Supabase Storage image URLs';

















