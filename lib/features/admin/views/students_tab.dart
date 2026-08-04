import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Admin Tab 3: Searchable Student Directory
class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStudentDetailsModal(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        final name = data['displayName'] ?? 'Student User';
        final email = data['email'] ?? '';
        final matric = data['studentIdNumber'] ?? 'NT20240111512';
        final dept = data['departmentId'] ?? 'Networking';
        final level = data['freePracticeLevel'] ?? 1;
        final courses = (data['enrolledCourseIds'] as List?)?.cast<String>() ?? [];

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
              Text(name, style: const TextStyle(color: AppTheme.textBright, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Matric No: $matric',
                  style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              Text('Email: $email', style: const TextStyle(color: AppTheme.textBright, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Department: $dept', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Practice Level: Level $level', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Enrolled Courses:', style: TextStyle(color: AppTheme.textBright, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: courses
                    .map((c) => Chip(
                          label: Text(c, style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 11)),
                          backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.primaryCyan)),
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
          style: TextStyle(color: AppTheme.textBright, fontSize: 20, fontWeight: FontWeight.bold),
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
            hintText: 'Search by Matric Number (NT20240111512), Name, or Email...',
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
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
        ),
        const SizedBox(height: 24),

        // StreamBuilder of Students
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('${AppConstants.rootPath}/${AppConstants.usersCollection}')
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
              final matric = (data['studentIdNumber'] ?? '').toString().toLowerCase();

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
                  child: Text('No matching student profiles found.', style: TextStyle(color: AppTheme.textMuted)),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final data = filteredDocs[index].data() as Map<String, dynamic>;
                final name = data['displayName'] ?? 'Student User';
                final email = data['email'] ?? 'student@univ.edu';
                final matric = data['studentIdNumber'] ?? 'NT20240111512';
                final level = data['freePracticeLevel'] ?? 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
                      child: const Icon(Icons.person, color: AppTheme.primaryCyan),
                    ),
                    title: Row(
                      children: [
                        Text(name, style: const TextStyle(color: AppTheme.textBright, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            matric,
                            style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('$email • Level $level', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 14),
                    onTap: () => _showStudentDetailsModal(context, data),
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
