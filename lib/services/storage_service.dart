import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  final FirebaseStorage? _storage;

  StorageService({FirebaseStorage? storage}) : _storage = storage ?? _tryGetStorage();

  static FirebaseStorage? _tryGetStorage() {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Upload file to Firebase Storage with organized path structure
  Future<String?> uploadFile({
    required String storagePath,
    required File file,
    SettableMetadata? metadata,
  }) async {
    final storage = _storage;
    if (storage == null) return null;
    try {
      final ref = storage.ref().child(storagePath);
      final uploadTask = await ref.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('StorageService uploadFile error: $e');
      return null;
    }
  }

  /// Upload raw bytes to Firebase Storage (for web or memory images)
  Future<String?> uploadData({
    required String storagePath,
    required Uint8List data,
    String mimeType = 'image/jpeg',
  }) async {
    final storage = _storage;
    if (storage == null) return null;
    try {
      final ref = storage.ref().child(storagePath);
      final uploadTask = await ref.putData(data, SettableMetadata(contentType: mimeType));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('StorageService uploadData error: $e');
      return null;
    }
  }

  /// Standard Path Generator: Student Profile Photo
  String studentPhotoPath(String uid) => 'student-photos/$uid/profile';

  /// Standard Path Generator: Staff Profile Photo
  String staffPhotoPath(String uid) => 'staff-photos/$uid/profile';

  /// Standard Path Generator: Father Photo
  String fatherPhotoPath(String studentId) => 'parent-photos/$studentId/father';

  /// Standard Path Generator: Mother Photo
  String motherPhotoPath(String studentId) => 'parent-photos/$studentId/mother';

  /// Standard Path Generator: Certificate Storage Path
  String certificatePath(String studentId, String certificateId) => 'certificates/$studentId/$certificateId';

  /// Standard Path Generator: Hackathon Document Path
  String hackathonDocumentPath(String hackathonId, String fileName) => 'hackathons/$hackathonId/documents/$fileName';

  /// Get Download URL for a Storage Path
  Future<String?> getDownloadUrl(String path) async {
    final storage = _storage;
    if (storage == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    try {
      return await storage.ref().child(path).getDownloadURL();
    } catch (e) {
      debugPrint('StorageService getDownloadUrl error: $e');
      return null;
    }
  }

  /// Delete a file from Firebase Storage
  Future<bool> deleteFile(String path) async {
    final storage = _storage;
    if (storage == null || path.isEmpty) return false;
    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final ref = storage.refFromURL(path);
        await ref.delete();
      } else {
        final ref = storage.ref().child(path);
        await ref.delete();
      }
      return true;
    } catch (e) {
      debugPrint('StorageService deleteFile error: $e');
      return false;
    }
  }
}
