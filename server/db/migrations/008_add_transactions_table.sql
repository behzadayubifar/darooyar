-- Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    payment_method TEXT NOT NULL,
    reference_id TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    metadata TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create index on reference_id for faster lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_reference_id ON transactions(reference_id);

-- Create index on user_id for faster user transaction lookups
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);

-- Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC); 