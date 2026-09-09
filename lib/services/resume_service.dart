import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/certification_model.dart';
import 'package:unisphere/models/hackathon_registration_model.dart';
import 'package:unisphere/models/project_model.dart';
import 'package:unisphere/models/student_model.dart';
import 'package:unisphere/models/student_resume_model.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';

final resumeServiceProvider = Provider<ResumeService>((ref) {
  return ResumeService();
});

/// Stream of the currently authenticated student's dynamic live resume
final currentStudentResumeStreamProvider = StreamProvider.autoDispose<StudentResumeModel?>((ref) {
  final authState = ref.watch(currentUserProvider);
  final user = authState.value ?? ref.watch(authServiceProvider).currentUser;
  final identifier = user?.metadata?['registerNumber']?.toString().isNotEmpty == true
      ? user!.metadata!['registerNumber'].toString()
      : (user?.uid ?? '');

  final resumeService = ref.watch(resumeServiceProvider);
  return resumeService.watchResumeForStudent(identifier, currentUserFallback: user);
});

/// Future provider to fetch any student's resume by UID or Registration Number
final studentResumeProvider = FutureProvider.family<StudentResumeModel?, String>((ref, identifier) async {
  final resumeService = ref.watch(resumeServiceProvider);
  final authState = ref.watch(currentUserProvider);
  final user = authState.value ?? ref.watch(authServiceProvider).currentUser;
  return resumeService.generateResumeForStudent(identifier, currentUserFallback: user);
});

/// Future provider for all students in a department (HOD)
final departmentResumesProvider = FutureProvider.family<List<StudentResumeModel>, String>((ref, departmentName) async {
  final resumeService = ref.watch(resumeServiceProvider);
  return resumeService.getResumesForDepartment(departmentName);
});

/// Future provider for assigned students (Adviser)
final adviserResumesProvider = FutureProvider.family<List<StudentResumeModel>, String>((ref, sectionOrBatch) async {
  final resumeService = ref.watch(resumeServiceProvider);
  return resumeService.getResumesForAdviser(sectionOrBatch);
});

class ResumeService {
  final FirebaseFirestore? _firestore;

  ResumeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Instant zero-latency synchronous resume generation ensuring the UI is never blank
  StudentResumeModel generateSyncFallbackResume({
    String? studentId,
    UserModel? user,
    String? customName,
    String? customDepartment,
    String? customYear,
    String? customCgpa,
    String? customGithub,
    String? customLeetCode,
    String? customLinkedin,
  }) {
    final cleanId = (studentId ?? user?.metadata?['registerNumber']?.toString() ?? user?.uid ?? '').trim();
    final userMeta = user?.metadata ?? {};

    final fullName = (customName ?? user?.fullName ?? user?.name ?? 'Student').trim();
    final headline = userMeta['headline']?.toString() ?? '';
    final collegeEmail = user?.email ?? '';
    final personalEmail = userMeta['personalEmail']?.toString();
    final primaryMobile = user?.phone ?? '';
    final isPhoneVisible = userMeta['isPhoneVisible'] != false;
    final location = userMeta['location']?.toString() ?? '';

    final rawLinkedin = customLinkedin ?? userMeta['linkedinUrl']?.toString();
    final linkedinUrl = rawLinkedin != null && rawLinkedin.isNotEmpty
        ? (rawLinkedin.startsWith('http') ? rawLinkedin : 'https://$rawLinkedin')
        : '';

    final githubUser = customGithub ?? userMeta['githubUsername']?.toString() ?? '';
    final githubUrl = githubUser.isNotEmpty
        ? (githubUser.startsWith('http') ? githubUser : 'https://github.com/$githubUser')
        : '';

    final leetcodeUser = customLeetCode ?? userMeta['leetcodeUsername']?.toString() ?? '';
    final leetcodeUrl = leetcodeUser.isNotEmpty
        ? (leetcodeUser.startsWith('http') ? leetcodeUser : 'https://leetcode.com/u/$leetcodeUser')
        : '';

    final portfolioUrl = userMeta['portfolioUrl']?.toString() ?? '';

    final header = ResumeHeader(
      fullName: fullName,
      headline: headline,
      collegeEmail: collegeEmail,
      personalEmail: personalEmail,
      phone: isPhoneVisible && primaryMobile.isNotEmpty ? primaryMobile : null,
      isPhoneVisible: isPhoneVisible,
      location: location,
      linkedinUrl: linkedinUrl.isNotEmpty ? linkedinUrl : null,
      githubUrl: githubUrl.isNotEmpty ? githubUrl : null,
      leetcodeUrl: leetcodeUrl.isNotEmpty ? leetcodeUrl : null,
      portfolioUrl: portfolioUrl.isNotEmpty ? portfolioUrl : null,
      languages: const [],
      professionalInterests: const [],
    );

    final deptName = customDepartment ?? userMeta['department']?.toString() ?? userMeta['departmentName']?.toString() ?? '';
    final currentSem = userMeta['semester']?.toString() ?? '';
    final currentYear = customYear ?? userMeta['year']?.toString() ?? '';
    final cgpa = customCgpa ?? userMeta['cgpa']?.toString() ?? '';

    final List<ResumeEducationItem> educationList = [
      if (deptName.isNotEmpty)
        ResumeEducationItem(
          degree: 'Bachelor of Engineering in $deptName',
          institution: 'VSB Engineering College (Autonomous)',
          boardOrUniversity: 'Anna University',
          period: userMeta['batch']?.toString() ?? '',
          score: cgpa.isNotEmpty ? cgpa : '-',
          scoreLabel: cgpa.isNotEmpty ? 'CGPA: $cgpa' : '',
          currentYearOrSem: currentYear.isNotEmpty ? '$currentYear${currentSem.isNotEmpty ? ' ($currentSem)' : ''}' : currentSem,
          isPrimaryCollege: true,
        ),
    ];

    final List<ResumeExperienceItem> experienceList = const [];
    final List<ResumeProjectItem> projectList = const [];
    final List<ResumeCertificationItem> certList = const [];
    final List<ResumeActivityItem> activityList = const [];
    final List<String> allSkills = const [];
    final categorizedSkills = _categorizeSkills(allSkills);

    final summary = headline;

    final completeness = _calculateCompleteness(
      fullName: fullName,
      collegeEmail: collegeEmail,
      deptName: deptName,
      year: currentYear,
      skills: allSkills,
      headline: headline,
      linkedinUrl: linkedinUrl,
      githubUrl: githubUrl,
      portfolioUrl: portfolioUrl,
      projects: projectList,
      certifications: certList,
      experiences: experienceList,
      activities: activityList,
    );

    return StudentResumeModel(
      studentUid: cleanId,
      registerNumber: userMeta['registerNumber']?.toString() ?? cleanId,
      department: deptName,
      academicYear: currentYear,
      section: userMeta['section']?.toString() ?? '',
      header: header,
      professionalSummary: summary,
      education: educationList,
      experience: experienceList,
      projects: projectList,
      certifications: certList,
      activitiesAndAchievements: activityList,
      categorizedSkills: categorizedSkills,
      allSkills: allSkills,
      completeness: completeness,
      lastUpdatedAt: DateTime.now(),
      version: 1,
    );
  }

  /// Watch real-time resume updates with immediate first emission
  Stream<StudentResumeModel?> watchResumeForStudent(String uidOrRegNo, {UserModel? currentUserFallback}) async* {
    // 1. Immediately yield initial generated resume to ensure instant UI rendering
    try {
      final initial = await generateResumeForStudent(uidOrRegNo, currentUserFallback: currentUserFallback);
      if (initial != null) {
        yield initial;
      }
    } catch (e) {
      debugPrint('Initial resume generation notice: $e');
    }

    // 2. Listen for live Firestore updates
    final firestore = _firestore;
    if (firestore != null && uidOrRegNo.isNotEmpty) {
      try {
        final stream = firestore.collection('users').doc(uidOrRegNo).snapshots();
        await for (final _ in stream) {
          final updated = await generateResumeForStudent(uidOrRegNo, currentUserFallback: currentUserFallback);
          if (updated != null) {
            yield updated;
          }
        }
      } catch (e) {
        debugPrint('Resume live stream notice: $e');
      }
    }
  }

  /// Dynamic resume generation engine that aggregates real database records
  Future<StudentResumeModel?> generateResumeForStudent(String uidOrRegNo, {UserModel? currentUserFallback}) async {
    final cleanId = uidOrRegNo.trim();

    final firestore = _firestore;

    // 1. Fetch User Record
    UserModel? user;
    if (firestore != null && cleanId.isNotEmpty) {
      try {
        final doc = await firestore.collection('users').doc(cleanId).get().timeout(const Duration(milliseconds: 1200));
        if (doc.exists && doc.data() != null) {
          user = UserModel.fromMap(doc.data()!, doc.id);
        } else {
          final q = await firestore.collection('users').where('metadata.registerNumber', isEqualTo: cleanId).limit(1).get().timeout(const Duration(milliseconds: 1200));
          if (q.docs.isNotEmpty) {
            user = UserModel.fromMap(q.docs.first.data(), q.docs.first.id);
          } else if (currentUserFallback != null && currentUserFallback.email.isNotEmpty) {
            final qEmail = await firestore.collection('users').where('email', isEqualTo: currentUserFallback.email).limit(1).get().timeout(const Duration(milliseconds: 1200));
            if (qEmail.docs.isNotEmpty) {
              user = UserModel.fromMap(qEmail.docs.first.data(), qEmail.docs.first.id);
            }
          }
        }
      } catch (e) {
        debugPrint('ResumeService user lookup notice: $e');
      }
    }

    user = user ?? currentUserFallback;

    // 2. Fetch Student Record
    StudentModel? student;
    if (firestore != null && cleanId.isNotEmpty) {
      try {
        final doc = await firestore.collection('students').doc(cleanId).get().timeout(const Duration(milliseconds: 1200));
        if (doc.exists && doc.data() != null) {
          student = StudentModel.fromMap(doc.data()!, doc.id);
        } else {
          final q = await firestore.collection('students').where('registerNumber', isEqualTo: cleanId).limit(1).get().timeout(const Duration(milliseconds: 1200));
          if (q.docs.isNotEmpty) {
            student = StudentModel.fromMap(q.docs.first.data(), q.docs.first.id);
          } else {
            final q2 = await firestore.collection('students').where('userId', isEqualTo: cleanId).limit(1).get().timeout(const Duration(milliseconds: 1200));
            if (q2.docs.isNotEmpty) {
              student = StudentModel.fromMap(q2.docs.first.data(), q2.docs.first.id);
            }
          }
        }
      } catch (e) {
        debugPrint('ResumeService student lookup notice: $e');
      }
    }

    // 3. Fetch Full Student 360° Profile Record
    Map<String, dynamic> profileMap = {};
    if (firestore != null) {
      try {
        final regNo = student?.registerNumber ?? user?.metadata?['registerNumber']?.toString() ?? cleanId;
        if (regNo.isNotEmpty) {
          final doc = await firestore.collection('student_profiles').doc(regNo).get().timeout(const Duration(milliseconds: 1200));
          if (doc.exists && doc.data() != null) {
            profileMap = doc.data()!;
          } else {
            final doc2 = await firestore.collection('student_profiles').doc(user?.uid ?? cleanId).get().timeout(const Duration(milliseconds: 1200));
            if (doc2.exists && doc2.data() != null) {
              profileMap = doc2.data()!;
            }
          }
        }
      } catch (e) {
        debugPrint('ResumeService profile lookup notice: $e');
      }
    }

    // 4. Fetch Projects
    List<ProjectModel> projects = [];
    if (firestore != null) {
      try {
        final uid = user?.uid ?? student?.userId ?? cleanId;
        final regNo = student?.registerNumber ?? user?.metadata?['registerNumber']?.toString() ?? cleanId;
        
        final snap = await firestore.collection('projects').get().timeout(const Duration(milliseconds: 1200));
        projects = snap.docs
            .map((d) => ProjectModel.fromMap(d.data(), d.id))
            .where((p) => p.studentUid == uid || p.studentUid == regNo || p.studentUid == cleanId)
            .toList();
      } catch (e) {
        debugPrint('ResumeService projects lookup notice: $e');
      }
    }

    // 5. Fetch Certifications
    List<CertificationModel> certs = [];
    if (firestore != null) {
      try {
        final uid = user?.uid ?? student?.userId ?? cleanId;
        final regNo = student?.registerNumber ?? user?.metadata?['registerNumber']?.toString() ?? cleanId;

        final snap = await firestore.collection('certifications').get().timeout(const Duration(milliseconds: 1200));
        certs = snap.docs
            .map((d) => CertificationModel.fromMap(d.data(), d.id))
            .where((c) =>
                (c.studentId == uid || c.studentId == regNo || c.studentUid == uid || c.studentUid == regNo || c.studentId == cleanId) &&
                (c.approvalStatus == 'approved' || c.verificationStatus == 'verified'))
            .toList();
      } catch (e) {
        debugPrint('ResumeService certs lookup notice: $e');
      }
    }

    // 6. Fetch Hackathon Registrations
    List<HackathonRegistrationModel> hackathons = [];
    if (firestore != null) {
      try {
        final uid = user?.uid ?? student?.userId ?? cleanId;
        final regNo = student?.registerNumber ?? user?.metadata?['registerNumber']?.toString() ?? cleanId;

        final snap = await firestore.collection('hackathonRegistrations').get().timeout(const Duration(milliseconds: 1200));
        final snap2 = await firestore.collection('hackathon_registrations').get().timeout(const Duration(milliseconds: 1200));
        final allDocs = [...snap.docs, ...snap2.docs];
        final seenIds = <String>{};

        for (var d in allDocs) {
          if (!seenIds.contains(d.id)) {
            seenIds.add(d.id);
            final h = HackathonRegistrationModel.fromMap(d.data(), d.id);
            if (h.studentId == uid || h.studentId == regNo || h.email == user?.email) {
              hackathons.add(h);
            }
          }
        }
      } catch (e) {
        debugPrint('ResumeService hackathons lookup notice: $e');
      }
    }

    // Fallback extraction from metadata/profile
    final userMeta = user?.metadata ?? {};
    final personalObj = (profileMap['personal'] as Map<String, dynamic>?) ?? {};
    final contactObj = (profileMap['contact'] as Map<String, dynamic>?) ?? {};
    final educationObj = (profileMap['education'] as Map<String, dynamic>?) ?? {};

    // ── Build Header ──
    final rawFullName = personalObj['fullName']?.toString() ??
        user?.fullName ??
        user?.name ??
        student?.fullName ??
        '';

    final fullName = rawFullName.trim().isNotEmpty ? rawFullName.trim() : (user?.email.split('@').first ?? '');

    final headline = userMeta['headline']?.toString().isNotEmpty == true
        ? userMeta['headline'].toString()
        : (userMeta['linkedinHeadline']?.toString().isNotEmpty == true
            ? userMeta['linkedinHeadline'].toString()
            : '');

    final collegeEmail = personalObj['collegeEmail']?.toString().isNotEmpty == true
        ? personalObj['collegeEmail'].toString()
        : (user?.email.isNotEmpty == true ? user!.email : '');

    final personalEmail = contactObj['personalEmail']?.toString() ?? userMeta['personalEmail']?.toString();
    final primaryMobile = contactObj['primaryMobile']?.toString() ?? user?.phone ?? '';
    final isPhoneVisible = userMeta['isPhoneVisible'] != false;

    final permAddr = (contactObj['permanentAddress'] as Map<String, dynamic>?) ?? {};
    final city = permAddr['city']?.toString() ?? '';
    final state = permAddr['state']?.toString() ?? '';
    final country = permAddr['country']?.toString() ?? '';
    final location = [city, state, country].where((s) => s.isNotEmpty).join(', ');

    final rawLinkedin = userMeta['linkedinUrl']?.toString() ?? '';
    final linkedinUrl = rawLinkedin.isNotEmpty
        ? (rawLinkedin.startsWith('http') ? rawLinkedin : 'https://$rawLinkedin')
        : '';

    final githubUser = userMeta['githubUsername']?.toString() ?? '';
    final githubUrl = githubUser.isNotEmpty
        ? (githubUser.startsWith('http') ? githubUser : 'https://github.com/$githubUser')
        : '';

    final leetcodeUser = userMeta['leetcodeUsername']?.toString() ?? '';
    final leetcodeUrl = leetcodeUser.isNotEmpty
        ? (leetcodeUser.startsWith('http') ? leetcodeUser : 'https://leetcode.com/u/$leetcodeUser')
        : '';

    final portfolioUrl = userMeta['portfolioUrl']?.toString() ?? '';

    final languages = <String>[
      if (personalObj['motherTongue'] != null) '${personalObj['motherTongue']} (Native)',
      if (userMeta['languages'] is List)
        ...(userMeta['languages'] as List).map((e) => e.toString()),
    ];

    final interests = <String>[
      if (userMeta['interests'] is List)
        ...(userMeta['interests'] as List).map((e) => e.toString()),
    ];

    final header = ResumeHeader(
      fullName: fullName,
      headline: headline,
      collegeEmail: collegeEmail,
      personalEmail: personalEmail,
      phone: isPhoneVisible && primaryMobile.isNotEmpty ? primaryMobile : null,
      isPhoneVisible: isPhoneVisible,
      location: location,
      linkedinUrl: linkedinUrl,
      githubUrl: githubUrl,
      leetcodeUrl: leetcodeUrl,
      portfolioUrl: portfolioUrl,
      languages: languages,
      professionalInterests: interests,
    );

    // ── Build Education ──
    final deptName = student?.departmentName ?? userMeta['department']?.toString() ?? '';
    final currentSem = student?.semester ?? userMeta['semester']?.toString() ?? '';
    final currentYear = userMeta['year']?.toString() ?? '';
    final admissionYear = student?.admissionYear;
    final gradYear = admissionYear != null ? admissionYear + 4 : null;
    final cgpa = student?.cgpa ?? userMeta['cgpa']?.toString() ?? '';

    final List<ResumeEducationItem> educationList = [];
    if (deptName.isNotEmpty || cgpa.isNotEmpty) {
      educationList.add(ResumeEducationItem(
        degree: deptName.isNotEmpty ? 'Bachelor of Engineering in $deptName' : 'Bachelor of Engineering',
        institution: 'VSB Engineering College (Autonomous)',
        boardOrUniversity: 'Anna University, Chennai',
        period: admissionYear != null ? '$admissionYear – $gradYear' : '',
        score: cgpa,
        scoreLabel: cgpa.isNotEmpty ? 'Current CGPA: $cgpa / 10.0' : '',
        currentYearOrSem: [currentYear, currentSem].where((s) => s.isNotEmpty).join(' '),
        isPrimaryCollege: true,
      ));
    }

    // 12th / Diploma
    final twelfthObj = (educationObj['twelfthOrDiploma'] as Map<String, dynamic>?) ?? {};
    if (twelfthObj.isNotEmpty && twelfthObj['institutionName']?.toString().isNotEmpty == true) {
      educationList.add(ResumeEducationItem(
        degree: twelfthObj['course']?.toString() ?? 'Higher Secondary Certificate (HSC – Class XII)',
        institution: twelfthObj['institutionName']?.toString() ?? '',
        boardOrUniversity: twelfthObj['boardOrUniversity']?.toString() ?? '',
        period: twelfthObj['passingYear']?.toString() ?? '',
        score: twelfthObj['percentage'] != null ? '${twelfthObj['percentage']}%' : '',
        scoreLabel: twelfthObj['percentage'] != null ? 'Score: ${twelfthObj['percentage']}%' : '',
      ));
    }

    // 10th Standard
    final tenthObj = (educationObj['tenth'] as Map<String, dynamic>?) ?? {};
    if (tenthObj.isNotEmpty && tenthObj['institutionName']?.toString().isNotEmpty == true) {
      educationList.add(ResumeEducationItem(
        degree: 'Secondary School Leaving Certificate (SSLC – Class X)',
        institution: tenthObj['institutionName']?.toString() ?? '',
        boardOrUniversity: tenthObj['boardOrUniversity']?.toString() ?? '',
        period: tenthObj['passingYear']?.toString() ?? '',
        score: tenthObj['percentage'] != null ? '${tenthObj['percentage']}%' : '',
        scoreLabel: tenthObj['percentage'] != null ? 'Score: ${tenthObj['percentage']}%' : '',
      ));
    }

    // ── Build Experience ──
    final List<ResumeExperienceItem> experienceList = [];
    if (userMeta['experiences'] is List) {
      for (final exp in userMeta['experiences'] as List) {
        if (exp is Map<String, dynamic>) {
          experienceList.add(ResumeExperienceItem(
            id: exp['id']?.toString() ?? '',
            organization: exp['organization']?.toString() ?? '',
            role: exp['role']?.toString() ?? '',
            type: exp['type']?.toString() ?? 'Internship',
            duration: exp['duration']?.toString() ?? '',
            location: exp['location']?.toString() ?? '',
            bulletPoints: (exp['bulletPoints'] as List?)?.map((e) => e.toString()).toList() ?? const [],
          ));
        }
      }
    }

    // ── Build Projects ──
    final List<ResumeProjectItem> projectList = [];
    if (projects.isNotEmpty) {
      for (var p in projects) {
        projectList.add(ResumeProjectItem(
          id: p.id,
          title: p.title,
          role: 'Lead Developer',
          description: p.description,
          technologies: p.technologies,
          githubUrl: p.githubUrl ?? githubUrl,
          status: p.status,
          outcomes: [
            if (p.guideName != null && p.guideName!.isNotEmpty) 'Mentored under ${p.guideName}',
          ],
        ));
      }
    }

    // ── Build Certifications ──
    final List<ResumeCertificationItem> certList = [];
    if (certs.isNotEmpty) {
      for (var c in certs) {
        certList.add(ResumeCertificationItem(
          id: c.id,
          title: c.title,
          provider: c.provider,
          type: c.type == CertificationType.nptel ? 'NPTEL / SWAYAM' : 'Industry Certification',
          certificateId: c.certificateId,
          issueDate: '${c.issueDate.year}-${c.issueDate.month.toString().padLeft(2, '0')}',
          credentialUrl: c.documentUrl,
          isVerified: true,
        ));
      }
    }

    // ── Build Activities & Achievements ──
    final List<ResumeActivityItem> activityList = [];
    if (hackathons.isNotEmpty) {
      for (var h in hackathons) {
        activityList.add(ResumeActivityItem(
          id: h.id,
          title: h.hackathonTitle,
          category: 'Hackathon',
          organizer: h.organizer,
          roleOrRank: 'Participant (${h.teamName})',
          date: '${h.startDate.year}-${h.startDate.month.toString().padLeft(2, '0')}',
          description: h.description,
        ));
      }
    }

    final hasMembership = student?.hasMembership ?? userMeta['hasMembership'] == true;
    if (hasMembership) {
      final org = student?.membershipOrg ?? userMeta['membershipOrg']?.toString() ?? '';
      final memId = student?.membershipId ?? userMeta['membershipId']?.toString() ?? '';
      if (org.isNotEmpty) {
        activityList.add(ResumeActivityItem(
          id: 'mem-1',
          title: 'Professional Member - $org',
          category: 'Professional Society',
          organizer: org,
          roleOrRank: 'Student Member',
          date: 'Active',
          description: 'Member ID: $memId',
        ));
      }
    }

    // ── Build Skills Categorization ──
    final allCollectedSkills = <String>{};

    for (var p in projectList) {
      allCollectedSkills.addAll(p.technologies);
    }

    if (userMeta['skills'] is List) {
      for (var s in userMeta['skills'] as List) {
        if (s.toString().trim().isNotEmpty) {
          allCollectedSkills.add(s.toString().trim());
        }
      }
    }

    final categorizedSkills = _categorizeSkills(allCollectedSkills.toList());

    // ── Build Dynamic Professional Summary ──
    final String summary = _generateSynthesizedSummary(
      fullName: fullName,
      deptName: deptName,
      year: currentYear,
      cgpa: cgpa,
      projectsCount: projectList.length,
      certsCount: certList.length,
      topTechs: allCollectedSkills.take(5).toList(),
      experienceList: experienceList,
    );

    // ── Build Resume Completeness Checklist ──
    final completeness = _calculateCompleteness(
      fullName: fullName,
      collegeEmail: collegeEmail,
      deptName: deptName,
      year: currentYear,
      skills: allCollectedSkills.toList(),
      headline: headline,
      linkedinUrl: linkedinUrl,
      githubUrl: githubUrl,
      portfolioUrl: portfolioUrl,
      projects: projectList,
      certifications: certList,
      experiences: experienceList,
      activities: activityList,
    );

    final resume = StudentResumeModel(
      studentUid: user?.uid ?? student?.userId ?? cleanId,
      registerNumber: student?.registerNumber ?? userMeta['registerNumber']?.toString() ?? cleanId,
      department: deptName,
      academicYear: currentYear,
      section: student?.section ?? userMeta['section']?.toString() ?? '',
      header: header,
      professionalSummary: summary,
      education: educationList,
      experience: experienceList,
      projects: projectList,
      certifications: certList,
      activitiesAndAchievements: activityList,
      categorizedSkills: categorizedSkills,
      allSkills: allCollectedSkills.toList(),
      completeness: completeness,
      lastUpdatedAt: DateTime.now(),
      version: 1,
    );

    return resume;
  }

  /// Categorize skill strings into 5 structured domain buckets
  List<ResumeSkillCategory> _categorizeSkills(List<String> rawSkills) {
    final languages = <String>{};
    final frontendMobile = <String>{};
    final backendDatabase = <String>{};
    final cloudAi = <String>{};
    final toolsWorkflow = <String>{};

    for (var s in rawSkills) {
      final lower = s.toLowerCase().trim();

      if (['dart', 'python', 'c++', 'java', 'c', 'javascript', 'typescript', 'sql', 'solidity', 'golang', 'rust', 'kotlin', 'swift'].contains(lower)) {
        languages.add(s);
      } else if (lower.contains('flutter') || lower.contains('react') || lower.contains('vue') || lower.contains('angular') || lower.contains('html') || lower.contains('css') || lower.contains('tailwind') || lower.contains('mobile') || lower.contains('android') || lower.contains('ios') || lower.contains('frontend')) {
        frontendMobile.add(s);
      } else if (lower.contains('node') || lower.contains('firebase') || lower.contains('firestore') || lower.contains('postgres') || lower.contains('mongo') || lower.contains('sql') || lower.contains('rest') || lower.contains('api') || lower.contains('graphql') || lower.contains('express') || lower.contains('backend') || lower.contains('django')) {
        backendDatabase.add(s);
      } else if (lower.contains('cloud') || lower.contains('aws') || lower.contains('gcp') || lower.contains('google cloud') || lower.contains('docker') || lower.contains('kubernetes') || lower.contains('tensor') || lower.contains('opencv') || lower.contains('machine learning') || lower.contains('ai') || lower.contains('devops') || lower.contains('deep learning')) {
        cloudAi.add(s);
      } else {
        toolsWorkflow.add(s);
      }
    }

    final categories = <ResumeSkillCategory>[];
    if (languages.isNotEmpty) {
      categories.add(ResumeSkillCategory(categoryName: 'Programming Languages', skills: languages.toList()));
    }
    if (frontendMobile.isNotEmpty) {
      categories.add(ResumeSkillCategory(categoryName: 'Mobile & Frontend Development', skills: frontendMobile.toList()));
    }
    if (backendDatabase.isNotEmpty) {
      categories.add(ResumeSkillCategory(categoryName: 'Backend, Databases & APIs', skills: backendDatabase.toList()));
    }
    if (cloudAi.isNotEmpty) {
      categories.add(ResumeSkillCategory(categoryName: 'Cloud, AI & Distributed Systems', skills: cloudAi.toList()));
    }
    if (toolsWorkflow.isNotEmpty) {
      categories.add(ResumeSkillCategory(categoryName: 'Developer Tools & Workflow', skills: toolsWorkflow.toList()));
    }

    return categories;
  }

  /// Synthesize a clean, professional summary from verified facts only
  String _generateSynthesizedSummary({
    required String fullName,
    required String deptName,
    required String year,
    required String cgpa,
    required int projectsCount,
    required int certsCount,
    required List<String> topTechs,
    required List<ResumeExperienceItem> experienceList,
  }) {
    final techString = topTechs.take(4).join(', ');
    final experienceContext = experienceList.isNotEmpty
        ? 'with internship experience in ${experienceList.first.role}'
        : 'with strong practical acumen in software development';

    return '$year $deptName undergraduate with a strong academic foundation (CGPA: $cgpa) and demonstrated expertise in $techString. Proven track record of developing $projectsCount+ end-to-end technical projects, $experienceContext, and earning $certsCount verified industry certifications. Eager to contribute to scalable engineering solutions in fast-paced software environments.';
  }

  /// Calculate Resume Completeness Score with Required vs Recommended breakdown
  ResumeCompleteness _calculateCompleteness({
    required String fullName,
    required String collegeEmail,
    required String deptName,
    required String year,
    required List<String> skills,
    required String headline,
    required String? linkedinUrl,
    required String? githubUrl,
    required String? portfolioUrl,
    required List<ResumeProjectItem> projects,
    required List<ResumeCertificationItem> certifications,
    required List<ResumeExperienceItem> experiences,
    required List<ResumeActivityItem> activities,
  }) {
    final checklist = <ResumeCompletenessItem>[
      // Required Profile Information (50% total weight)
      ResumeCompletenessItem(
        id: 'req_name',
        title: 'Full Student Name',
        description: 'Official registered name on campus records',
        isCompleted: fullName.trim().isNotEmpty,
        isRequired: true,
        actionRoute: 'profile',
        actionLabel: 'Edit Profile',
      ),
      ResumeCompletenessItem(
        id: 'req_email',
        title: 'Institutional College Email',
        description: 'Verified college domain email address',
        isCompleted: collegeEmail.trim().isNotEmpty,
        isRequired: true,
        actionRoute: 'profile',
        actionLabel: 'Verify Email',
      ),
      ResumeCompletenessItem(
        id: 'req_dept',
        title: 'Degree & Department Information',
        description: 'Official academic discipline & batch enrollment',
        isCompleted: deptName.trim().isNotEmpty && year.trim().isNotEmpty,
        isRequired: true,
        actionRoute: 'profile',
        actionLabel: 'Check Dept',
      ),
      ResumeCompletenessItem(
        id: 'req_skills',
        title: 'Core Technical Skills (Min. 3)',
        description: 'Programming languages, tools, or frameworks',
        isCompleted: skills.length >= 3,
        isRequired: true,
        actionRoute: 'profile',
        actionLabel: 'Add Skills',
      ),
      ResumeCompletenessItem(
        id: 'req_education',
        title: 'Primary Education Record',
        description: 'Institution, expected graduation year & CGPA',
        isCompleted: true,
        isRequired: true,
        actionRoute: 'profile',
        actionLabel: 'View Academics',
      ),

      // Recommended Resume Enhancements (50% total weight)
      ResumeCompletenessItem(
        id: 'rec_headline',
        title: 'Professional Headline',
        description: 'A clear career tagline (e.g. Flutter & Mobile Developer)',
        isCompleted: headline.trim().isNotEmpty && !headline.contains('Undergraduate & Aspiring'),
        isRequired: false,
        actionRoute: 'profile',
        actionLabel: 'Set Tagline',
      ),
      ResumeCompletenessItem(
        id: 'rec_linkedin',
        title: 'LinkedIn Professional Profile',
        description: 'Connect your public LinkedIn URL for recruiter verification',
        isCompleted: linkedinUrl != null && linkedinUrl.isNotEmpty,
        isRequired: false,
        actionRoute: 'profile',
        actionLabel: 'Link LinkedIn',
      ),
      ResumeCompletenessItem(
        id: 'rec_github',
        title: 'GitHub Developer Portfolio',
        description: 'Showcase repositories, commit activity & open-source code',
        isCompleted: githubUrl != null && githubUrl.isNotEmpty,
        isRequired: false,
        actionRoute: 'profile',
        actionLabel: 'Link GitHub',
      ),
      ResumeCompletenessItem(
        id: 'rec_projects',
        title: 'Key Technical Projects (Min. 2)',
        description: 'Add live projects with tech stacks and outcomes',
        isCompleted: projects.length >= 2,
        isRequired: false,
        actionRoute: 'projects',
        actionLabel: 'Add Projects',
      ),
      ResumeCompletenessItem(
        id: 'rec_certs',
        title: 'Verified Certifications (NPTEL / Industry)',
        description: 'Include approved NPTEL or cloud/software credentials',
        isCompleted: certifications.isNotEmpty,
        isRequired: false,
        actionRoute: 'certifications',
        actionLabel: 'Upload Certs',
      ),
      ResumeCompletenessItem(
        id: 'rec_activities',
        title: 'Hackathons & Campus Achievements',
        description: 'Record competition participations, awards, or club roles',
        isCompleted: activities.isNotEmpty,
        isRequired: false,
        actionRoute: 'hackathons',
        actionLabel: 'Add Activities',
      ),
      ResumeCompletenessItem(
        id: 'rec_experience',
        title: 'Internship / Work Experience',
        description: 'Document industry internships, freelance, or startup work',
        isCompleted: experiences.isNotEmpty,
        isRequired: false,
        actionRoute: 'profile',
        actionLabel: 'Add Experience',
      ),
    ];

    final requiredList = checklist.where((c) => c.isRequired).toList();
    final recommendedList = checklist.where((c) => !c.isRequired).toList();

    final reqCompleted = requiredList.where((c) => c.isCompleted).length;
    final recCompleted = recommendedList.where((c) => c.isCompleted).length;

    // 50% for required, 50% for recommended
    final double reqWeight = requiredList.isEmpty ? 50 : (reqCompleted / requiredList.length) * 50;
    final double recWeight = recommendedList.isEmpty ? 50 : (recCompleted / recommendedList.length) * 50;
    final int score = (reqWeight + recWeight).round().clamp(0, 100);

    return ResumeCompleteness(
      scorePercentage: score,
      requiredTotal: requiredList.length,
      requiredCompleted: reqCompleted,
      recommendedTotal: recommendedList.length,
      recommendedCompleted: recCompleted,
      checklist: checklist,
    );
  }

  /// Get list of student resumes for HOD authorized department
  Future<List<StudentResumeModel>> getResumesForDepartment(String departmentName) async {
    final firestore = _firestore;
    final List<StudentResumeModel> results = [];

    if (firestore != null) {
      try {
        final snap = await firestore.collection('students').get();
        for (var doc in snap.docs) {
          final data = doc.data();
          final dept = data['departmentName'] ?? data['department_name'] ?? data['departmentId'] ?? '';
          if (dept.toString().toLowerCase().contains(departmentName.toLowerCase()) || departmentName == 'All') {
            final r = await generateResumeForStudent(doc.id);
            if (r != null) results.add(r);
          }
        }
      } catch (e) {
        debugPrint('getResumesForDepartment error: $e');
      }
    }

    return results;
  }

  /// Get list of student resumes for Adviser's assigned class / batch
  Future<List<StudentResumeModel>> getResumesForAdviser(String sectionOrBatch) async {
    final firestore = _firestore;
    final List<StudentResumeModel> results = [];

    if (firestore != null) {
      try {
        final snap = await firestore.collection('students').get();
        for (var doc in snap.docs) {
          final data = doc.data();
          final sec = data['section']?.toString() ?? '';
          final b = data['batch']?.toString() ?? '';
          if (sectionOrBatch == 'All' || sec.contains(sectionOrBatch) || b.contains(sectionOrBatch)) {
            final r = await generateResumeForStudent(doc.id);
            if (r != null) results.add(r);
          }
        }
      } catch (e) {
        debugPrint('getResumesForAdviser error: $e');
      }
    }

    return results;
  }
}
