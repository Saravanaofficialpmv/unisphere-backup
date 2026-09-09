import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/constants/app_departments.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

class UserManagementModule extends StatefulWidget {
  const UserManagementModule({super.key});

  @override
  State<UserManagementModule> createState() => _UserManagementModuleState();
}

class _UserManagementModuleState extends State<UserManagementModule> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allUsers = [
    {
      'id': 'USR-1001',
      'name': 'Ethan Caldwell',
      'email': 'e.caldwell@unisphere.edu',
      'role': 'STUDENT',
      'dept': 'Computer Science',
      'status': 'Active',
      'phone': '+1 (555) 234-5678',
      'joined': 'Aug 2023',
    },
    {
      'id': 'USR-1002',
      'name': 'Dr. Sarah Jenkins',
      'email': 's.jenkins@unisphere.edu',
      'role': 'STAFF',
      'dept': 'Applied Physics',
      'status': 'Active',
      'phone': '+1 (555) 345-6789',
      'joined': 'Jan 2021',
    },
    {
      'id': 'USR-1003',
      'name': 'Marcus Thorne',
      'email': 'm.thorne@unisphere.edu',
      'role': 'PARENT',
      'dept': 'N/A',
      'status': 'Pending',
      'phone': '+1 (555) 456-7890',
      'joined': 'Jul 2024',
    },
    {
      'id': 'USR-1004',
      'name': 'Elena Rodriguez',
      'email': 'e.rod@unisphere.edu',
      'role': 'ADMIN',
      'dept': 'Administration',
      'status': 'Inactive',
      'phone': '+1 (555) 567-8901',
      'joined': 'Mar 2019',
    },
    {
      'id': 'USR-1005',
      'name': 'Dr. Robert Chen',
      'email': 'r.chen@unisphere.edu',
      'role': 'STAFF',
      'dept': 'Computer Science',
      'status': 'Active',
      'phone': '+1 (555) 678-9012',
      'joined': 'Sep 2020',
    },
    {
      'id': 'USR-1006',
      'name': 'Sophia Martinez',
      'email': 's.martinez@unisphere.edu',
      'role': 'STUDENT',
      'dept': 'Applied Physics',
      'status': 'Active',
      'phone': '+1 (555) 789-0123',
      'joined': 'Aug 2023',
    },
    {
      'id': 'USR-1007',
      'name': 'Liam Wilson',
      'email': 'l.wilson@unisphere.edu',
      'role': 'STUDENT',
      'dept': 'Computer Science',
      'status': 'Pending',
      'phone': '+1 (555) 890-1234',
      'joined': 'Jun 2024',
    },
  ];

  String _searchQuery = '';
  String _selectedRole = 'All Roles';
  String _selectedDept = 'All Departments';
  String _selectedStatus = 'Any Status';

  int _currentPage = 1;
  final int _pageSize = 3;

  final List<String> _roles = ['All Roles', 'STUDENT', 'STAFF', 'PARENT', 'ADMIN'];
  final List<String> _departments = [
    'All Departments',
    ...AppDepartments.list,
    'Administration',
    'N/A',
  ];
  final List<String> _statuses = ['Any Status', 'Active', 'Pending', 'Inactive'];

  List<Map<String, dynamic>> get _filteredUsers {
    return _allUsers.where((user) {
      final matchesSearch =
          user['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _selectedRole == 'All Roles' || user['role'] == _selectedRole;
      final matchesDept = _selectedDept == 'All Departments' || user['dept'] == _selectedDept;
      final matchesStatus = _selectedStatus == 'Any Status' || user['status'] == _selectedStatus;

      return matchesSearch && matchesRole && matchesDept && matchesStatus;
    }).toList();
  }

  int get _totalPages {
    final count = _filteredUsers.length;
    if (count == 0) return 1;
    return (count / _pageSize).ceil();
  }

  List<Map<String, dynamic>> get _paginatedUsers {
    final filtered = _filteredUsers;
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= filtered.length) return [];
    return filtered.skip(startIndex).take(_pageSize).toList();
  }

  StreamSubscription? _usersSub;

  @override
  void initState() {
    super.initState();
    _connectFirestore();
  }

  void _connectFirestore() {
    try {
      final firestore = FirebaseFirestore.instance;
      _usersSub = firestore.collection('users').snapshots().listen((snap) {
        if (!mounted) return;
        if (snap.docs.isNotEmpty) {
          final liveList = snap.docs.map((doc) {
            final data = doc.data();
            final roleStr = (data['role']?.toString().toUpperCase()) ?? 'STUDENT';
            final meta = data['metadata'] is Map ? data['metadata'] as Map<String, dynamic> : <String, dynamic>{};
            return {
              'id': doc.id,
              'name': data['fullName'] ?? data['name'] ?? 'User',
              'email': data['email'] ?? '',
              'role': roleStr,
              'dept': data['department'] ?? data['departmentName'] ?? meta['department'] ?? 'Computer Science',
              'status': data['status'] ?? (data['isActive'] == false ? 'Inactive' : 'Active'),
              'phone': data['phoneNumber'] ?? data['phone'] ?? '-',
              'joined': data['createdAt'] != null
                  ? (data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).toDate().toString().substring(0, 10)
                      : data['createdAt'].toString().substring(0, 10))
                  : 'Aug 2024',
            };
          }).toList();

          setState(() {
            _allUsers.clear();
            _allUsers.addAll(liveList);
          });
        }
      }, onError: (e) {
        debugPrint('Firestore users stream notice: $e');
      });
    } catch (_) {}
  }

  Future<void> _saveUserToFirestore(Map<String, dynamic> userMap) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final uid = userMap['id']?.toString() ?? 'USR_${DateTime.now().millisecondsSinceEpoch}';
      await firestore.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': userMap['name'],
        'name': userMap['name'],
        'email': userMap['email'],
        'role': userMap['role']?.toString().toLowerCase(),
        'department': userMap['dept'],
        'status': userMap['status'] ?? 'Active',
        'isActive': userMap['status'] != 'Inactive',
        'phoneNumber': userMap['phone'],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (userMap['role'] == 'STUDENT') {
        await firestore.collection('students').doc(uid).set({
          'userId': uid,
          'fullName': userMap['name'],
          'departmentId': userMap['dept'],
          'registerNumber': uid,
        }, SetOptions(merge: true));
      } else if (userMap['role'] == 'STAFF') {
        await firestore.collection('staff').doc(uid).set({
          'userId': uid,
          'fullName': userMap['name'],
          'departmentId': userMap['dept'],
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore save user error: $e');
    }
  }

  Future<void> _deleteUserFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).delete();
      await firestore.collection('students').doc(uid).delete();
      await firestore.collection('staff').doc(uid).delete();
    } catch (e) {
      debugPrint('Firestore delete user error: $e');
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildTopActions(),
        const SizedBox(height: 24),
        _buildTotalUsersHero(),
        const SizedBox(height: 24),
        _buildSearchBar(),
        const SizedBox(height: 16),
        _buildFilterBar(),
        const SizedBox(height: 24),
        _buildUserList(),
        const SizedBox(height: 24),
        _buildPagination(),
        const SizedBox(height: 32),
        _buildBottomSummaries(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ADMINISTRATION > USER MANAGEMENT HUB',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Institutional Directory',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage ${_allUsers.length} active identities across departments.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTopActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showBulkUploadDialog,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Bulk Upload', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddUserDialog(),
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Add New User', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalUsersHero() {
    final activeCount = _allUsers.where((u) => u['status'] == 'Active').length;
    final pendingCount = _allUsers.where((u) => u['status'] == 'Pending').length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL USERS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_outline, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_allUsers.length}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$activeCount Active • $pendingCount Pending',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
          _currentPage = 1;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search by name, email, or user ID...',
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _currentPage = 1;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final bool hasActiveFilters =
        _selectedRole != 'All Roles' || _selectedDept != 'All Departments' || _selectedStatus != 'Any Status';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterDropdown(
            label: _selectedRole,
            items: _roles,
            onSelected: (val) {
              setState(() {
                _selectedRole = val;
                _currentPage = 1;
              });
            },
          ),
          const SizedBox(width: 8),
          _filterDropdown(
            label: _selectedDept,
            items: _departments,
            onSelected: (val) {
              setState(() {
                _selectedDept = val;
                _currentPage = 1;
              });
            },
          ),
          const SizedBox(width: 8),
          _filterDropdown(
            label: _selectedStatus,
            items: _statuses,
            onSelected: (val) {
              setState(() {
                _selectedStatus = val;
                _currentPage = 1;
              });
            },
          ),
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedRole = 'All Roles';
                  _selectedDept = 'All Departments';
                  _selectedStatus = 'Any Status';
                  _currentPage = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.filter_alt_off, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text('Reset', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = !label.startsWith('All') && !label.startsWith('Any');

    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                fontSize: 12,
                fontWeight: item == label ? FontWeight.bold : FontWeight.normal,
                color: item == label ? Colors.blue : Colors.black87,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.blue : AppColors.border),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    final users = _paginatedUsers;

    if (users.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No matching users found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your search criteria or active filters.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    Color statusColor = Colors.green;
    if (user['status'] == 'Pending') statusColor = Colors.orange;
    if (user['status'] == 'Inactive') statusColor = Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  user['name'].toString().substring(0, 1).toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(user['email'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              _roleBadge(user['role']),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DEPARTMENT', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(user['dept'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  CircleAvatar(radius: 3, backgroundColor: statusColor),
                  const SizedBox(width: 6),
                  Text(user['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                ],
              ),
              Row(
                children: [
                  _actionIcon(
                    Icons.visibility_outlined,
                    Colors.grey,
                    () => _showUserDetailDialog(user),
                  ),
                  _actionIcon(
                    Icons.edit_outlined,
                    Colors.blue,
                    () => _showAddUserDialog(user),
                  ),
                  _actionIcon(
                    Icons.delete_outline,
                    Colors.red,
                    () => _showDeleteConfirmation(user),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    Color color = Colors.blue;
    if (role == 'STAFF') color = Colors.purple;
    if (role == 'PARENT') color = Colors.orange;
    if (role == 'ADMIN') color = Colors.indigo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(role, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = _totalPages;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            child: _pageBox('<', false, enabled: _currentPage > 1),
          ),
        ),
        for (int i = 1; i <= totalPages; i++)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _currentPage = i),
              child: _pageBox('$i', i == _currentPage),
            ),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            child: _pageBox('>', false, enabled: _currentPage < totalPages),
          ),
        ),
      ],
    );
  }

  Widget _pageBox(String label, bool active, {bool enabled = true}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: active ? Colors.blue : AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: active
              ? Colors.white
              : (enabled ? Colors.grey.shade800 : Colors.grey.shade400),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomSummaries() {
    return Column(
      children: [
        _summaryCard(
          'GROWTH TRENDS',
          'Student enrollment is up by 14% this semester, primarily in CS.',
          Icons.trending_up,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _summaryCard(
          'ACTION REQUIRED',
          '${_allUsers.where((u) => u['status'] == 'Pending').length} user accounts are currently in \'Pending\' status.',
          Icons.error_outline,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _summaryCard(
          'ACCESS LOGS',
          'System recorded 2,104 successful logins in the last hour.',
          Icons.security,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String body, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- INTERACTIVE DIALOGS ---

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildModalDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog([Map<String, dynamic>? userToEdit]) {
    final isEditing = userToEdit != null;
    final nameController = TextEditingController(text: isEditing ? userToEdit['name'] : '');
    final emailController = TextEditingController(text: isEditing ? userToEdit['email'] : '');
    final phoneController = TextEditingController(text: isEditing ? userToEdit['phone'] : '');

    String role = isEditing ? userToEdit['role'] : 'STUDENT';
    String dept = isEditing ? userToEdit['dept'] : 'Computer Science';
    String status = isEditing ? userToEdit['status'] : 'Active';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: const Color(0xFFEFEFF4),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit User Details' : 'Add New User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildModalTextField(
                          controller: nameController,
                          hintText: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildModalTextField(
                          controller: emailController,
                          hintText: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _buildModalTextField(
                          controller: phoneController,
                          hintText: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildModalDropdown(
                          label: 'Role',
                          value: role,
                          items: _roles.where((r) => r != 'All Roles').toList(),
                          onChanged: (val) => setDialogState(() => role = val),
                        ),
                        const SizedBox(height: 12),
                        _buildModalDropdown(
                          label: 'Department',
                          value: dept,
                          items: _departments.where((d) => d != 'All Departments').toList(),
                          onChanged: (val) => setDialogState(() => dept = val),
                        ),
                        const SizedBox(height: 12),
                        _buildModalDropdown(
                          label: 'Status',
                          value: status,
                          items: _statuses.where((s) => s != 'Any Status').toList(),
                          onChanged: (val) => setDialogState(() => status = val),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0066FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              final name = nameController.text.trim();
                              final email = emailController.text.trim();
                              final phone = phoneController.text.trim();

                              if (name.isEmpty || email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill in Name and Email fields.')),
                                );
                                return;
                              }

                              final userMap = isEditing
                                  ? {
                                      'id': userToEdit['id'],
                                      'name': name,
                                      'email': email,
                                      'phone': phone.isNotEmpty ? phone : userToEdit['phone'],
                                      'role': role,
                                      'dept': dept,
                                      'status': status,
                                    }
                                  : {
                                      'id': 'USR-${1000 + _allUsers.length + 1}',
                                      'name': name,
                                      'email': email,
                                      'phone': phone.isNotEmpty ? phone : '+1 (555) 000-0000',
                                      'role': role,
                                      'dept': dept,
                                      'status': status,
                                      'joined': 'Aug 2026',
                                    };

                              setState(() {
                                if (isEditing) {
                                  userToEdit['name'] = name;
                                  userToEdit['email'] = email;
                                  userToEdit['phone'] = phone.isNotEmpty ? phone : userToEdit['phone'];
                                  userToEdit['role'] = role;
                                  userToEdit['dept'] = dept;
                                  userToEdit['status'] = status;
                                } else {
                                  _allUsers.insert(0, userMap);
                                }
                              });

                              _saveUserToFirestore(userMap);

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'User $name updated successfully!'
                                        : 'New user $name added successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: Text(
                              isEditing ? 'Save Changes' : 'Create User',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showUserDetailDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: const Color(0xFFEFEFF4),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        user['name'].toString().substring(0, 1).toUpperCase(),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text(user['id'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Email', user['email'], Icons.email_outlined),
                      const Divider(height: 16),
                      _detailRow('Phone', user['phone'] ?? 'N/A', Icons.phone_outlined),
                      const Divider(height: 16),
                      _detailRow('Role', user['role'], Icons.badge_outlined),
                      const Divider(height: 16),
                      _detailRow('Department', user['dept'], Icons.business_outlined),
                      const Divider(height: 16),
                      _detailRow('Status', user['status'], Icons.info_outline),
                      const Divider(height: 16),
                      _detailRow('Joined', user['joined'] ?? 'N/A', Icons.calendar_today_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddUserDialog(user);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text('$label:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFFEFEFF4),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Confirm Deletion',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete user "${user['name']}"? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          final uid = user['id']?.toString() ?? '';
                          setState(() {
                            _allUsers.removeWhere((u) => u['id'] == user['id']);
                          });
                          if (uid.isNotEmpty) {
                            _deleteUserFromFirestore(uid);
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('User "${user['name']}" deleted.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBulkUploadDialog() {
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: const Color(0xFFEFEFF4),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.upload_file, color: Color(0xFF0066FF)),
                        SizedBox(width: 8),
                        Text(
                          'Bulk User Upload',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload a CSV or Excel file containing user details (Name, Email, Role, Department).',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          if (isUploading) ...[
                            const CustomLoader(
                              size: 36,
                              label: 'Processing and validating records...',
                            ),
                          ] else ...[
                            const Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF0066FF)),
                            const SizedBox(height: 8),
                            const Text('Drag & Drop CSV file here', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            const Text('or click to select file', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isUploading ? null : () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0066FF))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isUploading
                            ? null
                            : () {
                                setDialogState(() => isUploading = true);
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (!mounted) return;
                                  setState(() {
                                    _allUsers.addAll([
                                      {
                                        'id': 'USR-${1000 + _allUsers.length + 1}',
                                        'name': 'Prof. Daniel Vance',
                                        'email': 'd.vance@unisphere.edu',
                                        'role': 'STAFF',
                                        'dept': 'Computer Science',
                                        'status': 'Active',
                                        'phone': '+1 (555) 901-2345',
                                        'joined': 'Aug 2026',
                                      },
                                      {
                                        'id': 'USR-${1000 + _allUsers.length + 2}',
                                        'name': 'Chloe Bennet',
                                        'email': 'c.bennet@unisphere.edu',
                                        'role': 'STUDENT',
                                        'dept': 'Applied Physics',
                                        'status': 'Active',
                                        'phone': '+1 (555) 012-3456',
                                        'joined': 'Aug 2026',
                                      },
                                    ]);
                                  });
                                  if (navigator.canPop()) {
                                    navigator.pop();
                                  }
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Successfully imported 2 users from file!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                });
                              },
                        child: const Text('Simulate Import', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

