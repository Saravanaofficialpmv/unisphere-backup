import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/leetcode_service.dart';
import 'package:unisphere/services/github_service.dart';
import 'package:unisphere/services/linkedin_service.dart';

class CustomUserLink {
  final String id;
  final String title;
  final String url;
  final String category;

  const CustomUserLink({
    required this.id,
    required this.title,
    required this.url,
    this.category = 'General',
  });
}

/// Data model representing the student's academic overview metrics.
class AcademicOverviewData {
  final double attendancePercentage;
  final double attendanceTrend;
  final String attendanceStatus;
  final double cgpa;
  final double cgpaTrend;
  final String cgpaLabel;
  final int odDays;
  final String odStatus;
  final int leetcodeSolved;
  final String leetcodeStatus;
  final String leetcodeUsername;
  final String githubUsername;
  final int githubRepos;
  final int githubStars;
  final int githubCommits;
  final String linkedinUrl;
  final String linkedinConnections;
  final String linkedinHeadline;
  final List<CustomUserLink> customLinks;

  const AcademicOverviewData({
    required this.attendancePercentage,
    required this.attendanceTrend,
    required this.attendanceStatus,
    required this.cgpa,
    required this.cgpaTrend,
    required this.cgpaLabel,
    this.odDays = 0,
    this.odStatus = 'None',
    this.leetcodeSolved = 0,
    this.leetcodeStatus = 'Not linked',
    this.leetcodeUsername = '',
    this.githubUsername = '',
    this.githubRepos = 0,
    this.githubStars = 0,
    this.githubCommits = 0,
    this.linkedinUrl = '',
    this.linkedinConnections = '0',
    this.linkedinHeadline = '',
    this.customLinks = const [],
  });
}

/// Notifier to manage state updates for the student's academic overview.
class AcademicOverviewNotifier extends StateNotifier<AcademicOverviewData> {
  AcademicOverviewNotifier({UserModel? user})
      : super(_buildInitialState(user)) {
    if (state.leetcodeUsername.isNotEmpty) {
      fetchLeetCodeStats(state.leetcodeUsername);
    }
    if (state.githubUsername.isNotEmpty) {
      fetchGitHubStats(state.githubUsername);
    }
    if (state.linkedinUrl.isNotEmpty) {
      fetchLinkedInStats(state.linkedinUrl);
    }
  }

  static AcademicOverviewData _buildInitialState(UserModel? user) {
    final meta = user?.metadata ?? {};

    final double? savedCgpa = double.tryParse(meta['cgpa']?.toString() ?? '');
    final double? savedAtt = double.tryParse(meta['attendance']?.toString() ?? '');

    // Live values from user metadata in database or empty defaults
    final leetcodeUser = meta['leetcodeUsername']?.toString() ?? '';
    final githubUser = meta['githubUsername']?.toString() ?? '';
    final linkedinUrl = meta['linkedinUrl']?.toString() ?? '';
    final double cgpa = savedCgpa ?? 0.0;
    final double attendance = savedAtt ?? 0.0;

    return AcademicOverviewData(
      attendancePercentage: attendance,
      attendanceTrend: 0.0,
      attendanceStatus: attendance >= 75.0 ? 'Good' : (attendance > 0 ? 'Critical' : 'N/A'),
      cgpa: cgpa,
      cgpaTrend: 0.0,
      cgpaLabel: cgpa > 0 ? 'Current CGPA' : 'Not set',
      odDays: 0,
      odStatus: 'None',
      leetcodeSolved: 0,
      leetcodeStatus: leetcodeUser.isNotEmpty ? 'Syncing...' : 'Not linked',
      leetcodeUsername: leetcodeUser,
      githubUsername: githubUser,
      githubRepos: 0,
      githubStars: 0,
      githubCommits: 0,
      linkedinUrl: linkedinUrl,
      linkedinConnections: '0',
      linkedinHeadline: '',
      customLinks: const [],
    );
  }

  /// Automatically updates LeetCode solved count from public LeetCode API
  Future<void> fetchLeetCodeStats(String username) async {
    if (username.isEmpty) return;
    final stats = await LeetCodeService.fetchUserStats(username);
    if (!mounted) return;
    state = AcademicOverviewData(
      attendancePercentage: state.attendancePercentage,
      attendanceTrend: state.attendanceTrend,
      attendanceStatus: state.attendanceStatus,
      cgpa: state.cgpa,
      cgpaTrend: state.cgpaTrend,
      cgpaLabel: state.cgpaLabel,
      odDays: state.odDays,
      odStatus: state.odStatus,
      leetcodeSolved: stats.totalSolved,
      leetcodeStatus: stats.status,
      leetcodeUsername: username,
      githubUsername: state.githubUsername,
      githubRepos: state.githubRepos,
      githubStars: state.githubStars,
      githubCommits: state.githubCommits,
      linkedinUrl: state.linkedinUrl,
      linkedinConnections: state.linkedinConnections,
      linkedinHeadline: state.linkedinHeadline,
      customLinks: state.customLinks,
    );
  }

  /// Automatically updates GitHub stats from GitHub REST API
  Future<void> fetchGitHubStats(String username) async {
    if (username.isEmpty) return;
    final stats = await GitHubService.fetchUserStats(username);
    if (!mounted) return;
    state = AcademicOverviewData(
      attendancePercentage: state.attendancePercentage,
      attendanceTrend: state.attendanceTrend,
      attendanceStatus: state.attendanceStatus,
      cgpa: state.cgpa,
      cgpaTrend: state.cgpaTrend,
      cgpaLabel: state.cgpaLabel,
      odDays: state.odDays,
      odStatus: state.odStatus,
      leetcodeSolved: state.leetcodeSolved,
      leetcodeStatus: state.leetcodeStatus,
      leetcodeUsername: state.leetcodeUsername,
      githubUsername: username,
      githubRepos: stats.publicRepos,
      githubStars: stats.starsEarned,
      githubCommits: stats.commitsThisYear,
      linkedinUrl: state.linkedinUrl,
      linkedinConnections: state.linkedinConnections,
      linkedinHeadline: state.linkedinHeadline,
      customLinks: state.customLinks,
    );
  }

  /// Automatically updates LinkedIn professional profile stats
  Future<void> fetchLinkedInStats(String urlOrHandle) async {
    if (urlOrHandle.isEmpty) return;
    final stats = await LinkedInService.fetchProfileStats(urlOrHandle);
    if (!mounted) return;
    state = AcademicOverviewData(
      attendancePercentage: state.attendancePercentage,
      attendanceTrend: state.attendanceTrend,
      attendanceStatus: state.attendanceStatus,
      cgpa: state.cgpa,
      cgpaTrend: state.cgpaTrend,
      cgpaLabel: state.cgpaLabel,
      odDays: state.odDays,
      odStatus: state.odStatus,
      leetcodeSolved: state.leetcodeSolved,
      leetcodeStatus: state.leetcodeStatus,
      leetcodeUsername: state.leetcodeUsername,
      githubUsername: state.githubUsername,
      githubRepos: state.githubRepos,
      githubStars: state.githubStars,
      githubCommits: state.githubCommits,
      linkedinUrl: stats.profileUrl,
      linkedinConnections: stats.connectionsCount,
      linkedinHeadline: stats.headline,
      customLinks: state.customLinks,
    );
  }

  /// Performs full concurrent sync with LeetCode, GitHub, and LinkedIn API stats
  Future<void> refreshAllStats() async {
    final futures = <Future>[];
    if (state.leetcodeUsername.isNotEmpty) {
      futures.add(fetchLeetCodeStats(state.leetcodeUsername));
    }
    if (state.githubUsername.isNotEmpty) {
      futures.add(fetchGitHubStats(state.githubUsername));
    }
    if (state.linkedinUrl.isNotEmpty) {
      futures.add(fetchLinkedInStats(state.linkedinUrl));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  void addCustomLink({required String title, required String url, String category = 'General'}) {
    final newLink = CustomUserLink(
      id: 'cl_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      url: url.trim(),
      category: category,
    );
    final updatedLinks = [...state.customLinks, newLink];
    state = AcademicOverviewData(
      attendancePercentage: state.attendancePercentage,
      attendanceTrend: state.attendanceTrend,
      attendanceStatus: state.attendanceStatus,
      cgpa: state.cgpa,
      cgpaTrend: state.cgpaTrend,
      cgpaLabel: state.cgpaLabel,
      odDays: state.odDays,
      odStatus: state.odStatus,
      leetcodeSolved: state.leetcodeSolved,
      leetcodeStatus: state.leetcodeStatus,
      leetcodeUsername: state.leetcodeUsername,
      githubUsername: state.githubUsername,
      githubRepos: state.githubRepos,
      githubStars: state.githubStars,
      githubCommits: state.githubCommits,
      linkedinUrl: state.linkedinUrl,
      linkedinConnections: state.linkedinConnections,
      linkedinHeadline: state.linkedinHeadline,
      customLinks: updatedLinks,
    );
  }

  void removeCustomLink(String linkId) {
    final updatedLinks = state.customLinks.where((l) => l.id != linkId).toList();
    state = AcademicOverviewData(
      attendancePercentage: state.attendancePercentage,
      attendanceTrend: state.attendanceTrend,
      attendanceStatus: state.attendanceStatus,
      cgpa: state.cgpa,
      cgpaTrend: state.cgpaTrend,
      cgpaLabel: state.cgpaLabel,
      odDays: state.odDays,
      odStatus: state.odStatus,
      leetcodeSolved: state.leetcodeSolved,
      leetcodeStatus: state.leetcodeStatus,
      leetcodeUsername: state.leetcodeUsername,
      githubUsername: state.githubUsername,
      githubRepos: state.githubRepos,
      githubStars: state.githubStars,
      githubCommits: state.githubCommits,
      linkedinUrl: state.linkedinUrl,
      linkedinConnections: state.linkedinConnections,
      linkedinHeadline: state.linkedinHeadline,
      customLinks: updatedLinks,
    );
  }

  void updateData({
    double? attendancePercentage,
    double? attendanceTrend,
    String? attendanceStatus,
    double? cgpa,
    double? cgpaTrend,
    String? cgpaLabel,
    int? odDays,
    String? odStatus,
    int? leetcodeSolved,
    String? leetcodeStatus,
    String? leetcodeUsername,
    String? githubUsername,
    int? githubRepos,
    int? githubStars,
    int? githubCommits,
    String? linkedinUrl,
    String? linkedinConnections,
    String? linkedinHeadline,
    List<CustomUserLink>? customLinks,
  }) {
    state = AcademicOverviewData(
      attendancePercentage: attendancePercentage ?? state.attendancePercentage,
      attendanceTrend: attendanceTrend ?? state.attendanceTrend,
      attendanceStatus: attendanceStatus ?? state.attendanceStatus,
      cgpa: cgpa ?? state.cgpa,
      cgpaTrend: cgpaTrend ?? state.cgpaTrend,
      cgpaLabel: cgpaLabel ?? state.cgpaLabel,
      odDays: odDays ?? state.odDays,
      odStatus: odStatus ?? state.odStatus,
      leetcodeSolved: leetcodeSolved ?? state.leetcodeSolved,
      leetcodeStatus: leetcodeStatus ?? state.leetcodeStatus,
      leetcodeUsername: leetcodeUsername ?? state.leetcodeUsername,
      githubUsername: githubUsername ?? state.githubUsername,
      githubRepos: githubRepos ?? state.githubRepos,
      githubStars: githubStars ?? state.githubStars,
      githubCommits: githubCommits ?? state.githubCommits,
      linkedinUrl: linkedinUrl ?? state.linkedinUrl,
      linkedinConnections: linkedinConnections ?? state.linkedinConnections,
      linkedinHeadline: linkedinHeadline ?? state.linkedinHeadline,
      customLinks: customLinks ?? state.customLinks,
    );
  }
}

/// Riverpod provider for student academic overview metrics.
final academicOverviewProvider =
    StateNotifierProvider<AcademicOverviewNotifier, AcademicOverviewData>(
  (ref) {
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    return AcademicOverviewNotifier(user: user);
  },
);
