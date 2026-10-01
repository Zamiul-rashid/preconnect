import 'package:preconnect/api/exam_map.dart';
import 'package:preconnect/model/section_info.dart' as section;
import 'package:preconnect/tools/time_utils.dart';

class CourseSectionExamFilter {
  const CourseSectionExamFilter._();

  static bool isFinishedAfterFinalExam({
    required section.Section section,
    required Map<String, ExamScheduleOverride> overrides,
    DateTime? now,
  }) {
    final resolved = ExamScheduleService().resolveSection(
      section: section,
      overrides: overrides,
    );
    final finalDateTime = AppTime.parseDateTime(
      resolved.finalDate,
      resolved.finalEndTime ?? resolved.finalStartTime,
    );
    final current = now ?? DateTime.now();
    if (finalDateTime != null) {
      return !current.isBefore(finalDateTime);
    }
    final endDate = AppTime.parseDate(section.sectionSchedule.classEndDate);
    if (endDate != null) {
      return current.isAfter(
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
      );
    }
    return false;
  }

  static Set<String> finishedSectionKeys(
    Iterable<section.Section> sections,
    Map<String, ExamScheduleOverride> overrides, {
    DateTime? now,
  }) {
    final keys = <String>{};
    for (final item in sections) {
      if (!isFinishedAfterFinalExam(
        section: item,
        overrides: overrides,
        now: now,
      )) {
        continue;
      }
      final key = ExamMapService.sectionKey(
        courseCode: item.courseCode,
        sectionName: item.sectionName,
      );
      if (key.isNotEmpty) {
        keys.add(key);
      }
    }
    return keys;
  }
}
