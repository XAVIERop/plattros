-- =====================================================
-- UPDATE BLOCK ENUM TO INCLUDE B12 AND G8
-- =====================================================
-- This migration adds the missing blocks B12 and G8 to the block_type enum

-- Add B12 to the block_type enum
ALTER TYPE block_type ADD VALUE 'B12';

-- Add G8 to the block_type enum  
ALTER TYPE block_type ADD VALUE 'G8';

-- Verify the enum now contains all blocks
-- The complete enum should now be: B1, B2, B3, B4, B5, B6, B7, B8, B9, B10, B11, B12, G1, G2, G3, G4, G5, G6, G7, G8
