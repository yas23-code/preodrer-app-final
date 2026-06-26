-- ============================================================
-- Order Refunds columns and triggers
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Add columns to public.orders table
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS refund_status TEXT NOT NULL DEFAULT 'none';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS refund_processed_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS refund_processed_by UUID REFERENCES public.profiles(id);

-- 2. Create index for fast status lookups
CREATE INDEX IF NOT EXISTS idx_orders_refund_status ON public.orders (refund_status);

-- 3. Create trigger to automatically set refund_status to 'pending' when order status becomes 'declined' or 'rejected'
CREATE OR REPLACE FUNCTION trigger_set_refund_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IN ('declined', 'rejected') AND OLD.status NOT IN ('declined', 'rejected') THEN
    NEW.refund_status := 'pending';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_refund_status ON public.orders;

CREATE TRIGGER trg_set_refund_status
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION trigger_set_refund_status();

-- 4. Enable RLS and add superadmin policies for orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for superadmins" ON public.orders;
CREATE POLICY "Allow all for superadmins"
  ON public.orders FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'superadmin'
    )
  );

-- 5. Enable RLS and add superadmin policies for order_items
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for superadmins" ON public.order_items;
CREATE POLICY "Allow all for superadmins"
  ON public.order_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'superadmin'
    )
  );

