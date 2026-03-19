-- Add SWJ Class values to block_type enum
-- IMPORTANT: Each ALTER TYPE must be run in a separate transaction
-- Run each statement one at a time in Supabase SQL Editor

-- Step 1: Add CLASS1 (run this first, then wait for it to complete)
ALTER TYPE block_type ADD VALUE IF NOT EXISTS 'CLASS1';

-- Step 2: Add CLASS2 (run this after Step 1 completes)
ALTER TYPE block_type ADD VALUE IF NOT EXISTS 'CLASS2';

-- Step 3: Add CLASS3 (run this after Step 2 completes)
ALTER TYPE block_type ADD VALUE IF NOT EXISTS 'CLASS3';

-- Step 4: Add CLASS4 (run this after Step 3 completes)
ALTER TYPE block_type ADD VALUE IF NOT EXISTS 'CLASS4';

-- Step 5: Verify all enum values were added (run this last)
SELECT unnest(enum_range(NULL::block_type)) as block_type_values
ORDER BY block_type_values;

