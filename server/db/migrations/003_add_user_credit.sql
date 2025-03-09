-- Add credit field to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS credit DECIMAL(10, 2) NOT NULL DEFAULT 0.00;

-- Add index for quicker lookups
CREATE INDEX IF NOT EXISTS idx_users_credit ON users(credit); 