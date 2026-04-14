-- Trusted test seeding path for Edge Function.
-- Inserts one ticket row with Solapur test coordinates/defaults while bypassing
-- strict tickets RLS through SECURITY DEFINER.

CREATE OR REPLACE FUNCTION public.fn_seed_test_ticket(
  p_citizen_id uuid,
  p_citizen_phone text,
  p_citizen_name text,
  p_source_channel text,
  p_lat double precision,
  p_lng double precision,
  p_image_url text,
  p_address_text text,
  p_nearest_landmark text,
  p_damage_type text,
  p_department_id integer
)
RETURNS TABLE (
  id uuid,
  ticket_ref text,
  status public.ticket_status,
  zone_id integer,
  prabhag_id integer,
  assigned_je uuid,
  citizen_id uuid,
  citizen_phone character varying,
  photo_before text[],
  created_at timestamptz,
  address_text text,
  source_channel text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_location geography(point, 4326);
BEGIN
  IF p_citizen_id IS NULL THEN
    RAISE EXCEPTION 'p_citizen_id is required';
  END IF;
  IF p_citizen_phone IS NULL OR btrim(p_citizen_phone) = '' THEN
    RAISE EXCEPTION 'p_citizen_phone is required';
  END IF;
  IF p_image_url IS NULL OR btrim(p_image_url) = '' THEN
    RAISE EXCEPTION 'p_image_url is required';
  END IF;
  IF p_lat IS NULL OR p_lng IS NULL THEN
    RAISE EXCEPTION 'p_lat and p_lng are required';
  END IF;

  v_location := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;

  RETURN QUERY
  INSERT INTO public.tickets (
    citizen_id,
    citizen_phone,
    citizen_name,
    source_channel,
    latitude,
    longitude,
    location,
    photo_before,
    address_text,
    nearest_landmark,
    damage_type,
    department_id
  )
  VALUES (
    p_citizen_id,
    p_citizen_phone,
    NULLIF(btrim(COALESCE(p_citizen_name, '')), ''),
    COALESCE(NULLIF(btrim(COALESCE(p_source_channel, '')), ''), 'app'),
    p_lat,
    p_lng,
    v_location,
    ARRAY[p_image_url],
    COALESCE(
      NULLIF(btrim(COALESCE(p_address_text, '')), ''),
      'Majrewadi corridor near Solapur-Bijapur Road (citizen live test)'
    ),
    COALESCE(
      NULLIF(btrim(COALESCE(p_nearest_landmark, '')), ''),
      'Majrewadi Naka'
    ),
    COALESCE(NULLIF(btrim(COALESCE(p_damage_type, '')), ''), 'pothole'),
    COALESCE(p_department_id, 1)
  )
  RETURNING
    tickets.id,
    tickets.ticket_ref,
    tickets.status,
    tickets.zone_id,
    tickets.prabhag_id,
    tickets.assigned_je,
    tickets.citizen_id,
    tickets.citizen_phone,
    tickets.photo_before,
    tickets.created_at,
    tickets.address_text,
    tickets.source_channel;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_seed_test_ticket(
  uuid, text, text, text, double precision, double precision, text, text, text, text, integer
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.fn_seed_test_ticket(
  uuid, text, text, text, double precision, double precision, text, text, text, text, integer
) TO service_role;

COMMENT ON FUNCTION public.fn_seed_test_ticket(
  uuid, text, text, text, double precision, double precision, text, text, text, text, integer
) IS
  'Trusted SECURITY DEFINER path for seed-test-ticket edge function to insert test tickets under strict RLS.';
