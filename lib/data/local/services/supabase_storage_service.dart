import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class SupabaseStorageService {
  static final SupabaseStorageService _instance =
      SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  final _supabase = Supabase.instance.client;

  /// Uploads a file to a specific bucket and returns the public URL.
  /// [file] The File to upload.
  /// [bucket] The target bucket (e.g., 'profile_images', 'dish_images').
  /// [remotePath] The path/filename in the bucket.
  Future<String?> uploadFile({
    required File file,
    required String bucket,
    required String remotePath,
  }) async {
    try {
      if (!file.existsSync()) return null;

      await _supabase.storage
          .from(bucket)
          .upload(
            remotePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from(bucket).getPublicUrl(remotePath);
    } catch (e) {
      debugPrint('Supabase Upload Error ($bucket): $e');
      return null;
    }
  }

  /// Helper to generate a unique filename
  String generateFileName(String originalPath, String prefix) {
    final extension = path.extension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp$extension';
  }
}
