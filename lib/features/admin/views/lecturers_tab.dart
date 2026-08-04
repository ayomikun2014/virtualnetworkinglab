import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../services/admin_provision_service.dart';

/// Admin Tab 1: Lecturer Provisioning & Roster Directory
class LecturersTab extends StatefulWidget {
  const LecturersTab({super.key});

  @override
  State<LecturersTab> createState() => _LecturersTabState();
}

class _LecturersTabState extends State<LecturersTab> {
  final _adminProvisionService = AdminProvisionService();

  void _showProvisionLecturerModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedDept = 'dept_net';
    final List<String> selectedCourses = ['crs_net201'];
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
                  Icon(Icons.person_add, color: AppTheme.primaryCyan),
                  SizedBox(width: 10),
                  Text('Provision Lecturer Profile', style: TextStyle(color: AppTheme.textBright, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: AppTheme.textBright),
                          decoration: const InputDecoration(
                            labelText: 'Faculty Full Name',
                            prefixIcon: Icon(Icons.person, color: AppTheme.primaryCyan),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter full name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          style: const TextStyle(color: AppTheme.textBright),
                          decoration: const InputDecoration(
                            labelText: 'Institutional Email Address',
                            prefixIcon: Icon(Icons.email, color: AppTheme.primaryCyan),
                          ),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          style: const TextStyle(color: AppTheme.textBright),
                          decoration: const InputDecoration(
                            labelText: 'Initial Password',
                            prefixIcon: Icon(Icons.lock, color: AppTheme.primaryCyan),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedDept,
                          dropdownColor: AppTheme.surfaceGlass,
                          style: const TextStyle(color: AppTheme.textBright),
                          decoration: const InputDecoration(
                            labelText: 'Academic Department',
                            prefixIcon: Icon(Icons.school, color: AppTheme.primaryCyan),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'dept_net', child: Text('Networking & Telecommunications')),
                            DropdownMenuItem(value: 'dept_cs', child: Text('Computer Science & Infrastructure')),
                            DropdownMenuItem(value: 'dept_sec', child: Text('Cybersecurity & Defense')),
                          ],
                          onChanged: (val) => setModalState(() => selectedDept = val!),
                        ),
                      ],
                    ),
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
                  label: const Text('Provision Faculty'),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setModalState(() => isSubmitting = true);

                          final success = await _adminProvisionService.provisionLecturer(
                            email: emailController.text.trim(),
                            password: passwordController.text,
                            displayName: nameController.text.trim(),
                            departmentId: selectedDept,
                            taughtClassIds: selectedCourses,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Lecturer account provisioned successfully!' : 'Failed to provision lecturer.'),
                                backgroundColor: success ? AppTheme.accentEmerald : AppTheme.accentCrimson,
                              ),
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
                  'Lecturer Faculty Directory',
                  style: TextStyle(color: AppTheme.textBright, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Provision faculty profiles and review assigned academic departments.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Provision Lecturer'),
              onPressed: () => _showProvisionLecturerModal(context),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Real-time Stream of Lecturers
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('${AppConstants.rootPath}/${AppConstants.usersCollection}')
              .where('role', isEqualTo: 'lecturer')
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
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.badge, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No Lecturer Accounts Provisioned Yet',
                        style: TextStyle(color: AppTheme.textBright, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Click "Provision Lecturer" above to create faculty credentials.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
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
                final name = data['displayName'] ?? 'Faculty Member';
                final email = data['email'] ?? 'faculty@univ.edu';
                final dept = data['departmentId'] ?? 'dept_net';
                final courses = (data['taughtClassIds'] as List?)?.cast<String>() ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
                      child: const Icon(Icons.badge, color: AppTheme.primaryCyan),
                    ),
                    title: Text(name, style: const TextStyle(color: AppTheme.textBright, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Email: $email', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        Text('Department: $dept', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: courses
                              .map((c) => Chip(
                                    label: Text(c, style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 11)),
                                    backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
                                    side: BorderSide.none,
                                  ))
                              .toList(),
                        ),
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
