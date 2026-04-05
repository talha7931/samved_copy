import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  String _ext(String fileExtension) {
    final e = fileExtension.trim();
    if (e.isEmpty) return '.jpg';
    return e.startsWith('.') ? e : '.$e';
  }

  Future<String> uploadTicketBeforePhoto({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final name =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}${_ext(fileExtension)}';
    final path = 'before/$name';
    await _client.storage.from('ticket-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('ticket-photos').getPublicUrl(path);
  }

  Future<String> uploadAfterPhoto({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final name =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}${_ext(fileExtension)}';
    final path = 'after/$name';
    await _client.storage.from('after-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('after-photos').getPublicUrl(path);
  }

  Future<String> uploadJeInspectionPhoto({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final name =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}${_ext(fileExtension)}';
    final path = 'inspection/$name';
    await _client.storage.from('je-inspection').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('je-inspection').getPublicUrl(path);
  }
}
