/// A course a lecturer can create a class section for, or author an exercise
/// under.
class CourseOption {
  final String code;
  final String title;

  const CourseOption({required this.code, required this.title});

  String get label => '$code — $title';
}

/// The fixed set of courses this deployment supports.
///
/// Single source of truth, deliberately shared between class creation
/// (`class_management_tab.dart`) and exercise authoring
/// (`exercise_authoring_tab.dart`). Those two previously used a dropdown of
/// these same three codes for one and a free-text field for the other — a
/// lecturer typing `'Net201'` or `'NET-201'` into the free-text field
/// produced an exercise whose `categoryId` didn't exactly match any
/// student's `enrolledCourseIds` (which only ever contain the class's real
/// `courseId`), so the exercise silently never appeared for anyone, with no
/// error anywhere. A dropdown sourced from this same list makes that
/// mismatch structurally impossible instead of relying on lecturers typing
/// the same string correctly twice.
const List<CourseOption> kAvailableCourses = [
  CourseOption(code: 'NET201', title: 'Networking Principles'),
  CourseOption(code: 'NET102', title: 'Subnetting & IP Design'),
  CourseOption(code: 'SEC301', title: 'Network Defense & Firewalls'),
];
