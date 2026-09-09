import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/user_service.dart';

class RoleManagementModule extends ConsumerStatefulWidget {
  const RoleManagementModule({super.key});

  @override
  ConsumerState<RoleManagementModule> createState() => _RoleManagementModuleState();
}

class _RoleManagementModuleState extends ConsumerState<RoleManagementModule> {
  final Set<String> _selectedUids = {};
  final Map<String, UserRole> _proposedRoles = {};
  UserRole _bulkRole = UserRole.student;
  bool _isProcessing = false;
  String _searchQuery = '';
  int _selectedTabIndex = 0; // 0: Pending Requests, 1: Active Users
  int _currentPage = 1;
  static const int _pageSize = 8;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1100;

    final usersAsync = ref.watch(allUsersStreamProvider);

    return usersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Error loading user directory: $err',
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(allUsersStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (users) {
        final pendingUsers = users.where((u) => !u.isActive || u.role == UserRole.unknown).toList();
        final activeUsers = users.where((u) => u.isActive && u.role != UserRole.unknown).toList();

        final rawList = _selectedTabIndex == 0 ? pendingUsers : activeUsers;
        final filteredList = rawList.where((u) {
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.toLowerCase().trim();
          final name = u.fullName.toLowerCase();
          final email = u.email.toLowerCase();
          final regNo = (u.metadata?['registerNumber'] ?? '').toString().toLowerCase();
          return name.contains(q) || email.contains(q) || regNo.contains(q);
        }).toList();

        final totalPages = (filteredList.length / _pageSize).ceil().clamp(1, 999);
        if (_currentPage > totalPages) {
          _currentPage = totalPages;
        }

        final startIndex = (_currentPage - 1) * _pageSize;
        final endIndex = (startIndex + _pageSize < filteredList.length)
            ? startIndex + _pageSize
            : filteredList.length;
        final pagedList = filteredList.isEmpty
            ? <UserModel>[]
            : filteredList.sublist(startIndex, endIndex);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(pendingUsers.length),
            const SizedBox(height: 24),
            _buildTopGovernanceStats(users, pendingUsers.length, activeUsers.length),
            const SizedBox(height: 32),
            _buildAccessTableSection(
              isDesktop: isDesktop,
              filteredUsers: pagedList,
              totalFiltered: filteredList.length,
              currentPage: _currentPage,
              totalPages: totalPages,
              pendingCount: pendingUsers.length,
              activeCount: activeUsers.length,
            ),
            const SizedBox(height: 32),
            _buildGovernanceFooter(isDesktop, users),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int pendingCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SECURITY & GOVERNANCE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Access Requests & Role Assignment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pendingCount > 0
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: pendingCount > 0 ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pendingCount > 0
                        ? '$pendingCount Pending Review'
                        : 'All Clear (0 Pending)',
                    style: TextStyle(
                      color: pendingCount > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopGovernanceStats(List<UserModel> allUsers, int pendingCount, int activeCount) {
    final activeRolesCount = allUsers.map((u) => u.role).where((r) => r != UserRole.unknown).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _governanceCard(
            'Pending Requests',
            '$pendingCount',
            pendingCount > 0 ? 'Action required' : 'No backlog',
            Icons.assignment_ind_rounded,
            pendingCount > 0 ? Colors.orange : Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _governanceCard(
            'Active Members',
            '$activeCount',
            'Verified campus accounts',
            Icons.how_to_reg_rounded,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _governanceCard(
            'Active Roles',
            '$activeRolesCount',
            'Configured permission tiers',
            Icons.verified_user_rounded,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _governanceCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTableSection({
    required bool isDesktop,
    required List<UserModel> filteredUsers,
    required int totalFiltered,
    required int currentPage,
    required int totalPages,
    required int pendingCount,
    required int activeCount,
  }) {
    final allPageUids = filteredUsers.map((u) => u.uid).toSet();
    final isAllSelected = allPageUids.isNotEmpty && _selectedUids.containsAll(allPageUids);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab switcher & search bar
          Row(
            children: [
              _buildTabButton(0, 'Pending Requests', pendingCount, Colors.orange),
              const SizedBox(width: 12),
              _buildTabButton(1, 'Active Directory', activeCount, Colors.green),
              const Spacer(),
              SizedBox(
                width: 240,
                height: 38,
                child: TextField(
                  onChanged: (val) => setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, ID...',
                    hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bulk action controls (primarily for pending requests)
          if (_selectedTabIndex == 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isAllSelected,
                      onChanged: filteredUsers.isEmpty
                          ? null
                          : (v) {
                              setState(() {
                                if (isAllSelected) {
                                  _selectedUids.removeAll(allPageUids);
                                } else {
                                  _selectedUids.addAll(allPageUids);
                                }
                              });
                            },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    const Text(
                      'Select Page',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      '${_selectedUids.length} selected',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Role for Bulk Approval:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UserRole>(
                          value: _bulkRole,
                          isDense: true,
                          style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                          items: const [
                            DropdownMenuItem(value: UserRole.student, child: Text('Student')),
                            DropdownMenuItem(value: UserRole.staff, child: Text('Staff / Faculty')),
                            DropdownMenuItem(value: UserRole.advisor, child: Text('Class Advisor')),
                            DropdownMenuItem(value: UserRole.hod, child: Text('HOD / Dept Admin')),
                            DropdownMenuItem(value: UserRole.parent, child: Text('Parent / Guardian')),
                            DropdownMenuItem(value: UserRole.admin, child: Text('Administrator')),
                          ],
                          onChanged: (role) {
                            if (role != null) setState(() => _bulkRole = role);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: (_selectedUids.isEmpty || _isProcessing) ? null : _handleBulkApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Bulk Approve (${_selectedUids.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          _tableHeader(),
          const Divider(height: 1),

          if (filteredUsers.isEmpty)
            _buildEmptyState()
          else
            ...filteredUsers.map((user) => _requestRow(user)),

          const SizedBox(height: 20),
          _paginationBar(totalFiltered, currentPage, totalPages),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, int count, Color activeColor) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() {
        _selectedTabIndex = index;
        _selectedUids.clear();
        _currentPage = 1;
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isPendingTab = _selectedTabIndex == 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isPendingTab ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPendingTab ? Icons.verified_user_rounded : Icons.person_off_outlined,
              size: 32,
              color: isPendingTab ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPendingTab ? 'No Pending Access Requests' : 'No Users Found',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            isPendingTab
                ? 'All pending campus registration requests have been reviewed and approved.'
                : 'No registered user accounts match your search query.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: const [
          SizedBox(width: 48, child: Center(child: Text('#', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)))),
          Expanded(flex: 3, child: Text('NAME & IDENTIFIER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 3, child: Text('EMAIL & CONTACT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text('JOINED / REQUESTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text('ASSIGNED ROLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _requestRow(UserModel user) {
    final isApproved = user.isActive && user.role != UserRole.unknown;
    final isSelected = _selectedUids.contains(user.uid);
    final userInitials = _getInitials(user.fullName);
    final idString = (user.metadata?['registerNumber'] ??
            user.metadata?['staffId'] ??
            user.metadata?['employeeId'] ??
            user.uid)
        .toString();

    final chosenRole = _proposedRoles[user.uid] ??
        (user.role == UserRole.unknown ? UserRole.student : user.role);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha: 0.03) : Colors.transparent,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          // Select Checkbox / Index indicator
          SizedBox(
            width: 48,
            child: Center(
              child: !isApproved
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedUids.add(user.uid);
                          } else {
                            _selectedUids.remove(user.uid);
                          }
                        });
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    )
                  : const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
            ),
          ),

          // User Name & ID
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isApproved
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  child: Text(
                    userInitials,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isApproved ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        idString,
                        style: TextStyle(
                          fontSize: 9,
                          color: isApproved ? Colors.grey.shade600 : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contact info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email.isNotEmpty ? user.email : 'No email',
                  style: const TextStyle(fontSize: 11, color: Colors.black87, overflow: TextOverflow.ellipsis),
                ),
                if (user.phone.isNotEmpty)
                  Text(
                    user.phone,
                    style: const TextStyle(fontSize: 9, color: Colors.grey, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),

          // Request Date
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.formattedCreatedAt,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                if (user.createdAt != null)
                  Text(
                    '${user.createdAt!.hour.toString().padLeft(2, '0')}:${user.createdAt!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  ),
              ],
            ),
          ),

          // Proposed / Assigned Role Dropdown
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isApproved ? Colors.green.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isApproved ? Colors.green.withValues(alpha: 0.3) : AppColors.border,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: chosenRole,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isApproved ? Colors.green.shade800 : Colors.black87,
                    ),
                    items: const [
                      DropdownMenuItem(value: UserRole.student, child: Text('Student')),
                      DropdownMenuItem(value: UserRole.staff, child: Text('Staff')),
                      DropdownMenuItem(value: UserRole.advisor, child: Text('Advisor')),
                      DropdownMenuItem(value: UserRole.hod, child: Text('HOD')),
                      DropdownMenuItem(value: UserRole.parent, child: Text('Parent')),
                      DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                    ],
                    onChanged: (newRole) {
                      if (newRole == null) return;
                      if (isApproved) {
                        _handleUpdateActiveRole(user, newRole);
                      } else {
                        setState(() => _proposedRoles[user.uid] = newRole);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),

          // Actions: Approve / Reject or Status
          Expanded(
            flex: 2,
            child: isApproved
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.block, size: 16, color: Colors.grey),
                          tooltip: 'Revoke Access',
                          onPressed: () => _handleReject(user),
                        ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isProcessing ? null : () => _handleReject(user),
                        child: const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : () => _handleApprove(user, chosenRole),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text(
                          'Approve',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _paginationBar(int totalItems, int currentPage, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${totalItems == 0 ? 0 : (_currentPage - 1) * _pageSize + 1} - ${(_currentPage * _pageSize).clamp(0, totalItems)} of $totalItems accounts',
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_left, size: 18),
              onPressed: currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
            const SizedBox(width: 4),
            Text(
              'Page $currentPage of $totalPages',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_right, size: 18),
              onPressed: currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGovernanceFooter(bool isDesktop, List<UserModel> users) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Role Quick Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _quickSettingCard(
                      'Admin Privileges',
                      'Full institutional controls and real-time database governance.',
                      Icons.vpn_key_outlined,
                      users.where((u) => u.role == UserRole.admin).length,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickSettingCard(
                      'Faculty Staff',
                      'Marks submission, attendance rosters, and syllabus delivery.',
                      Icons.assignment_ind_outlined,
                      users.where((u) => u.role == UserRole.staff || u.role == UserRole.advisor).length,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Icon(Icons.security_rounded, color: Colors.blue.shade700, size: 26),
                ),
                const SizedBox(height: 14),
                const Text('Role Governance Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Every role change and account approval is committed directly to the central institutional Firestore directory in real time, immediately updating permissions across all mobile and web portals.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Active System Accounts: ${users.length} Total Registered Users',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickSettingCard(String title, String sub, IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.blue.shade700, size: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count Active',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.4)),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _handleApprove(UserModel user, UserRole role) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(userServiceProvider).approveUserAccess(user.uid, role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved ${user.fullName} as ${role.name.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve access: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke / Reject Access'),
        content: Text('Are you sure you want to deactivate or reject access for ${user.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Deactivation', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(userServiceProvider).rejectUserAccess(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Access revoked for ${user.fullName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke access: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleUpdateActiveRole(UserModel user, UserRole newRole) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(userServiceProvider).updateUserRole(user.uid, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated role for ${user.fullName} to ${newRole.name.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleBulkApprove() async {
    if (_selectedUids.isEmpty) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(userServiceProvider).bulkApproveUsers(_selectedUids.toList(), _bulkRole);
      if (mounted) {
        final count = _selectedUids.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully approved $count accounts as ${_bulkRole.name.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _selectedUids.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk approval failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
