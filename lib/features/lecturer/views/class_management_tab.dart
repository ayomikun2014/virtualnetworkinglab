import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/lecturer_management_service.dart';

/// Lecturer Tab 1: Class Cohort Management & Student Roster Directory
class ClassManagementTab extends StatefulWidget {
  const ClassManagementTab({super.key});

  @override
  State<ClassManagementTab> createState() => _ClassManagementTabState();
}

class _ClassManagementTabState extends State<ClassManagementTab> {
  final _lecturerService = LecturerManagementService();

  void _showCreateClassModal(BuildContext context, String lecturerUid) {
    final formKey = GlobalKey<FormState>();
    final sectionController = TextEditingController(text: 'Section A');
    final semesterController = TextEditingController(text: 'Fall 2026');
    String courseId = 'NET201';
    bool isSubmitting = false;

    showDialog(
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
                children: const [
                  Icon(Icons.group_add, color: AppTheme.primaryCyan),
                  SizedBox(width: 10),
                  Text('Create Class & Join Code', style: TextStyle(color: AppTheme.textBright, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: courseId,
                        dropdownColor: AppTheme.surfaceGlass,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Assigned Course',
                          prefixIcon: Icon(Icons.menu_book, color: AppTheme.primaryCyan),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'NET201', child: Text('NET201 — Networking Principles')),
                          DropdownMenuItem(value: 'NET102', child: Text('NET102 — Subnetting & IP Design')),
                          DropdownMenuItem(value: 'SEC301', child: Text('SEC301 — Network Defense & Firewalls')),
                        ],
                        onChanged: (val) => setModalState(() => courseId = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: sectionController,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Class Section Name',
                          hintText: 'Section A',
                          prefixIcon: Icon(Icons.class_outlined, color: AppTheme.primaryCyan),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter section name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: semesterController,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Academic Semester',
                          hintText: 'Fall 2026',
                          prefixIcon: Icon(Icons.calendar_month, color: AppTheme.primaryCyan),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter semester' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton.icon(
                  icon: isSubmitting
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.backgroundMidnight))
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Generate Join Code'),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setModalState(() => isSubmitting = true);

                          final result = await _lecturerService.createClass(
                            courseId: courseId,
                            sectionName: sectionController.text.trim(),
                            lecturerUid: lecturerUid,
                            semester: semesterController.text.trim(),
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            if (result != null) {
                              _showJoinCodeCreatedDialog(context, result['joinCode'] ?? 'NET2026A');
                            }
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

  void _showJoinCodeCreatedDialog(BuildContext context, String joinCode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceGlass,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Class Created Successfully!', style: TextStyle(color: AppTheme.textBright)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this unique join code with your enrolled students:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryCyan),
                ),
                child: SelectableText(
                  joinCode,
                  style: const TextStyle(
                    color: AppTheme.primaryCyan,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final lecturerUid = authProvider.currentUser?.uid ?? 'lecturer';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Class Cohort & Roster Directory',
                  style: TextStyle(color: AppTheme.textBright, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Generate enrollment join codes and inspect student rosters.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Class Section'),
              onPressed: () => _showCreateClassModal(context, lecturerUid),
            ),
          ],
        ),
        const SizedBox(height: 24),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('${AppConstants.rootPath}/${AppConstants.classesCollection}')
              .where('lecturerUid', isEqualTo: lecturerUid)
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
                  child: Text('No active class sections found. Click "Create Class Section" above.', style: TextStyle(color: AppTheme.textMuted)),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final section = data['sectionName'] ?? 'Section A';
                final course = data['courseId'] ?? 'NET201';
                final code = data['joinCode'] ?? 'NET2026A';
                final count = data['studentCount'] ?? 18;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
                      child: const Icon(Icons.class_outlined, color: AppTheme.primaryCyan),
                    ),
                    title: Text('$course — $section', style: const TextStyle(color: AppTheme.textBright, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('Join Code: $code • Enrolled: $count Students', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: AppTheme.backgroundMidnight.withValues(alpha: 0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Class Roster (Enrolled Students):', style: TextStyle(color: AppTheme.textBright, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _buildSampleStudentRow('Alex Johnson', 'alex.j@univ.edu', 'NT20240111512'),
                            _buildSampleStudentRow('Maria Garcia', 'm.garcia@univ.edu', 'NT20240111513'),
                            _buildSampleStudentRow('David Smith', 'd.smith@univ.edu', 'NT20240111514'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSampleStudentRow(String name, String email, String matric) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 16, color: AppTheme.primaryCyan),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(color: AppTheme.textBright, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(matric, style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Text(email, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
