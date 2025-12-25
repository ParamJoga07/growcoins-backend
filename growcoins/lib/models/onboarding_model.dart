class OnboardingData {
  // Personal Details
  String? fullName;
  String? email;
  DateTime? dateOfBirth;
  
  // KYC Details
  String? panNumber;
  String? aadharNumber;
  
  // Financial Information
  String? monthlyIncomeRange;
  String? savingsManagement;
  String? monthlySavingsPercentage;
  String? spendingCategory;
  
  // Bank Statement
  String? bankStatementPath; // File path if uploaded
  
  OnboardingData();

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'panNumber': panNumber,
      'aadharNumber': aadharNumber,
      'monthlyIncomeRange': monthlyIncomeRange,
      'savingsManagement': savingsManagement,
      'monthlySavingsPercentage': monthlySavingsPercentage,
      'spendingCategory': spendingCategory,
      'bankStatementPath': bankStatementPath,
      'completedAt': DateTime.now().toIso8601String(),
    };
  }

  bool isComplete() {
    return fullName != null &&
        email != null &&
        dateOfBirth != null &&
        panNumber != null &&
        aadharNumber != null &&
        monthlyIncomeRange != null &&
        savingsManagement != null &&
        monthlySavingsPercentage != null &&
        spendingCategory != null;
  }
}

// Income range options
class IncomeRange {
  static const String below25k = 'Below ₹25,000';
  static const String range25to50k = '₹25,001 - ₹50,000';
  static const String range50to75k = '₹50,001 - ₹75,000';
  static const String above75k = 'Above ₹75,001';
  
  static List<String> get all => [
    below25k,
    range25to50k,
    range50to75k,
    above75k,
  ];
}

// Savings management options
class SavingsManagement {
  static const String regularSavings = 'Regular Savings Account';
  static const String fixedDeposit = 'Fixed Deposit';
  static const String mutualFunds = 'Investment In Mutual Funds';
  static const String notSaving = 'Not Actively Saving';
  
  static List<String> get all => [
    regularSavings,
    fixedDeposit,
    mutualFunds,
    notSaving,
  ];
}

// Monthly savings percentage
class SavingsPercentage {
  static const String lessThan10 = 'Less than 10%';
  static const String range10to20 = '10% - 20%';
  static const String range21to30 = '21% - 30%';
  static const String moreThan30 = 'More than 30%';
  
  static List<String> get all => [
    lessThan10,
    range10to20,
    range21to30,
    moreThan30,
  ];
}

// Spending categories
class SpendingCategory {
  static const String essentialsOnly = 'Essential Expenses Only';
  static const String essentialsAndSome = 'Essential Expenses & Some Discretionary Spending';
  static const String balanced = 'Balanced Spending Of Essentials & Discretionary Items';
  static const String heavyDiscretionary = 'Heavy Discretionary Spending With Minimal Savings';
  
  static List<String> get all => [
    essentialsOnly,
    essentialsAndSome,
    balanced,
    heavyDiscretionary,
  ];
}

