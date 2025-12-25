import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'investment_plan_details_screen.dart';

class InvestmentPlanIntroScreen extends StatefulWidget {
  final String? riskProfile;
  final int? goalId;

  const InvestmentPlanIntroScreen({
    super.key,
    this.riskProfile,
    this.goalId,
  });

  @override
  State<InvestmentPlanIntroScreen> createState() =>
      _InvestmentPlanIntroScreenState();
}

class _InvestmentPlanIntroScreenState
    extends State<InvestmentPlanIntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToPlan() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => InvestmentPlanDetailsScreen(
          riskProfile: widget.riskProfile,
          goalId: widget.goalId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Investment Planning',
          style: AppTheme.headingSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      'Here is your personalized investment plan',
                      style: AppTheme.headingLarge.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _navigateToPlan,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 18,
                        ),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('View Plan'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

