-- ============================================================
-- Add superadmin RLS policies for orders and order_items
-- ============================================================

-- 1. Enable RLS and add superadmin policies for orders
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

-- 2. Enable RLS and add superadmin policies for order_items
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
