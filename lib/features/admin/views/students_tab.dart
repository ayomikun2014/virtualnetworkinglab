import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_notification.dart';
import '../services/admin_provision_service.dart';

/// Admin Tab 2: Searchable Student Directory
class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final _searchController = TextEditingController();
  final _adminService = AdminProvisionService();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmSuspend(
    BuildContext context, {
    required String uid,
    required String displayName,
    required bool currentlyActive,
  }) async {
    final suspending = currentlyActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGlass,
        title: Text(
          suspending ? 'Suspend this student?' : 'Reactivate this student?',
          style: const TextStyle(color: AppTheme.textBright, fontSize: 17),
        ),
        content: Text(
          suspending
              ? '$displayName will not be able to sign in until '
                    'reactivated. A session already signed in on their '
                    'device is not force-ended, but their next sign-in '
                    'attempt is blocked.'
              : '$displayName will be able to sign in again immediately.',
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
              backgroundColor: suspending
                  ? AppTheme.accentCrimson
                  : AppTheme.accentEmerald,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(suspending ? 'Suspend' : 'Reactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await _adminService.setUserActive(
      uid: uid,
      displayName: displayName,
      isActive: !suspending,
    );
    if (!context.mounted) return;
    AppNotifier.show(
      context,
      success
          ? '$displayName ${suspending ? 'suspended' : 'reactivated'}.'
          : 'Failed to update $displayName.',
      type: success ? AppNotificationType.info : AppNotificationType.error,
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
          'Delete this student?',
          style: TextStyle(color: AppTheme.textBright, fontSize: 17),
        ),
        content: Text(
          "$displayName's profile, progress and enrolments are removed "
          'from the directory. Their sign-in credentials are not revoked — '
          "if they sign in again they'll start over as a brand-new "
          'student account.',
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
      success ? '$displayName deleted.' : 'Failed to delete $displayName.',
      type: success ? AppNotificationType.info : AppNotificationType.error,
    );
  }

  void _showStudentDetailsModal(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final name = data['displayName'] ?? 'Student User';
        final email = data['email'] ?? '';
        final matric = data['studentIdNumber'] ?? 'NT20240111512';
        final dept = data['departmentId'] ?? 'Networking';
        final level = data['freePracticeLevel'] ?? 1;
        final isActive = data['isActive'] as bool? ?? true;
        final courses =
            (data['enrolledCourseIds'] as List?)?.cast<String>() ?? [];

        return AlertDialog(
          backgroundColor: AppTheme.surfaceGlass,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          title: Row(
            children: [
              const Icon(Icons.person, color: AppTheme.primaryCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textBright,
                    fontSize: 18,
                  ),
                ),
              ),
              if (!isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCrimson.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SUSPENDED',
                    style: TextStyle(
                      color: AppTheme.accentCrimson,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Matric No: $matric',
                  style: const TextStyle(
                    color: AppTheme.primaryCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Email: $email',
                style: const TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Department: $dept',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Practice Level: Level $level',
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enrolled Courses:',
                style: TextStyle(
                  color: AppTheme.textBright,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              courses.isEmpty
                  ? const Text(
                      'None yet.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    )
                  : Wrap(
                      spacing: 6,
                      children: courses
                          .map(
                            (c) => Chip(
                              label: Text(
                                c,
                                style: const TextStyle(
                                  color: AppTheme.primaryCyan,
                                  fontSize: 11,
                                ),
                              ),
                              backgroundColor: AppTheme.primaryCyan.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: Icon(
                isActive ? Icons.block : Icons.check_circle_outline,
                size: 16,
                color: isActive
                    ? AppTheme.accentCrimson
                    : AppTheme.accentEmerald,
              ),
              label: Text(
                isActive ? 'Suspend' : 'Reactivate',
                style: TextStyle(
                  color: isActive
                      ? AppTheme.accentCrimson
                      : AppTheme.accentEmerald,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _confirmSuspend(
                  context,
                  uid: uid,
                  displayName: name,
                  currentlyActive: isActive,
                );
              },
            ),
            TextButton.icon(
              icon: const Icon(
                Icons.delete_outline,
                size: 16,
                color: AppTheme.accentCrimson,
              ),
              label: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.accentCrimson),
              ),
              onPressed: () {
                Navigator.pop(context);
                _confirmDelete(context, uid: uid, displayName: name);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppTheme.primaryCyan),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Student Matriculation Directory',
          style: TextStyle(
            color: AppTheme.textBright,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Real-time student registry with matriculation number verification and course enrollments.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Search Input Field
        TextField(
          controller: _searchController,
          style: const TextStyle(color: AppTheme.textBright),
          decoration: InputDecoration(
            hintText:
                'Search by Matric Number (NT20240111512), Name, or Email...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryCyan),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (val) =>
              setState(() => _searchQuery = val.trim().toLowerCase()),
        ),
        const SizedBox(height: 24),

        // StreamBuilder of Students
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .where('role', isEqualTo: 'student')
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
            final filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['displayName'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              final matric = (data['studentIdNumber'] ?? '')
                  .toString()
                  .toLowerCase();

              return _searchQuery.isEmpty ||
                  name.contains(_searchQuery) ||
                  email.contains(_searchQuery) ||
                  matric.contains(_searchQuery);
            }).toList();

            if (filteredDocs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Center(
                  child: Text(
                    'No matching student profiles found.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final uid = filteredDocs[index].id;
                final data = filteredDocs[index].data() as Map<String, dynamic>;
                final name = data['displayName'] ?? 'Student User';
                final email = data['email'] ?? 'student@univ.edu';
                final matric = data['studentIdNumber'] ?? 'NT20240111512';
                final level = data['freePracticeLevel'] ?? 1;
                final isActive = data['isActive'] as bool? ?? true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      backgroundColor:
                          (isActive
                                  ? AppTheme.primaryCyan
                                  : AppTheme.accentCrimson)
                              .withValues(alpha: 0.15),
                      child: Icon(
                        isActive ? Icons.person : Icons.block,
                        color: isActive
                            ? AppTheme.primaryCyan
                            : AppTheme.accentCrimson,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textBright,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            matric,
                            style: const TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCrimson.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SUSPENDED',
                              style: TextStyle(
                                color: AppTheme.accentCrimson,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '$email • Level $level',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppTheme.textMuted,
                      ),
                      color: AppTheme.surfaceGlass,
                      onSelected: (action) {
                        if (action == 'suspend') {
                          _confirmSuspend(
                            context,
                            uid: uid,
                            displayName: name,
                            currentlyActive: isActive,
                          );
                        } else if (action == 'delete') {
                          _confirmDelete(context, uid: uid, displayName: name);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'suspend',
                          child: Row(
                            children: [
                              Icon(
                                isActive ? Icons.block : Icons.check_circle,
                                size: 18,
                                color: isActive
                                    ? AppTheme.accentCrimson
                                    : AppTheme.accentEmerald,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isActive ? 'Suspend' : 'Reactivate',
                                style: const TextStyle(
                                  color: AppTheme.textBright,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppTheme.accentCrimson,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppTheme.textBright),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showStudentDetailsModal(context, uid, data),
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
