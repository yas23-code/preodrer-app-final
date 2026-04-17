-- =============================================================================
-- Enable realtime replication for the orders table
-- =============================================================================

-- Add the orders table to the supabase_realtime publication
-- This enables Postgres to stream INSERT/UPDATE/DELETE events to the Realtime server
DO $$
BEGIN
  -- We use an exception block to avoid failing if the table is already in the publication
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  EXCEPTION WHEN OTHERS THEN
    -- Ignore if already added or publication does not exist
  END;
END
$$;
