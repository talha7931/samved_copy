import 'dart:convert';
import 'dart:io';

import 'package:supabase/supabase.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/list_citizen_tickets.dart <citizenAuthUserId>',
    );
    exit(64);
  }

  final citizenId = args[0];

  final env =
      jsonDecode(File('dart_define.json').readAsStringSync()) as Map<String, dynamic>;
  final supabaseUrl = env['SUPABASE_URL'] as String;
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] as String;

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  final auth = await client.auth.signInWithPassword(
    email: 'superadmin@ssr.demo',
    password: 'Demo@SSR2025',
  );

  if (auth.session == null) {
    stderr.writeln('Could not sign in as superadmin.');
    exit(65);
  }

  final rows = await client
      .from('tickets')
      .select(
        'id,ticket_ref,status,zone_id,prabhag_id,assigned_je,citizen_id,citizen_phone,damage_type,ai_confidence,epdo_score,severity_tier,photo_before,created_at,address_text',
      )
      .eq('citizen_id', citizenId)
      .order('created_at', ascending: false)
      .limit(10);

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(rows));
}
