import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../services/admin_provision_service.dart';

/// Admin Tab 2: Departments & Course Curriculum Management
class CoursesTab extends StatefulWidget {
  const CoursesTab({super.key});

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  final _adminService = AdminProvisionService();

  void _showAddCourseModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final codeController = TextEditingController();
    String deptId = 'dept_net';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceGlass,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          title: const Text('Add New Course Curriculum', style: TextStyle(color: AppTheme.textBright, fontSize: 18)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  style: const TextStyle(color: AppTheme.textBright),
                  decoration: const InputDecoration(
                    labelText: 'Course Title',
                    hintText: 'Computer Networking Principles',
                    prefixIcon: Icon(Icons.book, color: AppTheme.primaryCyan),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter course title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeController,
                  style: const TextStyle(color: AppTheme.textBright),
                  decoration: const InputDecoration(
                    labelText: 'Course Code',
                    hintText: 'NET201',
                    prefixIcon: Icon(Icons.code, color: AppTheme.primaryCyan),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter course code' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: deptId,
                  dropdownColor: AppTheme.surfaceGlass,
                  style: const TextStyle(color: AppTheme.textBright),
                  decoration: const InputDecoration(
                    labelText: 'Academic Department',
                    prefixIcon: Icon(Icons.school, color: AppTheme.primaryCyan),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'dept_net', child: Text('Networking & Telecommunications')),
                    DropdownMenuItem(value: 'dept_cs', child: Text('Computer Science')),
                    DropdownMenuItem(value: 'dept_sec', child: Text('Cybersecurity & Infrastructure')),
                  ],
                  onChanged: (val) => deptId = val!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final courseCode = codeController.text.trim().toUpperCase();
                final id = 'crs_${courseCode.toLowerCase()}';

                final success = await _adminService.createCourse(
                  id: id,
                  title: titleController.text.trim(),
                  code: courseCode,
                  departmentId: deptId,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Course curriculum added!' : 'Failed to create course.'),
                      backgroundColor: success ? AppTheme.accentEmerald : AppTheme.accentCrimson,
                    ),
                  );
                }
              },
              child: const Text('Save Course'),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Academic Curriculum Directory',
                  style: TextStyle(color: AppTheme.textBright, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage departments and course offerings available for student enrollment.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Course'),
              onPressed: () => _showAddCourseModal(context),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Stream of Courses from /virtuanetlab/app/courses
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('${AppConstants.rootPath}/${AppConstants.coursesCollection}')
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
                  child: Text('No courses created yet. Click "Add Course" above.', style: TextStyle(color: AppTheme.textMuted)),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.8,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Networking Principles';
                final code = data['code'] ?? 'NET201';
                final dept = data['departmentId'] ?? 'dept_net';

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceGlass,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const Icon(Icons.school, color: AppTheme.textMuted, size: 20),
                        ],
                      ),
                      Text(
                        title,
                        style: const TextStyle(color: AppTheme.textBright, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Department: $dept',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
}
