import 'package:flutter/material.dart';
import '../widgets/growcoins_logo.dart';
import '../theme/app_theme.dart';
import 'login_selection_screen.dart';
import 'home_screen.dart';
import '../services/auth_state_service.dart';
import '../services/backend_auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/biometric_auth_service.dart';
import 'onboarding/onboarding_kyc_screen.dart';
import 'onboarding/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  final bool firebaseInitialized;

  const SplashScreen({super.key, required this.firebaseInitialized});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Navigate after delay
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for minimum splash duration (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check authentication status
    final authStateService = AuthStateService();
    bool isFirebaseLoggedIn = false;
    bool isBackendLoggedIn = false;

    // Check Firebase auth
    if (widget.firebaseInitialized) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        isFirebaseLoggedIn = user != null;
      } catch (e) {
        debugPrint('Error checking Firebase auth: $e');
      }
    }

    // Check backend auth
    try {
      isBackendLoggedIn = await BackendAuthService.isLoggedIn();
    } catch (e) {
      debugPrint('Error checking backend auth: $e');
    }

    // Navigate based on auth status
    if (isFirebaseLoggedIn || isBackendLoggedIn) {
      // Check biometric authentication for backend users
      if (isBackendLoggedIn) {
        final userId = await BackendAuthService.getUserId();
        if (userId != null) {
          try {
            debugPrint('Checking biometric preference for user: $userId');
            final biometricEnabled =
                await BackendAuthService.getBiometricPreference(userId);
            debugPrint('Biometric enabled in backend: $biometricEnabled');

            // Only show biometric prompt if explicitly enabled (true)
            if (biometricEnabled == true) {
              final biometricService = BiometricAuthService();
              final isAvailable = await biometricService.isBiometricAvailable();
              debugPrint('Biometric available on device: $isAvailable');

              if (isAvailable) {
                // Wait a bit to ensure splash screen is visible before showing biometric prompt
                await Future.delayed(const Duration(milliseconds: 500));

                debugPrint('Requesting biometric authentication...');
                final authenticated = await biometricService.authenticate();
                debugPrint('Biometric authentication result: $authenticated');

                if (!authenticated) {
                  // Biometric authentication failed, but don't logout
                  // Continue with normal flow - user remains logged in
                  debugPrint('Biometric authentication failed, but user remains logged in');
                } else {
                  debugPrint('Biometric authentication successful!');
                }
              } else {
                debugPrint('Biometric not available on device');
              }
            } else {
              if (biometricEnabled == null) {
                debugPrint('Biometric preference not set for this user');
              } else {
                debugPrint('Biometric not enabled for this user');
              }
            }
          } catch (e) {
            debugPrint('Error checking biometric: $e');
            // Continue with normal flow if error
          }
        } else {
          debugPrint('User ID is null, cannot check biometric preference');
        }
      }

      // Check onboarding status
      final onboardingCompleted = await authStateService
          .isOnboardingCompleted();

      if (onboardingCompleted) {
        // Navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Check if KYC details are already filled
        final hasKyc = await OnboardingService.hasKycDetails();

        if (hasKyc) {
          // KYC details already filled, go to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // Get personal details from profile and navigate to KYC screen
          final personalData =
              await OnboardingService.getPersonalDetailsFromProfile();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OnboardingKYCScreen(existingData: personalData),
            ),
          );
        }
      }
    } else {
      // Not logged in - check if app onboarding has been shown
      final appOnboardingCompleted = await authStateService
          .isAppOnboardingCompleted();

      if (appOnboardingCompleted) {
        // App onboarding already shown, go to login selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginSelectionScreen()),
        );
      } else {
        // First time user or not logged in - show app onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        const GrowcoinsLogo(width: 200, height: 200),
                        const SizedBox(height: 40),
                        // App Name
                        const SizedBox(height: 12),
                        // Tagline

                        // Loading indicator
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
