import 'package:flutter/material.dart';
import 'package:unisphere/models/user_model.dart';

/// Workspace & Role Selection Dialog for multi-role / multi-institution users.
/// Conforms to Unisphere's official design system.
class WorkspaceSelectionDialog extends StatefulWidget {
  final UserModel user;
  final List<String> availableInstitutions;
  final List<UserRole> availableRoles;

  const WorkspaceSelectionDialog({
    super.key,
    required this.user,
    required this.availableInstitutions,
    required this.availableRoles,
  });

  static Future<({String institution, UserRole role})?> show(
    BuildContext context, {
    required UserModel user,
  }) {
    final insts = user.availableInstitutions;
    final roles = user.availableRoles;

    if (insts.length <= 1 && roles.length <= 1) {
      return Future.value((
        institution: insts.isNotEmpty ? insts.first : 'VSB Engineering College',
        role: roles.isNotEmpty ? roles.first : user.role,
      ));
    }

    return showDialog<({String institution, UserRole role})>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WorkspaceSelectionDialog(
        user: user,
        availableInstitutions: insts,
        availableRoles: roles,
      ),
    );
  }

  @override
  State<WorkspaceSelectionDialog> createState() => _WorkspaceSelectionDialogState();
}

class _WorkspaceSelectionDialogState extends State<WorkspaceSelectionDialog> {
  late String _selectedInstitution;
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedInstitution = widget.availableInstitutions.isNotEmpty
        ? widget.availableInstitutions.first
        : 'VSB Engineering College';
    _selectedRole = widget.availableRoles.isNotEmpty
        ? widget.availableRoles.first
        : widget.user.role;
  }

  String _formatRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.hod:
        return 'Head of Department (HOD)';
      case UserRole.advisor:
        return 'Class Advisor';
      case UserRole.staff:
        return 'Faculty / Staff';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent / Guardian';
      case UserRole.unknown:
        return 'Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2563EB);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: brandBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.domain_rounded, color: brandBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select your workspace',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose an institution and portal role',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Institution Selector
              const Text(
                'Institution',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedInstitution,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    items: widget.availableInstitutions.map((inst) {
                      return DropdownMenuItem<String>(
                        value: inst,
                        child: Text(inst, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedInstitution = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Role Selector
              const Text(
                'Role',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: _selectedRole,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    items: widget.availableRoles.map((role) {
                      return DropdownMenuItem<UserRole>(
                        value: role,
                        child: Text(_formatRoleName(role), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop((
                          institution: _selectedInstitution,
                          role: _selectedRole,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
