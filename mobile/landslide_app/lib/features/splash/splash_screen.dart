import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../auth/login_screen.dart';
import '../../navigation/main_navigation_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Navigate once auth status is determined
    ref.listen(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationShell()),
            );
          }
        });
      } else if (next.status == AuthStatus.unauthenticated) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon / Logo
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.terrain_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 36),

                  // Title
                  const Text(
                    'NER LANDSLIDE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 200.ms)
                      .slideY(begin: 0.3, end: 0)
                      .fadeIn(duration: 500.ms),

                  const Text(
                    'EARLY WARNING',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 300.ms)
                      .slideY(begin: 0.3, end: 0)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 16),

                  const Text(
                    'Protecting communities through\nAI-powered risk monitoring',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 600.ms),

                  const SizedBox(height: 64),

                  if (authState.status == AuthStatus.loading ||
                      authState.status == AuthStatus.initial)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 80),

                  // Footer
                  const Text(
                    'North Eastern Region, India',
                    style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                  ).animate(delay: 500.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
