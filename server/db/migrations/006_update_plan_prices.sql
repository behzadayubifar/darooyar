-- Update existing plans to use prices in thousands of Tomans
-- This migration multiplies all plan prices by 1000 to convert from thousands to actual Tomans

-- First, create a backup of the current plans
CREATE TABLE IF NOT EXISTS plans_backup AS SELECT * FROM plans;

-- Update all plan prices by multiplying by 1000
UPDATE plans SET price = price * 1000;

-- Update any user credit that might need adjustment (optional)
-- UPDATE users SET credit = credit * 1000;

-- Log the migration
INSERT INTO migration_logs (migration_name, description, executed_at)
VALUES ('006_update_plan_prices', 'Updated plan prices to be in actual Tomans instead of thousands', NOW())
ON CONFLICT (migration_name) DO NOTHING; 