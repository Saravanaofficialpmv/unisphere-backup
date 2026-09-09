import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/resume_service.dart';
import 'package:unisphere/widgets/resume/resume_completeness_card.dart';
import 'package:unisphere/widgets/resume/resume_document_view.dart';
import 'package:unisphere/widgets/student/student_profile_completion_sheet.dart';
import 'package:unisphere/widgets/student/student_profile_edit_request_modal.dart';

/// Helper function to display the Student Resume as a sleek bottom popup modal
void showStudentResumeModalSheet(BuildContext context, {String? studentId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    useSafeArea: true,
    builder: (ctx) => StudentResumeModalSheet(studentId: studentId),
  );
}

class StudentResumeModalSheet extends ConsumerStatefulWidget {
  final String? studentId;

  const StudentResumeModalSheet({
    super.key,
    this.studentId,
  });

  @override
  ConsumerState<StudentResumeModalSheet> createState() => _StudentResumeModalSheetState();
}

class _StudentResumeModalSheetState extends ConsumerState<StudentResumeModalSheet> {
  int _activeSegment = 0; // 0 = A4 Resume Preview, 1 = Readiness & Completeness

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StudentProfileEditRequestModal(),
    );
  }

  void _handleCompletenessAction(String actionKey) {
    if (actionKey == 'complete_profile' || actionKey == 'edit_profile') {
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const StudentProfileCompletionSheet(),
      );
    } else {
      _showEditProfileModal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final targetId = widget.studentId ??
        currentUser?.metadata?['registerNumber']?.toString() ??
        currentUser?.uid ??
        '';

    final resumeAsync = ref.watch(studentResumeProvider(targetId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top Header & Drag Handle ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle pill
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Title Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        size: 20,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Professional Resume',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Verified institutional credential & dynamic A4 portfolio',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Live Sync Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync_rounded, size: 12, color: Color(0xFF059669)),
                          SizedBox(width: 3),
                          Text(
                            'Live Sync',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Segment Control (Preview vs Readiness)
                Container(
                  height: 36,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeSegment = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _activeSegment == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _activeSegment == 0
                                  ? [
                                      const BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 15,
                                  color: _activeSegment == 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'A4 Document View',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _activeSegment == 0 ? FontWeight.bold : FontWeight.w600,
                                    color: _activeSegment == 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeSegment = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _activeSegment == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _activeSegment == 1
                                  ? [
                                      const BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pie_chart_outline_rounded,
                                  size: 15,
                                  color: _activeSegment == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Resume Readiness',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _activeSegment == 1 ? FontWeight.bold : FontWeight.w600,
                                    color: _activeSegment == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content Area ──
          Expanded(
            child: _activeSegment == 1
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ResumeCompletenessCard(
                      completeness: (resumeAsync.value ?? ref.read(resumeServiceProvider).generateSyncFallbackResume(
                            studentId: targetId,
                            user: currentUser,
                          )).completeness,
                      onActionTap: _handleCompletenessAction,
                    ),
                  )
                : ResumeDocumentView(
                    resume: resumeAsync.value ??
                        ref.read(resumeServiceProvider).generateSyncFallbackResume(
                              studentId: targetId,
                              user: currentUser,
                            ),
                    onEditRequest: _showEditProfileModal,
                    showControls: true,
                  ),
          ),
        ],
      ),
    );
  }
}
