-- Dynamic Function Security Fix
-- Dynamically finds and fixes all functions that exist
-- This avoids signature mismatch errors

-- ===========================================
-- DYNAMICALLY FIX ALL EXISTING FUNCTIONS
-- ===========================================

-- Create a function to fix search_path for all existing functions
DO $$
DECLARE
    func_record RECORD;
    func_signature TEXT;
BEGIN
    -- Loop through all functions in the public schema
    FOR func_record IN 
        SELECT 
            p.proname as func_name,
            pg_get_function_identity_arguments(p.oid) as func_args,
            p.oid as func_oid
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.prokind = 'f'  -- Only functions, not procedures
        AND p.proconfig IS NULL  -- Only functions without existing config
    LOOP
        -- Build the function signature
        func_signature := 'public.' || func_record.func_name || '(' || func_record.func_args || ')';
        
        -- Try to set search_path for this function
        BEGIN
            EXECUTE 'ALTER FUNCTION ' || func_signature || ' SET search_path = public';
            RAISE NOTICE 'Fixed search_path for function: %', func_signature;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not fix function %: %', func_signature, SQLERRM;
        END;
    END LOOP;
END $$;

-- ===========================================
-- VERIFICATION
-- ===========================================

-- Show all functions that now have secure search_path
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments,
    p.proconfig as config_settings
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
    AND p.proconfig IS NOT NULL
    AND 'search_path=public' = ANY(p.proconfig)
ORDER BY p.proname;














