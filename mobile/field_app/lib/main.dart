import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppEnv.isConfigured) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                AppEnv.configError,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: RoadNirmanApp(),
    ),
  );
}
