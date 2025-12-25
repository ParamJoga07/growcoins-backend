import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/goal_models.dart';
import '../models/investment_plan_model.dart';
import '../models/savings_models.dart';
import '../services/goal_service.dart';
import '../services/investment_plan_service.dart';
import '../services/savings_service.dart';
import 'onboarding/auto_save_config_screen.dart';
import 'onboarding/auto_roundoff_config_screen.dart';
import 'investment/investment_plan_intro_screen.dart';

class GoalDetailsScreen extends StatefulWidget {
  final int goalId;

  const GoalDetailsScreen({
    super.key,
    required this.goalId,
  });

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen>
    with SingleTickerProviderStateMixin {
  Goal? _goal;
  InvestmentPlan? _investmentPlan;
  RoundoffSetting? _roundoffSetting;
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

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

    _loadGoalDetails();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load goal details (should include investment_plan if backend supports it)
      final goal = await GoalService.getGoalDetails(widget.goalId);
      
      // Parse investment plan from goal if included
      InvestmentPlan? plan;
      if (goal.investmentPlan != null) {
        try {
          final planData = goal.investmentPlan as Map<String, dynamic>;
          plan = InvestmentPlan.fromJson(planData);
        } catch (e) {
          debugPrint('Error parsing investment plan from goal: $e');
        }
      }
      
      // If investment plan not in goal response, fetch separately
      if (plan == null) {
        try {
          plan = await InvestmentPlanService.getPlan(goalId: widget.goalId);
        } catch (e) {
          debugPrint('Investment plan not found: $e');
        }
      }

      // Load roundoff setting
      RoundoffSetting? roundoff;
      try {
        roundoff = await SavingsService.getRoundoffSetting();
        // Check if roundoff is linked to this goal
        if (roundoff.roundoffAmount == 0) {
          roundoff = null; // Not configured
        }
      } catch (e) {
        debugPrint('Roundoff setting not found: $e');
      }

      setState(() {
        _goal = goal;
        _investmentPlan = plan;
        _roundoffSetting = roundoff;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _getCategoryColor() {
    // Use primary color as default, can be enhanced to fetch from category
    return AppTheme.primaryColor;
  }

  String _formatTimeRemaining(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    
    if (difference.isNegative) {
      return 'Target date passed';
    }
    
    final days = difference.inDays;
    final months = (days / 30).floor();
    final years = (months / 12).floor();
    final remainingMonths = months % 12;
    
    if (years > 0 && remainingMonths > 0) {
      return '$years year${years > 1 ? 's' : ''} ${remainingMonths} month${remainingMonths > 1 ? 's' : ''}';
    } else if (years > 0) {
      return '$years year${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      return '$days day${days > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_errorMessage != null || _goal == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Failed to load goal details',
                style: AppTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadGoalDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final goal = _goal!;
    final categoryColor = _getCategoryColor();
    final categoryGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        categoryColor,
        categoryColor.withOpacity(0.7),
      ],
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Goal Details',
          style: AppTheme.headingSmall,
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _loadGoalDetails,
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal Header Card
                  _buildGoalHeaderCard(goal, categoryColor, categoryGradient),

                  const SizedBox(height: 24),

                  // Progress Card
                  _buildProgressCard(goal, categoryColor),

                  const SizedBox(height: 24),

                  // Auto Save Configuration
                  _buildConfigurationCard(
                    title: 'Auto Save',
                    subtitle: _investmentPlan != null
                        ? '${_investmentPlan!.autoSave.frequency == 'monthly' ? 'Monthly' : _investmentPlan!.autoSave.frequency == 'weekly' ? 'Weekly' : 'Daily'} - ₹${_investmentPlan!.autoSave.monthlyAmount.toStringAsFixed(0)}'
                        : 'Not configured',
                    icon: Icons.savings_rounded,
                    color: categoryColor,
                    gradient: categoryGradient,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AutoSaveConfigScreen(
                            goal: goal,
                            existingPlan: _investmentPlan,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadGoalDetails();
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Auto Roundoff Configuration
                  _buildConfigurationCard(
                    title: 'Auto Roundoff',
                    subtitle: _roundoffSetting != null && _roundoffSetting!.isActive
                        ? '₹${_roundoffSetting!.roundoffAmount} per transaction'
                        : 'Not configured',
                    icon: Icons.rounded_corner_rounded,
                    color: categoryColor,
                    gradient: categoryGradient,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AutoRoundoffConfigScreen(
                            goal: goal,
                            existingSetting: _roundoffSetting,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadGoalDetails();
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Investment Plan
                  _buildConfigurationCard(
                    title: _investmentPlan != null ? 'Investment Plan' : 'Setup Investment',
                    subtitle: _investmentPlan != null
                        ? '${_investmentPlan!.portfolio.allocations.length} funds configured'
                        : 'Not configured',
                    icon: _investmentPlan != null
                        ? Icons.trending_up_rounded
                        : Icons.description_rounded,
                    color: categoryColor,
                    gradient: categoryGradient,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvestmentPlanIntroScreen(
                            goalId: goal.id,
                            riskProfile: _investmentPlan?.riskProfile,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadGoalDetails();
                      }
                    },
                    showInvestments: _investmentPlan != null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalHeaderCard(
    Goal goal,
    Color color,
    LinearGradient gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.goalName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goal.categoryName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Amount',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${goal.targetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Current Amount',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${goal.currentAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Target: ${_formatTimeRemaining(goal.targetDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Goal goal, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: AppTheme.headingSmall,
              ),
              Text(
                '${goal.progressPercentage.toStringAsFixed(1)}%',
                style: AppTheme.headingSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (goal.progressPercentage.clamp(0.0, 100.0) / 100).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved: ₹${goal.currentAmount.toStringAsFixed(0)}',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Remaining: ₹${(goal.targetAmount - goal.currentAmount).toStringAsFixed(0)}',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              if (showInvestments && _investmentPlan != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                ...(_investmentPlan!.portfolio.allocations
                    .take(3)
                    .map(
                      (allocation) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
      ),
    );
  }
}

