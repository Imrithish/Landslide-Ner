import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../navigation/main_navigation_shell.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.terrain_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NER Landslide', style: TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        )),
                        Text('Early Warning System', style: TextStyle(
                          color: AppColors.darkTextMuted,
                          fontSize: 12,
                        )),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 48),

                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate(delay: 100.ms).slideX(begin: -0.1).fadeIn(duration: 400.ms),

                const SizedBox(height: 6),

                const Text(
                  'Sign in to monitor landslide risk in NER',
                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
                ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 36),

                // Error message
                if (authState.errorMessage != null && authState.status == AuthStatus.unauthenticated)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: AppColors.darkTextMuted),
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.darkTextMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email address';
                    return null;
                  },
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: AppColors.darkTextMuted),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.darkTextMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.darkTextMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 40),

                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Real ML predictions from the FastAPI backend. No mock data in production.',
                          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
