import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/staff_model.dart';
import 'package:unisphere/services/auth_service.dart';

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService();
});

/// Real-time stream of all staff members
final staffMembersStreamProvider = StreamProvider.autoDispose<List<StaffModel>>((ref) {
  final service = ref.watch(staffServiceProvider);
  return service.getStaffMembersStream();
});

/// Real-time stream of current logged-in staff member profile
final currentStaffProfileStreamProvider = StreamProvider.autoDispose<StaffModel?>((ref) {
  final currentUser = ref.watch(authServiceProvider).currentUser;
  final uid = currentUser?.uid ?? '';
  if (uid.isEmpty) return Stream.value(null);
  final service = ref.watch(staffServiceProvider);
  return service.getStaffStream(uid);
});

class StaffService {
  final FirebaseFirestore? _firestore;

  StaffService({FirebaseFirestore? firestore}) : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Get staff profile from staff/{uid}
  Future<StaffModel?> getStaffByUid(String uid) async {
    final firestore = _firestore;
    if (uid.isEmpty || firestore == null) return null;
    try {
      final doc = await firestore.collection('staff').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return StaffModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('StaffService getStaffByUid error: $e');
    }
    return null;
  }

  /// Stream a single staff member profile
  Stream<StaffModel?> getStaffStream(String uid) {
    final firestore = _firestore;
    if (uid.isEmpty || firestore == null) return Stream.value(null);
    return firestore.collection('staff').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return StaffModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    }).handleError((e) {
      debugPrint('StaffService getStaffStream error: $e');
      return null;
    });
  }

  /// Save or update staff profile staff/{uid}
  Future<void> saveStaff(StaffModel staff) async {
    final firestore = _firestore;
    if (firestore == null || staff.userId.isEmpty) return;
    try {
      final data = staff.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await firestore.collection('staff').doc(staff.userId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('StaffService saveStaff error: $e');
    }
  }

  /// Assign / Update Staff Role by HOD (Teaching Faculty vs Class Advisor)
  Future<void> assignStaffRole({
    required String staffUid,
    required bool isAdvisor,
    String? advisorSection,
  }) async {
    final firestore = _firestore;
    if (firestore == null || staffUid.isEmpty) return;
    try {
      final batch = firestore.batch();

      // 1. Update staff/{staffUid}
      final staffRef = firestore.collection('staff').doc(staffUid);
      batch.set(
        staffRef,
        {
          'isAdvisor': isAdvisor,
          'is_advisor': isAdvisor,
          'advisorSection': isAdvisor ? (advisorSection ?? '') : null,
          'advisor_section': isAdvisor ? (advisorSection ?? '') : null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Update users/{staffUid}
      final userRef = firestore.collection('users').doc(staffUid);
      batch.set(
        userRef,
        {
          'role': isAdvisor ? 'advisor' : 'staff',
          'isAdvisor': isAdvisor,
          'advisorSection': isAdvisor ? (advisorSection ?? '') : null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      debugPrint('StaffService: Role successfully updated for $staffUid (isAdvisor=$isAdvisor, section=$advisorSection)');
    } catch (e) {
      debugPrint('StaffService assignStaffRole error: $e');
      rethrow;
    }
  }

  /// Get all staff members
  Future<List<StaffModel>> getStaffMembers({String? departmentId}) async {
    final firestore = _firestore;
    if (firestore == null) return [];
    try {
      Query query = firestore.collection('staff');
      if (departmentId != null && departmentId.isNotEmpty) {
        query = query.where('departmentId', isEqualTo: departmentId);
      }
      final snap = await query.get();
      return snap.docs.map((d) => StaffModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
    } catch (e) {
      debugPrint('StaffService getStaffMembers error: $e');
      return [];
    }
  }

  /// Real-time stream of staff members
  Stream<List<StaffModel>> getStaffMembersStream({String? departmentId}) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);
    Query query = firestore.collection('staff');
    if (departmentId != null && departmentId.isNotEmpty) {
      query = query.where('departmentId', isEqualTo: departmentId);
    }
    return query.snapshots().map((snap) {
      return snap.docs
          .map((d) => StaffModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    }).handleError((e) {
      debugPrint('StaffService getStaffMembersStream error: $e');
      return <StaffModel>[];
    });
  }

  /// Get staff count
  Future<int> getStaffCount() async {
    final firestore = _firestore;
    if (firestore == null) return 0;
    try {
      final snap = await firestore.collection('staff').count().get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('StaffService getStaffCount notice: $e');
      return 0;
    }
  }
}
