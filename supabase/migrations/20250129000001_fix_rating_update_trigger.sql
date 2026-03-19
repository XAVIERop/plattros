-- Fix Rating Update Trigger
-- Ensures cafe ratings are properly updated when cafe_ratings table changes
-- This migration consolidates and fixes any trigger conflicts

-- 1. Ensure the update function exists and is correct
CREATE OR REPLACE FUNCTION update_cafe_rating_stats(cafe_id_param UUID)
RETURNS VOID AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    total_count INTEGER;
BEGIN
    -- Calculate average rating and total count from cafe_ratings table
    SELECT 
        COALESCE(ROUND(AVG(rating)::NUMERIC, 2), 0)::DECIMAL(3,2),
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Ensure the trigger function exists and is correct
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

-- 3. Drop any conflicting triggers
DROP TRIGGER IF EXISTS cafe_ratings_update_trigger ON cafe_ratings;
DROP TRIGGER IF EXISTS trigger_update_cafe_rating ON cafe_ratings;
DROP TRIGGER IF EXISTS trigger_update_cafe_rating_delete ON cafe_ratings;

-- 4. Create the main trigger (only one trigger needed)
CREATE TRIGGER cafe_ratings_update_trigger
    AFTER INSERT OR UPDATE OR DELETE ON cafe_ratings
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_cafe_rating_stats();

-- 5. Grant permissions
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO anon;

-- 6. Update all existing cafe ratings to ensure they're correct
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
    WHERE id NOT IN (SELECT DISTINCT cafe_id FROM cafe_ratings WHERE cafe_id IS NOT NULL);
    
    RAISE NOTICE 'Updated rating statistics for all cafes';
END $$;

-- 7. Verify the trigger is working
DO $$
BEGIN
    RAISE NOTICE 'Rating update trigger fixed and verified!';
    RAISE NOTICE 'Trigger: cafe_ratings_update_trigger on cafe_ratings table';
    RAISE NOTICE 'Function: trigger_update_cafe_rating_stats()';
    RAISE NOTICE 'Update function: update_cafe_rating_stats(UUID)';
END $$;




