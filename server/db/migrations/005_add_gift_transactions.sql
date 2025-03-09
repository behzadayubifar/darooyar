-- Add is_admin field to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Create gift_transactions table
CREATE TABLE IF NOT EXISTS gift_transactions (
    id SERIAL PRIMARY KEY,
    admin_id BIGINT NOT NULL REFERENCES users(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    gift_type VARCHAR(50) NOT NULL,
    plan_id BIGINT REFERENCES plans(id),
    credit_amount DECIMAL(10, 2),
    message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_gift_transactions_user_id ON gift_transactions(user_id);

-- Create index on admin_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_gift_transactions_admin_id ON gift_transactions(admin_id); 