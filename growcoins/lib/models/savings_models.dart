// Roundoff Setting Model
class RoundoffSetting {
  final int? id;
  final int userId;
  final int roundoffAmount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RoundoffSetting({
    this.id,
    required this.userId,
    required this.roundoffAmount,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory RoundoffSetting.fromJson(Map<String, dynamic> json) {
    return RoundoffSetting(
      id: json['id'],
      userId: json['user_id'],
      roundoffAmount: json['roundoff_amount'],
      isActive: json['is_active'] ?? true,
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
      'roundoff_amount': roundoffAmount,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// Transaction Model
class Transaction {
  final int id;
  final DateTime transactionDate;
  final String description;
  final double amount;
  final double roundoffAmount;
  final double roundedAmount;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.transactionDate,
    required this.description,
    required this.amount,
    required this.roundoffAmount,
    required this.roundedAmount,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      transactionDate: DateTime.parse(json['transaction_date']),
      description: json['description'] ?? '',
      amount: double.parse(json['amount'].toString()),
      roundoffAmount: double.parse(json['roundoff_amount']?.toString() ?? '0'),
      roundedAmount: double.parse(
          json['rounded_amount']?.toString() ?? json['amount'].toString()),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Transactions Response Model
class TransactionsResponse {
  final List<Transaction> transactions;
  final int total;
  final int limit;
  final int offset;

  TransactionsResponse({
    required this.transactions,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    return TransactionsResponse(
      transactions: (json['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList(),
      total: json['total'],
      limit: json['limit'],
      offset: json['offset'],
    );
  }
}

// Projections Model
class Projections {
  final DailyProjection daily;
  final MonthlyProjection monthly;
  final YearlyProjection yearly;
  final PeriodProjection period;

  Projections({
    required this.daily,
    required this.monthly,
    required this.yearly,
    required this.period,
  });

  factory Projections.fromJson(Map<String, dynamic> json) {
    return Projections(
      daily: DailyProjection.fromJson(json['daily']),
      monthly: MonthlyProjection.fromJson(json['monthly']),
      yearly: YearlyProjection.fromJson(json['yearly']),
      period: PeriodProjection.fromJson(json['period']),
    );
  }
}

class DailyProjection {
  final double transactions;
  final double savings;

  DailyProjection({required this.transactions, required this.savings});

  factory DailyProjection.fromJson(Map<String, dynamic> json) {
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

    return DailyProjection(
      transactions: _toDouble(json['transactions']),
      savings: _toDouble(json['savings']),
    );
  }
}

class MonthlyProjection {
  final double transactions;
  final double savings;

  MonthlyProjection({required this.transactions, required this.savings});

  factory MonthlyProjection.fromJson(Map<String, dynamic> json) {
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

    return MonthlyProjection(
      transactions: _toDouble(json['transactions']),
      savings: _toDouble(json['savings']),
    );
  }
}

class YearlyProjection {
  final double transactions;
  final double savings;

  YearlyProjection({required this.transactions, required this.savings});

  factory YearlyProjection.fromJson(Map<String, dynamic> json) {
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

    return YearlyProjection(
      transactions: _toDouble(json['transactions']),
      savings: _toDouble(json['savings']),
    );
  }
}

class PeriodProjection {
  final int days;
  final int transactions;
  final double savings;

  PeriodProjection({
    required this.days,
    required this.transactions,
    required this.savings,
  });

  factory PeriodProjection.fromJson(Map<String, dynamic> json) {
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

    return PeriodProjection(
      days: json['days'] ?? 0,
      transactions: json['transactions'] ?? 0,
      savings: _toDouble(json['savings']),
    );
  }
}

// Savings Summary Model
class SavingsSummary {
  final double totalSavings;
  final int transactionCount;
  final double totalWithdrawn;
  final double totalRounded;
  final double averageRoundoff;
  final int roundoffAmount;
  final DateRange? dateRange;
  final Projections? projections;
  final String? insights;
  final String? message;

  SavingsSummary({
    required this.totalSavings,
    required this.transactionCount,
    required this.totalWithdrawn,
    required this.totalRounded,
    required this.averageRoundoff,
    required this.roundoffAmount,
    this.dateRange,
    this.projections,
    this.insights,
    this.message,
  });

  factory SavingsSummary.fromJson(Map<String, dynamic> json) {
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

    return SavingsSummary(
      totalSavings: _toDouble(json['total_savings']),
      transactionCount: json['transaction_count'] ?? 0,
      totalWithdrawn: _toDouble(json['total_withdrawn']),
      totalRounded: _toDouble(json['total_rounded']),
      averageRoundoff: _toDouble(json['average_roundoff']),
      roundoffAmount: json['roundoff_amount'] ?? 10,
      dateRange: json['date_range'] != null
          ? DateRange.fromJson(json['date_range'])
          : null,
      projections: json['projections'] != null
          ? Projections.fromJson(json['projections'])
          : null,
      insights: json['insights'],
      message: json['message'],
    );
  }
}

class DateRange {
  final String start;
  final String end;
  final int days;

  DateRange({
    required this.start,
    required this.end,
    required this.days,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      start: json['start'],
      end: json['end'],
      days: json['days'],
    );
  }
}

// Savings Upload Response Model
class SavingsUploadResponse {
  final String message;
  final int statementId;
  final int transactionsProcessed;
  final SavingsSummary summary;
  final Projections projections;
  final String insights;

  SavingsUploadResponse({
    required this.message,
    required this.statementId,
    required this.transactionsProcessed,
    required this.summary,
    required this.projections,
    required this.insights,
  });

  factory SavingsUploadResponse.fromJson(Map<String, dynamic> json) {
    return SavingsUploadResponse(
      message: json['message'],
      statementId: json['statement_id'],
      transactionsProcessed: json['transactions_processed'],
      summary: SavingsSummary.fromJson(json['summary']),
      projections: Projections.fromJson(json['projections']),
      insights: json['insights'],
    );
  }
}

// Savings Insights Model
class SavingsInsights {
  final SavingsSummary summary;
  final Projections projections;
  final List<String> insights;
  final DateRange dateRange;

  SavingsInsights({
    required this.summary,
    required this.projections,
    required this.insights,
    required this.dateRange,
  });

  factory SavingsInsights.fromJson(Map<String, dynamic> json) {
    return SavingsInsights(
      summary: SavingsSummary.fromJson(json['summary']),
      projections: Projections.fromJson(json['projections']),
      insights: List<String>.from(json['insights']),
      dateRange: DateRange.fromJson(json['date_range']),
    );
  }
}

