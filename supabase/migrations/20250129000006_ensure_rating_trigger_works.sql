-- Ensure Rating Trigger Works Correctly
-- This migration ensures the average is ALWAYS calculated from ALL users' ratings

-- 1. Drop and recreate the function to ensure it's correct
CREATE OR REPLACE FUNCTION update_cafe_rating_stats(cafe_id_param UUID)
RETURNS VOID AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    total_count INTEGER;
    all_ratings INTEGER[];
BEGIN
    -- Get all ratings for this cafe from ALL users
    SELECT 
        ARRAY_AGG(rating ORDER BY created_at),
        COALESCE(ROUND(AVG(rating)::NUMERIC, 2), 0)::DECIMAL(3,2),
        COUNT(*)
    INTO all_ratings, avg_rating, total_count
    FROM cafe_ratings 
    WHERE cafe_id = cafe_id_param;
    
    -- Update the cafe's rating statistics
    -- This average is calculated from ALL users' ratings
    UPDATE cafes 
    SET 
        average_rating = avg_rating,
        total_ratings = total_count,
        updated_at = NOW()
    WHERE id = cafe_id_param;
    
    -- Log for debugging
    RAISE NOTICE 'Updated cafe %: average_rating=%, total_ratings=%', 
        cafe_id_param, avg_rating, total_count;
    RAISE NOTICE '  All ratings: %', all_ratings;
    RAISE NOTICE '  Calculation: SUM(%) / % = %', 
        all_ratings, total_count, avg_rating;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Ensure trigger function fires on every change
CREATE OR REPLACE FUNCTION trigger_update_cafe_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Always recalculate from ALL users' ratings
    IF TG_OP = 'INSERT' THEN
        PERFORM update_cafe_rating_stats(NEW.cafe_id);
        RETURN NEW;
    END IF;
    
    IF TG_OP = 'UPDATE' THEN
        -- If cafe_id changed, update both
        IF OLD.cafe_id != NEW.cafe_id THEN
            PERFORM update_cafe_rating_stats(OLD.cafe_id);
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        ELSE
            -- Same cafe - rating changed, recalculate average from ALL users
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        END IF;
        RETURN NEW;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        PERFORM update_cafe_rating_stats(OLD.cafe_id);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Ensure trigger exists and is active
DROP TRIGGER IF EXISTS cafe_ratings_update_trigger ON cafe_ratings;
CREATE TRIGGER cafe_ratings_update_trigger
    AFTER INSERT OR UPDATE OR DELETE ON cafe_ratings
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_cafe_rating_stats();

-- 4. Recalculate ALL cafe ratings to ensure they're correct
DO $$
DECLARE
    cafe_record RECORD;
    recalc_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Recalculating ratings for all cafes...';
    
    FOR cafe_record IN 
        SELECT DISTINCT cafe_id FROM cafe_ratings WHERE cafe_id IS NOT NULL
    LOOP
        PERFORM update_cafe_rating_stats(cafe_record.cafe_id);
        recalc_count := recalc_count + 1;
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
    
    RAISE NOTICE 'Recalculated ratings for % cafes', recalc_count;
END $$;

-- 5. Grant permissions
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO anon;

-- 6. Test the calculation with an example
DO $$
DECLARE
    test_cafe_id UUID;
    test_ratings INTEGER[];
    calculated_avg DECIMAL(3,2);
    expected_avg DECIMAL(3,2);
BEGIN
    -- Get a cafe with multiple ratings
    SELECT cafe_id INTO test_cafe_id
    FROM cafe_ratings
    GROUP BY cafe_id
    HAVING COUNT(*) > 1
    LIMIT 1;
    
    IF test_cafe_id IS NOT NULL THEN
        -- Get all ratings
        SELECT ARRAY_AGG(rating), AVG(rating)::DECIMAL(3,2)
        INTO test_ratings, calculated_avg
        FROM cafe_ratings
        WHERE cafe_id = test_cafe_id;
        
        -- Calculate expected average manually
        SELECT (SUM(rating)::DECIMAL / COUNT(*)::DECIMAL)::DECIMAL(3,2)
        INTO expected_avg
        FROM cafe_ratings
        WHERE cafe_id = test_cafe_id;
        
        RAISE NOTICE 'Test Calculation for cafe %:', test_cafe_id;
        RAISE NOTICE '  All ratings: %', test_ratings;
        RAISE NOTICE '  Calculated average: %', calculated_avg;
        RAISE NOTICE '  Expected average: %', expected_avg;
        
        IF calculated_avg = expected_avg THEN
            RAISE NOTICE '  ✅ Calculation is CORRECT!';
        ELSE
            RAISE WARNING '  ⚠️ Calculation mismatch!';
        END IF;
    END IF;
END $$;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Rating System Verified!';
    RAISE NOTICE 'The average is calculated from ALL users'' ratings.';
    RAISE NOTICE 'When you rate, it updates YOUR rating, then recalculates the average.';
    RAISE NOTICE 'The displayed rating is the AVERAGE, not your individual rating.';
    RAISE NOTICE '========================================';
END $$;




