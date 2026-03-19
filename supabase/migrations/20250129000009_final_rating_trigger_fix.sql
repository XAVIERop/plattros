-- Final Rating Trigger Fix
-- This ensures the trigger ALWAYS fires and updates correctly

-- 1. Drop and recreate with explicit error handling
DROP TRIGGER IF EXISTS cafe_ratings_update_trigger ON cafe_ratings;

-- 2. Recreate the update function with better error handling
CREATE OR REPLACE FUNCTION update_cafe_rating_stats(cafe_id_param UUID)
RETURNS VOID AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    total_count INTEGER;
    sum_ratings INTEGER;
BEGIN
    -- Get all ratings for this cafe
    SELECT 
        COALESCE(SUM(rating), 0),
        COUNT(*)
    INTO sum_ratings, total_count
    FROM cafe_ratings 
    WHERE cafe_id = cafe_id_param;
    
    -- Calculate average: sum / count
    IF total_count > 0 THEN
        avg_rating := ROUND((sum_ratings::DECIMAL / total_count::DECIMAL)::NUMERIC, 2)::DECIMAL(3,2);
    ELSE
        avg_rating := 0;
    END IF;
    
    -- Update the cafe's rating statistics
    -- This is the CRITICAL part - it updates cafes.average_rating with the average of ALL users
    UPDATE cafes 
    SET 
        average_rating = avg_rating,
        total_ratings = total_count,
        updated_at = NOW()
    WHERE id = cafe_id_param;
    
    -- Log for debugging (only in development)
    -- RAISE NOTICE 'Updated cafe %: average=%, total=% (from % ratings)', cafe_id_param, avg_rating, total_count, total_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Recreate trigger function with explicit handling
CREATE OR REPLACE FUNCTION trigger_update_cafe_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- This trigger fires on INSERT, UPDATE, or DELETE
    -- It recalculates the average from ALL users' ratings
    
    IF TG_OP = 'INSERT' THEN
        -- New rating added - recalculate average
        PERFORM update_cafe_rating_stats(NEW.cafe_id);
        RETURN NEW;
    END IF;
    
    IF TG_OP = 'UPDATE' THEN
        -- Rating updated - recalculate average
        -- If cafe_id changed, update both old and new cafe
        IF OLD.cafe_id IS DISTINCT FROM NEW.cafe_id THEN
            PERFORM update_cafe_rating_stats(OLD.cafe_id);
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        ELSE
            -- Same cafe, rating changed - recalculate average from ALL ratings
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        END IF;
        RETURN NEW;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        -- Rating deleted - recalculate average
        PERFORM update_cafe_rating_stats(OLD.cafe_id);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 4. Create the trigger - MUST be AFTER (not BEFORE)
CREATE TRIGGER cafe_ratings_update_trigger
    AFTER INSERT OR UPDATE OR DELETE ON cafe_ratings
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_cafe_rating_stats();

-- 5. Ensure trigger is enabled (should be by default, but just in case)
ALTER TABLE cafe_ratings ENABLE TRIGGER cafe_ratings_update_trigger;

-- 6. Grant permissions
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO anon;
GRANT EXECUTE ON FUNCTION trigger_update_cafe_rating_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION trigger_update_cafe_rating_stats() TO anon;

-- 7. Recalculate ALL existing ratings to ensure they're correct
DO $$
DECLARE
    cafe_record RECORD;
    count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Recalculating all cafe ratings...';
    
    FOR cafe_record IN 
        SELECT DISTINCT cafe_id FROM cafe_ratings WHERE cafe_id IS NOT NULL
    LOOP
        PERFORM update_cafe_rating_stats(cafe_record.cafe_id);
        count := count + 1;
    END LOOP;
    
    -- Set cafes with no ratings to 0
    UPDATE cafes 
    SET 
        average_rating = 0,
        total_ratings = 0,
        updated_at = NOW()
    WHERE id NOT IN (
        SELECT DISTINCT cafe_id 
        FROM cafe_ratings 
        WHERE cafe_id IS NOT NULL
    );
    
    RAISE NOTICE 'Recalculated % cafes', count;
END $$;

-- 8. Verify trigger exists and is enabled
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'cafe_ratings_update_trigger'
        AND tgenabled = 'O'  -- 'O' means enabled for origin
    ) THEN
        RAISE NOTICE '✅ Trigger exists and is ENABLED';
    ELSE
        RAISE WARNING '❌ Trigger does NOT exist or is DISABLED!';
    END IF;
END $$;




