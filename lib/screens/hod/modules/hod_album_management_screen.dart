import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/photo_album_model.dart';
import 'package:unisphere/providers/gallery_provider.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/screens/gallery/album_details_screen.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/gallery_service.dart';
import 'package:unisphere/widgets/common/unisphere_header_card.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

class HodAlbumManagementScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const HodAlbumManagementScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<HodAlbumManagementScreen> createState() => _HodAlbumManagementScreenState();
}

class _HodAlbumManagementScreenState extends ConsumerState<HodAlbumManagementScreen> {
  void _openCreateAlbumSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateOrEditAlbumSheet(),
    );
  }

  void _openEditAlbumSheet(BuildContext context, PhotoAlbumModel album) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateOrEditAlbumSheet(existingAlbum: album),
    );
  }

  Future<void> _confirmDeleteAlbum(BuildContext context, PhotoAlbumModel album) async {
    final user = ref.read(authServiceProvider).currentUser;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Photo Album?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${album.title}"? All uploaded photos in this album will be permanently deleted.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && user != null) {
      final success = await ref.read(galleryServiceProvider).deleteAlbum(
            albumId: album.albumId,
            userId: user.uid,
            userName: user.fullName,
            userRole: user.role.name,
          );
      if (mounted && success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Photo album deleted successfully.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _publishAlbum(BuildContext context, PhotoAlbumModel album) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(galleryServiceProvider).publishAlbum(
          albumId: album.albumId,
          userId: user.uid,
          userName: user.fullName,
          userRole: user.role.name,
        );

    if (mounted && success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('🎉 Album "${album.title}" published to campus gallery!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dept = ref.watch(currentHodDepartmentProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final userDept = (dept?.name != null && dept!.name.isNotEmpty && dept.name != 'Computer Science & Engineering')
        ? dept.name
        : (user?.departmentName ??
            user?.department ??
            user?.metadata?['department']?.toString() ??
            'Department');

    final albumsAsync = ref.watch(departmentAlbumsProvider(userDept));
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      body: SafeArea(
        child: Column(
          children: [
            // Unisphere Signature Header Card
            UnisphereHeaderCard(
              title: 'Department Photo Albums',
              subtitle: 'Upload, Manage & Publish Event Photos',
              onBack: widget.onBack ?? (Navigator.canPop(context) ? () => Navigator.of(context).pop() : null),
              rightActions: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
                  tooltip: 'Create New Album',
                  onPressed: () => _openCreateAlbumSheet(context),
                ),
              ],
            ),

            // Main Album List
            Expanded(
              child: albumsAsync.when(
                data: (albums) {
                  if (albums.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 2),
                              ),
                              child: const Icon(Icons.collections_bookmark_outlined, size: 36, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Albums for $userDept',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Upload event photos and publish them to students & parents across the campus.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 18),
                              label: const Text('Create First Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () => _openCreateAlbumSheet(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    physics: const BouncingScrollPhysics(),
                    itemCount: albums.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return _buildHodAlbumCard(context, album, dateFormat);
                    },
                  );
                },
                loading: () => const Center(
                  child: Loader(label: 'Loading department albums...'),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading albums: $err', style: const TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: const Text('Create Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
        onPressed: () => _openCreateAlbumSheet(context),
      ),
    );
  }

  Widget _buildHodAlbumCard(BuildContext context, PhotoAlbumModel album, DateFormat dateFormat) {
    final isPublished = album.isPublished;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isPublished ? AppColors.success.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Image Banner & Status Chip
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AlbumDetailsScreen(album: album)),
              );
            },
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  album.coverPhotoUrl.isNotEmpty
                      ? Image.network(
                          album.coverPhotoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.surfaceSecondary,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surfaceSecondary,
                            child: const Icon(Icons.collections_outlined, color: AppColors.textTertiary, size: 48),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceSecondary,
                          child: const Icon(Icons.collections_outlined, color: AppColors.textTertiary, size: 48),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPublished ? AppColors.success : AppColors.warning,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isPublished ? AppColors.success : AppColors.warning).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        isPublished ? '● PUBLISHED' : '● DRAFT',
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Text(
                      album.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Metadata & Action Buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Event: ${dateFormat.format(album.eventDate)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.photo_library_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${album.photoCount} Photos', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!isPublished) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.publish_rounded, color: Colors.white, size: 16),
                        label: const Text('Publish Album', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _publishAlbum(context, album),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 16),
                      label: const Text('Edit / Photos', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () => _openEditAlbumSheet(context, album),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      tooltip: 'Delete Album',
                      onPressed: () => _confirmDeleteAlbum(context, album),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreateOrEditAlbumSheet extends ConsumerStatefulWidget {
  final PhotoAlbumModel? existingAlbum;

  const CreateOrEditAlbumSheet({
    super.key,
    this.existingAlbum,
  });

  @override
  ConsumerState<CreateOrEditAlbumSheet> createState() => _CreateOrEditAlbumSheetState();
}

class _CreateOrEditAlbumSheetState extends ConsumerState<CreateOrEditAlbumSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedEventDate;
  late String _selectedDepartment;
  File? _coverPhotoFile;
  final List<File> _galleryPhotoFiles = [];
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final album = widget.existingAlbum;
    _titleController = TextEditingController(text: album?.title ?? '');
    _descController = TextEditingController(text: album?.description ?? '');
    _selectedEventDate = album?.eventDate ?? DateTime.now();
    _selectedDepartment = album?.departmentName ?? 'Computer Science & Engineering';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _coverPhotoFile = File(picked.path));
    }
  }

  Future<void> _pickGalleryPhotos() async {
    final pickedList = await _picker.pickMultiImage(imageQuality: 80);
    if (pickedList.isNotEmpty) {
      setState(() {
        _galleryPhotoFiles.addAll(pickedList.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _saveAlbum({required bool publishNow}) async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final galleryService = ref.read(galleryServiceProvider);
      final albumId = widget.existingAlbum?.albumId ?? 'ALBUM-${DateTime.now().millisecondsSinceEpoch}';

      final albumModel = PhotoAlbumModel(
        albumId: albumId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        eventDate: _selectedEventDate,
        departmentId: 'DEP-CSE',
        departmentName: _selectedDepartment,
        coverPhotoUrl: widget.existingAlbum?.coverPhotoUrl ?? '',
        status: publishNow ? AlbumStatus.published : (widget.existingAlbum?.status ?? AlbumStatus.draft),
        createdBy: user.uid,
        createdByName: user.fullName,
        createdAt: widget.existingAlbum?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: publishNow ? DateTime.now() : widget.existingAlbum?.publishedAt,
        photoCount: (widget.existingAlbum?.photoCount ?? 0) + _galleryPhotoFiles.length,
      );

      if (widget.existingAlbum == null) {
        await galleryService.createAlbum(
          album: albumModel,
          userId: user.uid,
          userName: user.fullName,
          userRole: user.role.name,
          coverPhotoFile: _coverPhotoFile,
        );
      } else {
        await galleryService.updateAlbum(
          album: albumModel,
          userId: user.uid,
          userName: user.fullName,
          userRole: user.role.name,
          newCoverPhotoFile: _coverPhotoFile,
        );
      }

      if (_galleryPhotoFiles.isNotEmpty) {
        await galleryService.uploadPhotosToAlbum(
          albumId: albumId,
          files: _galleryPhotoFiles,
          uploadedBy: user.uid,
          userName: user.fullName,
          userRole: user.role.name,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publishNow
                  ? '🎉 Album published successfully!'
                  : 'Album saved as draft. You can publish whenever ready.',
            ),
            backgroundColor: publishNow ? AppColors.success : AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving album: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAlbum != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Photo Album' : 'Create New Event Album',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (val) => val == null || val.trim().isEmpty ? 'Album title is required' : null,
                decoration: InputDecoration(
                  labelText: 'Album / Event Title *',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundSubtle,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Event Description',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundSubtle,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),

              // Event Date & Cover Photo Pickers Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: AppColors.backgroundSubtle,
                      ),
                      icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                      label: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedEventDate),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedEventDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedEventDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: AppColors.backgroundSubtle,
                      ),
                      icon: Icon(
                        _coverPhotoFile != null ? Icons.check_circle_rounded : Icons.image_rounded,
                        color: _coverPhotoFile != null ? AppColors.success : AppColors.primary,
                        size: 18,
                      ),
                      label: Text(
                        _coverPhotoFile != null ? 'Cover Selected' : 'Set Cover',
                        style: TextStyle(
                          color: _coverPhotoFile != null ? AppColors.success : AppColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: _pickCoverPhoto,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gallery Photos Multi-Picker Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upload Photos (${_galleryPhotoFiles.length} selected)',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 16, color: Colors.white),
                          label: const Text('Select Photos', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: _pickGalleryPhotos,
                        ),
                      ],
                    ),
                    if (_galleryPhotoFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 70,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _galleryPhotoFiles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(_galleryPhotoFiles[idx], width: 70, height: 70, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _galleryPhotoFiles.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Action Buttons
              if (_isSaving)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Loader.inline(size: 32, label: 'Saving album photos...'),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _saveAlbum(publishNow: false),
                        child: const Text('Save Draft', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _saveAlbum(publishNow: true),
                        child: const Text('Publish Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
