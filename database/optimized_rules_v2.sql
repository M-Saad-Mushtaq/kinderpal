-- =====================================================
-- KinderPal Custom Rules — Optimized Single-Table Migration (v2)
-- Run this in your Supabase SQL Editor BEFORE updating the app.
-- This replaces the 5-table structure with a single JSONB/array table.
-- =====================================================

-- Drop old 5-table structure (cascade removes all FK children)
DROP TABLE IF EXISTS rule_time_constraints   CASCADE;
DROP TABLE IF EXISTS rule_blocked_channels   CASCADE;
DROP TABLE IF EXISTS rule_blocked_categories CASCADE;
DROP TABLE IF EXISTS rule_allowed_categories CASCADE;
DROP VIEW  IF EXISTS v_custom_rules_complete;
DROP TABLE IF EXISTS custom_rules            CASCADE;

-- =====================================================
-- Single Custom Rules Table
-- All structured data stored as native arrays / JSONB
-- =====================================================
CREATE TABLE custom_rules (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_profile_id UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,

    -- Original guardian input
    rule_text        TEXT NOT NULL,

    -- AI-classified type
    rule_type        VARCHAR(50) NOT NULL CHECK (
        rule_type IN ('channel_block', 'time_limit', 'content_filter',
                      'goal_based', 'category_control', 'mixed')
    ),

    -- Structured data (inline — no joins needed)
    blocked_channels   TEXT[]  NOT NULL DEFAULT '{}',
    blocked_categories TEXT[]  NOT NULL DEFAULT '{}',
    allowed_categories TEXT[]  NOT NULL DEFAULT '{}',
    time_constraint    JSONB   DEFAULT NULL,   -- {daily_limit, start_time, end_time, weekday_limit, weekend_limit}

    -- Metadata
    goal_identified  TEXT,
    age_context      INTEGER,
    severity         VARCHAR(20) CHECK (severity IN ('strict', 'moderate', 'lenient')),
    is_active        BOOLEAN NOT NULL DEFAULT true,

    created_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(child_profile_id, rule_text)
);

-- Indexes
CREATE INDEX idx_custom_rules_profile ON custom_rules(child_profile_id);
CREATE INDEX idx_custom_rules_active  ON custom_rules(child_profile_id, is_active);

-- updated_at trigger
CREATE OR REPLACE FUNCTION _trg_custom_rules_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = CURRENT_TIMESTAMP; RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS trg_custom_rules_updated_at ON custom_rules;
CREATE TRIGGER trg_custom_rules_updated_at
    BEFORE UPDATE ON custom_rules
    FOR EACH ROW EXECUTE FUNCTION _trg_custom_rules_updated_at();

-- =====================================================
-- Row-Level Security
-- =====================================================
ALTER TABLE custom_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "select_own_rules" ON custom_rules FOR SELECT
    USING (child_profile_id IN (
        SELECT id FROM child_profiles WHERE guardian_id = auth.uid()
    ));

CREATE POLICY "insert_own_rules" ON custom_rules FOR INSERT
    WITH CHECK (child_profile_id IN (
        SELECT id FROM child_profiles WHERE guardian_id = auth.uid()
    ));

CREATE POLICY "update_own_rules" ON custom_rules FOR UPDATE
    USING (child_profile_id IN (
        SELECT id FROM child_profiles WHERE guardian_id = auth.uid()
    ));

CREATE POLICY "delete_own_rules" ON custom_rules FOR DELETE
    USING (child_profile_id IN (
        SELECT id FROM child_profiles WHERE guardian_id = auth.uid()
    ));
