import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/academic_record_model.dart';
import 'package:unisphere/repositories/academic_record_repository.dart';
import 'package:unisphere/services/academic_record_service.dart';
import 'package:unisphere/services/auth_service.dart';

final academicRecordRepositoryProvider = Provider<AcademicRecordRepository>((ref) {
  return AcademicRecordRepository();
});

final academicRecordServiceProvider = Provider<AcademicRecordService>((ref) {
  final repo = ref.watch(academicRecordRepositoryProvider);
  return AcademicRecordService(repository: repo);
});

/// Real-time stream provider for a specific student ID
final studentAcademicRecordsStreamProvider = StreamProvider.family<List<AcademicRecord>, String>((ref, studentId) {
  final cleanId = studentId.trim();
  if (cleanId.isEmpty) {
    return Stream.value([]);
  }
  final service = ref.watch(academicRecordServiceProvider);
  return service.watchStudentRecords(cleanId);
});

/// Real-time stream provider for the currently authenticated student
final currentStudentAcademicRecordsStreamProvider = StreamProvider<List<AcademicRecord>>((ref) {
  final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
  final regNo = user?.metadata?['registerNumber']?.toString().trim() ?? '';
  final studentId = regNo.isNotEmpty ? regNo : (user?.uid ?? '');

  if (studentId.isEmpty) {
    return Stream.value([]);
  }

  final service = ref.watch(academicRecordServiceProvider);
  return service.watchStudentRecords(studentId);
});

/// State provider for selected semester (0-indexed or 1-indexed, default semester 6 / index 5 or 4)
final selectedAcademicSemesterIndexProvider = StateProvider<int>((ref) => 5);

/// State provider for assessment filter ('All', 'IA-1', 'IA-2', 'Model', 'Attendance')
final selectedAcademicAssessmentFilterProvider = StateProvider<String>((ref) => 'All');
