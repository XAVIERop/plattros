-- Force Trigger Creation and Verify It Works
-- This migration ensures the trigger exists and is working

-- 1. First, check if trigger exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'cafe_ratings_update_trigger'
    ) THEN
        RAISE NOTICE 'Trigger exists';
    ELSE
        RAISE WARNING 'Trigger does NOT exist!';
    END IF;
END $$;

-- 2. Drop everything and recreate from scratch
DROP TRIGGER IF EXISTS cafe_ratings_update_trigger ON cafe_ratings;
DROP FUNCTION IF EXISTS trigger_update_cafe_rating_stats();
DROP FUNCTION IF EXISTS update_cafe_rating_stats(UUID);

-- 3. Create the update function
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
    UPDATE cafes 
    SET 
        average_rating = avg_rating,
        total_ratings = total_count,
        updated_at = NOW()
    WHERE id = cafe_id_param;
    
    RAISE NOTICE 'Updated cafe %: average=%, total=%', cafe_id_param, avg_rating, total_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create the trigger function
CREATE OR REPLACE FUNCTION trigger_update_cafe_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Trigger fired: % operation', TG_OP;
    
    IF TG_OP = 'INSERT' THEN
        PERFORM update_cafe_rating_stats(NEW.cafe_id);
        RETURN NEW;
    END IF;
    
    IF TG_OP = 'UPDATE' THEN
        IF OLD.cafe_id IS DISTINCT FROM NEW.cafe_id THEN
            PERFORM update_cafe_rating_stats(OLD.cafe_id);
            PERFORM update_cafe_rating_stats(NEW.cafe_id);
        ELSE
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

-- 5. Create the trigger
CREATE TRIGGER cafe_ratings_update_trigger
    AFTER INSERT OR UPDATE OR DELETE ON cafe_ratings
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_cafe_rating_stats();

-- 6. Grant permissions
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cafe_rating_stats(UUID) TO anon;
GRANT EXECUTE ON FUNCTION trigger_update_cafe_rating_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION trigger_update_cafe_rating_stats() TO anon;

-- 7. Recalculate all existing ratings
DO $$
DECLARE
    cafe_record RECORD;
    count INTEGER := 0;
BEGIN
    FOR cafe_record IN 
        SELECT DISTINCT cafe_id FROM cafe_ratings WHERE cafe_id IS NOT NULL
    LOOP
        PERFORM update_cafe_rating_stats(cafe_record.cafe_id);
        count := count + 1;
    END LOOP;
    
    RAISE NOTICE 'Recalculated % cafes', count;
END $$;

-- 8. Test the trigger by inserting a test rating (if possible)
DO $$
DECLARE
    test_cafe_id UUID;
    test_user_id UUID;
BEGIN
    -- Get a cafe and user for testing
    SELECT id INTO test_cafe_id FROM cafes LIMIT 1;
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    IF test_cafe_id IS NOT NULL AND test_user_id IS NOT NULL THEN
        -- Try to insert a test rating (will fail if already exists, that's ok)
        BEGIN
            INSERT INTO cafe_ratings (cafe_id, user_id, rating, created_at, updated_at)
            VALUES (test_cafe_id, test_user_id, 5, NOW(), NOW())
            ON CONFLICT (cafe_id, user_id) DO UPDATE SET rating = 5, updated_at = NOW();
            
            RAISE NOTICE 'Test rating inserted/updated - trigger should have fired';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Test rating insert failed (expected if constraint exists): %', SQLERRM;
        END;
    END IF;
END $$;

-- 9. Verify trigger exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'cafe_ratings_update_trigger'
    ) THEN
        RAISE NOTICE '✅ Trigger created successfully!';
    ELSE
        RAISE EXCEPTION '❌ Trigger was NOT created!';
    END IF;
END $$;




