-- =============================================================================
-- Add payment tracking columns to public.orders
--
-- New columns:
--   payment_status    TEXT  DEFAULT 'pending'  (pending | paid | failed)
--   payment_provider  TEXT  DEFAULT 'cashfree'
--   cashfree_order_id TEXT  (Cashfree-side order ID)
--   payment_session_id TEXT (Cashfree payment session for SDK)
--   paid_at           TIMESTAMPTZ (when payment was confirmed)
--
-- Backfills all existing rows to payment_status = 'paid' so the vendor
-- dashboard continues to show them.
-- =============================================================================

-- 1. Add columns (idempotent — uses IF NOT EXISTS via DO block)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'payment_status'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN payment_status TEXT DEFAULT 'pending';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'payment_provider'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN payment_provider TEXT DEFAULT 'cashfree';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'cashfree_order_id'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN cashfree_order_id TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'payment_session_id'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN payment_session_id TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'paid_at'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN paid_at TIMESTAMPTZ;
  END IF;
END
$$;

-- 2. Backfill: mark all existing orders as 'paid' so vendor keeps seeing them
UPDATE public.orders
SET payment_status = 'paid',
    paid_at = created_at
WHERE payment_status IS NULL OR payment_status = 'pending';

-- 3. Index for vendor dashboard query performance
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON public.orders (payment_status);
