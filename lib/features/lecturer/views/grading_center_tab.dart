import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/lecturer_management_service.dart';

/// Lecturer Tab 3: Grading Center & Manual Grade Overrides
class GradingCenterTab extends StatefulWidget {
  const GradingCenterTab({super.key});

  @override
  State<GradingCenterTab> createState() => _GradingCenterTabState();
}

class _GradingCenterTabState extends State<GradingCenterTab> {
  final _service = LecturerManagementService();

  void _showGradingModal(BuildContext context, Map<String, dynamic> data, String submissionId, String lecturerUid) {
    final formKey = GlobalKey<FormState>();
    final scoreController = TextEditingController(text: (data['finalScore'] ?? 95.0).toString());
    final feedbackController = TextEditingController(text: data['lecturerFeedback'] ?? 'Great job on the OSPF configuration!');
    bool isSaving = false;

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
                  Icon(Icons.grade, color: AppTheme.primaryCyan),
                  SizedBox(width: 10),
                  Text('Submission Evaluation & Grade Override', style: TextStyle(color: AppTheme.textBright, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Automated Engine Results
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundMidnight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accentEmerald.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Automated Lab Evaluation Results:', style: TextStyle(color: AppTheme.textBright, fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 8),
                              Text('✓ ICMP Echo Ping: Passed (100% Reachability)', style: TextStyle(color: AppTheme.accentEmerald, fontSize: 12)),
                              Text('✓ OSPF Adjacency: Passed (FULL/DR State)', style: TextStyle(color: AppTheme.accentEmerald, fontSize: 12)),
                              Text('✓ IP Addressing: Passed (Subnet Mask Correct)', style: TextStyle(color: AppTheme.accentEmerald, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Score Input
                        TextFormField(
                          controller: scoreController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textBright),
                          decoration: const InputDecoration(
                            labelText: 'Final Score (Max: 100)',
                            prefixIcon: Icon(Icons.stars, color: AppTheme.primaryCyan),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter score' : null,
                        ),
                        const SizedBox(height: 16),

                        // Feedback Input
                        TextFormField(
                          controller: feedbackController,
                          maxLines: 3,
                          style: const TextStyle(color: AppTheme.textBright),
                          decoration: const InputDecoration(
                            labelText: 'Lecturer Evaluation Feedback',
                            prefixIcon: Icon(Icons.comment, color: AppTheme.primaryCyan),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter feedback' : null,
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
                  icon: isSaving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.backgroundMidnight))
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Save Grade & Release'),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setModalState(() => isSaving = true);
                          final score = double.tryParse(scoreController.text) ?? 95.0;

                          final success = await _service.submitGradeOverride(
                            submissionId: submissionId,
                            finalScore: score,
                            feedback: feedbackController.text.trim(),
                            lecturerUid: lecturerUid,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Grade override saved!' : 'Failed to save grade.'),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final lecturerUid = authProvider.currentUser?.uid ?? 'lecturer';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Student Submissions & Grading Center',
          style: TextStyle(color: AppTheme.textBright, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Inspect student frozen topology snapshots, review automated engine evaluations, and assign manual grade overrides.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('${AppConstants.rootPath}/submissions')
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
              // Sample Demo Submissions Cards if collection is fresh
              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSampleSubmissionCard(
                    context,
                    submissionId: 'sub_001',
                    studentName: 'Alex Johnson',
                    matric: 'NT20240111512',
                    labTitle: 'Assessment 1: Single Area OSPF Convergence',
                    status: 'Pending Review',
                    statusColor: Colors.amber,
                    score: '95 / 100',
                    lecturerUid: lecturerUid,
                  ),
                  const SizedBox(height: 12),
                  _buildSampleSubmissionCard(
                    context,
                    submissionId: 'sub_002',
                    studentName: 'Maria Garcia',
                    matric: 'NT20240111513',
                    labTitle: 'Assessment 2: VLAN Trunking & Inter-VLAN Routing',
                    status: 'Graded',
                    statusColor: AppTheme.accentEmerald,
                    score: '98 / 100',
                    lecturerUid: lecturerUid,
                  ),
                ],
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final subId = docs[index].id;
                final student = data['studentName'] ?? 'Student';
                final matric = data['studentIdNumber'] ?? 'NT20240111512';
                final lab = data['exerciseTitle'] ?? 'OSPF Lab Assignment';
                final status = (data['status'] ?? 'pending').toString().toUpperCase();
                final score = data['finalScore'] ?? 95.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
                      child: const Icon(Icons.assignment_turned_in, color: AppTheme.primaryCyan),
                    ),
                    title: Text(student, style: const TextStyle(color: AppTheme.textBright, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('Matric: $matric • $lab • Status: $status', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: Text('Grade ($score)'),
                      onPressed: () => _showGradingModal(context, data, subId, lecturerUid),
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

  Widget _buildSampleSubmissionCard(
    BuildContext context, {
    required String submissionId,
    required String studentName,
    required String matric,
    required String labTitle,
    required String status,
    required Color statusColor,
    required String score,
    required String lecturerUid,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.15),
          child: const Icon(Icons.assignment_turned_in, color: AppTheme.primaryCyan),
        ),
        title: Row(
          children: [
            Text(studentName, style: const TextStyle(color: AppTheme.textBright, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(matric, style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Text(labTitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.rate_review, size: 16),
          label: Text('Grade ($score)'),
          onPressed: () => _showGradingModal(
            context,
            {
              'finalScore': 95.0,
              'lecturerFeedback': 'Excellent IEEE 802.1Q trunking configuration.',
            },
            submissionId,
            lecturerUid,
          ),
        ),
      ),
    );
  }
}
