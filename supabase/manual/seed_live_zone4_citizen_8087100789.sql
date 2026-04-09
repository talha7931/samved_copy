-- Live citizen test ticket for phone 8087100789 in Zone 4.
-- Fill the uploaded public image URL before executing.

INSERT INTO public.tickets (
  citizen_id,
  citizen_phone,
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
  'deea009f-21ee-4ade-9a05-329df420094b',
  '8087100789',
  'app',
  17.6720,
  75.9300,
  ST_GeogFromText('SRID=4326;POINT(75.9300000 17.6720000)'),
  ARRAY['__PUBLIC_IMAGE_URL__'],
  'Majrewadi corridor near Solapur-Bijapur Road (citizen live test)',
  'Majrewadi Naka',
  'pothole',
  1
)
RETURNING
  id,
  ticket_ref,
  status,
  zone_id,
  prabhag_id,
  assigned_je,
  citizen_id,
  citizen_phone,
  photo_before,
  created_at;
