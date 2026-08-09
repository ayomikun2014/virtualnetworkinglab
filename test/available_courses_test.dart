import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/constants/available_courses.dart';

void main() {
  group('kAvailableCourses', () {
    test('has at least one course', () {
      expect(kAvailableCourses, isNotEmpty);
    });

    test('every course code is unique', () {
      // This is the single source of truth both class creation and exercise
      // authoring dropdowns are built from — a duplicate code here would
      // silently make two different courses indistinguishable to a student
      // matching by categoryId.
      final codes = kAvailableCourses.map((c) => c.code).toSet();
      expect(codes.length, kAvailableCourses.length);
    });

    test('codes and titles are non-empty', () {
      for (final course in kAvailableCourses) {
        expect(course.code.trim(), isNotEmpty);
        expect(course.title.trim(), isNotEmpty);
      }
    });

    test('label combines code and title', () {
      const course = CourseOption(code: 'NET201', title: 'Networking Principles');
      expect(course.label, 'NET201 — Networking Principles');
    });
  });
}
