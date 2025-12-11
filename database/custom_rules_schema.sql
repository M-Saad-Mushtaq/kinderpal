-- =====================================================
-- KinderPal Custom Rules Database Schema
-- Supports structured rules from Ollama LLM parsing
-- =====================================================

-- STEP 1: Backup existing data from old custom_rules table (if exists)
CREATE TEMP TABLE IF NOT EXISTS temp_old_custom_rules AS
SELECT * FROM custom_rules WHERE 1=0; -- Create empty table with same structure

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'custom_rules') THEN
        INSERT INTO temp_old_custom_rules SELECT * FROM custom_rules;
        RAISE NOTICE 'Backed up % rows from existing custom_rules table', (SELECT COUNT(*) FROM temp_old_custom_rules);
    END IF;
END $$;

-- STEP 2: Drop existing tables if recreating
DROP TABLE IF EXISTS rule_time_constraints CASCADE;
DROP TABLE IF EXISTS rule_blocked_channels CASCADE;
DROP TABLE IF EXISTS rule_blocked_categories CASCADE;
DROP TABLE IF EXISTS rule_allowed_categories CASCADE;
DROP TABLE IF EXISTS custom_rules CASCADE;

-- =====================================================
-- Main Custom Rules Table
-- =====================================================
CREATE TABLE custom_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_profile_id UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
    
    -- Core rule fields
    rule_text TEXT NOT NULL,  -- Original parent input
    rule_type VARCHAR(50) NOT NULL CHECK (
        rule_type IN ('channel_block', 'time_limit', 'content_filter', 'goal_based', 'category_control', 'mixed')
    ),
    
    -- Additional metadata
    goal_identified TEXT,
    age_context INTEGER,
    severity VARCHAR(20) CHECK (severity IN ('strict', 'moderate', 'lenient')),
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(child_profile_id, rule_text)  -- Prevent duplicate rules
);

-- =====================================================
-- Blocked Channels Table
-- =====================================================
CREATE TABLE rule_blocked_channels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    custom_rule_id UUID NOT NULL REFERENCES custom_rules(id) ON DELETE CASCADE,
    channel_name TEXT NOT NULL,
    channel_id TEXT,  -- YouTube channel ID if available
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(custom_rule_id, channel_name)
);

-- =====================================================
-- Blocked Categories Table
-- =====================================================
CREATE TABLE rule_blocked_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    custom_rule_id UUID NOT NULL REFERENCES custom_rules(id) ON DELETE CASCADE,
    category TEXT NOT NULL,  -- e.g., gaming, vlogs, pranks, violent, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(custom_rule_id, category)
);

-- =====================================================
-- Allowed Categories Table
-- =====================================================
CREATE TABLE rule_allowed_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    custom_rule_id UUID NOT NULL REFERENCES custom_rules(id) ON DELETE CASCADE,
    category TEXT NOT NULL,  -- e.g., educational, science, math, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(custom_rule_id, category)
);

-- =====================================================
-- Time Constraints Table
-- =====================================================
CREATE TABLE rule_time_constraints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    custom_rule_id UUID NOT NULL REFERENCES custom_rules(id) ON DELETE CASCADE,
    
    daily_limit INTEGER,  -- Total minutes per day
    start_time TIME,  -- e.g., 08:00
    end_time TIME,    -- e.g., 20:00
    weekday_limit INTEGER,  -- Minutes per day on weekdays
    weekend_limit INTEGER,  -- Minutes per day on weekends
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(custom_rule_id)  -- One time constraint per rule
);

-- =====================================================
-- Indexes for Performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_custom_rules_profile ON custom_rules(child_profile_id);
CREATE INDEX IF NOT EXISTS idx_custom_rules_type ON custom_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_custom_rules_active ON custom_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_blocked_channels_rule ON rule_blocked_channels(custom_rule_id);
CREATE INDEX IF NOT EXISTS idx_blocked_categories_rule ON rule_blocked_categories(custom_rule_id);
CREATE INDEX IF NOT EXISTS idx_allowed_categories_rule ON rule_allowed_categories(custom_rule_id);
CREATE INDEX IF NOT EXISTS idx_time_constraints_rule ON rule_time_constraints(custom_rule_id);

-- =====================================================
-- Update Timestamp Trigger
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_custom_rules_updated_at ON custom_rules;
CREATE TRIGGER update_custom_rules_updated_at
    BEFORE UPDATE ON custom_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Helper Views for Easy Querying
-- =====================================================

-- View: Complete rules with all related data
CREATE OR REPLACE VIEW v_custom_rules_complete AS
SELECT 
    cr.id,
    cr.child_profile_id,
    cp.name as child_name,
    cr.rule_text,
    cr.rule_type,
    cr.goal_identified,
    cr.age_context,
    cr.severity,
    cr.is_active,
    cr.created_at,
    
    -- Aggregated blocked channels
    (SELECT json_agg(channel_name) 
     FROM rule_blocked_channels 
     WHERE custom_rule_id = cr.id) as blocked_channels,
    
    -- Aggregated blocked categories
    (SELECT json_agg(category) 
     FROM rule_blocked_categories 
     WHERE custom_rule_id = cr.id) as blocked_categories,
    
    -- Aggregated allowed categories
    (SELECT json_agg(category) 
     FROM rule_allowed_categories 
     WHERE custom_rule_id = cr.id) as allowed_categories,
    
    -- Time constraints as JSON
    (SELECT row_to_json(tc.*) 
     FROM rule_time_constraints tc 
     WHERE tc.custom_rule_id = cr.id) as time_constraint
     
FROM custom_rules cr
JOIN child_profiles cp ON cr.child_profile_id = cp.id
ORDER BY cr.created_at DESC;

-- =====================================================
-- Migration: Copy existing custom_rules from child_profiles
-- =====================================================
-- This migrates data from child_profiles.custom_rules array column

DO $$
DECLARE
    profile_record RECORD;
    current_rule_text TEXT;
    new_rule_id UUID;
BEGIN
    -- First, try to migrate from old custom_rules table if it had different structure
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'temp_old_custom_rules') THEN
        RAISE NOTICE 'Migrating from old custom_rules table structure...';
        
        -- Attempt to copy data - adjust columns based on old schema
        -- This is a best-effort migration
        BEGIN
            INSERT INTO custom_rules (child_profile_id, rule_text, rule_type, is_active)
            SELECT 
                child_profile_id,
                COALESCE(rule_text, rule_name, 'Migrated rule') as rule_text,
                'content_filter' as rule_type,
                true as is_active
            FROM temp_old_custom_rules;
            
            RAISE NOTICE 'Migrated % rows from old custom_rules table', (SELECT COUNT(*) FROM temp_old_custom_rules);
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not migrate old custom_rules: %', SQLERRM;
        END;
    END IF;

    -- Then, migrate from child_profiles.custom_rules array if exists
    IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'child_profiles' 
        AND column_name = 'custom_rules'
    ) THEN
        RAISE NOTICE 'Migrating from child_profiles.custom_rules array...';
        
        -- Loop through all child profiles that have custom_rules
        FOR profile_record IN 
            SELECT id, custom_rules 
            FROM child_profiles 
            WHERE custom_rules IS NOT NULL 
            AND array_length(custom_rules, 1) > 0
        LOOP
            -- Loop through each rule in the custom_rules array
            FOREACH current_rule_text IN ARRAY profile_record.custom_rules
            LOOP
                -- Insert into new custom_rules table
                -- Default to 'content_filter' type since we don't have parsed data yet
                INSERT INTO custom_rules (
                    child_profile_id,
                    rule_text,
                    rule_type,
                    is_active
                )
                VALUES (
                    profile_record.id,
                    current_rule_text,
                    'content_filter',  -- Default type
                    true
                )
                ON CONFLICT (child_profile_id, rule_text) DO NOTHING;
            END LOOP;
        END LOOP;
        
        RAISE NOTICE 'Migration complete!';
    END IF;
END $$;

-- =====================================================
-- Sample Data (for testing)
-- =====================================================
/*
-- Example: Channel Block Rule
INSERT INTO custom_rules (child_profile_id, rule_text, rule_type)
VALUES ('your-profile-id', 'Block Cocomelon and Natsya YouTube channels', 'channel_block')
RETURNING id;

-- Add blocked channels
INSERT INTO rule_blocked_channels (custom_rule_id, channel_name)
VALUES 
    ('rule-id-from-above', 'Cocomelon'),
    ('rule-id-from-above', 'Natsya');

-- Example: Time Limit Rule
INSERT INTO custom_rules (child_profile_id, rule_text, rule_type)
VALUES ('your-profile-id', 'Limit YouTube watching to 2 hours daily', 'time_limit')
RETURNING id;

-- Add time constraint
INSERT INTO rule_time_constraints (custom_rule_id, daily_limit, start_time, end_time)
VALUES ('rule-id-from-above', 120, '08:00', '22:00');
*/

-- =====================================================
-- RLS (Row Level Security) Policies
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE custom_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE rule_blocked_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE rule_blocked_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE rule_allowed_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE rule_time_constraints ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access rules for their own child profiles
CREATE POLICY "Users can view their own child profile rules"
    ON custom_rules FOR SELECT
    USING (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE guardian_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert rules for their own child profiles"
    ON custom_rules FOR INSERT
    WITH CHECK (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE guardian_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own child profile rules"
    ON custom_rules FOR UPDATE
    USING (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE guardian_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own child profile rules"
    ON custom_rules FOR DELETE
    USING (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE guardian_id = auth.uid()
        )
    );

-- Similar policies for related tables (they inherit through FK relationship)
CREATE POLICY "Users can manage blocked channels"
    ON rule_blocked_channels FOR ALL
    USING (
        custom_rule_id IN (
            SELECT cr.id FROM custom_rules cr
            JOIN child_profiles cp ON cr.child_profile_id = cp.id
            WHERE cp.guardian_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage blocked categories"
    ON rule_blocked_categories FOR ALL
    USING (
        custom_rule_id IN (
            SELECT cr.id FROM custom_rules cr
            JOIN child_profiles cp ON cr.child_profile_id = cp.id
            WHERE cp.guardian_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage allowed categories"
    ON rule_allowed_categories FOR ALL
    USING (
        custom_rule_id IN (
            SELECT cr.id FROM custom_rules cr
            JOIN child_profiles cp ON cr.child_profile_id = cp.id
            WHERE cp.guardian_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage time constraints"
    ON rule_time_constraints FOR ALL
    USING (
        custom_rule_id IN (
            SELECT cr.id FROM custom_rules cr
            JOIN child_profiles cp ON cr.child_profile_id = cp.id
            WHERE cp.guardian_id = auth.uid()
        )
    );
