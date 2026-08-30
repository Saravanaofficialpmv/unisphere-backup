import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/gallery_photo_model.dart';
import 'package:unisphere/models/photo_album_model.dart';
import 'package:unisphere/providers/gallery_provider.dart';
import 'package:unisphere/widgets/common/latest_photo_gallery_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LatestPhotoGalleryCard Widget Tests', () {
    testWidgets('1. Renders clean filled photo card with fallback when empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentPublishedAlbumsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LatestPhotoGalleryCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check filled image is rendered with BoxFit.cover
      final filledImageFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.fit == BoxFit.cover,
      );
      expect(filledImageFinder, findsOneWidget);
    });

    testWidgets('2. Displays only the latest uploaded album with filled image (BoxFit.cover) and no text overlays', (WidgetTester tester) async {
      final now = DateTime.now();
      final olderAlbum = PhotoAlbumModel(
        albumId: 'album-old',
        title: 'Older Symposium 2025',
        description: 'Old Symposium',
        eventDate: now.subtract(const Duration(days: 30)),
        departmentId: 'DEP-CSE',
        departmentName: 'Computer Science & Engineering',
        coverPhotoUrl: 'https://example.com/old_cover.jpg',
        status: AlbumStatus.published,
        createdBy: 'HOD-CSE-01',
        createdByName: 'Dr. Old Head',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
        publishedAt: now.subtract(const Duration(days: 30)),
      );

      final newestAlbum = PhotoAlbumModel(
        albumId: 'album-new',
        title: 'National AI Hackathon 2026',
        description: 'Latest Hackathon Winners',
        eventDate: now.subtract(const Duration(hours: 2)),
        departmentId: 'DEP-CSE',
        departmentName: 'Computer Science & Engineering',
        coverPhotoUrl: 'https://example.com/new_cover.jpg',
        status: AlbumStatus.published,
        createdBy: 'HOD-CSE-01',
        createdByName: 'Dr. Suresh Kumar (HOD)',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        publishedAt: now.subtract(const Duration(hours: 2)),
      );

      final newestPhotos = [
        GalleryPhotoModel(
          photoId: 'p1',
          albumId: 'album-new',
          photoUrl: 'https://example.com/hackathon_winners.jpg',
          caption: 'Hackathon Grand Prize Distribution',
          uploadedBy: 'HOD-CSE-01',
          uploadedAt: now.subtract(const Duration(hours: 2)),
          displayOrder: 0,
        ),
        GalleryPhotoModel(
          photoId: 'p2',
          albumId: 'album-new',
          photoUrl: 'https://example.com/hackathon_team.jpg',
          caption: 'Team Presentation on Stage',
          uploadedBy: 'HOD-CSE-01',
          uploadedAt: now.subtract(const Duration(hours: 2)),
          displayOrder: 1,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentPublishedAlbumsProvider.overrideWith((ref) => Stream.value([newestAlbum, olderAlbum])),
            albumPhotosProvider('album-new').overrideWith((ref) => Stream.value(newestPhotos)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LatestPhotoGalleryCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify image uses BoxFit.cover (completely filled, zero space)
      final filledImageFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.fit == BoxFit.cover,
      );
      expect(filledImageFinder, findsOneWidget);

      // Verify no text overlays remain
      expect(find.text('Advisor & HOD Updates'), findsNothing);
      expect(find.text('View Details'), findsNothing);
    });
  });
}
