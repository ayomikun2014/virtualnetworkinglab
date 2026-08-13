import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/app_logo_widget.dart';
import '../../../core/widgets/project_credits_widget.dart';
import '../providers/auth_provider.dart';

/// Dual-Identifier Login Screen with High-Tech Local Asset Background Image
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Clear previous errors before attempting login
    authProvider.clearError();

    final success = await authProvider.loginWithIdentifierAndPassword(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (!success && mounted && authProvider.errorMessage != null) {
      AppNotifier.error(context, authProvider.errorMessage!);
    }
  }

  /// Builds a prominent inline error banner widget
  Widget _buildErrorBanner(String message, AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentCrimson.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.accentCrimson.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.accentCrimson,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.accentCrimson,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => authProvider.clearError(),
            child: Icon(
              Icons.close_rounded,
              color: AppTheme.accentCrimson.withValues(alpha: 0.7),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Local Background Image Asset with Dark Overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: AppTheme.backgroundMidnight);
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              color: AppTheme.backgroundMidnight.withValues(alpha: 0.75),
            ),
          ),

          // Glassmorphic Login Form Container
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass.withValues(alpha: 0.85),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand Header Icon
                      const AppLogoWidget(size: 64),
                      const SizedBox(height: 20),
                      const Text(
                        'Virtual Networking Laboratory',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textBright,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Virtual Networking Laboratory Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Inline Error Banner — visible when login fails
                      if (authProvider.errorMessage != null)
                        _buildErrorBanner(
                          authProvider.errorMessage!,
                          authProvider,
                        ),

                      // Dual Identifier Field (Email OR Matriculation Number)
                      TextFormField(
                        controller: _identifierController,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: const InputDecoration(
                          labelText: 'Email or Matriculation Number',
                          hintText: 'alex@univ.edu OR NT20010100001',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter your Email or Matriculation Number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppTheme.textBright),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppTheme.primaryCyan,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Login Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : _handleLogin,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.backgroundMidnight,
                                  ),
                                )
                              : const Text('Sign In to Laboratory'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Registration Navigation Link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "New Student? ",
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: const Text(
                              "Register Matriculation Profile",
                              style: TextStyle(
                                color: AppTheme.primaryCyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Academic Project Credits Badge
                      const ProjectCreditsWidget(),
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
