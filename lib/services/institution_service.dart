import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model representing Institution / College configuration set by Admin
class InstitutionModel {
  final String collegeName;
  final String shortName;
  final String tagline;
  final String affiliation;
  final String logoUrl;
  final String address;
  final String website;
  final String contactEmail;

  const InstitutionModel({
    this.collegeName = 'VSB Engineering College',
    this.shortName = 'VSBEC',
    this.tagline = 'Autonomous Institution',
    this.affiliation = 'Affiliated to Anna University',
    this.logoUrl = '',
    this.address = 'Covai Road, Karur - 639111',
    this.website = 'www.vsbec.ac.in',
    this.contactEmail = 'info@vsbec.ac.in',
  });

  factory InstitutionModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const InstitutionModel();
    return InstitutionModel(
      collegeName: data['collegeName'] ?? data['name'] ?? data['institutionName'] ?? 'VSB Engineering College',
      shortName: data['shortName'] ?? data['code'] ?? 'VSBEC',
      tagline: data['tagline'] ?? data['subtitle'] ?? 'Autonomous Institution',
      affiliation: data['affiliation'] ?? 'Affiliated to Anna University',
      logoUrl: data['logoUrl'] ?? data['logo'] ?? '',
      address: data['address'] ?? 'Covai Road, Karur - 639111',
      website: data['website'] ?? 'www.vsbec.ac.in',
      contactEmail: data['contactEmail'] ?? data['email'] ?? 'info@vsbec.ac.in',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collegeName': collegeName,
      'name': collegeName,
      'shortName': shortName,
      'tagline': tagline,
      'affiliation': affiliation,
      'logoUrl': logoUrl,
      'address': address,
      'website': website,
      'contactEmail': contactEmail,
    };
  }
}

final institutionServiceProvider = Provider<InstitutionService>((ref) {
  return InstitutionService();
});

/// Reactive stream of the Institution / College settings configured by Admin in Firestore
final institutionStreamProvider = StreamProvider<InstitutionModel>((ref) {
  final service = ref.watch(institutionServiceProvider);
  return service.streamInstitution();
});

/// Direct provider for the active College Name set by Admin
final collegeNameProvider = Provider<String>((ref) {
  final inst = ref.watch(institutionStreamProvider).value;
  return inst?.collegeName ?? 'VSB Engineering College';
});

class InstitutionService {
  final FirebaseFirestore? _firestore;
  static InstitutionModel _cachedInstitution = const InstitutionModel();

  InstitutionService({FirebaseFirestore? firestore}) : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Stream real-time institution document from Firestore
  Stream<InstitutionModel> streamInstitution() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(_cachedInstitution);
    }

    return firestore.collection('settings').doc('institution').snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _cachedInstitution = InstitutionModel.fromMap(snapshot.data());
        return _cachedInstitution;
      }
      return _cachedInstitution;
    }).handleError((error) {
      debugPrint('InstitutionService stream error: $error');
      return _cachedInstitution;
    });
  }

  /// Fetch institution document once
  Future<InstitutionModel> getInstitutionInfo() async {
    final firestore = _firestore;
    if (firestore == null) return _cachedInstitution;

    try {
      final doc = await firestore.collection('settings').doc('institution').get();
      if (doc.exists && doc.data() != null) {
        _cachedInstitution = InstitutionModel.fromMap(doc.data());
        return _cachedInstitution;
      }

      // Fallback check system_settings
      final sysDoc = await firestore.collection('system_settings').doc('institution').get();
      if (sysDoc.exists && sysDoc.data() != null) {
        _cachedInstitution = InstitutionModel.fromMap(sysDoc.data());
        return _cachedInstitution;
      }
    } catch (e) {
      debugPrint('InstitutionService getInstitutionInfo error: $e');
    }

    return _cachedInstitution;
  }

  /// Admin method to update college name and institution settings in Firestore
  Future<void> saveInstitutionInfo(InstitutionModel institution) async {
    _cachedInstitution = institution;
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final data = institution.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await firestore.collection('settings').doc('institution').set(data, SetOptions(merge: true));
      await firestore.collection('system_settings').doc('institution').set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('InstitutionService saveInstitutionInfo error: $e');
    }
  }
}
