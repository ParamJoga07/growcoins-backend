import 'package:flutter/material.dart';

class InvestmentPlan {
  final int? id;
  final int userId;
  final String riskProfile;
  final String riskProfileDisplay; // e.g., "Capital Protection Investor"
  final AutoSaveConfig autoSave;
  final PortfolioAllocation portfolio;
  final int? goalId; // Optional: linked to a specific goal
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvestmentPlan({
    this.id,
    required this.userId,
    required this.riskProfile,
    required this.riskProfileDisplay,
    required this.autoSave,
    required this.portfolio,
    this.goalId,
    this.createdAt,
    this.updatedAt,
  });

  factory InvestmentPlan.fromJson(Map<String, dynamic> json) {
    // Safely parse goalId - handle both int and string types
    int? parseGoalId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return InvestmentPlan(
      id: json['id'],
      userId: json['user_id'],
      riskProfile: json['risk_profile'],
      riskProfileDisplay: json['risk_profile_display'] ?? json['risk_profile'],
      autoSave: AutoSaveConfig.fromJson(json['auto_save']),
      portfolio: PortfolioAllocation.fromJson(json['portfolio']),
      goalId: parseGoalId(json['goal_id']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'risk_profile': riskProfile,
      'risk_profile_display': riskProfileDisplay,
      'auto_save': autoSave.toJson(),
      'portfolio': portfolio.toJson(),
      'goal_id': goalId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class AutoSaveConfig {
  final String frequency; // 'monthly', 'weekly', 'daily'
  final double monthlyAmount; // Amount per month
  final int durationMonths; // Duration in months
  final double? weeklyAmount; // Calculated from monthly
  final double? dailyAmount; // Calculated from monthly

  AutoSaveConfig({
    required this.frequency,
    required this.monthlyAmount,
    required this.durationMonths,
    this.weeklyAmount,
    this.dailyAmount,
  });

  factory AutoSaveConfig.fromJson(Map<String, dynamic> json) {
    final monthly = json['monthly_amount'] as num;
    return AutoSaveConfig(
      frequency: json['frequency'] ?? 'monthly',
      monthlyAmount: monthly.toDouble(),
      durationMonths: json['duration_months'] ?? 18,
      weeklyAmount: json['weekly_amount'] != null
          ? (json['weekly_amount'] as num).toDouble()
          : monthly.toDouble() / 4.33,
      dailyAmount: json['daily_amount'] != null
          ? (json['daily_amount'] as num).toDouble()
          : monthly.toDouble() / 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'monthly_amount': monthlyAmount,
      'duration_months': durationMonths,
      'weekly_amount': weeklyAmount,
      'daily_amount': dailyAmount,
    };
  }

  double getAmountForFrequency() {
    switch (frequency) {
      case 'weekly':
        return weeklyAmount ?? monthlyAmount / 4.33;
      case 'daily':
        return dailyAmount ?? monthlyAmount / 30;
      default:
        return monthlyAmount;
    }
  }
}

class PortfolioAllocation {
  final List<MutualFundAllocation> allocations;
  final String description; // e.g., "According to your Risk Folio, We have curated the best investment portfolio"

  PortfolioAllocation({
    required this.allocations,
    this.description = '',
  });

  factory PortfolioAllocation.fromJson(Map<String, dynamic> json) {
    return PortfolioAllocation(
      allocations: (json['allocations'] as List)
          .map((a) => MutualFundAllocation.fromJson(a))
          .toList(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allocations': allocations.map((a) => a.toJson()).toList(),
      'description': description,
    };
  }

  double getTotalPercentage() {
    return allocations.fold(0.0, (sum, alloc) => sum + alloc.percentage);
  }
}

class MutualFundAllocation {
  final int schemeCode;
  final String schemeName;
  final String category; // 'Equity', 'Debt', 'Balanced', 'Hybrid'
  final double percentage; // Allocation percentage (0-100)
  final double amount; // Calculated amount based on monthly investment
  final MutualFundDetails? fundDetails; // Full fund details from mutual fund API

  MutualFundAllocation({
    required this.schemeCode,
    required this.schemeName,
    required this.category,
    required this.percentage,
    required this.amount,
    this.fundDetails,
  });

  factory MutualFundAllocation.fromJson(Map<String, dynamic> json) {
    return MutualFundAllocation(
      schemeCode: json['scheme_code'],
      schemeName: json['scheme_name'],
      category: json['category'],
      percentage: (json['percentage'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      fundDetails: json['fund_details'] != null
          ? MutualFundDetails.fromJson(json['fund_details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheme_code': schemeCode,
      'scheme_name': schemeName,
      'category': category,
      'percentage': percentage,
      'amount': amount,
      'fund_details': fundDetails?.toJson(),
    };
  }

  Color getCategoryColor() {
    switch (category.toLowerCase()) {
      case 'equity':
        return const Color(0xFFFFD700); // Yellow/Gold
      case 'debt':
        return const Color(0xFF90EE90); // Light Green
      case 'balanced':
      case 'hybrid':
        return const Color(0xFF9370DB); // Purple
      default:
        return const Color(0xFF808080); // Gray
    }
  }
}

class MutualFundDetails {
  final int schemeCode;
  final String schemeName;
  final String fundHouse;
  final String schemeType;
  final String schemeCategory;
  final String category;
  final String riskLevel;
  final double? annualizedReturn; // p.a. percentage
  final double latestNav;
  final String? planType; // 'Direct' or 'Regular'
  final double? rating; // 1-5 stars

  MutualFundDetails({
    required this.schemeCode,
    required this.schemeName,
    required this.fundHouse,
    required this.schemeType,
    required this.schemeCategory,
    required this.category,
    required this.riskLevel,
    this.annualizedReturn,
    required this.latestNav,
    this.planType,
    this.rating,
  });

  factory MutualFundDetails.fromJson(Map<String, dynamic> json) {
    return MutualFundDetails(
      schemeCode: json['scheme_code'],
      schemeName: json['scheme_name'],
      fundHouse: json['fund_house'] ?? '',
      schemeType: json['scheme_type'] ?? '',
      schemeCategory: json['scheme_category'] ?? '',
      category: json['category'] ?? '',
      riskLevel: json['risk_level'] ?? 'Moderate',
      annualizedReturn: json['annualized_return'] != null
          ? (json['annualized_return'] as num).toDouble()
          : null,
      latestNav: (json['latest_nav'] as num).toDouble(),
      planType: json['plan_type'] ?? 'Direct',
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheme_code': schemeCode,
      'scheme_name': schemeName,
      'fund_house': fundHouse,
      'scheme_type': schemeType,
      'scheme_category': schemeCategory,
      'category': category,
      'risk_level': riskLevel,
      'annualized_return': annualizedReturn,
      'latest_nav': latestNav,
      'plan_type': planType,
      'rating': rating,
    };
  }

  String getRatingStars() {
    if (rating == null) return '★★★★☆';
    final stars = (rating! * 5).round();
    return '★' * stars + '☆' * (5 - stars);
  }
}

