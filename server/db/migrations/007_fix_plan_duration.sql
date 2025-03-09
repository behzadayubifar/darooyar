-- Fix plan duration for plans without time limitations
-- This migration updates any plans with duration_days = 0 to NULL to properly represent unlimited duration

-- Update plans with plan_type 'usage_based' that have duration_days = 0
UPDATE plans
SET duration_days = NULL
WHERE plan_type = 'usage_based' AND duration_days = 0;

-- Log the migration
INSERT INTO migration_logs (migration_name, description, executed_at)
VALUES ('007_fix_plan_duration', 'Updated plans with duration_days = 0 to NULL for plans without time limitations', NOW())
ON CONFLICT (migration_name) DO NOTHING; 