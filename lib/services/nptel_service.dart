import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/nptel_certificate_model.dart';

class NptelService extends ChangeNotifier {
  static final NptelService _instance = NptelService._internal();
  factory NptelService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  NptelService._internal() {
    _initFirestoreListener();
  }

  final List<NptelCertificateModel> _certificates = [];

  List<NptelCertificateModel> get certificates => List.unmodifiable(_certificates);

  List<NptelCertificateModel> get pendingCertificates =>
      _certificates.where((c) => c.status == 'Pending Verification').toList();

  List<NptelCertificateModel> get verifiedCertificates =>
      _certificates.where((c) => c.status == 'Verified').toList();

  List<NptelCertificateModel> get rejectedCertificates =>
      _certificates.where((c) => c.status == 'Rejected').toList();

  void _initFirestoreListener() {
    try {
      _subscription = _firestore
          .collection('nptel_certificates')
          .orderBy('uploadDate', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _certificates.clear();
          for (final doc in snapshot.docs) {
            try {
              _certificates.add(NptelCertificateModel.fromMap(doc.data(), doc.id));
            } catch (e) {
              debugPrint('Error parsing NptelCertificate ${doc.id}: $e');
            }
          }
          notifyListeners();
        },
        onError: (err) {
          debugPrint('NptelService firestore subscription error: $err');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize NptelService listener: $e');
    }
  }

  Stream<List<NptelCertificateModel>> streamCertificates() {
    return _firestore
        .collection('nptel_certificates')
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NptelCertificateModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((e) {
      debugPrint('NptelService streamCertificates error: $e');
      return <NptelCertificateModel>[];
    });
  }

  Stream<List<NptelCertificateModel>> streamStudentCertificates({String? studentUid, String? rollNo}) {
    Query<Map<String, dynamic>> query = _firestore.collection('nptel_certificates');
    if (studentUid != null && studentUid.isNotEmpty) {
      query = query.where('studentUid', isEqualTo: studentUid);
    } else if (rollNo != null && rollNo.isNotEmpty) {
      query = query.where('rollNo', isEqualTo: rollNo);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => NptelCertificateModel.fromMap(doc.data(), doc.id))
        .toList()).handleError((e) {
      debugPrint('NptelService streamStudentCertificates error: $e');
      return <NptelCertificateModel>[];
    });
  }

  Stream<List<NptelCertificateModel>> streamDepartmentCertificates(String department) {
    return _firestore
        .collection('nptel_certificates')
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NptelCertificateModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((e) {
      debugPrint('NptelService streamDepartmentCertificates error: $e');
      return <NptelCertificateModel>[];
    });
  }

  Future<void> uploadCertificate(NptelCertificateModel cert) async {
    final docRef = _firestore.collection('nptel_certificates').doc(cert.id);
    await docRef.set(cert.toMap(), SetOptions(merge: true));

    final index = _certificates.indexWhere((c) => c.id == cert.id);
    if (index == -1) {
      _certificates.insert(0, cert);
      notifyListeners();
    }
  }

  Future<void> reuploadCertificate({
    required String existingId,
    required String courseName,
    required String courseCode,
    required String semester,
    required String academicYear,
    required String score,
    required String grade,
    required String certificateId,
    required String issueDate,
    required String fileName,
    required String fileSize,
    String? fileUrl,
  }) async {
    final updateData = <String, dynamic>{
      'courseName': courseName,
      'courseCode': courseCode,
      'semester': semester,
      'academicYear': academicYear,
      'score': score,
      'grade': grade,
      'certificateId': certificateId,
      'issueDate': issueDate,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadDate': Timestamp.now(),
      'status': 'Pending Verification',
      'rejectionReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fileUrl != null) {
      updateData['fileUrl'] = fileUrl;
    }

    await _firestore.collection('nptel_certificates').doc(existingId).update(updateData);

    final index = _certificates.indexWhere((c) => c.id == existingId);
    if (index != -1) {
      final old = _certificates[index];
      _certificates[index] = old.copyWith(
        courseName: courseName,
        courseCode: courseCode,
        semester: semester,
        academicYear: academicYear,
        score: score,
        grade: grade,
        certificateId: certificateId,
        issueDate: issueDate,
        fileName: fileName,
        fileSize: fileSize,
        fileUrl: fileUrl ?? old.fileUrl,
        uploadDate: DateTime.now(),
        status: 'Pending Verification',
        rejectionReason: null,
      );
      notifyListeners();
    }
  }

  Future<void> verifyCertificate(String id, String reviewer) async {
    await _firestore.collection('nptel_certificates').doc(id).update({
      'status': 'Verified',
      'reviewedBy': reviewer,
      'reviewedAt': Timestamp.now(),
      'rejectionReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final index = _certificates.indexWhere((c) => c.id == id);
    if (index != -1) {
      _certificates[index] = _certificates[index].copyWith(
        status: 'Verified',
        reviewedBy: reviewer,
        reviewedAt: DateTime.now(),
        rejectionReason: null,
      );
      notifyListeners();
    }
  }

  Future<void> rejectCertificate(String id, String reason, String reviewer) async {
    await _firestore.collection('nptel_certificates').doc(id).update({
      'status': 'Rejected',
      'rejectionReason': reason,
      'reviewedBy': reviewer,
      'reviewedAt': Timestamp.now(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final index = _certificates.indexWhere((c) => c.id == id);
    if (index != -1) {
      _certificates[index] = _certificates[index].copyWith(
        status: 'Rejected',
        rejectionReason: reason,
        reviewedBy: reviewer,
        reviewedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// Riverpod Providers
final nptelServiceProvider = Provider<NptelService>((ref) => NptelService());

final nptelCertificatesStreamProvider = StreamProvider<List<NptelCertificateModel>>((ref) {
  return ref.watch(nptelServiceProvider).streamCertificates();
});

final nptelStudentCertificatesStreamProvider =
    StreamProvider.family<List<NptelCertificateModel>, String>((ref, rollNo) {
  return ref.watch(nptelServiceProvider).streamStudentCertificates(rollNo: rollNo);
});

final nptelDepartmentCertificatesStreamProvider =
    StreamProvider.family<List<NptelCertificateModel>, String>((ref, department) {
  return ref.watch(nptelServiceProvider).streamDepartmentCertificates(department);
});
