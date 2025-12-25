import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../theme/app_theme.dart';
import '../models/goal_models.dart';
import 'onboarding/goal_category_selection_screen.dart';
import 'goal_details_screen.dart';

class AllGoalsScreen extends StatefulWidget {
  const AllGoalsScreen({super.key});

  @override
  State<AllGoalsScreen> createState() => _AllGoalsScreenState();
}

class _AllGoalsScreenState extends State<AllGoalsScreen> {
  List<Goal> _goals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final goalsResponse = await GoalService.getUserGoals();
      setState(() {
        _goals = goalsResponse.goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load goals. Please try again.';
      });
      debugPrint('Error loading goals: $e');
    }
  }

  String? _getIconAsset(String iconName) {
    final lowerName = iconName.toLowerCase().trim();

    switch (lowerName) {
      case 'home':
        return 'assets/images/3d-home-realistic-icon-design-illustrations-3d-render-design-concept-vector 2.png';
      case 'camera':
      case 'gadget':
        return 'assets/images/3d-camera-icon-png-transformed 2.png';
      case 'trip':
      case 'international trip':
      case 'domestic trip':
      case 'flight':
      case 'landscape':
        return 'assets/images/3d-world-trip-icon-png-transformed-removebg-preview (1) 3.png';
      case 'birthday':
      case 'cake':
        return 'assets/images/cake-with-confetti-happy-birthday-event-anniversary-surprise-sign-symbol-object-cartoon-3d-background-illustration_56104-2293-removebg-preview 2.png';
      case 'party':
      case 'celebration':
        return 'assets/images/istockphoto-1483188505-612x612-removebg-preview 3.png';
      case 'car':
      case 'directions_car':
        return 'assets/images/isometric-view-cute-vintage-car-made-with-generative-ai_878954-202-transformed-removebg-preview 2.png';
      case 'phone':
        return 'assets/images/Asset 1 2.png';
      case 'other':
      case 'person':
        return 'assets/images/abstract-human-symbol-d-icon-social-avatar-online-communication-work-minimalistic-sign-people-user-business-symbology-230189749-transformed-removebg-preview 3.png';
      default:
        return null;
    }
  }

  Widget _buildGoalIcon(String iconName, Color? color) {
    final iconAsset = _getIconAsset(iconName);

    if (iconAsset != null) {
      return Image.asset(
        iconAsset,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        color: null,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.category_rounded,
            size: 40,
            color: color ?? AppTheme.primaryColor,
          );
        },
      );
    }

    return Icon(
      Icons.category_rounded,
      size: 40,
      color: color ?? AppTheme.primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Goals',
          style: AppTheme.headingSmall.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalCategorySelectionScreen(),
                ),
              );
              if (result == true) {
                _loadGoals();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _errorMessage != null
              ? Center(
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
                        _errorMessage!,
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadGoals,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _goals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.flag_outlined,
                              size: 64,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Goals Yet',
                            style: AppTheme.headingMedium.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first goal to start saving',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const GoalCategorySelectionScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadGoals();
                              }
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create Goal'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadGoals,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _goals.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < _goals.length - 1 ? 16 : 0,
                            ),
                            child: _buildGoalCard(_goals[index]),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalDetailsScreen(goalId: goal.id),
            ),
          ).then((result) {
            if (result == true) {
              _loadGoals();
            }
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _buildGoalIcon(goal.categoryIcon, Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.goalName,
                      style: AppTheme.headingSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.categoryName,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: goal.status == 'completed'
                      ? AppTheme.successColor.withOpacity(0.1)
                      : goal.status == 'active'
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : AppTheme.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  goal.status.toUpperCase(),
                  style: AppTheme.bodySmall.copyWith(
                    color: goal.status == 'completed'
                        ? AppTheme.successColor
                        : goal.status == 'active'
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${goal.progressPercentage.toStringAsFixed(1)}%',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (goal.progressPercentage / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Amount Info
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${goal.currentAmount.toStringAsFixed(0)}',
                        style: AppTheme.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${goal.targetAmount.toStringAsFixed(0)}',
                        style: AppTheme.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Additional Info
          if (goal.daysRemaining != null && goal.daysRemaining! > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${goal.daysRemaining} days remaining',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (goal.monthlySavingsNeeded != null) ...[
                  const Spacer(),
                  Icon(
                    Icons.savings_rounded,
                    size: 16,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${goal.monthlySavingsNeeded!.toStringAsFixed(0)}/month',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
          ),
        ),
      ),
    );
  }
}

