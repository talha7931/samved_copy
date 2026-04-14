import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase/supabase.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/seed_zone4_citizen_ticket.dart <citizenAuthUserId> <imagePathOrPublicUrl> [citizenPhone]',
    );
    exit(64);
  }

  final citizenId = args[0];
  final imagePathOrUrl = args[1];
  final citizenPhone = args.length >= 3 ? args[2] : '8087100789';
  final serviceRoleKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

  final envFile = File('dart_define.json');
  if (!envFile.existsSync()) {
    stderr.writeln('Missing dart_define.json in project root.');
    exit(65);
  }

  final env =
      jsonDecode(envFile.readAsStringSync()) as Map<String, dynamic>;
  final supabaseUrl = env['SUPABASE_URL'] as String?;
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] as String?;
  if (supabaseUrl == null || supabaseAnonKey == null) {
    stderr.writeln('dart_define.json is missing SUPABASE_URL or SUPABASE_ANON_KEY');
    exit(66);
  }

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  final auth = await client.auth.signInWithPassword(
    email: 'superadmin@ssr.demo',
    password: 'Demo@SSR2025',
  );

  if (auth.session == null) {
    stderr.writeln('Could not sign in as superadmin.');
    exit(67);
  }

  late final String publicUrl;
  if (imagePathOrUrl.startsWith('http://') || imagePathOrUrl.startsWith('https://')) {
    publicUrl = imagePathOrUrl;
  } else {
    final imageFile = File(imagePathOrUrl);
    if (!imageFile.existsSync()) {
      stderr.writeln('Image not found: $imagePathOrUrl');
      exit(68);
    }

    final bytes = Uint8List.fromList(imageFile.readAsBytesSync());
    final storagePath =
        'before/manual-zone4-$citizenPhone-${DateTime.now().millisecondsSinceEpoch}.jpg';

    await client.storage.from('ticket-photos').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    publicUrl = client.storage.from('ticket-photos').getPublicUrl(storagePath);
  }

  final inserted = await client
      .from('tickets')
      .insert({
        'citizen_id': citizenId,
        'citizen_phone': citizenPhone,
        'source_channel': 'app',
        'latitude': 17.6720,
        'longitude': 75.9300,
        'location': 'SRID=4326;POINT(75.9300000 17.6720000)',
        'photo_before': [publicUrl],
        'address_text':
            'Majrewadi corridor near Solapur-Bijapur Road (citizen live test)',
        'nearest_landmark': 'Majrewadi Naka',
        'damage_type': 'pothole',
        'department_id': 1,
      })
      .select(
        'id,ticket_ref,status,zone_id,prabhag_id,assigned_je,citizen_id,citizen_phone,photo_before,created_at',
      )
      .single();

  final ticketId = inserted['id'] as String;

  Map<String, dynamic>? detectData;
  Map<String, dynamic>? severityData;
  String? functionWarning;

  if (serviceRoleKey == null || serviceRoleKey.isEmpty) {
    functionWarning =
        'SUPABASE_SERVICE_ROLE_KEY not provided; skipped Edge Function calls.';
  } else {
    try {
      detectData = await _invokeEdgeFunction(
        supabaseUrl,
        serviceRoleKey,
        'detect-road-damage',
        {'ticket_id': ticketId},
      );
      severityData = await _invokeEdgeFunction(
        supabaseUrl,
        serviceRoleKey,
        'score-severity',
        {'ticket_id': ticketId},
      );
    } catch (error) {
      functionWarning = error.toString();
    }
  }

  final finalTicket = await client
      .from('tickets')
      .select(
        'id,ticket_ref,status,zone_id,prabhag_id,assigned_je,citizen_id,citizen_phone,damage_type,ai_confidence,total_potholes,ai_bounding_boxes,ai_severity_index,ai_source,epdo_score,severity_tier,photo_before,created_at',
      )
      .eq('id', ticketId)
      .single();

  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'uploaded_before_photo': publicUrl,
      'inserted_ticket': inserted,
      'detect_response': detectData,
      'severity_response': severityData,
      'function_warning': functionWarning,
      'final_ticket': finalTicket,
    }),
  );
}

Future<Map<String, dynamic>> _invokeEdgeFunction(
  String supabaseUrl,
  String serviceRoleKey,
  String functionName,
  Map<String, dynamic> body,
) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/functions/v1/$functionName'),
    );
    request.headers.set('apikey', serviceRoleKey);
    request.headers.set('Authorization', 'Bearer $serviceRoleKey');
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close();
    final raw = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Edge Function $functionName failed: ${response.statusCode} $raw',
      );
    }
    final decoded = jsonDecode(raw);
    return Map<String, dynamic>.from(decoded as Map);
  } finally {
    client.close(force: true);
  }
}
