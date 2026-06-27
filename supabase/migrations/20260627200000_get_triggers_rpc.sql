-- ============================================================
-- RPC to retrieve triggers for debugging
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

CREATE OR REPLACE FUNCTION get_triggers(table_name text)
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT json_agg(row_to_json(t)) INTO result
  FROM pg_trigger t
  JOIN pg_class c ON t.tgrelid = c.oid
  WHERE c.relname = table_name;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
