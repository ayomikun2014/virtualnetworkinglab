import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/departments.dart';
import '../services/admin_provision_service.dart';
import '../widgets/course_assignment_form.dart';

/// Admin Tab 1: Lecturer Approval Queue & Faculty Directory
///
/// Lecturers create their own accounts from the Register screen — an admin
/// no longer types in a name/email/password for them, since a client SDK
/// can't create another user's Firebase Auth account without hijacking its
/// own session (see the account-creation note that used to live here).
/// What an admin does instead is review each self-registered account and
/// decide what it can teach.
class LecturersTab extends StatefulWidget {
  const LecturersTab({super.key});

  @override
  State<LecturersTab> createState() => _LecturersTabState();
}

class _LecturersTabState extends State<LecturersTab> {
  final _adminService = AdminProvisionService();

  Future<void> _showApproveModal(
    BuildContext context, {
    required String uid,
    required String displayName,
  }) async {
    final formKey = GlobalKey<CourseAssignmentFormState>();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceGlass,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              title: Row(
                children: [
                  const Icon(Icons.how_to_reg, color: AppTheme.accentEmerald),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Approve $displayName',
                      style: const TextStyle(
                        color: AppTheme.textBright,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign at least one course. This is what the '
                        "lecturer's dashboard will show as theirs to teach.",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CourseAssignmentForm(key: formKey),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
                ElevatedButton.icon(
                  icon: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.backgroundMidnight,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final formState = formKey.currentState!;
                          if (!formState.isValid) {
                            setModalState(() {});
                            return;
                          }
                          final courses = formState.courses();
                          if (courses.isEmpty) {
                            AppNotifier.error(
                              context,
                              'Assign at least one course before approving.',
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          final success = await _adminService.approveLecturer(
                            uid: uid,
                            displayName: displayName,
                            assignedCourses: courses,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            AppNotifier.show(
                              context,
                              success
                                  ? '$displayName approved.'
                                  : 'Failed to approve $displayName.',
                              type: success
                                  ? AppNotificationType.success
                                  : AppNotificationType.error,
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmReject(
    BuildContext context, {
    required String uid,
    required String displayName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGlass,
        title: const Text(
          'Reject this application?',
          style: TextStyle(color: AppTheme.textBright, fontSize: 17),
        ),
        content: Text(
          '$displayName\'s lecturer application will be removed. They can '
          'still sign in, but as an ordinary student account, not a '
          'lecturer.',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCrimson,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await _adminService.deleteUserProfile(
      uid: uid,
      displayName: displayName,
    );
    if (!context.mounted) return;
    AppNotifier.show(
      context,
      success ? 'Application rejected.' : 'Failed to reject application.',
      type: success ? AppNotificationType.info : AppNotificationType.error,
    );
  }

  Future<void> _showEditModal(
    BuildContext context, {
    required String uid,
    required String displayName,
    required String currentDepartment,
    required List<Map<String, String>> currentCourses,
  }) async {
    final formKey = GlobalKey<CourseAssignmentFormState>();
    String deptId = currentDepartment;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceGlass,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              title: Row(
                children: [
                  const Icon(Icons.edit, color: AppTheme.primaryCyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Edit $displayName',
                      style: const TextStyle(
                        color: AppTheme.textBright,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: deptId,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceGlass,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Academic Department',
                          prefixIcon: Icon(
                            Icons.school,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                        items: kDepartmentNames.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  e.value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => deptId = val!),
                      ),
                      const SizedBox(height: 16),
                      CourseAssignmentForm(
                        key: formKey,
                        initialCourses: currentCourses,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
                ElevatedButton.icon(
                  icon: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.backgroundMidnight,
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: const Text('Save Changes'),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final formState = formKey.currentState!;
                          if (!formState.isValid) {
                            setModalState(() {});
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          final success = await _adminService
                              .updateLecturerAssignment(
                                uid: uid,
                                displayName: displayName,
                                departmentId: deptId,
                                assignedCourses: formState.courses(),
                              );

                          if (context.mounted) {
                            Navigator.pop(context);
                            AppNotifier.show(
                              context,
                              success
                                  ? 'Updated $displayName.'
                                  : 'Failed to save changes.',
                              type: success
                                  ? AppNotificationType.success
                                  : AppNotificationType.error,
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String uid,
    required String displayName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGlass,
        title: const Text(
          'Delete this lecturer?',
          style: TextStyle(color: AppTheme.textBright, fontSize: 17),
        ),
        content: Text(
          '$displayName loses lecturer access — their course assignments '
          'and profile are removed. Their sign-in credentials still work, '
          'but they land back as an ordinary student.',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCrimson,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await _adminService.deleteUserProfile(
      uid: uid,
      displayName: displayName,
    );
    if (!context.mounted) return;
    AppNotifier.show(
      context,
      success ? 'Lecturer deleted.' : 'Failed to delete lecturer.',
      type: success ? AppNotificationType.info : AppNotificationType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Lecturer Faculty Directory',
          style: TextStyle(
            color: AppTheme.textBright,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Lecturers register themselves from the sign-up page. Review '
          'each application below and assign the courses they teach.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Pending approvals — surfaced above the roster, since this is the
        // queue that actually needs the admin's attention.
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .where('role', isEqualTo: 'lecturer')
              .where('approvalStatus', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Pending Approval (${docs.length})',
                        style: const TextStyle(
                          color: AppTheme.textBright,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final uid = doc.id;
                    final name = data['displayName'] ?? 'Lecturer Applicant';
                    final email = data['email'] ?? '';
                    final dept = departmentLabel(
                      data['departmentId'] as String?,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.amber.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.amber,
                              child: Icon(
                                Icons.hourglass_top,
                                color: AppTheme.backgroundMidnight,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: AppTheme.textBright,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '$email • $dept',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppTheme.accentCrimson,
                              ),
                              tooltip: 'Reject',
                              onPressed: () => _confirmReject(
                                context,
                                uid: uid,
                                displayName: name,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentEmerald,
                              ),
                              onPressed: () => _showApproveModal(
                                context,
                                uid: uid,
                                displayName: name,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),

        const Text(
          'Active Lecturers',
          style: TextStyle(
            color: AppTheme.textBright,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .where('role', isEqualTo: 'lecturer')
              .where('approvalStatus', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.primaryCyan),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.badge, size: 48, color: AppTheme.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No approved lecturers yet',
                        style: TextStyle(
                          color: AppTheme.textBright,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Approvals show up here once a pending application '
                        'is reviewed above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final uid = docs[index].id;
                final name = data['displayName'] ?? 'Faculty Member';
                final email = data['email'] ?? 'faculty@univ.edu';
                final deptId = data['departmentId'] as String? ?? 'dept_net';
                final courses =
                    (data['assignedCourses'] as List?)
                        ?.cast<Map<String, dynamic>>()
                        .map((c) => c.map((k, v) => MapEntry(k, '$v')))
                        .toList() ??
                    <Map<String, String>>[];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryCyan.withValues(
                                alpha: 0.15,
                              ),
                              child: const Icon(
                                Icons.badge,
                                color: AppTheme.primaryCyan,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: AppTheme.textBright,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '$email • ${departmentLabel(deptId)}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.primaryCyan,
                                size: 20,
                              ),
                              tooltip: 'Edit courses & department',
                              onPressed: () => _showEditModal(
                                context,
                                uid: uid,
                                displayName: name,
                                currentDepartment: deptId,
                                currentCourses: courses,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.accentCrimson,
                                size: 20,
                              ),
                              tooltip: 'Delete',
                              onPressed: () => _confirmDelete(
                                context,
                                uid: uid,
                                displayName: name,
                              ),
                            ),
                          ],
                        ),
                        if (courses.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: courses
                                .map(
                                  (c) => Chip(
                                    label: Text(
                                      '${c['code']} — ${c['title']}',
                                      style: const TextStyle(
                                        color: AppTheme.primaryCyan,
                                        fontSize: 11,
                                      ),
                                    ),
                                    backgroundColor: AppTheme.primaryCyan
                                        .withValues(alpha: 0.15),
                                    side: BorderSide.none,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
