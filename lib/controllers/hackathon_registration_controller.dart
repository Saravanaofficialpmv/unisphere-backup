import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/hackathon_registration_model.dart';
import 'package:unisphere/models/hackathon_model.dart';
import 'package:unisphere/services/hackathon_reminder_engine.dart';
import 'package:unisphere/services/hackathon_activity_logger.dart';

final hackathonRegistrationProvider =
    StateNotifierProvider<HackathonRegistrationNotifier, List<HackathonRegistrationModel>>((ref) {
  return HackathonRegistrationNotifier();
});

class HackathonRegistrationNotifier extends StateNotifier<List<HackathonRegistrationModel>> {
  final HackathonReminderEngine _reminderEngine = HackathonReminderEngine();

  HackathonRegistrationNotifier() : super(const []);

  /// Get student-specific registrations
  List<HackathonRegistrationModel> getStudentRegistrations(String? studentId) {
    if (studentId == null || studentId.isEmpty) {
      return const [];
    }
    return state.where((r) {
      return r.studentId.toLowerCase() == studentId.toLowerCase() ||
          r.email.toLowerCase() == studentId.toLowerCase();
    }).toList();
  }

  static Map<String, String> _getAdvisorForYearAndSection(String year, String section) {
    final y = year.trim();
    final s = section.trim();
    final tag = [y, s].where((e) => e.isNotEmpty).join(' ');
    return {
      'id': tag.isNotEmpty ? 'ADV-${tag.replaceAll(' ', '-')}' : 'ADV-GEN',
      'name': tag.isNotEmpty ? 'Class Advisor ($tag)' : 'Class Advisor',
    };
  }

  /// Check if logged in student is registered for a specific hackathon
  bool isRegisteredForHackathon(String hackathonId, String? studentId) {
    final list = getStudentRegistrations(studentId);
    return list.any((r) => r.hackathonId == hackathonId);
  }

  /// Register student for a new hackathon with team, external registration ID, year, section, and screenshot proof
  HackathonRegistrationModel registerStudentForHackathon({
    required HackathonModel hackathon,
    required String studentId,
    required String studentName,
    required String department,
    required String year,
    String section = 'Sec A',
    required String email,
    required String phone,
    required String teamName,
    required List<String> teamMembers,
    String externalRegistrationId = '',
    String registrationScreenshotUrl = '',
  }) {
    final now = DateTime.now();
    final regId = 'REG-${now.year}-${1000 + (now.millisecondsSinceEpoch % 8999)}';

    // Auto-identify advisor based on Year + Section
    final advisorMap = _getAdvisorForYearAndSection(year, section);

    final initialActivities = [
      HackathonActivityLogger.createActivity(
        hackathonId: hackathon.id,
        teamId: regId,
        studentId: studentId,
        actorId: studentId,
        actorRole: 'student',
        activityType: 'team_created',
        description: 'Team "$teamName" created by Team Leader ${studentName.isEmpty ? "Student" : studentName}',
        newStatus: 'Team Created',
      ),
      if (registrationScreenshotUrl.isNotEmpty)
        HackathonActivityLogger.createActivity(
          hackathonId: hackathon.id,
          teamId: regId,
          studentId: studentId,
          actorId: studentId,
          actorRole: 'student',
          activityType: 'screenshot_uploaded',
          description: 'Registration screenshot proof attached (ID: $externalRegistrationId)',
          newStatus: 'Screenshot Uploaded',
        ),
      HackathonActivityLogger.createActivity(
        hackathonId: hackathon.id,
        teamId: regId,
        studentId: studentId,
        actorId: studentId,
        actorRole: 'student',
        activityType: 'details_submitted',
        description: 'Registration details submitted to Class Advisor ${advisorMap['name']}',
        previousStatus: 'Details Incomplete',
        newStatus: 'Submitted to Advisor',
      ),
    ];

    final newRegistration = HackathonRegistrationModel(
      id: regId,
      hackathonId: hackathon.id,
      hackathonTitle: hackathon.title,
      studentId: studentId,
      studentName: studentName.isEmpty ? 'Student' : studentName,
      department: department.isEmpty ? 'Department' : department,
      year: year.isEmpty ? '1st Year' : year,
      section: section,
      email: email,
      phone: phone,
      teamName: teamName,
      teamMembers: [studentName.isEmpty ? 'Student (Lead)' : '$studentName (Lead)', ...teamMembers],
      registrationDate: now,
      startDate: hackathon.startDate,
      endDate: hackathon.endDate,
      participationStatus: 'Submitted to Advisor',
      mode: hackathon.mode,
      location: hackathon.location,
      organizer: hackathon.organizer,
      description: hackathon.description,
      bannerImage: hackathon.bannerImage,
      rules: [
        'All team members must check in prior to event kickoff.',
        'Submissions must adhere to safety and ethical guidelines.',
      ],
      submissionDeadline: hackathon.endDate,
      externalRegistrationId: externalRegistrationId,
      registrationScreenshotUrl: registrationScreenshotUrl,
      verificationStatus: 'Pending Verification',
      assignedAdvisorId: advisorMap['id']!,
      assignedAdvisorName: advisorMap['name']!,
      activities: initialActivities,
    );

    // Update state reactively
    state = [newRegistration, ...state];
    return newRegistration;
  }

  /// Advisor verifies student hackathon registration
  void verifyRegistration(String registrationId) {
    state = state.map((reg) {
      if (reg.id == registrationId) {
        final verifyAct = HackathonActivityLogger.createActivity(
          hackathonId: reg.hackathonId,
          teamId: reg.id,
          studentId: reg.studentId,
          actorId: reg.assignedAdvisorId,
          actorRole: 'advisor',
          activityType: 'registration_verified',
          description: 'Class Advisor (${reg.assignedAdvisorName}) verified hackathon team registration',
          previousStatus: reg.verificationStatus,
          newStatus: 'Verified',
        );
        return reg.copyWith(
          verificationStatus: 'Verified',
          participationStatus: 'Verified by Advisor',
          advisorCorrectionNotes: null,
          activities: [...reg.activities, verifyAct],
        );
      }
      return reg;
    }).toList();
  }

  /// Advisor requests correction from student
  void requestCorrection(String registrationId, String notes) {
    state = state.map((reg) {
      if (reg.id == registrationId) {
        final correctionAct = HackathonActivityLogger.createActivity(
          hackathonId: reg.hackathonId,
          teamId: reg.id,
          studentId: reg.studentId,
          actorId: reg.assignedAdvisorId,
          actorRole: 'advisor',
          activityType: 'correction_requested',
          description: 'Class Advisor (${reg.assignedAdvisorName}) requested correction: "$notes"',
          previousStatus: reg.verificationStatus,
          newStatus: 'Correction Required',
        );
        return reg.copyWith(
          verificationStatus: 'Correction Required',
          participationStatus: 'Correction Required by Advisor',
          advisorCorrectionNotes: notes,
          activities: [...reg.activities, correctionAct],
        );
      }
      return reg;
    }).toList();
  }

  /// Student resubmits proof screenshot & details after advisor correction request
  void resubmitRegistration({
    required String registrationId,
    required String screenshotUrl,
    String? externalRegId,
  }) {
    state = state.map((reg) {
      if (reg.id == registrationId) {
        final resubmitAct = HackathonActivityLogger.createActivity(
          hackathonId: reg.hackathonId,
          teamId: reg.id,
          studentId: reg.studentId,
          actorId: reg.studentId,
          actorRole: 'student',
          activityType: 'correction_submitted',
          description: 'Team Leader resubmitted updated registration screenshot proof',
          previousStatus: reg.verificationStatus,
          newStatus: 'Pending Verification',
        );
        return reg.copyWith(
          registrationScreenshotUrl: screenshotUrl,
          externalRegistrationId: externalRegId ?? reg.externalRegistrationId,
          verificationStatus: 'Pending Verification',
          participationStatus: 'Resubmitted to Advisor',
          advisorCorrectionNotes: null,
          activities: [...reg.activities, resubmitAct],
        );
      }
      return reg;
    }).toList();
  }

  /// Get pending & total registrations assigned to an Advisor by Year/Section/ID
  List<HackathonRegistrationModel> getAdvisorRegistrations(String advisorId) {
    return state.where((r) => r.assignedAdvisorId == advisorId).toList();
  }

  /// Submit project for an ongoing hackathon
  void submitProject({
    required String registrationId,
    required String projectUrl,
    required String projectTitle,
    String? notes,
  }) {
    state = state.map((reg) {
      if (reg.id == registrationId) {
        return reg.copyWith(
          projectSubmissionUrl: projectUrl,
          projectSubmissionTitle: projectTitle,
          projectSubmissionNotes: notes,
          submittedAt: DateTime.now(),
          participationStatus: 'Project Submitted',
        );
      }
      return reg;
    }).toList();
  }

  /// Clear registrations for testing empty state
  void clearAllRegistrations() {
    state = [];
  }

  /// Trigger automated reminder evaluation check targeting Team Leaders
  Future<int> runAutomatedRemindersCheck(List<HackathonModel> hackathons) async {
    return await _reminderEngine.evaluateAndSendReminders(
      registrations: state,
      hackathons: hackathons,
    );
  }

  /// Reset default mock data
  void resetToDefault() {
    state = const [];
  }
}
