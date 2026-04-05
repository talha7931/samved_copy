/// Matches Supabase `user_role` enum (mobile + web).
const Set<String> kMobileRoles = {
  'citizen',
  'je',
  'mukadam',
  'contractor',
};

const Set<String> kWebHandoffRoles = {
  'ae',
  'de',
  'ee',
  'assistant_commissioner',
  'city_engineer',
  'commissioner',
  'standing_committee',
  'accounts',
  'super_admin',
};

bool isMobileRole(String? role) =>
    role != null && kMobileRoles.contains(role);

bool isWebHandoffRole(String? role) =>
    role != null && kWebHandoffRoles.contains(role);
