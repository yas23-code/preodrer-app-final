CREATE OR REPLACE FUNCTION public.register_device_token(p_token TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete this token if it is already registered to ANY user
  -- Security definer allows this function to bypass RLS and clean up the old record
  DELETE FROM public.user_device_tokens WHERE fcm_token = p_token;
  
  -- Insert the token for the currently authenticated user
  INSERT INTO public.user_device_tokens (user_id, fcm_token)
  VALUES (auth.uid(), p_token);
END;
$$;
