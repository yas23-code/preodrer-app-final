
-- =============================================================================
-- Migration: Cashfree → Razorpay
--
-- Changes:
--   1. Add razorpay_order_id column
--   2. Add razorpay_payment_id column
--   3. Update payment_provider default to 'razorpay'
--
-- NOTE: We keep the old cashfree_order_id and payment_session_id columns
-- so that existing/historical orders are not broken.
-- =============================================================================

-- 1. Add Razorpay columns (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'razorpay_order_id'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN razorpay_order_id TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'razorpay_payment_id'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN razorpay_payment_id TEXT;
  END IF;
END
$$;

-- 2. Update default payment provider for new orders
ALTER TABLE public.orders ALTER COLUMN payment_provider SET DEFAULT 'razorpay';

-- 3. Index for Razorpay order lookups
CREATE INDEX IF NOT EXISTS idx_orders_razorpay_order_id ON public.orders (razorpay_order_id);

