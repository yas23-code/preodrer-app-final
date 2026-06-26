-- ============================================================
-- Search Module columns and policies
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Add columns to public.profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS banned BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS student_id TEXT;

-- 2. Add columns to public.canteens table
ALTER TABLE public.canteens ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.canteens ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.canteens ADD COLUMN IF NOT EXISTS banned BOOLEAN DEFAULT FALSE NOT NULL;

-- 3. Sync existing profiles email/phone from auth.users (if possible)
UPDATE public.profiles p
SET 
  email = u.email,
  phone = u.phone,
  student_id = 'STU' || substring(p.id::text from 1 for 6)
FROM auth.users u
WHERE p.id = u.id AND p.email IS NULL;

-- 4. Sync existing canteens email/phone from vendor profiles (if possible)
UPDATE public.canteens c
SET
  email = p.email,
  phone = p.phone
FROM public.profiles p
WHERE c.vendor_id = p.id AND c.email IS NULL;

-- 5. Add default student_id values for any profiles missing them
UPDATE public.profiles
SET student_id = 'STU' || substring(id::text from 1 for 6)
WHERE role = 'student' AND student_id IS NULL;

-- 6. Add default email/phone dummy values if still null for testing
UPDATE public.profiles
SET 
  email = COALESCE(email, name || '@gmail.com'),
  phone = COALESCE(phone, '9876543210')
WHERE email IS NULL OR phone IS NULL;

UPDATE public.canteens
SET 
  email = COALESCE(email, 'canteen_' || name || '@gmail.com'),
  phone = COALESCE(phone, '9876543211')
WHERE email IS NULL OR phone IS NULL;

-- 7. Enable RLS and add superadmin policies for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for superadmins" ON public.profiles;
CREATE POLICY "Allow all for superadmins"
  ON public.profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'superadmin'
    )
  );

-- 8. Enable RLS and add superadmin policies for canteens
ALTER TABLE public.canteens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for superadmins" ON public.canteens;
CREATE POLICY "Allow all for superadmins"
  ON public.canteens FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'superadmin'
    )
  );
