import 'package:flutter/foundation.dart';

/// Release/pilot: pass via `--dart-define=SUPABASE_URL=...` and `SUPABASE_ANON_KEY=...`.
/// Optional: `WEB_DASHBOARD_URL=https://your-dashboard.example`.
///
/// **Local convenience:** copy `dart_define.example.json` to `dart_define.json` (gitignored)
/// and run:
/// `flutter run --dart-define-from-file=dart_define.json`
/// Same for release: `flutter build apk --release --dart-define-from-file=dart_define.json`
///
/// Use the **anon public** JWT only — never the service_role key in the app.
///
/// Do not use `https://example.supabase.co` or other tutorial placeholders — they are
/// rejected so you get this screen instead of a DNS error on "Send OTP".
class AppEnv {
  AppEnv._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String webDashboardUrl = String.fromEnvironment(
    'WEB_DASHBOARD_URL',
    defaultValue: 'http://localhost:3000',
  );

  static bool _isPlaceholderSupabaseUrl(String url) {
    final u = url.toLowerCase().trim();
    if (u.isEmpty) return true;
    if (u.contains('example.supabase.co')) return true;
    if (u.contains('your_project.supabase.co')) return true;
    if (u.contains('placeholder')) return true;
    return false;
  }

  static bool _isPlaceholderAnonKey(String key) {
    final k = key.trim();
    if (k.isEmpty) return true;
    final lower = k.toLowerCase();
    if (lower.contains('your_anon') || lower == 'anon' || lower == 'key') {
      return true;
    }
    // Real Supabase anon keys are JWT strings, almost always 150+ chars.
    if (k.length < 120) return true;
    return false;
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !_isPlaceholderSupabaseUrl(supabaseUrl) &&
      !_isPlaceholderAnonKey(supabaseAnonKey);

  static String get configError {
    final urlBad = supabaseUrl.isNotEmpty &&
        (_isPlaceholderSupabaseUrl(supabaseUrl) || !supabaseUrl.startsWith('https://'));
    final keyBad = supabaseAnonKey.isNotEmpty && _isPlaceholderAnonKey(supabaseAnonKey);

    if (urlBad) {
      return 'Invalid Supabase URL. You are using a placeholder host (e.g. example.supabase.co), '
          'which does not exist.\n\n'
          'Use your real project URL from the Supabase dashboard (Settings → API), '
          'for example https://abcdefghij.supabase.co\n\n'
          'Rebuild the APK or run:\n'
          'flutter run --dart-define=SUPABASE_URL=https://YOUR_REAL_REF.supabase.co '
          '--dart-define=SUPABASE_ANON_KEY=...';
    }
    if (keyBad) {
      return 'Invalid Supabase anon key. Use the long "anon public" JWT from '
          'Supabase (Settings → API), not a short placeholder.\n\n'
          'flutter build apk --release '
          '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...';
    }
    if (kReleaseMode) {
      return 'Missing build configuration. Rebuild with:\n'
          'flutter build apk --release '
          '--dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co '
          '--dart-define=SUPABASE_ANON_KEY=YOUR_LONG_ANON_JWT';
    }
    return 'Missing Supabase config. Run with:\n'
        'flutter run '
        '--dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co '
        '--dart-define=SUPABASE_ANON_KEY=YOUR_LONG_ANON_JWT';
  }
}
