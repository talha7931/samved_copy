-- ============================================================
-- New auth users (phone OTP, etc.) get a public.profiles row
-- with role = citizen so the mobile app never hits "no profile".
--
-- Staff accounts created in the Dashboard still get this row first;
-- super_admin (or SQL) must set role / zone_id / employee fields afterward.
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_name TEXT;
  v_phone TEXT;
BEGIN
  v_phone := NULLIF(TRIM(NEW.phone), '');
  v_name := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'full_name', '')), '');
  IF v_name IS NULL THEN
    v_name := COALESCE(v_phone, 'Citizen');
  END IF;

  INSERT INTO public.profiles (id, full_name, phone, role)
  VALUES (
    NEW.id,
    v_name,
    v_phone,
    'citizen'::public.user_role
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_auth_user() IS
  'After INSERT on auth.users, ensures a profiles row exists (default citizen) for mobile/web RBAC.';

REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_auth_user();

-- One-time backfill: users who already signed up before this trigger existed
INSERT INTO public.profiles (id, full_name, phone, role)
SELECT
  u.id,
  COALESCE(
    NULLIF(TRIM(COALESCE(u.raw_user_meta_data->>'full_name', '')), ''),
    NULLIF(TRIM(u.phone), ''),
    'Citizen'
  ),
  NULLIF(TRIM(u.phone), ''),
  'citizen'::public.user_role
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;
