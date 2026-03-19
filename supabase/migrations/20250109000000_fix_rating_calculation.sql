-- Fix Rating Calculation System
-- This migration creates proper rating calculation based on individual user ratings
-- Each user can only rate a cafe once, and the average is calculated from all user ratings

-- 1. Create function to calculate and update cafe ratings
CREATE OR REPLACE FUNCTION update_cafe_rating_stats(cafe_id_param UUID)
RETURNS VOID AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    total_count INTEGER;
BEGIN
    -- Calculate average rating and total count from cafe_ratings table
    SELECT 
        COALESCE(AVG(rating), 0),
        COUNT(*)
    INTO avg_rating, total_count
    FROM cafe_ratings 
    WHERE cafe_id = cafe_id_param;
    
    -- Update the cafe's rating statistics
    UPDATE cafes 
    SET 
        average_rating = avg_rating,
        total_ratings = total_count,
        updated_at = NOW()
    WHERE id = cafe_id_param;
    
    RAISE NOTICE 'Updated cafe %: average_rating=%, total_ratings=%', cafe_id_param, avg_rating, total_count;
END;
$$ LANGUAGE plpgsql;

-- 2. Create trigger function to automatically update ratings when cafe_ratings change
CREATE OR REPLACE FUNCTION trigger_update_cafe_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle INSERT
    IF TG_OP = 'INSERT' THEN
        PERFORM update_cafe_rating_stats(NEW.cafe_id);
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE
    IF TG_OP = 'UPDATE' THEN
        -- Update both old and new cafe_id if it changed
        IF OLD.cafe_id != NEW.cafe_id THEN
            PERFORM update_cafe_rating_stats(OLD.cafe_id);
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        ELSE
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        END IF;
        RETURN NEW;
    END IF;
    
    -- Handle DELETE
    IF TG_OP = 'DELETE' THEN
        PERFORM update_cafe_rating_stats(OLD.cafe_id);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Create trigger on cafe_ratings table
DROP TRIGGER IF EXISTS cafe_ratings_update_trigger ON cafe_ratings;
CREATE TRIGGER cafe_ratings_update_trigger
    AFTER INSERT OR UPDATE OR DELETE ON cafe_ratings
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_cafe_rating_stats();

-- 4. Update all existing cafe ratings
DO $$
DECLARE
    cafe_record RECORD;
BEGIN
    -- Loop through all cafes and update their rating statistics
    FOR cafe_record IN 
        SELECT DISTINCT cafe_id FROM cafe_ratings
    LOOP
        PERFORM update_cafe_rating_stats(cafe_record.cafe_id);
    END LOOP;
    
    -- Also update cafes that have no ratings (set to 0)
    UPDATE cafes 
    SET 
        average_rating = 0,
        total_ratings = 0,
        updated_at = NOW()
    WHERE id NOT IN (SELECT DISTINCT cafe_id FROM cafe_ratings);
    
    RAISE NOTICE 'Updated rating statistics for all cafes';
END $$;

-- 5. Create a function to get rating summary for a specific cafe
CREATE OR REPLACE FUNCTION get_cafe_rating_summary(cafe_id_param UUID)
RETURNS TABLE (
    average_rating DECIMAL(3,2),
    total_ratings INTEGER,
    rating_distribution JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(AVG(cr.rating), 0)::DECIMAL(3,2) as average_rating,
        COUNT(*)::INTEGER as total_ratings,
        jsonb_build_object(
            '1_star', COUNT(*) FILTER (WHERE cr.rating = 1),
            '2_star', COUNT(*) FILTER (WHERE cr.rating = 2),
            '3_star', COUNT(*) FILTER (WHERE cr.rating = 3),
            '4_star', COUNT(*) FILTER (WHERE cr.rating = 4),
            '5_star', COUNT(*) FILTER (WHERE cr.rating = 5)
        ) as rating_distribution
    FROM cafe_ratings cr
    WHERE cr.cafe_id = cafe_id_param;
END;
$$ LANGUAGE plpgsql;

-- 6. Grant permissions
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cafe_rating_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cafe_rating_summary(UUID) TO anon;
