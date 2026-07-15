-- ============================================================
-- Fix: Re-add superadmin policies that were accidentally dropped
-- by 20260627200000_temp_drop_policies.sql
--
-- This restores UPDATE/DELETE capability for superadmins on
-- canteen_registrations, and ensures proper WITH CHECK clauses
-- on user_roles so superadmins can insert roles for other users.
--
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Ensure the SECURITY DEFINER helper exists
CREATE OR REPLACE FUNCTION public.is_superadmin(check_user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_roles.user_id = check_user_id
    AND user_roles.role = 'superadmin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix canteen_registrations policies
--    The temp_drop_policies migration removed the superadmin FOR ALL
--    and the owner SELECT policies. Re-add them.

-- Keep the public SELECT (from public_select_policy migration)
-- but re-add the superadmin FOR ALL policy for UPDATE/DELETE

DROP POLICY IF EXISTS "Allow all for superadmins" ON canteen_registrations;
CREATE POLICY "Allow all for superadmins"
  ON canteen_registrations FOR ALL
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

-- 3. Fix user_roles policies for superadmin INSERT
--    The existing FOR ALL policy only has USING (for SELECT/UPDATE/DELETE).
--    We need WITH CHECK for INSERT operations too.

DROP POLICY IF EXISTS "Allow superadmins all on user_roles" ON user_roles;
CREATE POLICY "Allow superadmins all on user_roles"
  ON user_roles FOR ALL
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

-- 4. Fix canteens policies for superadmin INSERT
--    Same issue: ensure WITH CHECK is present for INSERT operations.

DROP POLICY IF EXISTS "Allow all for superadmins on canteens" ON canteens;
CREATE POLICY "Allow all for superadmins on canteens"
  ON canteens FOR ALL
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

DROP POLICY IF EXISTS "Allow all for superadmins" ON canteens;
CREATE POLICY "Allow all for superadmins"
  ON canteens FOR ALL
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

-- 5. Fix profiles policies for superadmin UPDATE
DROP POLICY IF EXISTS "Allow all for superadmins" ON profiles;
CREATE POLICY "Allow all for superadmins"
  ON profiles FOR ALL
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));
