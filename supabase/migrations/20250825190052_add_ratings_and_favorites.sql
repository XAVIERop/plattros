-- Add cafe ratings and favorites functionality
-- Create cafe_ratings table
CREATE TABLE IF NOT EXISTS public.cafe_ratings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(cafe_id, user_id)
);

-- Create user_favorites table
CREATE TABLE IF NOT EXISTS public.user_favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, cafe_id)
);

-- Add rating columns to cafes table
ALTER TABLE public.cafes 
ADD COLUMN IF NOT EXISTS average_rating DECIMAL(3,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS total_ratings INTEGER DEFAULT 0;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_cafe_ratings_cafe_id ON public.cafe_ratings(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_ratings_user_id ON public.cafe_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_cafe_id ON public.favorites(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafes_average_rating ON public.cafes(average_rating DESC);

-- Function to update cafe average rating
CREATE OR REPLACE FUNCTION update_cafe_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Update average rating and total ratings count
    UPDATE public.cafes 
    SET 
        average_rating = (
            SELECT COALESCE(AVG(rating), 0.00) 
            FROM public.cafe_ratings 
            WHERE cafe_id = NEW.cafe_id
        ),
        total_ratings = (
            SELECT COUNT(*) 
            FROM public.cafe_ratings 
            WHERE cafe_id = NEW.cafe_id
        )
    WHERE id = NEW.cafe_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update cafe rating when rating is deleted
CREATE OR REPLACE FUNCTION update_cafe_rating_on_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Update average rating and total ratings count
    UPDATE public.cafes 
    SET 
        average_rating = (
            SELECT COALESCE(AVG(rating), 0.00) 
            FROM public.cafe_ratings 
            WHERE cafe_id = OLD.cafe_id
        ),
        total_ratings = (
            SELECT COUNT(*) 
            FROM public.cafe_ratings 
            WHERE cafe_id = OLD.cafe_id
        )
    WHERE id = OLD.cafe_id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic rating updates
DROP TRIGGER IF EXISTS trigger_update_cafe_rating ON public.cafe_ratings;
CREATE TRIGGER trigger_update_cafe_rating
    AFTER INSERT OR UPDATE ON public.cafe_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_cafe_rating();

DROP TRIGGER IF EXISTS trigger_update_cafe_rating_delete ON public.cafe_ratings;
CREATE TRIGGER trigger_update_cafe_rating_delete
    AFTER DELETE ON public.cafe_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_cafe_rating_on_delete();

-- Add cuisine categories to cafes table if not exists
ALTER TABLE public.cafes 
ADD COLUMN IF NOT EXISTS cuisine_categories TEXT[] DEFAULT ARRAY['Multi-Cuisine'];

-- Update existing cafes with cuisine categories
UPDATE public.cafes SET cuisine_categories = ARRAY['North Indian'] WHERE name = 'Punjabi Tadka';
UPDATE public.cafes SET cuisine_categories = ARRAY['Quick Bytes', 'Multi-Cuisine'] WHERE name = 'Mini Meals';
UPDATE public.cafes SET cuisine_categories = ARRAY['Quick Bytes', 'Multi-Cuisine'] WHERE name = 'Munch Box';
UPDATE public.cafes SET cuisine_categories = ARRAY['North Indian', 'Multi-Cuisine'] WHERE name = 'Taste of India';
UPDATE public.cafes SET cuisine_categories = ARRAY['Street Food', 'Multi-Cuisine'] WHERE name = 'CHATKARA';
UPDATE public.cafes SET cuisine_categories = ARRAY['Italian', 'Pizza', 'Pasta'] WHERE name = 'ITALIAN OVEN';
UPDATE public.cafes SET cuisine_categories = ARRAY['Multi-Brand', 'Quick Bytes'] WHERE name = 'FOOD COURT';
UPDATE public.cafes SET cuisine_categories = ARRAY['North Indian', 'Multi-Cuisine'] WHERE name = 'The Kitchen & Curry';
UPDATE public.cafes SET cuisine_categories = ARRAY['Ice Cream', 'Desserts', 'Beverages'] WHERE name = 'Havmor';
UPDATE public.cafes SET cuisine_categories = ARRAY['Multi-Cuisine', 'Chinese', 'Indian'] WHERE name = 'COOK HOUSE';
UPDATE public.cafes SET cuisine_categories = ARRAY['Café', 'Lounge', 'Multi-Cuisine'] WHERE name = 'STARDOM Café & Lounge';
UPDATE public.cafes SET cuisine_categories = ARRAY['Waffles', 'Beverages', 'Fast Food'] WHERE name = 'Waffle Fit N Fresh';
UPDATE public.cafes SET cuisine_categories = ARRAY['Multi-Cuisine', 'Pizza', 'Burgers'] WHERE name = 'The Crazy Chef';
UPDATE public.cafes SET cuisine_categories = ARRAY['Café', 'Multi-Cuisine'] WHERE name = 'ZERO DEGREE CAFE';
UPDATE public.cafes SET cuisine_categories = ARRAY['Multi-Cuisine', 'Chinese', 'Indian'] WHERE name = 'ZAIKA';

-- Enable RLS on new tables
ALTER TABLE public.cafe_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

-- RLS policies for cafe_ratings
CREATE POLICY "Users can view all ratings" ON public.cafe_ratings FOR SELECT USING (true);
CREATE POLICY "Users can insert their own ratings" ON public.cafe_ratings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own ratings" ON public.cafe_ratings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own ratings" ON public.cafe_ratings FOR DELETE USING (auth.uid() = user_id);

-- RLS policies for user_favorites
CREATE POLICY "Users can view their own favorites" ON public.user_favorites FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own favorites" ON public.user_favorites FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own favorites" ON public.user_favorites FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON public.cafe_ratings TO authenticated;
GRANT ALL ON public.user_favorites TO authenticated;
GRANT SELECT ON public.cafe_ratings TO anon;
GRANT SELECT ON public.user_favorites TO anon;
