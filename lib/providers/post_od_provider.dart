import 'package:flutter_riverpod/flutter_riverpod.dart';

class OdTeamMember {
  final String uid;
  final String name;
  final String rollNo;
  final bool hasSubmittedCert;
  final String? certificateUrl;
  final DateTime? submittedAt;
  final String status; // 'Pending Teammate Upload', 'Uploaded - Pending HOD Approval', 'HOD Approved', 'Rejected'
  final String? hodRemarks;

  OdTeamMember({
    required this.uid,
    required this.name,
    required this.rollNo,
    this.hasSubmittedCert = false,
    this.certificateUrl,
    this.submittedAt,
    this.status = 'Pending Teammate Upload',
    this.hodRemarks,
  });

  OdTeamMember copyWith({
    bool? hasSubmittedCert,
    String? certificateUrl,
    DateTime? submittedAt,
    String? status,
    String? hodRemarks,
  }) {
    return OdTeamMember(
      uid: uid,
      name: name,
      rollNo: rollNo,
      hasSubmittedCert: hasSubmittedCert ?? this.hasSubmittedCert,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      hodRemarks: hodRemarks ?? this.hodRemarks,
    );
  }
}

class PostOdOutcomeModel {
  final String id;
  final String odRequestId;
  final String eventName;
  final String eventCategory;
  final String eventDate;
  final String teamLeaderUid;
  final String teamLeaderName;
  final String teamLeaderRollNo;
  final String outcome; // 'Won' or 'Lost'
  final String? prizeTitle; // e.g. '1st Prize / Winner', '2nd Runner Up'
  final String? cashPrizeAmount; // e.g. '₹25,000 & Trophy'
  final String? lossReason; // Mandatory post-mortem when outcome == 'Lost'
  final String? teamCertificateUrl;
  final DateTime submittedAt;
  final String hodStatus; // 'Pending HOD Verification', 'HOD Approved', 'Rejected'
  final String? hodRemarks;
  final List<OdTeamMember> teamMembers;

  PostOdOutcomeModel({
    required this.id,
    required this.odRequestId,
    required this.eventName,
    required this.eventCategory,
    required this.eventDate,
    required this.teamLeaderUid,
    required this.teamLeaderName,
    required this.teamLeaderRollNo,
    required this.outcome,
    this.prizeTitle,
    this.cashPrizeAmount,
    this.lossReason,
    this.teamCertificateUrl,
    required this.submittedAt,
    this.hodStatus = 'Pending HOD Verification',
    this.hodRemarks,
    required this.teamMembers,
  });

  bool get isWon => outcome == 'Won';
  bool get isLost => outcome == 'Lost';

  PostOdOutcomeModel copyWith({
    String? outcome,
    String? prizeTitle,
    String? cashPrizeAmount,
    String? lossReason,
    String? teamCertificateUrl,
    String? hodStatus,
    String? hodRemarks,
    List<OdTeamMember>? teamMembers,
  }) {
    return PostOdOutcomeModel(
      id: id,
      odRequestId: odRequestId,
      eventName: eventName,
      eventCategory: eventCategory,
      eventDate: eventDate,
      teamLeaderUid: teamLeaderUid,
      teamLeaderName: teamLeaderName,
      teamLeaderRollNo: teamLeaderRollNo,
      outcome: outcome ?? this.outcome,
      prizeTitle: prizeTitle ?? this.prizeTitle,
      cashPrizeAmount: cashPrizeAmount ?? this.cashPrizeAmount,
      lossReason: lossReason ?? this.lossReason,
      teamCertificateUrl: teamCertificateUrl ?? this.teamCertificateUrl,
      submittedAt: submittedAt,
      hodStatus: hodStatus ?? this.hodStatus,
      hodRemarks: hodRemarks ?? this.hodRemarks,
      teamMembers: teamMembers ?? this.teamMembers,
    );
  }
}

class PostOdState {
  final List<PostOdOutcomeModel> outcomes;

  const PostOdState({
    required this.outcomes,
  });

  PostOdState copyWith({
    List<PostOdOutcomeModel>? outcomes,
  }) {
    return PostOdState(
      outcomes: outcomes ?? this.outcomes,
    );
  }
}

class PostOdNotifier extends StateNotifier<PostOdState> {
  PostOdNotifier()
      : super(
          const PostOdState(
            outcomes: [],
          ),
        );

  /// Team Leader submits OD Return Outcome (Won or Lost)
  void submitLeaderOutcome({
    required String odRequestId,
    required String eventName,
    required String eventCategory,
    required String eventDate,
    required String teamLeaderUid,
    required String teamLeaderName,
    required String teamLeaderRollNo,
    required String outcome, // 'Won' or 'Lost'
    String? prizeTitle,
    String? cashPrizeAmount,
    String? lossReason,
    String? teamCertificateUrl,
    required List<Map<String, String>> members, // [{uid, name, rollNo}]
  }) {
    final now = DateTime.now();

    final teamMembersList = members.map((m) {
      final isLeader = m['uid'] == teamLeaderUid;
      return OdTeamMember(
        uid: m['uid']!,
        name: m['name']!,
        rollNo: m['rollNo']!,
        hasSubmittedCert: isLeader && teamCertificateUrl != null,
        certificateUrl: isLeader ? teamCertificateUrl : null,
        submittedAt: isLeader ? now : null,
        status: isLeader
            ? 'Uploaded - Pending HOD Approval'
            : (outcome == 'Won' ? 'Pending Teammate Upload' : 'Participation Logged'),
      );
    }).toList();

    final newOutcome = PostOdOutcomeModel(
      id: 'od_out_${now.millisecondsSinceEpoch}',
      odRequestId: odRequestId,
      eventName: eventName,
      eventCategory: eventCategory,
      eventDate: eventDate,
      teamLeaderUid: teamLeaderUid,
      teamLeaderName: teamLeaderName,
      teamLeaderRollNo: teamLeaderRollNo,
      outcome: outcome,
      prizeTitle: prizeTitle,
      cashPrizeAmount: cashPrizeAmount,
      lossReason: lossReason,
      teamCertificateUrl: teamCertificateUrl,
      submittedAt: now,
      hodStatus: 'Pending HOD Verification',
      teamMembers: teamMembersList,
    );

    state = state.copyWith(outcomes: [newOutcome, ...state.outcomes]);
  }

  /// Teammate uploads individual certificate
  void submitMemberCertificate({
    required String outcomeId,
    required String memberUid,
    required String certificateUrl,
  }) {
    final now = DateTime.now();

    final updatedOutcomes = state.outcomes.map((item) {
      if (item.id == outcomeId) {
        final updatedMembers = item.teamMembers.map((m) {
          if (m.uid == memberUid) {
            return m.copyWith(
              hasSubmittedCert: true,
              certificateUrl: certificateUrl,
              submittedAt: now,
              status: 'Uploaded - Pending HOD Approval',
            );
          }
          return m;
        }).toList();

        return item.copyWith(teamMembers: updatedMembers);
      }
      return item;
    }).toList();

    state = state.copyWith(outcomes: updatedOutcomes);
  }

  /// HOD approves overall OD outcome & certificates
  void approveOutcomeByHod(String outcomeId, {String? remarks}) {
    final updatedOutcomes = state.outcomes.map((item) {
      if (item.id == outcomeId) {
        final updatedMembers = item.teamMembers.map((m) {
          if (m.hasSubmittedCert) {
            return m.copyWith(status: 'HOD Approved', hodRemarks: remarks);
          }
          return m;
        }).toList();

        return item.copyWith(
          hodStatus: 'HOD Approved',
          hodRemarks: remarks ?? 'Post-OD outcome verified & approved by HOD.',
          teamMembers: updatedMembers,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(outcomes: updatedOutcomes);
  }

  /// HOD rejects overall outcome or requests re-upload
  void rejectOutcomeByHod(String outcomeId, {required String remarks}) {
    final updatedOutcomes = state.outcomes.map((item) {
      if (item.id == outcomeId) {
        return item.copyWith(
          hodStatus: 'Rejected',
          hodRemarks: remarks,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(outcomes: updatedOutcomes);
  }

  /// HOD approves individual member certificate
  void approveMemberCertByHod(String outcomeId, String memberUid, {String? remarks}) {
    final updatedOutcomes = state.outcomes.map((item) {
      if (item.id == outcomeId) {
        final updatedMembers = item.teamMembers.map((m) {
          if (m.uid == memberUid) {
            return m.copyWith(status: 'HOD Approved', hodRemarks: remarks);
          }
          return m;
        }).toList();

        return item.copyWith(teamMembers: updatedMembers);
      }
      return item;
    }).toList();

    state = state.copyWith(outcomes: updatedOutcomes);
  }
}

final postOdProvider = StateNotifierProvider<PostOdNotifier, PostOdState>((ref) {
  return PostOdNotifier();
});
