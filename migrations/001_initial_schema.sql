-- Migration: 001_initial_schema
-- Created: 2026-03-05
-- Description: Initial database schema for ASilva Innovations Blog

-- Run this first to check if migration was already applied
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'migration_history') THEN
        IF EXISTS (SELECT 1 FROM migration_history WHERE version = '001_initial_schema') THEN
            RAISE EXCEPTION 'Migration 001_initial_schema already applied';
        END IF;
    END IF;
END $$;

-- Create migration tracking table if not exists
CREATE TABLE IF NOT EXISTS migration_history (
    id SERIAL PRIMARY KEY,
    version VARCHAR(50) UNIQUE NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    checksum VARCHAR(64),
    applied_by VARCHAR(255)
);

-- Insert migration record
INSERT INTO migration_history (version, applied_by) VALUES ('001_initial_schema', current_user);

-- Note: The actual schema creation SQL would go here (from schema.sql)
-- This file serves as a reference for migration structure
