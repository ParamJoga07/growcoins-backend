import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'goal_category_selection_screen.dart';
import '../savings_screen.dart';
import '../home_screen.dart';

class OnboardingSetupProfileScreen extends StatefulWidget {
  const OnboardingSetupProfileScreen({super.key});

  @override
  State<OnboardingSetupProfileScreen> createState() =>
      _OnboardingSetupProfileScreenState();
}

class _OnboardingSetupProfileScreenState
    extends State<OnboardingSetupProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonAnimation1;
  late Animation<double> _buttonAnimation2;
  late Animation<double> _buttonAnimation3;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _buttonAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );

    _buttonAnimation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToGoalSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoalCategorySelectionScreen(),
      ),
    );
  }

  void _navigateToRoundoffSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavingsScreen(),
      ),
    );
  }

  void _navigateToInvestProfile() {
    // TODO: Navigate to invest profile setup screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invest Profile setup coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Setup',
                    style: AppTheme.headingSmall.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Illustration
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: MediaQuery.of(context).size.width * 0.6,
                      constraints: const BoxConstraints(
                        maxWidth: 250,
                        maxHeight: 250,
                      ),
                      child: Image.asset(
                        'assets/images/onboarding1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Text
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text(
                          'Setup Your Profile',
                          style: AppTheme.headingMedium.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'For Maximum Savings',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Bottom section with buttons
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Setup Goal Button
                        FadeTransition(
                          opacity: _buttonAnimation1,
                          child: ScaleTransition(
                            scale: _buttonAnimation1,
                            child: _buildSetupButton(
                              icon: Icons.check_circle_rounded,
                              label: 'Setup Goal',
                              gradient: AppTheme.successGradient,
                              onTap: _navigateToGoalSetup,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Setup Roundoff and Invest Profile buttons
                        Row(
                          children: [
                            Expanded(
                              child: FadeTransition(
                                opacity: _buttonAnimation2,
                                child: ScaleTransition(
                                  scale: _buttonAnimation2,
                                  child: _buildSetupButton(
                                    icon: Icons.account_balance_wallet_rounded,
                                    label: 'Setup Roundoff',
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA500),
                                      ],
                                    ),
                                    onTap: _navigateToRoundoffSetup,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FadeTransition(
                                opacity: _buttonAnimation3,
                                child: ScaleTransition(
                                  scale: _buttonAnimation3,
                                  child: _buildSetupButton(
                                    icon: Icons.trending_up_rounded,
                                    label: 'Setup Invest Pro...',
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFE91E63),
                                        Color(0xFF9C27B0),
                                      ],
                                    ),
                                    onTap: _navigateToInvestProfile,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Skip button
                        TextButton(
                          onPressed: () {
                            // Navigate back to home screen
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: Text(
                            'Skip Setup',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildSetupButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
