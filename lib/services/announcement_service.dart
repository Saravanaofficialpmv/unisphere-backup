import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unisphere/models/announcement_model.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';

class AnnouncementService extends ChangeNotifier {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;

  StreamSubscription<List<AnnouncementModel>>? _subscription;

  AnnouncementService._internal() {
    _connectFirestoreStream();
  }

  final List<AnnouncementModel> _announcements = [];
  final String _currentUserId = '';

  List<AnnouncementModel> get announcements => List.unmodifiable(_announcements);

  int get unreadCount => _currentUserId.isEmpty ? 0 : _announcements.where((a) => !a.isReadBy(_currentUserId)).length;

  void _connectFirestoreStream() {
    try {
      final firestoreService = FirebaseFirestoreService();
      _subscription = firestoreService.getAnnouncements().listen(
        (list) {
          _announcements.clear();
          _announcements.addAll(list);
          notifyListeners();
        },
        onError: (e) {
          debugPrint('AnnouncementService stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('AnnouncementService connect error: $e');
    }
  }

  List<AnnouncementModel> getFilteredAnnouncements({
    String? category,
    bool unreadOnly = false,
    bool importantOnly = false,
    String? searchQuery,
  }) {
    return _announcements.where((ann) {
      final matchesCategory = category == null || category == 'All' || ann.category == category;
      final matchesUnread = !unreadOnly || !ann.isReadBy(_currentUserId);
      final matchesImportant = !importantOnly || ann.priority == 'Important' || ann.priority == 'Urgent';

      final query = searchQuery?.toLowerCase().trim() ?? '';
      final matchesSearch = query.isEmpty ||
          ann.title.toLowerCase().contains(query) ||
          ann.content.toLowerCase().contains(query) ||
          ann.authorName.toLowerCase().contains(query);

      return matchesCategory && matchesUnread && matchesImportant && matchesSearch;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void markAsRead(String announcementId) {
    final index = _announcements.indexWhere((a) => a.id == announcementId);
    if (index != -1 && !_announcements[index].isReadBy(_currentUserId)) {
      _announcements[index] = _announcements[index].markReadFor(_currentUserId);
      notifyListeners();
      FirebaseFirestoreService().markAnnouncementRead(announcementId, _currentUserId);
    }
  }

  void addAnnouncement(AnnouncementModel announcement) {
    _announcements.insert(0, announcement);
    notifyListeners();
    FirebaseFirestoreService().addAnnouncement(announcement);
  }

  void deleteAnnouncement(String announcementId) {
    _announcements.removeWhere((a) => a.id == announcementId);
    notifyListeners();
    FirebaseFirestoreService().deleteAnnouncement(announcementId);
  }

  List<String> get availableCategories => [
        'All',
        'General',
        'Academic',
        'Examination',
        'Department',
        'Placement',
        'Internship',
        'Event',
        'Holiday',
        'Emergency',
        'Fee / Administration',
      ];

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
