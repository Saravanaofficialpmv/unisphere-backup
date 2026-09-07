import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/repositories/staff_repository.dart';

final staffServiceProvider = Provider<StaffService>((ref) {
  final repo = ref.watch(staffRepositoryProvider);
  return StaffService(repository: repo);
});

/// Real-time stream of all staff members
final staffMembersStreamProvider = StreamProvider.autoDispose<List<StaffModel>>((ref) {
  final service = ref.watch(staffServiceProvider);
  return service.getStaffMembersStream();
});

class StaffService {
  final FirebaseFirestore? _firestore;
  final StaffRepository _repository;

  StaffService({FirebaseFirestore? firestore, StaffRepository? repository})
      : _firestore = firestore ?? _tryGetFirestore(),
        _repository = repository ?? StaffRepository(firestore: firestore);

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Get staff profile from staff/{uid}
  Future<StaffModel?> getStaffByUid(String uid) async {
    return _repository.getStaffProfile(uid);
  }

  /// Stream staff profile
  Stream<StaffModel?> watchStaffProfile(String uid) {
    return _repository.watchStaffProfile(uid);
  }

  /// Save or update staff profile staff/{uid}
  Future<void> saveStaff(StaffModel staff) async {
    return _repository.saveStaffProfile(staff);
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
      return snap.docs
          .map((d) => StaffModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
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

  /// Stream active responsibilities and assignments for a staff member
  Stream<List<StaffAssignmentModel>> watchStaffAssignments(String staffId) {
    return _repository.watchStaffAssignments(staffId);
  }

  /// Get active responsibilities for a staff member
  Future<List<StaffAssignmentModel>> getStaffAssignments(String staffId) {
    return _repository.getStaffAssignments(staffId);
  }

  /// Assign a new responsibility (e.g. Class Advisor, Subject Faculty)
  Future<void> assignResponsibility(StaffAssignmentModel assignment) {
    return _repository.assignResponsibility(assignment);
  }

  /// Revoke or unassign a responsibility
  Future<void> revokeAssignment(String assignmentId, {String? staffId}) {
    return _repository.revokeAssignment(assignmentId, staffId: staffId);
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
