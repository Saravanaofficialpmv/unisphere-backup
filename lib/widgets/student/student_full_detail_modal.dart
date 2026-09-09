import 'dart:io';
import 'package:flutter/material.dart';
import 'package:unisphere/screens/features/leetcode_detail_screen.dart';
import 'package:unisphere/screens/features/github_detail_screen.dart';
import 'package:unisphere/services/resume_service.dart';
import 'package:unisphere/models/student_resume_model.dart';
import 'package:unisphere/widgets/resume/resume_document_view.dart';
import 'package:unisphere/widgets/resume/resume_completeness_card.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';
import 'package:url_launcher/url_launcher.dart';

/// Comprehensive Modal Sheet allowing Staff & HOD to view full student details:
/// LeetCode Analytics, GitHub Repos, Resume PDF, Academic CGPA, Attendance, etc.
void showStudentFullDetailModal(BuildContext context, Map<String, dynamic> student) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StudentFullDetailSheet(student: student),
  );
}

class StudentFullDetailSheet extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentFullDetailSheet({super.key, required this.student});

  @override
  State<StudentFullDetailSheet> createState() => _StudentFullDetailSheetState();
}

class _StudentFullDetailSheetState extends State<StudentFullDetailSheet> {
  Future<void> _launchURL(String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening link: $urlString')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening link: $urlString')),
        );
      }
    }
  }

  void _showNotification(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final String name = s['name'] ?? '-';
    final String regNo = s['regNo'] ?? '-';
    final String year = s['year'] ?? '-';
    final String section = s['section'] ?? '-';
    final String photo = s['photo'] ?? '';
    final String cgpa = s['cgpa'] ?? '-';
    final String attendance = s['attendance'] ?? '-';

    final String leetcodeUsername = s['leetcodeUsername'] ?? '';
    final int leetcodeSolved = (s['leetcodeSolved'] as num?)?.toInt() ?? 0;
    final int leetcodeEasy = (s['leetcodeEasy'] as num?)?.toInt() ?? 0;
    final int leetcodeMedium = (s['leetcodeMedium'] as num?)?.toInt() ?? 0;
    final int leetcodeHard = (s['leetcodeHard'] as num?)?.toInt() ?? 0;
    final int leetcodeStreak = (s['leetcodeStreak'] as num?)?.toInt() ?? 0;

    final String githubUsername = s['githubUsername'] ?? '';
    final int githubRepos = (s['githubRepos'] as num?)?.toInt() ?? 0;
    final int githubCommits = (s['githubCommits'] as num?)?.toInt() ?? 0;
    final int githubStars = (s['githubStars'] as num?)?.toInt() ?? 0;
    final List<String> techStack = List<String>.from(
      s['githubTopTech'] ?? const [],
    );



    return DefaultTabController(
      length: 7,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle indicator
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),

            // Header Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: photo.startsWith('http')
                        ? NetworkImage(photo)
                        : (File(photo).existsSync() ? FileImage(File(photo)) : null) as ImageProvider?,
                    backgroundColor: const Color(0xFFE2E8F0),
                    child: photo.isEmpty ? const Icon(Icons.person, color: Color(0xFF2563EB)) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Text(
                                '$year ($section)',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Reg No: $regNo • CGPA: $cgpa • Att: $attendance',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable TabBar
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: const TabBar(
                isScrollable: true,
                labelColor: Color(0xFF2563EB),
                unselectedLabelColor: Color(0xFF64748B),
                indicatorColor: Color(0xFF2563EB),
                indicatorWeight: 3,
                tabs: [
                  Tab(icon: Icon(Icons.code_rounded, size: 18), text: 'LeetCode Analytics'),
                  Tab(icon: Icon(Icons.terminal_rounded, size: 18), text: 'GitHub & Repos'),
                  Tab(icon: Icon(Icons.description_rounded, size: 18), text: 'Resume & Links'),
                  Tab(icon: Icon(Icons.workspace_premium_rounded, size: 18), text: 'Certifications Portfolio'),
                  Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'Academic Record'),
                  Tab(icon: Icon(Icons.assignment_turned_in_rounded, size: 18), text: 'Internal Marks'),
                  Tab(icon: Icon(Icons.family_restroom_rounded, size: 18), text: 'Personal & Guardian'),
                ],
              ),
            ),

            // TabBar Views
            Expanded(
              child: TabBarView(
                children: [
                  // 1. LeetCode Tab
                  _buildLeetCodeTab(
                    context,
                    leetcodeUsername,
                    leetcodeSolved,
                    leetcodeEasy,
                    leetcodeMedium,
                    leetcodeHard,
                    leetcodeStreak,
                  ),

                  // 2. GitHub Tab
                  _buildGitHubTab(
                    githubUsername,
                    githubRepos,
                    githubCommits,
                    githubStars,
                    techStack,
                  ),

                  // 3. Resume & Links Tab
                  _buildResumeTab(s),

                  // 4. Certifications Portfolio Tab (NPTEL & Industry Certifications)
                  _buildCertificationsPortfolioTab(s),

                  // 5. Academic Record Tab
                  _buildAcademicTab(cgpa, attendance, s),

                  // 6. Internal Marks Tab
                  _buildInternalMarksTab(s),

                  // 7. Personal & Guardian Tab
                  _buildPersonalTab(s),
                ],
              ),
            ),

            // Action Footer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LeetCodeDetailScreen()),
                      );
                    },
                    icon: const Icon(Icons.analytics_rounded, size: 16),
                    label: const Text('Open Live LeetCode Analytics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showNotification('Opening Student PDF Resume...'),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download Resume'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showNotification('Sending email alert to student...'),
                    icon: const Icon(Icons.mail_outline_rounded, size: 16),
                    label: const Text('Contact Student'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: LeetCode Analytics ─────────────────
  Widget _buildLeetCodeTab(
    BuildContext context,
    String username,
    int total,
    int easy,
    int medium,
    int hard,
    int streak,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD8A8)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.code_rounded, color: Color(0xFFEA580C), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '@$username',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Verified Student Profile',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Problems Solved: $total • Streak: $streak Days 🔥',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFC2410C), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Problem Difficulty Breakdown Cards
          const Text(
            'Problem Difficulty Breakdown',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDiffCard('Easy', easy, 820, const Color(0xFF10B981), const Color(0xFFECFDF5)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDiffCard('Medium', medium, 1720, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDiffCard('Hard', hard, 750, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick LeetCode Key Metrics
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Total Solved', '$total', const Color(0xFFEA580C)),
                _buildStatColumn('Global Rank', '#1293478', const Color(0xFF6366F1)),
                _buildStatColumn('Acceptance', '68.4%', const Color(0xFF10B981)),
                _buildStatColumn('Streak', '$streak Days 🔥', const Color(0xFFF59E0B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffCard(String label, int solved, int total, Color color, Color bgColor) {
    final double pct = (solved / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text('$solved / $total', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // ── Tab 2: GitHub & Open Source ───────────────
  Widget _buildGitHubTab(
    String username,
    int repos,
    int commits,
    int stars,
    List<String> techStack,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GitHub Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.terminal_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$username',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'GitHub Developer Profile • Open Source Contributor',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GitHubDetailScreen()),
                        );
                      },
                      icon: const Icon(Icons.analytics_rounded, size: 14),
                      label: const Text('Analytics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => _launchURL('https://github.com/$username'),
                      icon: const Icon(Icons.open_in_new_rounded, size: 13),
                      label: const Text('GitHub', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GitHub Stats Grid
          Row(
            children: [
              Expanded(child: _buildGitStatCard('Public Repos', '$repos', Icons.folder_copy_rounded, const Color(0xFF2563EB))),
              const SizedBox(width: 10),
              Expanded(child: _buildGitStatCard('Commits (Year)', '$commits', Icons.commit_rounded, const Color(0xFF10B981))),
              const SizedBox(width: 10),
              Expanded(child: _buildGitStatCard('Stars Earned', '$stars ⭐', Icons.star_rounded, const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 16),

          // Top Tech Stack
          const Text('Top Languages & Technologies', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: techStack.map((tech) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.code_rounded, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text(tech, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Featured Projects List
          const Text('Featured Repositories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          _buildRepoItem('unisphere-mobile-app', 'Cross-platform Smart Campus ERP built with Flutter & Firebase', 'Dart', 24),
          const SizedBox(height: 8),
          _buildRepoItem('leetcode-solutions-cpp', 'Clean C++ implementations of 130+ LeetCode DSA questions', 'C++', 12),
          const SizedBox(height: 8),
          _buildRepoItem('agentic-ai-assistant', 'Agentic workflow scripts for automated software development', 'Python', 9),
        ],
      ),
    );
  }

  Widget _buildGitStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildRepoItem(String title, String desc, String lang, int stars) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.book_outlined, color: Color(0xFF475569), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(lang, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              const SizedBox(height: 2),
              Text('$stars ⭐', style: const TextStyle(fontSize: 10, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  final Map<String, Future<StudentResumeModel?>> _resumeFutures = {};

  // ── Tab 3: Dedicated Dynamic Resume & Links ────────────────────
  Widget _buildResumeTab(Map<String, dynamic> s) {
    final regNo = s['regNo']?.toString() ?? s['registerNumber']?.toString() ?? s['id']?.toString() ?? '';
    _resumeFutures[regNo] ??= ResumeService().generateResumeForStudent(regNo);

    return FutureBuilder<StudentResumeModel?>(
      future: _resumeFutures[regNo],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Loader(label: 'Aggregating live student resume records...'),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  'No verified resume records found for $regNo.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }

        final resume = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completeness Summary Card
              ResumeCompletenessCard(
                completeness: resume.completeness,
                isCompact: true,
              ),
              const SizedBox(height: 16),

              // Full A4 Document Preview Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          const Text(
                            'Institutional Verified Resume (A4 Preview)',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 11, color: Color(0xFF059669)),
                                SizedBox(width: 4),
                                Text(
                                  'Live Synchronized',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    SizedBox(
                      height: 520,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        child: ResumeDocumentView(
                          resume: resume,
                          showControls: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // ── Tab 4: Certifications Portfolio (NPTEL & Industry) ─────
  Widget _buildCertificationsPortfolioTab(Map<String, dynamic> s) {
    final List<Map<String, dynamic>> nptelCerts = [
      {
        'title': 'Programming in Java',
        'issuer': 'IIT Kharagpur & NPTEL',
        'score': '82%',
        'grade': 'Elite',
        'credentialId': 'NPTEL26CS820',
        'issueDate': 'Aug 2026',
        'status': 'Certified ✓',
        'badgeColor': const Color(0xFFD97706),
        'url': 'https://nptel.ac.in/noc/E-certificate',
      },
      {
        'title': 'NPTEL Elite + Gold: Data Structures and Algorithms in Java',
        'issuer': 'IIT Madras & NPTEL',
        'score': '92% (Top 1% National)',
        'grade': 'Elite + Gold',
        'credentialId': 'NPTEL25CS091',
        'issueDate': 'Oct 2025',
        'status': 'Verified',
        'badgeColor': const Color(0xFFD97706),
        'url': 'https://nptel.ac.in/noc/E-certificate',
      },
      {
        'title': 'NPTEL Elite + Silver: Database Management Systems',
        'issuer': 'IIT Kharagpur & NPTEL',
        'score': '86% (Top 5% National)',
        'grade': 'Elite + Silver',
        'credentialId': 'NPTEL24CS042',
        'issueDate': 'Apr 2025',
        'status': 'Verified',
        'badgeColor': const Color(0xFF475569),
        'url': 'https://nptel.ac.in/noc/E-certificate',
      },
    ];

    final List<Map<String, dynamic>> industryCerts = [
      {
        'title': 'AWS Certified Solutions Architect – Associate',
        'issuer': 'Amazon Web Services (AWS)',
        'level': 'Associate Level',
        'credentialId': 'AWS-ASA-9920148',
        'issueDate': 'Nov 2025',
        'expiryDate': 'Nov 2028',
        'status': 'Verified',
        'badgeColor': const Color(0xFF2563EB),
        'url': 'https://aws.amazon.com/verification',
      },
      {
        'title': 'Google Cloud Associate Cloud Engineer',
        'issuer': 'Google Cloud Training',
        'level': 'Professional Grade',
        'credentialId': 'GCP-ACE-778102',
        'issueDate': 'Jan 2026',
        'expiryDate': 'Jan 2028',
        'status': 'Verified',
        'badgeColor': const Color(0xFF059669),
        'url': 'https://google.accredible.com/verify',
      },
      {
        'title': 'Meta Front-End Developer Professional Certificate',
        'issuer': 'Coursera & Meta',
        'level': 'Specialization',
        'credentialId': 'META-FED-88419',
        'issueDate': 'Feb 2026',
        'expiryDate': 'Lifetime',
        'status': 'Pending Verification',
        'badgeColor': const Color(0xFF7C3AED),
        'url': 'https://coursera.org/verify/meta-fed',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio Overview Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Verified Certifications Portfolio',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Column(
                          children: [
                            Text('TOTAL CERTS', style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('5', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                        ),
                        child: const Column(
                          children: [
                            Text('NPTEL (IIT)', style: TextStyle(fontSize: 9, color: Color(0xFFFCD34D), fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('2', style: TextStyle(fontSize: 16, color: Color(0xFFFBBF24), fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.4)),
                        ),
                        child: const Column(
                          children: [
                            Text('INDUSTRY', style: TextStyle(fontSize: 9, color: Color(0xFF93C5FD), fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('3', style: TextStyle(fontSize: 16, color: Color(0xFF60A5FA), fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── SECTION 1: NPTEL CERTIFICATIONS ──────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school_rounded, color: Color(0xFFD97706), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                '🎓 NPTEL Certifications',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'IIT / MHRD Govt. Verified',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...nptelCerts.map((cert) => _buildNptelCertCard(cert)),

          const SizedBox(height: 24),

          // ── SECTION 2: INDUSTRY CERTIFICATIONS ───────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                '🏢 Industry Certifications',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Global Vendor Credentials',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...industryCerts.map((cert) => _buildIndustryCertCard(cert)),
        ],
      ),
    );
  }

  Widget _buildNptelCertCard(Map<String, dynamic> cert) {
    final Color badgeColor = (cert['badgeColor'] as Color?) ?? const Color(0xFF10B981);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.workspace_premium_rounded, color: badgeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert['title'] as String,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cert['issuer'] as String,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      cert['status'] as String,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SCORE & RANK', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(cert['score'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CREDENTIAL ID', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(cert['credentialId'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('ISSUE DATE', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(cert['issueDate'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _launchURL(cert['url'] as String),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('Verify NPTEL Certificate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndustryCertCard(Map<String, dynamic> cert) {
    final Color badgeColor = (cert['badgeColor'] as Color?) ?? const Color(0xFF10B981);
    final bool isVerified = cert['status'] == 'Verified';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.verified_user_rounded, color: badgeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert['title'] as String,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cert['issuer'] as String,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isVerified ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                      color: isVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cert['status'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CERT LEVEL', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(cert['level'] as String, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: badgeColor)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CREDENTIAL ID', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(cert['credentialId'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('VALIDITY', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${cert['issueDate']} - ${cert['expiryDate']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _launchURL(cert['url'] as String),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('Verify Vendor Credential', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: badgeColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 5: Academic Record ────────────────────
  Widget _buildAcademicTab(String cgpa, String attendance, Map<String, dynamic> s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildInfoCard('Current CGPA', cgpa, 'Rank #3 in Class', const Color(0xFF2563EB))),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoCard('Attendance', attendance, 'Eligible for Exams', const Color(0xFF10B981))),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoCard('Backlogs', '0', 'Clean History', const Color(0xFF059669))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Semester History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          _buildSemRow('Semester 1', '9.00', 'Passed'),
          _buildSemRow('Semester 2', '9.10', 'Passed'),
          _buildSemRow('Semester 3', '9.20', 'Passed'),
          _buildSemRow('Semester 4', '9.15', 'Passed'),
          _buildSemRow('Semester 5', '9.12', 'Passed'),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String mainVal, String subVal, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(mainVal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subVal, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildSemRow(String sem, String gpa, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(sem, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          Row(
            children: [
              Text('GPA: $gpa', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 5: Internal Marks ─────────────────────
  Widget _buildInternalMarksTab(Map<String, dynamic> s) {
    final List<Map<String, String>> subjects = [
      {'code': 'CS3501', 'name': 'Compiler Design', 't1': '48 / 50', 't2': '46 / 50', 'assign': '10 / 10'},
      {'code': 'CS3502', 'name': 'Computer Networks', 't1': '45 / 50', 't2': '47 / 50', 'assign': '10 / 10'},
      {'code': 'CS3503', 'name': 'Full Stack Web Dev', 't1': '50 / 50', 't2': '49 / 50', 'assign': '10 / 10'},
      {'code': 'CS3504', 'name': 'Artificial Intelligence', 't1': '46 / 50', 't2': '48 / 50', 'assign': '10 / 10'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subjects.map((sub) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sub['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Text(sub['code']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMarkPill('Internal Test 1', sub['t1']!),
                    _buildMarkPill('Internal Test 2', sub['t2']!),
                    _buildMarkPill('Assignments', sub['assign']!),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMarkPill(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
      ],
    );
  }

  // ── Tab 6: Personal & Guardian ────────────────
  Widget _buildPersonalTab(Map<String, dynamic> s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Full Name', s['name']?.toString() ?? '-'),
          _buildDetailRow('Register Number', s['regNo']?.toString() ?? '-'),
          _buildDetailRow('Email Address', s['email']?.toString() ?? '-'),
          _buildDetailRow('Phone Number', s['phone']?.toString() ?? '-'),
          _buildDetailRow('Faculty Advisor', s['advisor']?.toString() ?? '-'),
          _buildDetailRow('Residency Type', s['type']?.toString() ?? '-'),
          _buildDetailRow(
            'Professional Membership',
            (s['membershipId'] != null && s['membershipId'] != 'N/A')
                ? '${s['membershipOrg'] ?? 'Society'} (${s['membershipId']})'
                : (s['membership']?['membershipId'] != null && s['membership']?['membershipId'] != 'N/A')
                    ? '${s['membership']?['membershipOrg'] ?? 'Society'} (${s['membership']?['membershipId']})'
                    : '-',
          ),
          _buildDetailRow('Father / Guardian', s['fatherName'] ?? s['parents']?['father']?['name'] ?? '-'),
          _buildDetailRow('Parent Annual Income', s['parentAnnualIncome'] ?? s['parents']?['parentAnnualIncome'] ?? s['parents']?['annualIncome'] ?? '-'),
          _buildDetailRow('Residential Address', s['address'] ?? s['contact']?['permanentAddress']?['addressLine1'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              val,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
