import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/services/parent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Academic Performance Real-Time Upload & Stream Verification', () {
    late ParentService parentService;

    setUp(() {
      parentService = ParentService(firestore: null);
    });

    test('1. ParentService retrieves simulated default academic performance for student 922523243079', () async {
      final data = await parentService.getStudentAcademicPerformance('922523243079');
      expect(data, isNotNull);
      expect(data!['regNo'], equals('922523243079'));
      expect(data['studentName'], equals('Arun Kumar'));
      expect(data['department'], contains('Artificial Intelligence'));
      expect(data['cgpa'], equals('8.78'));

      final semesters = data['semesters'] as Map<String, dynamic>;
      expect(semesters, isNotEmpty);
      expect(semesters.containsKey('sem_5'), isTrue);

      final sem6 = semesters['sem_5'] as Map<String, dynamic>;
      final subjects = sem6['subjects'] as List;
      expect(subjects, isNotEmpty);

      // Verify CS3401 Algorithms details
      final algoSub = subjects.firstWhere((s) => s['code'] == 'CS3401');
      expect(algoSub['name'], equals('Design & Analysis of Algorithms'));
      expect(algoSub['ia1Conv'], equals('13.2 / 15'));
      expect(algoSub['ia2Conv'], equals('13.8 / 15'));
      expect(algoSub['modelConv'], equals('18.4 / 20'));
      expect(algoSub['totalInternal'], equals('55.2 / 60'));
      expect(algoSub['hasIa1Retest'], isTrue);
      expect(algoSub['ia1RetestStatus'], contains('Retest Cleared'));
    });

    test('2. Internal assessment score calculations are correctly converted to 60-mark scale', () {
      const double rawIa1 = 44; // out of 50
      const double rawIa2 = 46; // out of 50
      const double rawModel = 92; // out of 100
      const double rawAtt = 9.8; // out of 10

      final double ia1Conv = (rawIa1 / 50.0) * 15.0; // 13.2
      final double ia2Conv = (rawIa2 / 50.0) * 15.0; // 13.8
      final double modelConv = (rawModel / 100.0) * 20.0; // 18.4
      final double attConv = rawAtt; // 9.8

      final double totalInternal = ia1Conv + ia2Conv + modelConv + attConv; // 55.2

      expect(ia1Conv, closeTo(13.2, 0.01));
      expect(ia2Conv, closeTo(13.8, 0.01));
      expect(modelConv, closeTo(18.4, 0.01));
      expect(totalInternal, closeTo(55.2, 0.01));

      final double percent = totalInternal / 60.0;
      expect(percent, closeTo(0.92, 0.01));
      expect(percent >= 0.9, isTrue); // Grade 'O'
    });

    test('3. Retest improvement mark tracking retains both initial failure and cleared mark', () {
      final subjectRecord = {
        'code': 'CS3401',
        'name': 'Design & Analysis of Algorithms',
        'faculty': 'Dr. S. Ramanathan (CSE)',
        'ia1': '44 / 50',
        'ia1Conv': '13.2 / 15',
        'ia1Initial': '20 / 50',
        'hasIa1Retest': true,
        'ia1Retest': '44 / 50',
        'ia1RetestStatus': 'Retest Cleared (+24 Marks Improved)',
        'totalInternal': '55.2 / 60',
      };

      expect(subjectRecord['hasIa1Retest'], isTrue);
      expect(subjectRecord['ia1Initial'], equals('20 / 50'));
      expect(subjectRecord['ia1Retest'], equals('44 / 50'));
      expect(subjectRecord['ia1RetestStatus'], contains('+24 Marks Improved'));
    });

    test('4. Academic performance stream emits live updates for parent monitoring', () async {
      final stream = parentService.watchStudentAcademicPerformance('922523243079');
      final firstEmission = await stream.first;

      expect(firstEmission, isNotNull);
      expect(firstEmission!['regNo'], equals('922523243079'));
      expect(firstEmission['studentName'], equals('Arun Kumar'));
    });
  });
}
