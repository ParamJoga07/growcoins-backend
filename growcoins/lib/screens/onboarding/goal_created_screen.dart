import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/goal_models.dart';
import '../../models/investment_plan_model.dart';
import '../../models/savings_models.dart';
import '../../services/investment_plan_service.dart';
import '../../services/savings_service.dart';
import '../home_screen.dart';
import '../investment/investment_plan_intro_screen.dart';
import 'goal_configuration_screen.dart';
import 'auto_save_config_screen.dart';
import 'auto_roundoff_config_screen.dart';

class GoalCreatedScreen extends StatefulWidget {
  final Goal goal;
  final GoalCategory category;

  const GoalCreatedScreen({
    super.key,
    required this.goal,
    required this.category,
  });

  @override
  State<GoalCreatedScreen> createState() => _GoalCreatedScreenState();
}

class _GoalCreatedScreenState extends State<GoalCreatedScreen>
    with SingleTickerProviderStateMixin {
  bool _hasInvestmentPlan = false;
  bool _hasAutoSave = false;
  bool _hasAutoRoundoff = false;
  InvestmentPlan? _investmentPlan;
  RoundoffSetting? _roundoffSetting;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadConfigurationStatus();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvestmentPlan() async {
    try {
      final plan = await InvestmentPlanService.getPlan(goalId: widget.goal.id);
      if (plan != null) {
        setState(() {
          _hasInvestmentPlan = true;
          _investmentPlan = plan;
          _hasAutoSave = true; // If plan exists, auto-save is configured
        });
      }
    } catch (e) {
      debugPrint('Error fetching investment plan: $e');
    }
  }

  Future<void> _loadConfigurationStatus() async {
    try {
      // First, check if investment plan is included in the goal response
      if (widget.goal.investmentPlan != null) {
        try {
          // Parse investment plan from goal response
          final planData = widget.goal.investmentPlan as Map<String, dynamic>;
          final plan = InvestmentPlan.fromJson(planData);
          setState(() {
            _hasInvestmentPlan = true;
            _investmentPlan = plan;
            _hasAutoSave = true; // If plan exists, auto-save is configured
          });
        } catch (e) {
          debugPrint('Error parsing investment plan from goal: $e');
          // Fall back to fetching separately
          await _fetchInvestmentPlan();
        }
      } else {
        // If not in goal response, fetch separately
        await _fetchInvestmentPlan();
      }

      // Check roundoff setting
      try {
        final roundoff = await SavingsService.getRoundoffSetting();
        setState(() {
          _hasAutoRoundoff = roundoff.isActive;
          _roundoffSetting = roundoff;
        });
      } catch (e) {
        // Roundoff not configured yet
      }
    } catch (e) {
      // Configuration not set up yet
    }
  }

  String _formatTimePeriod(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    final months = (difference.inDays / 30).round();
    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (years > 0 && remainingMonths > 0) {
      return '${years}Y ${remainingMonths}M';
    } else if (years > 0) {
      return '${years}Y';
    } else {
      return '${months}M';
    }
  }

  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  Future<void> _configureInvestmentPlan() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvestmentPlanIntroScreen(
            goalId: widget.goal.id,
            riskProfile: null, // Will be fetched from user profile
          ),
        ),
      );

      if (result == true) {
        await _loadConfigurationStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _configureAutoSave() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoSaveConfigScreen(
          goal: widget.goal,
          existingPlan: _investmentPlan,
        ),
      ),
    );

    if (result == true) {
      await _loadConfigurationStatus();
    }
  }

  Future<void> _configureAutoRoundoff() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoRoundoffConfigScreen(
          goal: widget.goal,
          existingSetting: _roundoffSetting,
        ),
      ),
    );

    if (result == true) {
      await _loadConfigurationStatus();
    }
  }

  Future<void> _configureGoal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GoalConfigurationScreen(category: widget.category),
      ),
    );

    if (result == true) {
      // Reload goal data if needed
      Navigator.pop(context, true);
    }
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getColorFromString(widget.category.color);
    final categoryGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [categoryColor.withOpacity(0.6), categoryColor.withOpacity(0.4)],
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.home_rounded, color: categoryColor.withOpacity(0.7)),
          onPressed: _goToHome,
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: categoryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.goal.goalName,
            style: AppTheme.headingSmall.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.description_rounded,
              color: categoryColor.withOpacity(0.7),
            ),
            onPressed: () {
              // Show goal details
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        categoryColor.withOpacity(0.15),
                        categoryColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Target Time',
                                style: AppTheme.bodySmall.copyWith(
                                  color: categoryColor.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimePeriod(widget.goal.targetDate),
                                style: AppTheme.headingMedium.copyWith(
                                  color: categoryColor.withOpacity(0.9),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Target Amount',
                                style: AppTheme.bodySmall.copyWith(
                                  color: categoryColor.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${widget.goal.targetAmount.toStringAsFixed(0)}',
                                style: AppTheme.headingMedium.copyWith(
                                  color: categoryColor.withOpacity(0.9),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: categoryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _configureGoal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Configure',
                            style: AppTheme.buttonText.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Auto Saving Card
                _buildConfigurationCard(
                  title: 'Auto Saving',
                  subtitle: _hasAutoSave && _investmentPlan != null
                      ? '${_investmentPlan!.autoSave.frequency == 'monthly'
                            ? 'Monthly'
                            : _investmentPlan!.autoSave.frequency == 'weekly'
                            ? 'Weekly'
                            : 'Daily'} - ₹${_investmentPlan!.autoSave.monthlyAmount.toStringAsFixed(0)}'
                      : 'Configure',
                  icon: Icons.savings_rounded,
                  color: categoryColor,
                  gradient: categoryGradient,
                  onTap: _configureAutoSave,
                ),
                const SizedBox(height: 16),

                // Auto Roundoff Card
                _buildConfigurationCard(
                  title: 'Auto Roundingoff',
                  subtitle: _hasAutoRoundoff && _roundoffSetting != null
                      ? '₹${_roundoffSetting!.roundoffAmount} per transaction'
                      : 'Configure',
                  icon: Icons.rounded_corner_rounded,
                  color: categoryColor,
                  gradient: categoryGradient,
                  onTap: _configureAutoRoundoff,
                ),
                const SizedBox(height: 16),

                // Investment Setup Card
                _buildConfigurationCard(
                  title: _hasInvestmentPlan
                      ? 'Investments'
                      : 'Setup Investment',
                  subtitle: _hasInvestmentPlan
                      ? '${_investmentPlan!.portfolio.allocations.length} funds configured'
                      : 'Configure',
                  icon: _hasInvestmentPlan
                      ? Icons.trending_up_rounded
                      : Icons.description_rounded,
                  color: categoryColor,
                  gradient: categoryGradient,
                  onTap: _configureInvestmentPlan,
                  showInvestments: _hasInvestmentPlan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
    required VoidCallback onTap,
    bool showInvestments = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (showInvestments && _investmentPlan != null) ...[
                      const SizedBox(height: 8),
                      ...(_investmentPlan!.portfolio.allocations
                          .take(3)
                          .map(
                            (allocation) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      allocation.schemeName,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${allocation.percentage.toStringAsFixed(1)}%',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
