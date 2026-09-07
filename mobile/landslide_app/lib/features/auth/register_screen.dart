import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../navigation/main_navigation_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedState;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          stateName: _selectedState,
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
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join NER Early Warning',
                  style: TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 6),
                const Text(
                  'Register to receive landslide alerts for NER',
                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
                ).animate(delay: 50.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // Error
                if (authState.errorMessage != null && authState.status == AuthStatus.unauthenticated)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withAlpha(60)),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    labelStyle: TextStyle(color: AppColors.darkTextMuted),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.darkTextMuted),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    labelStyle: TextStyle(color: AppColors.darkTextMuted),
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.darkTextMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (optional)',
                    labelStyle: TextStyle(color: AppColors.darkTextMuted),
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.darkTextMuted),
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 14),

                // State dropdown
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  dropdownColor: AppColors.darkCard,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'State (NER Region)',
                    labelStyle: TextStyle(color: AppColors.darkTextMuted),
                    prefixIcon: Icon(Icons.location_city_outlined, color: AppColors.darkTextMuted),
                  ),
                  items: AppConstants.nerStates.map((state) {
                    return DropdownMenuItem(
                      value: state,
                      child: Text(state, style: const TextStyle(color: AppColors.darkTextPrimary)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedState = val),
                ).animate(delay: 250.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password *',
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
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ).animate(delay: 300.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 14),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    labelStyle: const TextStyle(color: AppColors.darkTextMuted),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.darkTextMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.darkTextMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ).animate(delay: 350.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 32),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleRegister,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ).animate(delay: 400.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Already have an account? Sign In',
                      style: TextStyle(color: AppColors.primary, fontSize: 14),
                    ),
                  ),
                ).animate(delay: 450.ms).fadeIn(duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
