-- Allow JE to read contractor company rows for their zone so the mobile app
-- can populate the private-contractor executor picker (profiles alone is not enough
-- because contractor profiles are not exposed by profiles_select_zone).

CREATE POLICY contractors_je_zone_read ON public.contractors
  FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'je'
    AND (SELECT zone_id FROM public.profiles WHERE id = auth.uid()) IS NOT NULL
    AND (SELECT zone_id FROM public.profiles WHERE id = auth.uid()) = ANY (zone_ids)
  );
