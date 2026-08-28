import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Photo Upload & Storage Security Tests', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
    });

    test('StorageService.deleteFile safely ignores local filesystem paths', () async {
      // Local simulator/device paths must never be treated as Storage paths
      expect(await storageService.deleteFile('/Users/saravana/tmp/photo.jpg'), false);
      expect(await storageService.deleteFile('/tmp/image_picker_123.jpg'), false);
      expect(await storageService.deleteFile('file:///private/var/mobile/Containers/photo.jpg'), false);
      expect(await storageService.deleteFile('/data/user/0/com.unisphere.app/cache/photo.jpg'), false);
      expect(await storageService.deleteFile(''), false);
    });

    test('StorageService.uploadProfilePhoto throws descriptive error when file is missing', () async {
      final nonExistentFile = File('/tmp/non_existent_profile_test_123.jpg');
      expect(
        () => storageService.uploadProfilePhoto(
          userId: 'test-user-123',
          file: nonExistentFile,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('UserModel preserves valid remote HTTPS photoUrl and profileImageUrl', () {
      final user = UserModel(
        uid: 'STU-001',
        email: 'student@unisphere.edu',
        fullName: 'Alex Johnson',
        role: UserRole.student,
        profileImageUrl: 'https://firebasestorage.googleapis.com/v0/b/unisphere.appspot.com/o/profile_photos%2FSTU-001%2Fprofile_123.jpg?alt=media',
        metadata: {
          'photoUrl': 'https://firebasestorage.googleapis.com/v0/b/unisphere.appspot.com/o/profile_photos%2FSTU-001%2Fprofile_123.jpg?alt=media',
          'passportPhotoUrl': 'https://firebasestorage.googleapis.com/v0/b/unisphere.appspot.com/o/profile_photos%2FSTU-001%2Fprofile_123.jpg?alt=media',
        },
      );

      final map = user.toMap();
      expect(map['profileImageUrl'], startsWith('https://firebasestorage.googleapis.com'));
      expect(map['metadata']['photoUrl'], startsWith('https://firebasestorage.googleapis.com'));

      final restored = UserModel.fromMap(map, 'STU-001');
      expect(restored.profileImageUrl, startsWith('https://firebasestorage.googleapis.com'));
    });

    test('URL sanitization logic identifies and differentiates valid remote URLs from local simulator paths', () {
      bool isRemoteUrl(String? url) {
        if (url == null || url.trim().isEmpty) return false;
        final clean = url.trim();
        return clean.startsWith('http://') || clean.startsWith('https://');
      }

      // Valid remote URLs
      expect(isRemoteUrl('https://firebasestorage.googleapis.com/v0/b/unisphere/profile.jpg'), true);
      expect(isRemoteUrl('http://example.com/photo.png'), true);

      // Invalid local paths
      expect(isRemoteUrl('/Users/saravana/Library/Developer/CoreSimulator/image_picker_123.jpg'), false);
      expect(isRemoteUrl('/tmp/image_picker_456.jpg'), false);
      expect(isRemoteUrl('file:///data/user/0/app/cache/photo.jpg'), false);
      expect(isRemoteUrl(''), false);
      expect(isRemoteUrl(null), false);
    });

    test('UserModel.copyWith clears profileImageUrl cleanly upon photo removal', () {
      final original = UserModel(
        uid: 'PRT-001',
        email: 'parent@unisphere.edu',
        fullName: 'John Doe',
        role: UserRole.parent,
        profileImageUrl: 'https://firebasestorage.googleapis.com/v0/b/unisphere/photo.jpg',
      );

      final cleared = original.copyWith(profileImageUrl: '');
      expect(cleared.profileImageUrl, '');
    });
  });
}
