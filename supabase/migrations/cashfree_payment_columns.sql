-- Migration: Add Cashfree payment columns to orders table
-- Run this in your Supabase SQL editor or via supabase db push

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS cashfree_order_id TEXT,
  ADD COLUMN IF NOT EXISTS payment_session_id TEXT,
  ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;

-- Optional: Index for faster payment status queries
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
