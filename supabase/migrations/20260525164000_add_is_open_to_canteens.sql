-- Add is_open column to canteens table
ALTER TABLE public.canteens ADD COLUMN IF NOT EXISTS is_open BOOLEAN DEFAULT true;
