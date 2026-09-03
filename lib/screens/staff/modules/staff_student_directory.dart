import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/widgets/student/student_full_detail_modal.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class StaffStudentDirectory extends ConsumerStatefulWidget {
  const StaffStudentDirectory({super.key});

  @override
  ConsumerState<StaffStudentDirectory> createState() => _StaffStudentDirectoryState();
}

class _StaffStudentDirectoryState extends ConsumerState<StaffStudentDirectory> {
  String _searchQuery = '';
  String _selectedYear = 'All';
  String _selectedSection = 'All';

  final List<Map<String, dynamic>> _studentList = [
    {
      'name': 'Aravind Swamy',
      'regNo': '917721104012',
      'year': '3rd Year',
      'semester': 'Semester 6',
      'section': 'CS-A',
      'cgpa': '9.12',
      'attendance': '96.5%',
      'advisor': 'Dr. S. Meenakshi',
      'gender': 'Male',
      'type': 'Day Scholar',
      'email': 'aravind.s@unisphere.edu',
      'phone': '+91 98765 43210',
      'photo': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
      'leetcodeUsername': 'aravind_s',
      'leetcodeSolved': 130,
      'leetcodeEasy': 104,
      'leetcodeMedium': 24,
      'leetcodeHard': 2,
      'leetcodeStreak': 12,
      'githubUsername': 'aravind-dev',
      'githubRepos': 14,
      'githubCommits': 87,
      'githubStars': 0,
      'githubTopTech': ['Flutter/Dart', 'C++', 'Java', 'Python'],
      'resumeFileName': 'Aravind_Swamy_Resume_2026.pdf',
      'resumeUpdated': 'Updated 2 weeks ago',
      'portfolioUrl': 'https://aravind-swamy.dev',
      'linkedinUrl': 'https://linkedin.com/in/aravind-swamy',
      'skills': ['Data Structures', 'Flutter App Dev', 'REST APIs', 'Firebase', 'Git'],
    },
    {
      'name': 'Priya Dharshini',
      'regNo': '917721104045',
      'year': '3rd Year',
      'semester': 'Semester 6',
      'section': 'CS-A',
      'cgpa': '8.85',
      'attendance': '92.0%',
      'advisor': 'Dr. S. Meenakshi',
      'gender': 'Female',
      'type': 'Hosteller',
      'email': 'priya.d@unisphere.edu',
      'phone': '+91 98765 43211',
      'photo': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      'leetcodeUsername': 'priya_dev',
      'leetcodeSolved': 185,
      'leetcodeEasy': 120,
      'leetcodeMedium': 55,
      'leetcodeHard': 10,
      'leetcodeStreak': 24,
      'githubUsername': 'priyadharshini',
      'githubRepos': 24,
      'githubCommits': 490,
      'githubStars': 68,
      'githubTopTech': ['Python', 'Machine Learning', 'React', 'C++'],
      'resumeFileName': 'Priya_Dharshini_Resume_2026.pdf',
      'resumeUpdated': 'Updated yesterday',
      'portfolioUrl': 'https://priyadharshini.dev',
      'linkedinUrl': 'https://linkedin.com/in/priya-dharshini',
      'skills': ['Machine Learning', 'Python', 'React', 'Data Science', 'SQL'],
    },
    {
      'name': 'Karthik Raja',
      'regNo': '917722104022',
      'year': '2nd Year',
      'semester': 'Semester 4',
      'section': 'CS-B',
      'cgpa': '7.45',
      'attendance': '71.5%',
      'advisor': 'Prof. Rajesh Kumar',
      'gender': 'Male',
      'type': 'Day Scholar',
      'email': 'karthik.r@unisphere.edu',
      'phone': '+91 98765 43212',
      'photo': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      'leetcodeUsername': 'karthik_coder',
      'leetcodeSolved': 74,
      'leetcodeEasy': 60,
      'leetcodeMedium': 14,
      'leetcodeHard': 0,
      'leetcodeStreak': 5,
      'githubUsername': 'karthikraja',
      'githubRepos': 8,
      'githubCommits': 120,
      'githubStars': 14,
      'githubTopTech': ['Java', 'Spring Boot', 'SQL'],
      'resumeFileName': 'Karthik_Raja_Resume.pdf',
      'resumeUpdated': 'Updated 1 month ago',
      'portfolioUrl': 'https://karthik.dev',
      'linkedinUrl': 'https://linkedin.com/in/karthik-raja',
      'skills': ['Java', 'OOP', 'Spring Boot', 'MySQL'],
    },
    {
      'name': 'Sneha Murali',
      'regNo': '917721104088',
      'year': '3rd Year',
      'semester': 'Semester 6',
      'section': 'CS-B',
      'cgpa': '9.45',
      'attendance': '98.0%',
      'advisor': 'Dr. R. Kumar',
      'gender': 'Female',
      'type': 'Day Scholar',
      'email': 'sneha.m@unisphere.edu',
      'phone': '+91 98765 43212',
      'photo': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'leetcodeUsername': 'snehamurali',
      'leetcodeSolved': 310,
      'leetcodeEasy': 150,
      'leetcodeMedium': 130,
      'leetcodeHard': 30,
      'leetcodeStreak': 40,
      'githubUsername': 'snehamurali',
      'githubRepos': 30,
      'githubCommits': 620,
      'githubStars': 95,
      'githubTopTech': ['C++', 'Rust', 'Algorithms', 'TypeScript'],
      'resumeFileName': 'Sneha_Murali_Resume_2026.pdf',
      'resumeUpdated': 'Updated 3 days ago',
      'portfolioUrl': 'https://snehamurali.dev',
      'linkedinUrl': 'https://linkedin.com/in/sneha-murali',
      'skills': ['Competitive Programming', 'C++', 'System Architecture', 'Rust'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final dbStudents = ref.watch(allStudentsStreamProvider).value ?? [];
    final List<Map<String, dynamic>> combinedList = [..._studentList];
    for (var u in dbStudents) {
      final meta = u.metadata ?? {};
      if (!combinedList.any((s) => s['email'] == u.email)) {
        combinedList.insert(0, {
          'name': u.name.isNotEmpty ? u.name : (u.email.contains('@') ? u.email.split('@').first : 'Registered Student'),
          'regNo': meta['registerNumber'] ?? u.uid,
          'year': meta['year'] ?? (meta['semester'] ?? '3rd Year'),
          'semester': meta['semester'] ?? 'Semester 6',
          'section': meta['section'] ?? 'Sec A',
          'cgpa': meta['cgpa']?.toString() ?? '0.0',
          'attendance': meta['attendance'] != null ? '${meta['attendance']}%' : 'N/A',
          'advisor': 'Dr. R. Kumar (HOD)',
          'gender': meta['gender'] ?? 'Not specified',
          'type': meta['residenceType'] ?? 'Day Scholar',
          'email': u.email,
          'phone': u.phoneNumber ?? meta['phoneNumber'] ?? 'Not set',
          'photo': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
          'leetcodeUsername': meta['leetcodeUsername'] ?? '',
          'leetcodeSolved': meta['leetcodeSolved'] ?? 0,
          'githubUsername': meta['githubUsername'] ?? '',
          'githubRepos': meta['githubRepos'] ?? 0,
          'githubCommits': meta['githubCommits'] ?? 0,
          'linkedinUrl': meta['linkedinUrl'] ?? '',
          'skills': meta['skills'] ?? ['Academic Student'],
        });
      }
    }

    final filtered = combinedList.where((s) {
      final matchesSearch = s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['regNo'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['leetcodeUsername'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesYear = _selectedYear == 'All' || s['year'] == _selectedYear;
      final matchesSection = _selectedSection == 'All' || s['section'] == _selectedSection;
      return matchesSearch && matchesYear && matchesSection;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppLiquidPullToRefresh(
        gifAsset: 'assets/tibsy-dp.gif',
        onRefresh: () async {
          ref.invalidate(allStudentsStreamProvider);
          await Future.delayed(const Duration(milliseconds: 1000));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FACULTY ACCESS PORTAL',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            const Text(
              'Student Directory & Portfolios',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Access student LeetCode analytics, GitHub repositories, Resumes, CGPA & academic progress.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 20),
            Text(
              'STUDENTS FOUND (${filtered.length})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildStudentCard(context, filtered[index]);
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          hintText: 'Search student name, reg no, or LeetCode handle...',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterDropdown('Year', _selectedYear, ['All', '1st Year', '2nd Year', '3rd Year', '4th Year'], (v) => setState(() => _selectedYear = v!)),
          const SizedBox(width: 10),
          _buildFilterDropdown('Section', _selectedSection, ['All', 'CS-A', 'CS-B', 'CS-C'], (v) => setState(() => _selectedSection = v!)),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text('$label: $e'))).toList(),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Map<String, dynamic> item) {
    final String leetcodeHandle = item['leetcodeUsername'] ?? '';
    final int solved = leetcodeHandle.isEmpty ? 0 : (item['leetcodeSolved'] ?? 0);
    final int streak = leetcodeHandle.isEmpty ? 0 : (item['leetcodeStreak'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 26, backgroundImage: NetworkImage(item['photo'])),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${item['regNo']} • ${item['year']} (${item['section']})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Text(
                  'LeetCode: $solved Solved',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Portfolio Highlights Pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildTagPill('@$leetcodeHandle', Icons.code_rounded, const Color(0xFFEA580C), const Color(0xFFFFF7ED)),
              _buildTagPill('CGPA: ${item['cgpa']}', Icons.school_rounded, AppColors.primary, const Color(0xFFEFF6FF)),
              _buildTagPill('${item['githubRepos']} Repos', Icons.terminal_rounded, const Color(0xFF0F172A), const Color(0xFFF1F5F9)),
              _buildTagPill('$streak Days Streak 🔥', Icons.local_fire_department_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
            ],
          ),
          const SizedBox(height: 14),

          // Primary View Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showStudentFullDetailModal(context, item),
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: const Text('Access LeetCode, GitHub & Full Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(String label, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
