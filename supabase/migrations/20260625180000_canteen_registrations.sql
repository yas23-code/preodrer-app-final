-- ============================================================
-- Canteen Registrations Table — for holding shop signups
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- Ensure the app_role enum has the 'superadmin' value
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'superadmin';

CREATE TABLE IF NOT EXISTS canteen_registrations (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  owner_name       TEXT NOT NULL,
  canteen_name     TEXT NOT NULL,
  email            TEXT NOT NULL UNIQUE,
  phone            TEXT NOT NULL,
  location         TEXT NOT NULL,
  status           TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  rejection_reason TEXT,
  created_at       TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for pending registrations and search
CREATE INDEX IF NOT EXISTS idx_canteen_registrations_status ON canteen_registrations(status);
CREATE INDEX IF NOT EXISTS idx_canteen_registrations_email ON canteen_registrations(email);

-- Enable RLS
ALTER TABLE canteen_registrations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert for canteen_registrations" ON canteen_registrations;
DROP POLICY IF EXISTS "Allow select for owner" ON canteen_registrations;
DROP POLICY IF EXISTS "Allow all for superadmins" ON canteen_registrations;

-- Allow anyone to sign up / submit a registration
CREATE POLICY "Allow public insert for canteen_registrations"
  ON canteen_registrations FOR INSERT
  WITH CHECK (true);

-- Allow users to view their own registration
CREATE POLICY "Allow select for owner"
  ON canteen_registrations FOR SELECT
  USING (auth.uid() = user_id);

-- Allow superadmins to do everything
CREATE POLICY "Allow all for superadmins"
  ON canteen_registrations FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'superadmin'
    )
  );
