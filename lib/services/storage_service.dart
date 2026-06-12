import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../main.dart';

class StorageService {
  Future<String> uploadVenueImage(File f) => _upload(f, 'venues', 'venue_');
  Future<String> uploadReviewImage(File f) => _upload(f, 'reviews', 'review_');
  Future<String> uploadAvatar(File f) {
    final uid = supabase.auth.currentUser?.id ?? 'unknown';
    return _upload(f, 'avatars', 'avatar_${uid}_');
  }

  Future<String> _upload(File file, String bucket, String prefix) async {
    const uuid = Uuid();
    final ext = path.extension(file.path);
    final name = '$prefix${uuid.v4()}$ext';
    await supabase.storage.from(bucket).upload(
      name, file, fileOptions: FileOptions(cacheControl: '3600', upsert: true),
    );
    return supabase.storage.from(bucket).getPublicUrl(name);
  }
}
