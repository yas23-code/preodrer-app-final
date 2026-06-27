-- ============================================================
-- Complete production RLS policies using SECURITY DEFINER function
-- to avoid infinite recursion on user_roles
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Create SECURITY DEFINER function to check superadmin status (bypasses RLS recursion)
CREATE OR REPLACE FUNCTION public.is_superadmin(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_roles.user_id = $1
    AND user_roles.role = 'superadmin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Policies for canteen_registrations
DROP POLICY IF EXISTS "Allow public insert for canteen_registrations" ON canteen_registrations;
CREATE POLICY "Allow public insert for canteen_registrations"
  ON canteen_registrations FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow select for owner" ON canteen_registrations;
CREATE POLICY "Allow select for owner"
  ON canteen_registrations FOR SELECT
  USING (auth.uid() = user_id OR public.is_superadmin(auth.uid()));

DROP POLICY IF EXISTS "Allow all for superadmins" ON canteen_registrations;
CREATE POLICY "Allow all for superadmins"
  ON canteen_registrations FOR ALL
  USING (public.is_superadmin(auth.uid()));

-- 3. Policies for user_roles
DROP POLICY IF EXISTS "Allow users to upsert own role" ON user_roles;
CREATE POLICY "Allow users to upsert own role"
  ON user_roles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow users to read own role" ON user_roles;
CREATE POLICY "Allow users to read own role"
  ON user_roles FOR SELECT
  USING (auth.uid() = user_id OR public.is_superadmin(auth.uid()));

DROP POLICY IF EXISTS "Allow superadmins all on user_roles" ON user_roles;
CREATE POLICY "Allow superadmins all on user_roles"
  ON user_roles FOR ALL
  USING (public.is_superadmin(auth.uid()));

-- 4. Policies for canteens
DROP POLICY IF EXISTS "Allow all for superadmins on canteens" ON canteens;
CREATE POLICY "Allow all for superadmins on canteens"
  ON canteens FOR ALL
  USING (public.is_superadmin(auth.uid()));
