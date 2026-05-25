import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../main.dart';

class StorageService {
  static const String _venuesBucket = 'venues';
  static const String _reviewsBucket = 'reviews';
  static const String _avatarsBucket = 'avatars';

  // Upload foto venue
  Future<String> uploadVenueImage(File imageFile) async {
    return await _uploadImage(imageFile, _venuesBucket, 'venue_');
  }

  // Upload foto review
  Future<String> uploadReviewImage(File imageFile) async {
    return await _uploadImage(imageFile, _reviewsBucket, 'review_');
  }

  // Upload avatar user
  Future<String> uploadAvatar(File imageFile) async {
    final userId = supabase.auth.currentUser?.id ?? 'unknown';
    return await _uploadImage(imageFile, _avatarsBucket, 'avatar_${userId}_');
  }

  // Generic upload
  Future<String> _uploadImage(
    File imageFile,
    String bucket,
    String prefix,
  ) async {
    const uuid = Uuid();
    final ext = path.extension(imageFile.path);
    final fileName = '$prefix${uuid.v4()}$ext';

    await supabase.storage
        .from(bucket)
        .upload(
          fileName,
          imageFile,
          fileOptions: FileOptions(cacheControl: '3600', upsert: true),
        );

    final publicUrl = supabase.storage.from(bucket).getPublicUrl(fileName);

    return publicUrl;
  }

  // Hapus gambar dari storage
  Future<void> deleteImage(String imageUrl, String bucket) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathParts = uri.pathSegments;
      // Path setelah nama bucket
      final bucketIndex = pathParts.indexOf(bucket);
      if (bucketIndex != -1 && bucketIndex < pathParts.length - 1) {
        final fileName = pathParts.sublist(bucketIndex + 1).join('/');
        await supabase.storage.from(bucket).remove([fileName]);
      }
    } catch (e) {
      // Abaikan error penghapusan
    }
  }
}
