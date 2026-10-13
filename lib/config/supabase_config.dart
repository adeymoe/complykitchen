/// Fill these in from your Supabase project: Settings -> API.
///
/// SUPABASE_URL looks like https://xxxxxxxxxxxx.supabase.co
/// SUPABASE_ANON_KEY is the long "anon / public" key on the same page.
///
/// The anon key is safe to ship in the app (it's what Row-Level
/// Security is designed to sit behind) - just never put the
/// "service_role" key here, that one bypasses RLS entirely.
///
/// For local testing without a live backend, the app can also run in
/// demo mode when the placeholder values are still present.
class SupabaseConfig {
  static const String url = 'https://putjkueuqhzjkysyuuxf.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB1dGprdWV1cWh6amt5c3l1dXhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0NTQ5NjEsImV4cCI6MjEwMDAzMDk2MX0.Xm5TCT3Y4qUpYSl6Vv5uCQDKep5d-xubzCUMM3dPS_o';

  static bool get isDemoMode =>
      url.contains('YOUR-PROJECT') || anonKey.contains('YOUR-ANON-KEY');
}
