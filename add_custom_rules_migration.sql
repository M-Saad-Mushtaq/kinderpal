-- Migration: Add custom_rules column to child_profiles table
-- Run this SQL in your Supabase SQL Editor if you already created the child_profiles table

-- Add custom_rules column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'child_profiles' 
        AND column_name = 'custom_rules'
    ) THEN
        ALTER TABLE public.child_profiles 
        ADD COLUMN custom_rules TEXT[] DEFAULT '{}';
    END IF;
END $$;

-- Verify the column was added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'child_profiles'
AND column_name = 'custom_rules';
