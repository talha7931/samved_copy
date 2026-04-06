-- ============================================================
-- Storage: create buckets (if missing) + RLS on storage.objects
-- Fixes citizen upload 403: "new row violates row-level security policy"
-- App paths: ticket-photos/before/{uid}_..., after-photos/after/{uid}_...,
--            je-inspection/inspection/{uid}_...
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES
  ('ticket-photos', 'ticket-photos', true),
  ('after-photos', 'after-photos', true),
  ('je-inspection', 'je-inspection', false)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- ticket-photos (public read)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS ssr_ticket_photos_select_public ON storage.objects;
CREATE POLICY ssr_ticket_photos_select_public
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'ticket-photos');

DROP POLICY IF EXISTS ssr_ticket_photos_insert_own ON storage.objects;
CREATE POLICY ssr_ticket_photos_insert_own
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'ticket-photos'
    AND split_part(name, '/', 1) = 'before'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
  );

DROP POLICY IF EXISTS ssr_ticket_photos_update_own ON storage.objects;
CREATE POLICY ssr_ticket_photos_update_own
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'ticket-photos'
    AND split_part(name, '/', 1) = 'before'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
  )
  WITH CHECK (
    bucket_id = 'ticket-photos'
    AND split_part(name, '/', 1) = 'before'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
  );

DROP POLICY IF EXISTS ssr_ticket_photos_delete_own ON storage.objects;
CREATE POLICY ssr_ticket_photos_delete_own
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'ticket-photos'
    AND split_part(name, '/', 1) = 'before'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
  );

-- ---------------------------------------------------------------------------
-- after-photos (public read) — mukadam / contractor execution proof
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS ssr_after_photos_select_public ON storage.objects;
CREATE POLICY ssr_after_photos_select_public
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'after-photos');

DROP POLICY IF EXISTS ssr_after_photos_insert_own ON storage.objects;
CREATE POLICY ssr_after_photos_insert_own
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'after-photos'
    AND split_part(name, '/', 1) = 'after'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
  );

DROP POLICY IF EXISTS ssr_after_photos_update_own ON storage.objects;
CREATE POLICY ssr_after_photos_update_own
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'after-photos'
    AND split_part(name, '/', 1) = 'after'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
  )
  WITH CHECK (
    bucket_id = 'after-photos'
    AND split_part(name, '/', 1) = 'after'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
  );

DROP POLICY IF EXISTS ssr_after_photos_delete_own ON storage.objects;
CREATE POLICY ssr_after_photos_delete_own
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'after-photos'
    AND split_part(name, '/', 1) = 'after'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
  );

-- ---------------------------------------------------------------------------
-- je-inspection (private) — JE uploads only; read for authenticated staff
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS ssr_je_inspection_insert_je ON storage.objects;
CREATE POLICY ssr_je_inspection_insert_je
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'je-inspection'
    AND split_part(name, '/', 1) = 'inspection'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'je'::public.user_role
    )
  );

DROP POLICY IF EXISTS ssr_je_inspection_select_authenticated ON storage.objects;
CREATE POLICY ssr_je_inspection_select_authenticated
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'je-inspection'
    AND (
      starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
      OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.role IN (
            'je'::public.user_role,
            'ae'::public.user_role,
            'de'::public.user_role,
            'ee'::public.user_role,
            'assistant_commissioner'::public.user_role,
            'city_engineer'::public.user_role,
            'commissioner'::public.user_role,
            'standing_committee'::public.user_role,
            'super_admin'::public.user_role
          )
      )
    )
  );

DROP POLICY IF EXISTS ssr_je_inspection_update_own_je ON storage.objects;
CREATE POLICY ssr_je_inspection_update_own_je
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'je-inspection'
    AND split_part(name, '/', 1) = 'inspection'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'je'::public.user_role
    )
  )
  WITH CHECK (
    bucket_id = 'je-inspection'
    AND split_part(name, '/', 1) = 'inspection'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
  );

DROP POLICY IF EXISTS ssr_je_inspection_delete_own_je ON storage.objects;
CREATE POLICY ssr_je_inspection_delete_own_je
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'je-inspection'
    AND split_part(name, '/', 1) = 'inspection'
    AND starts_with(split_part(name, '/', 2), auth.uid()::text || '_')
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'je'::public.user_role
    )
  );
