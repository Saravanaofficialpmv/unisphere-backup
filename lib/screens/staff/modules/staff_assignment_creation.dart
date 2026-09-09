import 'package:flutter/material.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/assignment_model.dart';
import 'package:unisphere/services/assignment_service.dart';
import 'package:unisphere/widgets/common/apple_glass_card.dart';

class StaffAssignmentCreation extends StatefulWidget {
  final VoidCallback? onCreated;

  const StaffAssignmentCreation({super.key, this.onCreated});

  @override
  State<StaffAssignmentCreation> createState() => _StaffAssignmentCreationState();
}

class _StaffAssignmentCreationState extends State<StaffAssignmentCreation> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController(text: 'Data Structures');
  final _courseCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxMarksController = TextEditingController(text: '100');

  final DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 5));
  final List<String> _selectedFileTypes = ['pdf', 'docx', 'zip'];
  final AssignmentService _service = AssignmentService();

  // Register Number Question Allocation Mappings
  final List<Map<String, String>> _regNoMappings = [];

  final _regInputController = TextEditingController();
  final _questionInputController = TextEditingController();

  void _addRegMapping() {
    if (_regInputController.text.isNotEmpty && _questionInputController.text.isNotEmpty) {
      setState(() {
        _regNoMappings.add({
          'reg': _regInputController.text.trim(),
          'question': _questionInputController.text.trim(),
        });
        _regInputController.clear();
        _questionInputController.clear();
      });
    }
  }

  void _submitAssignment() {
    if (_formKey.currentState!.validate()) {
      final mapObj = <String, String>{};
      for (var item in _regNoMappings) {
        mapObj[item['reg']!] = item['question']!;
      }

      final newAssignment = AssignmentModel(
        id: 'asg_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        authorName: 'Prof. Sarah Jenkins',
        subjectName: _subjectController.text.trim(),
        courseCode: _courseCodeController.text.trim(),
        createdAt: DateTime.now(),
        dueDate: _selectedDueDate,
        maxMarks: int.tryParse(_maxMarksController.text) ?? 100,
        targetedClasses: ['CSE - 3rd Year - Sec A'],
        allowedFileTypes: _selectedFileTypes,
        regNoQuestionMap: mapObj,
      );

      _service.addAssignment(newAssignment);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment Published & Distributed by Register Number successfully! 🎉'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      if (widget.onCreated != null) widget.onCreated!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Banner
              _buildHeaderBanner(),
              const SizedBox(height: 24),

              // Basic Assignment Information Section
              AppleGlassCard.frosted(
                padding: const EdgeInsets.all(24),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_task_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text('1. Assignment General Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Assignment Title',
                        hintText: 'e.g. Lab Report 4 - AVL Tree Implementation',
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(labelText: 'Subject Name'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _courseCodeController,
                            decoration: const InputDecoration(labelText: 'Course Code'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxMarksController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Max Marks'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'General Description & Guidelines',
                        hintText: 'Describe general rules, formatting expectations, and lab guidelines...',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Distribution by Register Number
              AppleGlassCard.frosted(
                padding: const EdgeInsets.all(24),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.format_list_bulleted_add, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text('2. Distribute Specific Questions by Student Register Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Assign distinct question prompts or set papers to specific student Register Numbers or Ranges (e.g. RA2111003010001-RA2111003010025).',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 24),

                    // Inputs to add mapping
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: _regInputController,
                            decoration: const InputDecoration(
                              labelText: 'Reg No / Range',
                              hintText: 'RA2111003010001',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _questionInputController,
                            decoration: const InputDecoration(
                              labelText: 'Specific Question / Set Description',
                              hintText: 'e.g. Set A: Solve Question 4 with custom matrix values.',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _addRegMapping,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Mapping'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 52)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // List of current mappings
                    const Text('Configured Question Mappings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (_regNoMappings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No specific register number mappings added. Assignment will apply to all students.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _regNoMappings.length,
                      itemBuilder: (context, index) {
                        final item = _regNoMappings[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                child: Text(item['reg']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(item['question']!, style: const TextStyle(fontSize: 13))),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                onPressed: () => setState(() => _regNoMappings.removeAt(index)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitAssignment,
                  icon: const Icon(Icons.publish_rounded, size: 20),
                  label: const Text('Publish Assignment & Distribute Questions'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.post_add_rounded, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New Digital Assignment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Faculty portal to configure homework tasks & assign questions by Register Number.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
