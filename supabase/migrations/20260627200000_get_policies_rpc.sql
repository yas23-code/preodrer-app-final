-- ============================================================
-- RPC to retrieve RLS policies for debugging
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

CREATE OR REPLACE FUNCTION get_policies(table_name text)
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT json_agg(row_to_json(p)) INTO result
  FROM pg_policies p
  WHERE p.tablename = table_name;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
