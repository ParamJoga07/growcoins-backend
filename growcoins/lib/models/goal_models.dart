
// Goal Category Model
class GoalCategory {
  final int id;
  final String name;
  final String icon;
  final String iconType;
  final String color;
  final String? description;
  final bool isActive;

  GoalCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconType,
    required this.color,
    this.description,
    required this.isActive,
  });

  factory GoalCategory.fromJson(Map<String, dynamic> json) {
    return GoalCategory(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      iconType: json['icon_type'] ?? 'material',
      color: json['color'] ?? '#2196F3',
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'icon_type': iconType,
      'color': color,
      'description': description,
      'is_active': isActive,
    };
  }
}

// Goal Model
class Goal {
  final int id;
  final int userId;
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double progressPercentage;
  final int? daysRemaining;
  final double? monthlySavingsNeeded;
  final dynamic investmentPlan; // InvestmentPlan? - using dynamic to avoid circular import

  Goal({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.progressPercentage,
    this.daysRemaining,
    this.monthlySavingsNeeded,
    this.investmentPlan,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return Goal(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? '',
      categoryIcon: json['category_icon'] ?? 'person',
      goalName: json['goal_name'],
      targetAmount: _toDouble(json['target_amount']),
      currentAmount: _toDouble(json['current_amount']),
      targetDate: DateTime.parse(json['target_date']),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      progressPercentage: _toDouble(json['progress_percentage']),
      daysRemaining: json['days_remaining'],
      monthlySavingsNeeded: json['monthly_savings_needed'] != null
          ? _toDouble(json['monthly_savings_needed'])
          : null,
      investmentPlan: json['investment_plan'], // Will be parsed separately if needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'goal_name': goalName,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String().split('T')[0],
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'progress_percentage': progressPercentage,
      'days_remaining': daysRemaining,
      'monthly_savings_needed': monthlySavingsNeeded,
    };
  }
}

// Goals Response Model
class GoalsResponse {
  final List<Goal> goals;
  final int total;
  final int limit;
  final int offset;

  GoalsResponse({
    required this.goals,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory GoalsResponse.fromJson(Map<String, dynamic> json) {
    return GoalsResponse(
      goals: (json['goals'] as List? ?? [])
          .map((g) => Goal.fromJson(g))
          .toList(),
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 50,
      offset: json['offset'] ?? 0,
    );
  }
}

// Setup Status Model
class SetupStatus {
  final int userId;
  final bool hasGoal;
  final bool hasRoundoffSetting;
  final bool hasInvestProfile;
  final bool setupComplete;
  final int goalsCount;
  final Map<String, dynamic>? roundoffSetting;
  final Map<String, dynamic>? investProfile;

  SetupStatus({
    required this.userId,
    required this.hasGoal,
    required this.hasRoundoffSetting,
    required this.hasInvestProfile,
    required this.setupComplete,
    required this.goalsCount,
    this.roundoffSetting,
    this.investProfile,
  });

  factory SetupStatus.fromJson(Map<String, dynamic> json) {
    return SetupStatus(
      userId: json['user_id'],
      hasGoal: json['has_goal'] ?? false,
      hasRoundoffSetting: json['has_roundoff_setting'] ?? false,
      hasInvestProfile: json['has_invest_profile'] ?? false,
      setupComplete: json['setup_complete'] ?? false,
      goalsCount: json['goals_count'] ?? 0,
      roundoffSetting: json['roundoff_setting'],
      investProfile: json['invest_profile'],
    );
  }
}

// Create Goal Request Model
class CreateGoalRequest {
  final int categoryId;
  final String goalName;
  final double targetAmount;
  final DateTime targetDate;
  final double initialAmount;
  final String? frequency; // Optional: "monthly", "weekly", or "daily"
  final double? monthlyAmount; // Optional: Monthly investment amount

  CreateGoalRequest({
    required this.categoryId,
    required this.goalName,
    required this.targetAmount,
    required this.targetDate,
    this.initialAmount = 0.0,
    this.frequency,
    this.monthlyAmount,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'category_id': categoryId,
      'goal_name': goalName,
      'target_amount': targetAmount,
      'target_date': targetDate.toIso8601String().split('T')[0],
      'initial_amount': initialAmount,
    };
    
    // Add optional investment plan fields
    if (frequency != null) {
      json['frequency'] = frequency!;
    }
    if (monthlyAmount != null) {
      json['monthly_amount'] = monthlyAmount!;
    }
    
    return json;
  }
}

