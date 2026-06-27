-- ============================================================
-- Test: Drop all policies except the insert policy to verify interference
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

DROP POLICY IF EXISTS "Allow all for superadmins" ON canteen_registrations;
DROP POLICY IF EXISTS "Allow select for owner" ON canteen_registrations;
