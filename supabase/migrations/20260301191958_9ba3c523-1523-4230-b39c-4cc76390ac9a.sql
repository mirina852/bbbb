
-- Function to check if registration is allowed (no users exist yet)
CREATE OR REPLACE FUNCTION public.is_registration_allowed()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT EXISTS (SELECT 1 FROM auth.users LIMIT 1);
$$;
