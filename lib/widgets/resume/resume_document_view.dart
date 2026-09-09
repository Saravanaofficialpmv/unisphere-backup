import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:unisphere/models/student_resume_model.dart';
import 'package:unisphere/services/resume_pdf_service.dart';
import 'package:unisphere/widgets/resume/resume_editor_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class ResumeDocumentView extends StatefulWidget {
  final StudentResumeModel resume;
  final bool isInteractive;
  final bool showControls;
  final bool shrinkWrap;
  final VoidCallback? onEditRequest;
  final Function(StudentResumeModel updatedResume)? onResumeUpdated;

  const ResumeDocumentView({
    super.key,
    required this.resume,
    this.isInteractive = true,
    this.showControls = true,
    this.shrinkWrap = false,
    this.onEditRequest,
    this.onResumeUpdated,
  });

  @override
  State<ResumeDocumentView> createState() => _ResumeDocumentViewState();
}

class _ResumeDocumentViewState extends State<ResumeDocumentView> {
  double _zoomScale = 1.0;

  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _copyResumeText() {
    final text = widget.resume.toPlainText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resume text copied to clipboard in standard ATS format!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openEditorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResumeEditorModal(
        resume: widget.resume,
        onSave: (updated) {
          if (widget.onResumeUpdated != null) {
            widget.onResumeUpdated!(updated);
          }
        },
      ),
    );
  }

  void _showPrintExportModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.print_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Text('Print & Export Resume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your dynamic resume is formatted according to international A4 dimensions (210 × 297 mm) and is ready for export, PDF download, and placement drives.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildExportOption(
                    Icons.picture_as_pdf_rounded,
                    'Print & Save as PDF',
                    'Open native OS print preview dialog to save or print A4 PDF',
                    () async {
                      Navigator.pop(ctx);
                      await ResumePdfService.printOrExportResume(widget.resume);
                    },
                  ),
                  const Divider(height: 16),
                  _buildExportOption(
                    Icons.share_rounded,
                    'Share PDF File',
                    'Directly share the PDF document via AirDrop, Email or Apps',
                    () async {
                      Navigator.pop(ctx);
                      await ResumePdfService.shareResumePdf(widget.resume);
                    },
                  ),
                  const Divider(height: 16),
                  _buildExportOption(
                    Icons.copy_all_rounded,
                    'Copy Plain Text / Markdown',
                    'Copy ATS-friendly structured resume text to clipboard',
                    () {
                      Navigator.pop(ctx);
                      _copyResumeText();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(IconData icon, String title, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resume;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (widget.shrinkWrap) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showControls) _buildControlsBar(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: _buildA4Paper(r, isMobile),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showControls) _buildControlsBar(),
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: _buildA4Paper(r, isMobile),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Customize Resume Button
            ElevatedButton.icon(
              onPressed: _openEditorModal,
              icon: const Icon(Icons.edit_note_rounded, size: 16),
              label: const Text('Customize Resume', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: const Color(0xFF2563EB),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Zoom In / Out
            IconButton(
              icon: const Icon(Icons.zoom_out_rounded, size: 18, color: Color(0xFF64748B)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                if (_zoomScale > 0.7) setState(() => _zoomScale = (_zoomScale - 0.1).clamp(0.7, 1.3));
              },
            ),
            Text(
              '${(_zoomScale * 100).toInt()}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in_rounded, size: 18, color: Color(0xFF64748B)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                if (_zoomScale < 1.3) setState(() => _zoomScale = (_zoomScale + 0.1).clamp(0.7, 1.3));
              },
            ),

            const SizedBox(width: 8),

            // Copy text action
            IconButton(
              icon: const Icon(Icons.copy_all_rounded, size: 18, color: Color(0xFF475569)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: _copyResumeText,
            ),

            const SizedBox(width: 8),

            // Print / PDF Button
            ElevatedButton.icon(
              onPressed: _showPrintExportModal,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
              label: const Text('Export / Print PDF', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildA4Paper(StudentResumeModel r, bool isMobile) {
    const Color headingNavy = Color(0xFF1A2A4A);
    const Color subtitleSlate = Color(0xFF55657A);
    const Color bodyTextColor = Color(0xFF1A1A1A);
    const Color accentBlue = Color(0xFF1F6FEB);

    return Container(
      width: isMobile ? double.infinity : 794,
      constraints: BoxConstraints(minHeight: isMobile ? 600 : 1000),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 44,
        vertical: isMobile ? 24 : 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          _buildHeaderSection(r.header, headingNavy, subtitleSlate, bodyTextColor, isMobile),

          const SizedBox(height: 16),

          // ── 1. PROFESSIONAL SUMMARY ──
          if (r.professionalSummary.isNotEmpty) ...[
            _buildSectionTitle('PROFESSIONAL SUMMARY', headingNavy, accentBlue),
            Text(
              r.professionalSummary,
              style: const TextStyle(
                fontSize: 11.2,
                color: bodyTextColor,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 14),
          ],

          // ── 2. EDUCATION ──
          if (r.hasEducation) ...[
            _buildSectionTitle('EDUCATION', headingNavy, accentBlue),
            ...r.education.map((e) => _buildEducationItem(e, headingNavy, subtitleSlate, bodyTextColor)),
            const SizedBox(height: 14),
          ],

          // ── 3. TECHNICAL SKILLS ──
          if (r.hasSkills) ...[
            _buildSectionTitle('TECHNICAL SKILLS', headingNavy, accentBlue),
            _buildSkillsGrid(r.categorizedSkills, headingNavy, bodyTextColor),
            const SizedBox(height: 14),
          ],

          // ── 4. PROJECTS ──
          if (r.hasProjects) ...[
            _buildSectionTitle('PROJECTS', headingNavy, accentBlue),
            ...r.projects.map((p) => _buildProjectItem(p, headingNavy, subtitleSlate, bodyTextColor)),
            const SizedBox(height: 10),
          ],

          // ── 5. CERTIFICATIONS ──
          if (r.hasCertifications) ...[
            _buildSectionTitle('CERTIFICATIONS', headingNavy, accentBlue),
            ...r.certifications.map((c) => _buildCertificationItem(c, bodyTextColor)),
            const SizedBox(height: 14),
          ],

          // ── 6. ADDITIONAL STRENGTHS ──
          _buildSectionTitle('ADDITIONAL STRENGTHS', headingNavy, accentBlue),
          _buildAdditionalStrengths(bodyTextColor),
          const SizedBox(height: 16),

          // ── FOOTER ──
          _buildResumeFooter(r),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ResumeHeader h, Color headingNavy, Color subtitleSlate, Color bodyColor, bool isMobile) {
    final displayName = h.fullName.trim().isNotEmpty ? h.fullName.trim() : 'STUDENT NAME';
    final displayHeadline = h.headline.trim();
    final displayEmail = h.collegeEmail.trim();
    final displayPhone = (h.phone != null && h.phone!.trim().isNotEmpty) ? h.phone!.trim() : '';

    String cleanLinkedin = (h.linkedinUrl != null && h.linkedinUrl!.trim().isNotEmpty)
        ? h.linkedinUrl!
        : '';
    if (cleanLinkedin.isNotEmpty) {
      cleanLinkedin = cleanLinkedin
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .replaceAll('www.', '');
      if (cleanLinkedin.endsWith('/')) cleanLinkedin = cleanLinkedin.substring(0, cleanLinkedin.length - 1);
    }

    String cleanGithub = (h.githubUrl != null && h.githubUrl!.trim().isNotEmpty)
        ? h.githubUrl!
        : '';
    if (cleanGithub.isNotEmpty) {
      cleanGithub = cleanGithub
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .replaceAll('www.', '');
      if (cleanGithub.endsWith('/')) cleanGithub = cleanGithub.substring(0, cleanGithub.length - 1);
    }

    final contactItems = <Widget>[];
    if (displayEmail.isNotEmpty) {
      contactItems.add(InkWell(
        onTap: () => _openLink('mailto:$displayEmail'),
        child: Text('✉ $displayEmail', style: TextStyle(fontSize: 10.8, color: bodyColor, fontWeight: FontWeight.w500)),
      ));
    }
    if (displayPhone.isNotEmpty) {
      if (contactItems.isNotEmpty) contactItems.add(const Text('|', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))));
      contactItems.add(InkWell(
        onTap: () => _openLink('tel:$displayPhone'),
        child: Text('☎ $displayPhone', style: TextStyle(fontSize: 10.8, color: bodyColor, fontWeight: FontWeight.w500)),
      ));
    }
    if (cleanLinkedin.isNotEmpty) {
      if (contactItems.isNotEmpty) contactItems.add(const Text('|', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))));
      contactItems.add(InkWell(
        onTap: () => _openLink(h.linkedinUrl),
        child: Text(cleanLinkedin, style: TextStyle(fontSize: 10.8, color: bodyColor, fontWeight: FontWeight.w500)),
      ));
    }
    if (cleanGithub.isNotEmpty) {
      if (contactItems.isNotEmpty) contactItems.add(const Text('|', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))));
      contactItems.add(InkWell(
        onTap: () => _openLink(h.githubUrl),
        child: Text(cleanGithub, style: TextStyle(fontSize: 10.8, color: bodyColor, fontWeight: FontWeight.w500)),
      ));
    }

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Name (All-Caps Bold)
          Text(
            displayName.toUpperCase(),
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: headingNavy,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Roles / Headline
          if (displayHeadline.isNotEmpty) ...[
            Text(
              displayHeadline,
              style: TextStyle(
                fontSize: isMobile ? 11.5 : 12.5,
                fontWeight: FontWeight.w600,
                color: subtitleSlate,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
          ],

          // Contact details row
          if (contactItems.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: contactItems,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color headingColor, Color accentBlue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w800,
              color: headingColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 1.5,
            width: double.infinity,
            color: accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(ResumeEducationItem e, Color headingNavy, Color subtitleSlate, Color bodyColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            e.degree,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: headingNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${e.institution}   |   ${e.period}  (Currently Pursuing)',
            style: TextStyle(
              fontSize: 10.8,
              color: subtitleSlate,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Relevant Coursework: ',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: headingNavy),
                ),
                const TextSpan(
                  text: 'Machine Learning & Deep Learning  ·  Data Structures & Algorithms  ·  Database Management Systems  ·  Cloud Computing & Distributed Systems',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsGrid(List<ResumeSkillCategory> categories, Color headingNavy, Color bodyColor) {
    final List<Map<String, String>> skillBlocks = [
      {
        'category': 'Programming Languages',
        'skills': 'Python  ·  Java  ·  SQL  ·  Dart  ·  C++',
      },
      {
        'category': 'AI / ML Technologies',
        'skills': 'Machine Learning  ·  Deep Learning  ·  NLP  ·  Data Analytics',
      },
      {
        'category': 'Database Management',
        'skills': 'SQL  ·  Database Design  ·  Query Optimisation  ·  Firebase Firestore',
      },
      {
        'category': 'Development Tools',
        'skills': 'Git  ·  VS Code  ·  Flutter  ·  Android Studio  ·  PyCharm  ·  Jupyter Notebooks',
      },
      {
        'category': 'Core Competencies',
        'skills': 'Algorithm Design  ·  Data Visualisation  ·  OOP  ·  SDLC  ·  Problem Solving',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: skillBlocks.map((block) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block['category']!,
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                  color: headingNavy,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                block['skills']!,
                style: TextStyle(
                  fontSize: 10.8,
                  color: bodyColor,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProjectItem(ResumeProjectItem p, Color headingNavy, Color subtitleSlate, Color bodyColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.title,
            style: TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
              color: headingNavy,
            ),
          ),
          const SizedBox(height: 1),
          if (p.technologies.isNotEmpty) ...[
            Text(
              'Technologies: ${p.technologies.join("  ·  ")}',
              style: TextStyle(
                fontSize: 10.8,
                fontWeight: FontWeight.w600,
                color: subtitleSlate,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            p.description,
            style: TextStyle(fontSize: 10.8, color: bodyColor, height: 1.35),
          ),
          if (p.outcomes.isNotEmpty) ...[
            const SizedBox(height: 2),
            ...p.outcomes.map((out) {
              if (out.toLowerCase().startsWith('impact:')) {
                final impactText = out.substring(7).trim();
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Impact: ',
                          style: TextStyle(fontSize: 10.8, fontWeight: FontWeight.w700, color: headingNavy),
                        ),
                        TextSpan(
                          text: impactText,
                          style: TextStyle(fontSize: 10.8, color: bodyColor),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(top: 1.5),
                child: Text(
                  '• $out',
                  style: TextStyle(fontSize: 10.8, color: bodyColor, height: 1.3),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificationItem(ResumeCertificationItem c, Color bodyColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '• ${c.title}  –  ',
              style: TextStyle(fontSize: 10.8, fontWeight: FontWeight.w600, color: bodyColor),
            ),
            TextSpan(
              text: c.provider,
              style: const TextStyle(fontSize: 10.8, color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalStrengths(Color bodyColor) {
    final List<String> strengths = [
      'Strong foundation in Object-Oriented Programming (OOP) and software design principles.',
      'Experience with cloud computing principles, distributed systems, and backend database integrations.',
      'Knowledge of modern mobile architectures, state management, and real-time synchronisation.',
      'Proficient in data pre-processing, algorithmic analysis, and structured problem-solving techniques.',
      'Quick learner with strong analytical and problem-solving abilities; excellent teamwork and communication skills.',
      'Detail-oriented, self-motivated, and passionate about emerging technologies and scalable software development.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: strengths.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            '• $s',
            style: TextStyle(
              fontSize: 10.8,
              color: bodyColor,
              height: 1.35,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResumeFooter(StudentResumeModel r) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final formattedDate = dateFormat.format(r.lastUpdatedAt);

    return Column(
      children: [
        const Divider(height: 18, color: Color(0xFFCBD5E1)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'UNISPHERE Academic Engine • Verified Institutional Resume',
              style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            Text(
              'Reg: ${r.registerNumber} • $formattedDate',
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
