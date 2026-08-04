import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_logo_widget.dart';
import '../providers/auth_provider.dart';

/// Student Registration Screen with Local Asset Background Image
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _matricController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedDepartment = 'dept_net';
  final List<String> _selectedCourseIds = ['crs_net201'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _matricController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.registerStudent(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _fullNameController.text.trim(),
      studentIdNumber: _matricController.text.trim().toUpperCase(),
      departmentId: _selectedDepartment,
      enrolledCourseIds: _selectedCourseIds,
    );

    if (!success && mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.accentCrimson,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Local Background Image Asset with Overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/register_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: AppTheme.backgroundMidnight);
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              color: AppTheme.backgroundMidnight.withValues(alpha: 0.78),
            ),
          ),

          // Glassmorphic Registration Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppTheme.textBright),
                            onPressed: () => context.go('/login'),
                          ),
                          const SizedBox(width: 8),
                          const AppLogoWidget(size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Student Signup',
                              style: TextStyle(
                                color: AppTheme.textBright,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Alex Johnson',
                          prefixIcon: Icon(Icons.badge, color: AppTheme.primaryCyan),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 2) {
                            return 'Enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Matriculation Number Field (NT20010100001)
                      TextFormField(
                        controller: _matricController,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Matriculation Number',
                          hintText: 'NT20010100001',
                          prefixIcon: Icon(Icons.verified_user, color: AppTheme.primaryCyan),
                        ),
                        validator: (val) {
                          if (val == null || !Validators.isValidMatricNumber(val.trim())) {
                            return 'Invalid format. Must match NT-YYYY-XXXXX (e.g. NT20010100001)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Institutional Email
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Institutional Email Address',
                          hintText: 'alex.johnson@univ.edu',
                          prefixIcon: Icon(Icons.email, color: AppTheme.primaryCyan),
                        ),
                        validator: (val) {
                          if (val == null || !Validators.isValidEmail(val.trim())) {
                            return 'Enter a valid institutional email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Department Picker Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDepartment,
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
                          DropdownMenuItem(value: 'dept_se', child: Text('Software Engineering')),
                        ],
                        onChanged: (val) => setState(() => _selectedDepartment = val!),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock, color: AppTheme.primaryCyan),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_clock, color: AppTheme.primaryCyan),
                        ),
                        validator: (val) {
                          if (val != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _handleRegister,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.backgroundMidnight,
                                  ),
                                )
                              : const Text('Complete Student Registration'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
