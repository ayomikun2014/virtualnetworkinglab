import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/features/admin/widgets/course_assignment_form.dart';

Future<GlobalKey<CourseAssignmentFormState>> _pump(
  WidgetTester tester, {
  List<Map<String, String>> initialCourses = const [],
}) async {
  final key = GlobalKey<CourseAssignmentFormState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CourseAssignmentForm(key: key, initialCourses: initialCourses),
      ),
    ),
  );
  return key;
}

void main() {
  testWidgets('starts with one empty row when nothing is pre-filled', (
    tester,
  ) async {
    final key = await _pump(tester);

    expect(find.byType(TextField), findsNWidgets(2)); // title + code
    expect(key.currentState!.courses(), isEmpty);
    expect(key.currentState!.isValid, isTrue);
  });

  testWidgets('pre-fills a row per existing assignment', (tester) async {
    final key = await _pump(
      tester,
      initialCourses: const [
        {'title': 'Networking Principles', 'code': 'NET201'},
        {'title': 'Subnetting & IP Design', 'code': 'NET102'},
      ],
    );

    // findsWidgets, not findsOneWidget: a TextField's text is reachable
    // through more than one widget in its render tree (the EditableText
    // plus its own internal Text nodes), so an exact-one match is brittle
    // here — the list of courses() is the real assertion below.
    expect(find.text('Networking Principles'), findsWidgets);
    expect(find.text('NET102'), findsWidgets);
    expect(key.currentState!.courses(), hasLength(2));
  });

  testWidgets('Add Another Course reveals a new blank row', (tester) async {
    final key = await _pump(tester);

    await tester.tap(find.text('Add Another Course'));
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(4));
    expect(key.currentState!.courses(), isEmpty);
  });

  testWidgets('courses() drops a row left entirely blank', (tester) async {
    final key = await _pump(tester);

    await tester.tap(find.text('Add Another Course'));
    await tester.pump();

    // Fill only the first row.
    await tester.enterText(find.byType(TextField).at(0), 'Networking Principles');
    await tester.enterText(find.byType(TextField).at(1), 'net201');
    await tester.pump();

    final courses = key.currentState!.courses();
    expect(courses, hasLength(1));
    expect(
      courses.single['code'],
      'NET201',
      reason: 'the code is upper-cased for consistency',
    );
  });

  testWidgets(
    'a row with only one of title/code filled in is invalid, not silently dropped',
    (tester) async {
      final key = await _pump(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Networking Principles');
      await tester.pump();

      expect(
        key.currentState!.isValid,
        isFalse,
        reason:
            'a half-filled row is a mistake the admin should fix, not data '
            'that quietly vanishes',
      );
    },
  );
}
