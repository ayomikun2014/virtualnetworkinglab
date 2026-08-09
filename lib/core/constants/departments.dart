/// The fixed set of academic departments this deployment supports, and
/// their display names.
///
/// Single source of truth — previously each admin/auth screen that needed
/// "dept_net" -> "Networking & Telecommunications" kept its own private
/// copy of this map, which is how they drifted (one had four entries,
/// another three, spelled slightly differently).
const Map<String, String> kDepartmentNames = {
  'dept_net': 'Networking & Telecommunications',
  'dept_cs': 'Computer Science & Infrastructure',
  'dept_sec': 'Cybersecurity & Defense',
  'dept_se': 'Software Engineering',
};

/// A department id's display name, or the raw id itself if it isn't one of
/// [kDepartmentNames] — better to show an unrecognised id than silently
/// swap in a generic label that hides a data problem.
String departmentLabel(String? id) =>
    kDepartmentNames[id] ?? (id == null || id.isEmpty ? 'Unassigned' : id);
