import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/backend_auth_service.dart';
import '../services/api_service.dart';
import '../services/auth_state_service.dart';
import '../services/onboarding_service.dart';
import '../services/biometric_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/growcoins_logo.dart';
import 'onboarding/onboarding_kyc_screen.dart';
import 'home_screen.dart';
import 'backend_register_screen.dart';

class BackendLoginScreen extends StatefulWidget {
  const BackendLoginScreen({super.key});

  @override
  State<BackendLoginScreen> createState() => _BackendLoginScreenState();
}

class _BackendLoginScreenState extends State<BackendLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _buttonController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Content animation controller
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _contentSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    // Button animation controller
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _logoController.dispose();
    _contentController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await BackendAuthService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Get user ID from response
      final userId = response['user']?['id'];

      if (mounted) {
        // Check if biometrics are available and user hasn't set preference yet
        final biometricService = BiometricAuthService();
        final isBiometricAvailable = await biometricService
            .isBiometricAvailable();

        debugPrint('=== Biometric Check ===');
        debugPrint('Biometric available on device: $isBiometricAvailable');
        debugPrint('User ID: $userId');

        // Check if user already has biometric preference set in backend
        bool? biometricPreference;
        if (userId != null) {
          try {
            biometricPreference =
                await BackendAuthService.getBiometricPreference(userId);
            if (biometricPreference == null) {
              debugPrint('Biometric preference: NOT SET (user never asked)');
            } else {
              debugPrint('Biometric preference: ${biometricPreference ? "ENABLED" : "DISABLED"}');
            }
          } catch (e) {
            debugPrint('Error getting biometric preference: $e');
            biometricPreference = null; // Treat as not set
          }
        }

        // Show dialog if:
        // 1. Biometrics are available on device
        // 2. User ID exists
        // 3. Preference is null (never set) OR false (user skipped before)
        if (isBiometricAvailable && userId != null) {
          if (biometricPreference == null || biometricPreference == false) {
            debugPrint('✓ Showing biometric setup dialog');
            _showBiometricSetupDialog(userId);
            return; // Don't navigate yet, wait for user choice
          } else {
            debugPrint('✗ Biometric already enabled, skipping dialog');
          }
        } else {
          if (!isBiometricAvailable) {
            debugPrint('✗ Biometrics not available on device');
          }
          if (userId == null) {
            debugPrint('✗ User ID is null');
          }
        }

        // Navigate based on onboarding status (if biometric dialog not shown)
        _navigateAfterLogin();
      }
    } on ApiException catch (e) {
      if (mounted) {
        String errorMessage = e.message;

        // Handle validation errors
        if (e.errors != null && e.errors!.isNotEmpty) {
          errorMessage = e.errors!.first['msg'] ?? e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An error occurred: ${e.toString()}',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showBiometricSetupDialog(int userId) {
    final authStateService = AuthStateService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Enable Biometric Authentication',
            style: AppTheme.headingSmall,
          ),
          content: Text(
            'Would you like to enable Face ID or Touch ID for faster login?',
            style: AppTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Save to local storage
                await authStateService.setBiometricEnabled(false);
                // Save to backend
                await BackendAuthService.setBiometricPreference(
                  userId: userId,
                  enabled: false,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  _navigateAfterLogin();
                }
              },
              child: Text(
                'Skip',
                style: AppTheme.labelLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save to local storage
                await authStateService.setBiometricEnabled(true);
                // Save to backend
                await BackendAuthService.setBiometricPreference(
                  userId: userId,
                  enabled: true,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  _navigateAfterLogin();
                }
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateAfterLogin() async {
    final authStateService = AuthStateService();
    final onboardingCompleted = await authStateService.isOnboardingCompleted();

    if (mounted) {
      if (onboardingCompleted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        // Check if KYC details are already filled
        final hasKyc = await OnboardingService.hasKycDetails();

        if (hasKyc) {
          // KYC details already filled, go to home screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          // Get personal details from profile and navigate to KYC screen
          final personalData =
              await OnboardingService.getPersonalDetailsFromProfile();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OnboardingKYCScreen(existingData: personalData),
            ),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with logo
              Expanded(
                flex: 2,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _logoRotationAnimation.value * math.pi,
                          child: const GrowcoinsLogo(width: 160, height: 160),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Bottom section with form
              Expanded(flex: 3, child: _buildLoginForm()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag indicator

              // Title
              FadeTransition(
                opacity: _contentFadeAnimation,
                child: SlideTransition(
                  position: _contentSlideAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Welcome Back',
                        style: AppTheme.headingMedium.copyWith(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login to continue',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Username field
              FadeTransition(
                opacity: _contentFadeAnimation,
                child: SlideTransition(
                  position: _contentSlideAnimation,
                  child: TextFormField(
                    controller: _usernameController,
                    style: AppTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Password field
              FadeTransition(
                opacity: _contentFadeAnimation,
                child: SlideTransition(
                  position: _contentSlideAnimation,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Login button
              FadeTransition(
                opacity: _buttonAnimation,
                child: ScaleTransition(
                  scale: _buttonAnimation,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Login',
                            style: AppTheme.buttonText.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Register link
              FadeTransition(
                opacity: _buttonAnimation,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BackendRegisterScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Register',
                          style: AppTheme.labelLarge.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
