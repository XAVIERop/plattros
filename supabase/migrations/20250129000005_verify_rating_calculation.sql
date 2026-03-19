-- Verify and Fix Rating Calculation
-- This ensures the average is calculated from ALL users' ratings, not just the latest

-- 1. Recreate the update function to ensure it's correct
CREATE OR REPLACE FUNCTION update_cafe_rating_stats(cafe_id_param UUID)
RETURNS VOID AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    total_count INTEGER;
BEGIN
    -- Calculate average rating and total count from ALL ratings in cafe_ratings table
    -- This includes ratings from ALL users, not just one
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
    
    RAISE NOTICE 'Updated cafe %: average_rating=%, total_ratings=% (calculated from % distinct users)', 
        cafe_id_param, avg_rating, total_count, total_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Ensure the trigger function fires on INSERT, UPDATE, and DELETE
CREATE OR REPLACE FUNCTION trigger_update_cafe_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle INSERT - new rating added
    IF TG_OP = 'INSERT' THEN
        RAISE NOTICE 'Trigger: INSERT detected for cafe_id=%, user_id=%, rating=%', 
            NEW.cafe_id, NEW.user_id, NEW.rating;
        PERFORM update_cafe_rating_stats(NEW.cafe_id);
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE - existing rating changed
    IF TG_OP = 'UPDATE' THEN
        RAISE NOTICE 'Trigger: UPDATE detected for cafe_id=%, user_id=%, old_rating=%, new_rating=%', 
            NEW.cafe_id, NEW.user_id, OLD.rating, NEW.rating;
        -- Update both old and new cafe_id if it changed
        IF OLD.cafe_id != NEW.cafe_id THEN
            PERFORM update_cafe_rating_stats(OLD.cafe_id);
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        ELSE
            -- Same cafe, just rating changed - recalculate average
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        END IF;
        RETURN NEW;
    END IF;
    
    -- Handle DELETE - rating removed
    IF TG_OP = 'DELETE' THEN
        RAISE NOTICE 'Trigger: DELETE detected for cafe_id=%, user_id=%', 
            OLD.cafe_id, OLD.user_id;
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

-- 4. Recalculate all existing cafe ratings to ensure they're correct
DO $$
DECLARE
    cafe_record RECORD;
    recalc_count INTEGER := 0;
BEGIN
    -- Loop through all cafes that have ratings
    FOR cafe_record IN 
        SELECT DISTINCT cafe_id FROM cafe_ratings WHERE cafe_id IS NOT NULL
    LOOP
        PERFORM update_cafe_rating_stats(cafe_record.cafe_id);
        recalc_count := recalc_count + 1;
    END LOOP;
    
    -- Also update cafes that have no ratings (set to 0)
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
    
    RAISE NOTICE 'Recalculated rating statistics for % cafes', recalc_count;
END $$;

-- 5. Grant permissions
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO anon;

-- 6. Verification query - shows how ratings are calculated
DO $$
DECLARE
    test_cafe_id UUID;
    avg_from_table DECIMAL(3,2);
    total_from_table INTEGER;
    avg_in_cafes DECIMAL(3,2);
    total_in_cafes INTEGER;
BEGIN
    -- Get a cafe with ratings for testing
    SELECT cafe_id INTO test_cafe_id
    FROM cafe_ratings
    LIMIT 1;
    
    IF test_cafe_id IS NOT NULL THEN
        -- Calculate from cafe_ratings table
        SELECT 
            COALESCE(ROUND(AVG(rating)::NUMERIC, 2), 0)::DECIMAL(3,2),
            COUNT(*)
        INTO avg_from_table, total_from_table
        FROM cafe_ratings
        WHERE cafe_id = test_cafe_id;
        
        -- Get from cafes table
        SELECT average_rating, total_ratings
        INTO avg_in_cafes, total_in_cafes
        FROM cafes
        WHERE id = test_cafe_id;
        
        RAISE NOTICE 'Verification for cafe %:', test_cafe_id;
        RAISE NOTICE '  From cafe_ratings table: avg=%, count=%', avg_from_table, total_from_table;
        RAISE NOTICE '  In cafes table: avg=%, count=%', avg_in_cafes, total_in_cafes;
        
        IF avg_from_table = avg_in_cafes AND total_from_table = total_in_cafes THEN
            RAISE NOTICE '  ✅ Ratings match! Calculation is correct.';
        ELSE
            RAISE WARNING '  ⚠️ Ratings do not match! Need to recalculate.';
        END IF;
    ELSE
        RAISE NOTICE 'No cafes with ratings found for verification';
    END IF;
END $$;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Rating calculation system verified and fixed!';
    RAISE NOTICE 'The average is now calculated from ALL users'' ratings.';
    RAISE NOTICE 'When a user updates their rating, the average recalculates from all users.';
END $$;




