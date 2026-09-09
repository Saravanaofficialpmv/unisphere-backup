import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:unisphere/models/hackathon_model.dart';
import 'package:unisphere/models/hackathon_registration_model.dart';
import 'package:unisphere/models/hackathon_team_model.dart';


abstract class HackathonService {
  Future<List<HackathonModel>> getHackathons({int page = 1, int limit = 10, String? category});
  Future<HackathonModel?> getFeaturedHackathon();
  Future<HackathonModel> getHackathonById(String id);
  Future<Map<String, dynamic>> registerTeam(String hackathonId, Map<String, dynamic> registrationData);
  Future<List<Map<String, dynamic>>> getUserRegistrations();
  Future<void> createOrUpdateTeam(String hackathonId, HackathonTeamModel team);
  Future<void> reviewRegistrationByHod(String registrationId, String reviewStatus);
}

class ApiHackathonService implements HackathonService {
  final String baseUrl;
  final http.Client client;
  final FirebaseFirestore? _firestore;

  ApiHackathonService({
    String? baseUrl,
    http.Client? client,
    FirebaseFirestore? firestore,
  })  : baseUrl = baseUrl ?? const String.fromEnvironment('HACKATHON_API_URL', defaultValue: 'https://api.unisphere.edu/api'),
        client = client ?? http.Client(),
        _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<HackathonModel>> getHackathons({int page = 1, int limit = 10, String? category}) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snap = await firestore.collection('hackathons').get();
        if (snap.docs.isNotEmpty) {
          var list = snap.docs.map((d) => HackathonModel.fromMap(d.data(), d.id)).toList();
          if (category != null && category != 'All') {
            list = list.where((h) => h.category.toLowerCase() == category.toLowerCase()).toList();
          }
          return list;
        }
      } catch (e) {
        debugPrint('Firestore hackathons query notice: $e');
      }
    }
    return [];
  }

  @override
  Future<HackathonModel?> getFeaturedHackathon() async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snap = await firestore.collection('hackathons').where('isFeatured', isEqualTo: true).limit(1).get();
        if (snap.docs.isNotEmpty) {
          return HackathonModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<HackathonModel> getHackathonById(String id) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final doc = await firestore.collection('hackathons').doc(id).get();
        if (doc.exists && doc.data() != null) {
          return HackathonModel.fromMap(doc.data()!, doc.id);
        }
      } catch (_) {}
    }
    throw Exception('Hackathon with id $id not found.');
  }

  /// Create/Update team with transaction-enforced maximum of 6 team members
  @override
  Future<void> createOrUpdateTeam(String hackathonId, HackathonTeamModel team) async {
    final firestore = _firestore;
    if (firestore == null) return;

    if (team.memberIds.length > 6) {
      throw Exception('Maximum 6 team members allowed per hackathon team.');
    }

    final teamRef = firestore.collection('hackathons').doc(hackathonId).collection('teams').doc(team.teamId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(teamRef);
      if (snapshot.exists) {
        final currentMembers = List<String>.from(snapshot.data()?['memberIds'] ?? []);
        if (currentMembers.length > 6) {
          throw Exception('Team already reached maximum allowed limit of 6 members.');
        }
      }

      final teamData = team.toMap();
      teamData['updatedAt'] = FieldValue.serverTimestamp();
      transaction.set(teamRef, teamData, SetOptions(merge: true));
    });
  }

  @override
  Future<Map<String, dynamic>> registerTeam(String hackathonId, Map<String, dynamic> registrationData) async {
    final firestore = _firestore;
    final teamMembers = List<String>.from(registrationData['teamMembers'] ?? registrationData['memberIds'] ?? []);

    if (teamMembers.length > 6) {
      throw Exception('Cannot register team: Maximum 6 team members permitted.');
    }

    final regId = 'REG-${DateTime.now().year}-${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}';
    final teamId = registrationData['teamId']?.toString() ?? 'TEAM-$regId';
    final leaderId = registrationData['leaderId']?.toString() ?? registrationData['studentId']?.toString() ?? '';

    if (firestore != null) {
      try {
        final regModel = HackathonRegistrationModel(
          id: regId,
          hackathonId: hackathonId,
          teamId: teamId,
          leaderId: leaderId,
          hackathonTitle: registrationData['hackathonTitle']?.toString() ?? registrationData['title']?.toString() ?? 'Hackathon Event',
          studentId: leaderId,
          studentName: registrationData['studentName']?.toString() ?? 'Team Leader',
          department: registrationData['department']?.toString() ?? 'Computer Science',
          year: registrationData['year']?.toString() ?? '3rd Year',
          email: registrationData['email']?.toString() ?? 'leader@unisphere.edu',
          phone: registrationData['phone']?.toString() ?? '',
          teamName: registrationData['teamName']?.toString() ?? 'Team Alpha',
          teamMembers: teamMembers,
          registrationDate: DateTime.now(),
          startDate: DateTime.now().add(const Duration(days: 7)),
          endDate: DateTime.now().add(const Duration(days: 9)),
          participationStatus: 'Registration Confirmed',
          registrationCompleted: true,
          externalRegistrationStatus: 'completed',
          hodReviewStatus: 'pending',
          mode: registrationData['mode']?.toString() ?? 'Online',
          location: registrationData['location']?.toString() ?? 'Online',
          organizer: registrationData['organizer']?.toString() ?? 'UniSphere Innovation Cell',
        );

        await firestore.collection('hackathonRegistrations').doc(regId).set(regModel.toMap(), SetOptions(merge: true));

        // Create team record under hackathons/{hackathonId}/teams/{teamId}
        final teamModel = HackathonTeamModel(
          teamId: teamId,
          hackathonId: hackathonId,
          teamName: registrationData['teamName']?.toString() ?? 'Team Alpha',
          leaderId: leaderId,
          memberIds: teamMembers,
          registrationStatus: 'registered',
          registrationCompleted: true,
          hodReviewStatus: 'pending',
        );
        await createOrUpdateTeam(hackathonId, teamModel);
      } catch (e) {
        debugPrint('Firestore registerTeam notice: $e');
      }
    }

    return {
      'status': 'success',
      'message': 'Successfully registered team for Hackathon',
      'registrationId': regId,
      'teamName': registrationData['teamName'] ?? 'Team Alpha',
    };
  }

  @override
  Future<void> reviewRegistrationByHod(String registrationId, String reviewStatus) async {
    final firestore = _firestore;
    if (firestore == null || registrationId.isEmpty) return;
    try {
      await firestore.collection('hackathonRegistrations').doc(registrationId).update({
        'hodReviewStatus': reviewStatus,
        'hod_review_status': reviewStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('HackathonService reviewRegistrationByHod error: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserRegistrations() async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snap = await firestore.collection('hackathonRegistrations').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => d.data()).toList();
        }
      } catch (_) {}
    }
    return [];
  }
}

