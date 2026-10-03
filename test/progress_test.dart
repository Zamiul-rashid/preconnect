import 'package:flutter_test/flutter_test.dart';
import 'package:preconnect/model/progress_info.dart';

Map<String, dynamic> _payload({
  required List<String> curriculumCodes,
  required List<Map<String, dynamic>> completed,
}) {
  return <String, dynamic>{
    'curriculum': <String, dynamic>{
      'name': 'Sample Program',
      'totalCredit': 6,
      'headerCreditRequirements': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'General Education',
          'minimumCreditRequired': 6,
          'subHeaderCreditRequirements': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Core',
              'curriculumCourses': <Map<String, dynamic>>[
                for (final code in curriculumCodes)
                  <String, dynamic>{
                    'courseCode': code,
                    'courseName': 'Course $code',
                    'courseCredit': 3,
                    'isMandatory': true,
                  },
              ],
            },
          ],
        },
      ],
    },
    'completedCourses': completed,
    'majorMinors': const <Map<String, dynamic>>[],
  };
}

Map<String, dynamic> _course(
  String code, {
  String grade = 'A',
  bool isCompleted = true,
}) {
  return <String, dynamic>{
    'courseCode': code,
    'courseTitle': 'Course $code',
    'grade': grade,
    'courseCredit': 3,
    'isCompleted': isCompleted,
  };
}

void main() {
  group('courseCodeKey', () {
    test('treats renamed course codes as the same course', () {
      expect(courseCodeKey('EMB101'), courseCodeKey('DEV101'));
      expect(courseCodeKey(' emb101 '), courseCodeKey('DEV101'));
    });

    test('normalizes unrelated codes without merging them', () {
      expect(courseCodeKey(' cse110 '), 'CSE110');
      expect(courseCodeKey('ENG101'), isNot(courseCodeKey('DEV101')));
    });
  });

  group('ProgressInfo with equivalent course codes', () {
    test('counts EMB101 toward a DEV101 requirement', () {
      final info = ProgressInfo.fromPayload(
        _payload(
          curriculumCodes: const ['DEV101', 'ENG101'],
          completed: [_course('EMB101')],
        ),
      );

      expect(info.headerProgress.single.earnedCredit, 3);
      expect(info.remainingCourses.map((c) => c.code), ['ENG101']);
    });

    test('counts DEV101 toward an EMB101 requirement', () {
      final info = ProgressInfo.fromPayload(
        _payload(
          curriculumCodes: const ['EMB101', 'ENG101'],
          completed: [_course('DEV101')],
        ),
      );

      expect(info.headerProgress.single.earnedCredit, 3);
      expect(info.remainingCourses.map((c) => c.code), ['ENG101']);
    });

    test('does not double count credit when both codes were passed', () {
      final info = ProgressInfo.fromPayload(
        _payload(
          curriculumCodes: const ['DEV101', 'ENG101'],
          completed: [_course('DEV101'), _course('EMB101')],
        ),
      );

      expect(info.completedCredit, 3);
    });

    test('a failed equivalent does not satisfy the requirement', () {
      final info = ProgressInfo.fromPayload(
        _payload(
          curriculumCodes: const ['DEV101', 'ENG101'],
          completed: [_course('EMB101', grade: 'F')],
        ),
      );

      expect(info.headerProgress.single.earnedCredit, 0);
      expect(info.remainingCourses.map((c) => c.code), ['DEV101', 'ENG101']);
    });
  });
}
