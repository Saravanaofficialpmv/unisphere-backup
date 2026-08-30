import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/gallery_photo_model.dart';
import 'package:unisphere/models/photo_album_model.dart';
import 'package:unisphere/providers/gallery_provider.dart';
import 'package:unisphere/screens/gallery/album_details_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Modern Pure Photo Display Card (Unisphere Design System)
/// Clean, text-free visual photo card displaying the latest photo update
/// uploaded to Firebase by Class Advisors & HODs.
/// - Image is completely filled (`BoxFit.cover`), edge-to-edge with no space.
/// - Text overlays completely removed for a clean, immersive look.
/// - Smooth swipe across album photos with subtle indicator dots.
/// - Tap to view full lightbox zoom or album details.
/// ─────────────────────────────────────────────────────────────────────────────
class LatestPhotoGalleryCard extends ConsumerStatefulWidget {
  final VoidCallback? onViewAllPressed;
  final String? departmentFilter;

  const LatestPhotoGalleryCard({
    super.key,
    this.onViewAllPressed,
    this.departmentFilter,
  });

  @override
  ConsumerState<LatestPhotoGalleryCard> createState() => _LatestPhotoGalleryCardState();
}

class _LatestPhotoGalleryCardState extends ConsumerState<LatestPhotoGalleryCard> {
  int _currentPhotoIndex = 0;
  late final PageController _photoPageController;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  void _openLightbox(BuildContext context, List<GalleryPhotoModel> photos, int initialIndex, PhotoAlbumModel album) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) => LightboxViewer(
        photos: photos,
        initialIndex: initialIndex,
        albumTitle: album.title,
        departmentName: album.departmentName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentAlbumsAsync = ref.watch(recentPublishedAlbumsProvider);

    return recentAlbumsAsync.when(
      data: (albums) {
        List<PhotoAlbumModel> eligible = albums;
        if (widget.departmentFilter != null && widget.departmentFilter!.isNotEmpty) {
          eligible = albums
              .where((a) =>
                  a.departmentId == widget.departmentFilter ||
                  a.departmentName.toLowerCase().contains(widget.departmentFilter!.toLowerCase()))
              .toList();
          if (eligible.isEmpty) eligible = albums;
        }

        final latestAlbum = eligible.isNotEmpty
            ? eligible.first
            : PhotoAlbumModel(
                albumId: 'default-campus-showcase',
                title: 'Campus Highlights',
                description: 'Campus Highlights',
                eventDate: DateTime.now(),
                departmentId: 'DEP-ALL',
                departmentName: 'Campus Highlights',
                coverPhotoUrl: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=1200&q=80',
                status: AlbumStatus.published,
                createdBy: 'HOD-CSE-01',
                createdByName: 'Advisor & HOD Updates',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                publishedAt: DateTime.now(),
              );

        return _buildFilledPhotoCard(context, latestAlbum);
      },
      loading: () => Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
      ),
      error: (_, __) => _buildFilledPhotoCard(
        context,
        PhotoAlbumModel(
          albumId: 'default-campus-showcase',
          title: 'Campus Highlights',
          description: 'Campus Highlights',
          eventDate: DateTime.now(),
          departmentId: 'DEP-ALL',
          departmentName: 'Campus Highlights',
          coverPhotoUrl: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=1200&q=80',
          status: AlbumStatus.published,
          createdBy: 'HOD-CSE-01',
          createdByName: 'Advisor & HOD Updates',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          publishedAt: DateTime.now(),
        ),
      ),
    );
  }

  Widget _buildFilledPhotoCard(BuildContext context, PhotoAlbumModel album) {
    final photosAsync = ref.watch(albumPhotosProvider(album.albumId));

    return photosAsync.when(
      data: (photos) {
        final displayPhotos = photos.isNotEmpty
            ? photos
            : [
                GalleryPhotoModel(
                  photoId: 'cover-${album.albumId}',
                  albumId: album.albumId,
                  photoUrl: album.coverPhotoUrl.isNotEmpty
                      ? album.coverPhotoUrl
                      : 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=1200&q=80',
                  caption: album.title,
                  uploadedBy: album.createdBy,
                  uploadedAt: album.publishedAt ?? album.createdAt,
                  displayOrder: 0,
                ),
              ];

        final totalPhotos = displayPhotos.length;
        final safeIndex = _currentPhotoIndex.clamp(0, totalPhotos - 1);

        final stackChildren = <Widget>[
          // 1. Edge-to-Edge Filled Image (BoxFit.cover, No space / margins)
          PageView.builder(
            controller: _photoPageController,
            itemCount: displayPhotos.length,
            onPageChanged: (idx) {
              setState(() {
                _currentPhotoIndex = idx;
              });
            },
            itemBuilder: (context, idx) {
              final p = displayPhotos[idx];
              return GestureDetector(
                onTap: () => _openLightbox(context, displayPhotos, idx, album),
                child: SizedBox.expand(
                  child: Image.network(
                    p.photoUrl,
                    fit: BoxFit.cover, // COMPLETELY FILLED, ZERO SPACE
                    alignment: Alignment.center,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFF0F172A),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                  : null,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF0F172A),
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.white60, size: 36),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ];

        // 2. Minimalist Pagination Dots (if multi-photo)
        if (totalPhotos > 1) {
          stackChildren.add(
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(totalPhotos, (index) {
                          final isActive = index == safeIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 14 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: stackChildren,
            ),
          ),
        );
      },
      loading: () => Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
