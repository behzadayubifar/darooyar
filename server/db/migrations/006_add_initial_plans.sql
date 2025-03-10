-- Add initial plans with correct pricing
-- This migration adds the three main subscription plans with their correct prices

-- First, check if there are any user subscriptions referencing these plans and delete them
DELETE FROM user_subscriptions WHERE plan_id IN (1, 2, 3);

-- Now we can safely delete the plans
DELETE FROM plans WHERE id IN (1, 2, 3);
ALTER SEQUENCE plans_id_seq RESTART WITH 1;

-- Insert the three plans that match our Flutter app
-- Plan 1: cephalexin (Basic plan)
INSERT INTO plans (id, title, description, price, duration_days, max_uses, plan_type, created_at, updated_at)
VALUES (
    1, 
    'سفالکسین', 
    'پلن اقتصادی برای استفاده کوتاه مدت', 
    45000, -- 45,000 Tomans (45 thousand)
    7, -- 7 days time limit
    3, -- 3 prescriptions
    'both', -- Both time and usage limits apply
    NOW(), 
    NOW()
);

-- Plan 2: cefuroxime (Standard plan)
INSERT INTO plans (id, title, description, price, duration_days, max_uses, plan_type, created_at, updated_at)
VALUES (
    2, 
    'سفوروکسیم', 
    'پلن متوسط با امکانات کاربردی', 
    135000, -- 135,000 Tomans (135 thousand)
    NULL, -- No time limit (NULL means unlimited)
    10, -- 10 prescriptions
    'usage_based', -- Only usage limit applies
    NOW(), 
    NOW()
);

-- Plan 3: cefixime (Premium plan)
INSERT INTO plans (id, title, description, price, duration_days, max_uses, plan_type, created_at, updated_at)
VALUES (
    3, 
    'سفکسیم', 
    'پلن پیشرفته با امکانات کامل', 
    375000, -- 375,000 Tomans (375 thousand)
    NULL, -- No time limit (NULL means unlimited)
    30, -- 30 prescriptions
    'usage_based', -- Only usage limit applies
    NOW(), 
    NOW()
);

-- Reset the sequence to the next value after our manually inserted IDs
SELECT setval('plans_id_seq', (SELECT MAX(id) FROM plans));

-- Log the migration
INSERT INTO migration_logs (migration_name, description, executed_at)
VALUES ('006_add_initial_plans', 'Added initial subscription plans with correct pricing', NOW())
ON CONFLICT (migration_name) DO NOTHING;
