function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const env = {
  supabaseUrl: requireEnv("SUPABASE_URL"),
  supabaseAnonKey: requireEnv("SUPABASE_ANON_KEY"),
  supabaseServiceRoleKey: requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
  aiServiceUrl: requireEnv("AI_SERVICE_URL").replace(/\/+$/, ""),
  aiServiceSecret: requireEnv("AI_SERVICE_SECRET"),
};

