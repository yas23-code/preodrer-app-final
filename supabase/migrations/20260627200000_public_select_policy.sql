-- ============================================================
-- Fix: Create wide-open SELECT policy on canteen_registrations
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

DROP POLICY IF EXISTS "Allow select for owner" ON canteen_registrations;
DROP POLICY IF EXISTS "Allow public select for canteen_registrations" ON canteen_registrations;

CREATE POLICY "Allow public select for canteen_registrations"
  ON canteen_registrations FOR SELECT
  USING (true);
