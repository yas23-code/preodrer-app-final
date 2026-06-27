-- Create temporary function to read all user_roles bypassing RLS
CREATE OR REPLACE FUNCTION public.check_user_roles()
RETURNS TABLE (user_id uuid, role public.app_role) AS $$
BEGIN
  RETURN QUERY SELECT ur.user_id, ur.role FROM public.user_roles ur;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
