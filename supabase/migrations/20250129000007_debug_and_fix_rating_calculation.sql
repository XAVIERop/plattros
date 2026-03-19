-- Debug and Fix Rating Calculation
-- This migration adds debugging and ensures the average is ALWAYS correct

-- 1. Create a more robust function with explicit calculation
CREATE OR REPLACE FUNCTION update_cafe_rating_stats(cafe_id_param UUID)
RETURNS VOID AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    total_count INTEGER;
    sum_ratings INTEGER;
    rating_list TEXT;
BEGIN
    -- Get all ratings for this cafe
    SELECT 
        COALESCE(SUM(rating), 0),
        COUNT(*),
        STRING_AGG(rating::TEXT, ', ' ORDER BY created_at)
    INTO sum_ratings, total_count, rating_list
    FROM cafe_ratings 
    WHERE cafe_id = cafe_id_param;
    
    -- Calculate average explicitly: sum / count
    IF total_count > 0 THEN
        avg_rating := (sum_ratings::DECIMAL / total_count::DECIMAL)::DECIMAL(3,2);
    ELSE
        avg_rating := 0;
    END IF;
    
    -- Update the cafe's rating statistics
    UPDATE cafes 
    SET 
        average_rating = avg_rating,
        total_ratings = total_count,
        updated_at = NOW()
    WHERE id = cafe_id_param;
    
    -- Detailed logging
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Updated cafe %:', cafe_id_param;
    RAISE NOTICE '  All ratings: %', rating_list;
    RAISE NOTICE '  Sum: %, Count: %', sum_ratings, total_count;
    RAISE NOTICE '  Average: % / % = %', sum_ratings, total_count, avg_rating;
    RAISE NOTICE '  Updated cafes.average_rating = %', avg_rating;
    RAISE NOTICE '  Updated cafes.total_ratings = %', total_count;
    RAISE NOTICE '========================================';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Ensure trigger fires and logs
CREATE OR REPLACE FUNCTION trigger_update_cafe_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Trigger fired: % on cafe_ratings', TG_OP;
    
    IF TG_OP = 'INSERT' THEN
        RAISE NOTICE '  New rating: user_id=%, cafe_id=%, rating=%', NEW.user_id, NEW.cafe_id, NEW.rating;
        PERFORM update_cafe_rating_stats(NEW.cafe_id);
        RETURN NEW;
    END IF;
    
    IF TG_OP = 'UPDATE' THEN
        RAISE NOTICE '  Updated rating: user_id=%, cafe_id=%, old_rating=%, new_rating=%', 
            NEW.user_id, NEW.cafe_id, OLD.rating, NEW.rating;
        IF OLD.cafe_id != NEW.cafe_id THEN
            PERFORM update_cafe_rating_stats(OLD.cafe_id);
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        ELSE
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        END IF;
        RETURN NEW;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RAISE NOTICE '  Deleted rating: user_id=%, cafe_id=%, rating=%', 
            OLD.user_id, OLD.cafe_id, OLD.rating;
        PERFORM update_cafe_rating_stats(OLD.cafe_id);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Drop and recreate trigger
DROP TRIGGER IF EXISTS cafe_ratings_update_trigger ON cafe_ratings;
CREATE TRIGGER cafe_ratings_update_trigger
    AFTER INSERT OR UPDATE OR DELETE ON cafe_ratings
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_cafe_rating_stats();

-- 4. Recalculate ALL ratings immediately
DO $$
DECLARE
    cafe_record RECORD;
    recalc_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Recalculating ALL cafe ratings...';
    
    FOR cafe_record IN 
        SELECT DISTINCT cafe_id FROM cafe_ratings WHERE cafe_id IS NOT NULL
    LOOP
        PERFORM update_cafe_rating_stats(cafe_record.cafe_id);
        recalc_count := recalc_count + 1;
    END LOOP;
    
    UPDATE cafes 
    SET average_rating = 0, total_ratings = 0, updated_at = NOW()
    WHERE id NOT IN (SELECT DISTINCT cafe_id FROM cafe_ratings WHERE cafe_id IS NOT NULL);
    
    RAISE NOTICE 'Recalculated % cafes', recalc_count;
END $$;

-- 5. Create a test function to verify calculation
CREATE OR REPLACE FUNCTION test_rating_calculation(test_cafe_id UUID)
RETURNS TABLE (
    cafe_name TEXT,
    all_ratings INTEGER[],
    sum_ratings INTEGER,
    count_ratings INTEGER,
    calculated_avg DECIMAL(3,2),
    stored_avg DECIMAL(3,2),
    stored_total INTEGER,
    is_correct BOOLEAN
) AS $$
DECLARE
    ratings_array INTEGER[];
    sum_val INTEGER;
    count_val INTEGER;
    calc_avg DECIMAL(3,2);
    stored_avg_val DECIMAL(3,2);
    stored_total_val INTEGER;
    cafe_name_val TEXT;
BEGIN
    -- Get all ratings
    SELECT 
        ARRAY_AGG(rating ORDER BY created_at),
        SUM(rating),
        COUNT(*)
    INTO ratings_array, sum_val, count_val
    FROM cafe_ratings
    WHERE cafe_id = test_cafe_id;
    
    -- Calculate average
    IF count_val > 0 THEN
        calc_avg := (sum_val::DECIMAL / count_val::DECIMAL)::DECIMAL(3,2);
    ELSE
        calc_avg := 0;
    END IF;
    
    -- Get stored values
    SELECT name, average_rating, total_ratings
    INTO cafe_name_val, stored_avg_val, stored_total_val
    FROM cafes
    WHERE id = test_cafe_id;
    
    RETURN QUERY SELECT
        cafe_name_val,
        COALESCE(ratings_array, ARRAY[]::INTEGER[]),
        COALESCE(sum_val, 0),
        COALESCE(count_val, 0),
        calc_avg,
        COALESCE(stored_avg_val, 0),
        COALESCE(stored_total_val, 0),
        (calc_avg = COALESCE(stored_avg_val, 0) AND count_val = COALESCE(stored_total_val, 0));
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION test_rating_calculation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION test_rating_calculation(UUID) TO anon;

-- 6. Grant permissions
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO anon;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Rating calculation system updated with debugging!';
    RAISE NOTICE 'The trigger will now log every rating change.';
    RAISE NOTICE 'Use test_rating_calculation(cafe_id) to verify calculations.';
END $$;




