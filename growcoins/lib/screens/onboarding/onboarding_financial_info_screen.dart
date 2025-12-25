import 'package:flutter/material.dart';
import '../../models/onboarding_model.dart';
import 'onboarding_setup_profile_screen.dart';

class OnboardingFinancialInfoScreen extends StatefulWidget {
  final int questionSet; // 1 or 2
  final OnboardingData? existingData;

  const OnboardingFinancialInfoScreen({
    super.key,
    required this.questionSet,
    this.existingData,
  });

  @override
  State<OnboardingFinancialInfoScreen> createState() =>
      _OnboardingFinancialInfoScreenState();
}

class _OnboardingFinancialInfoScreenState
    extends State<OnboardingFinancialInfoScreen> {
  String? _selectedIncomeRange;
  String? _selectedSavingsManagement;
  String? _selectedSavingsPercentage;
  String? _selectedSpendingCategory;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _selectedIncomeRange = widget.existingData!.monthlyIncomeRange;
      _selectedSavingsManagement = widget.existingData!.savingsManagement;
      _selectedSavingsPercentage =
          widget.existingData!.monthlySavingsPercentage;
      _selectedSpendingCategory = widget.existingData!.spendingCategory;
    }
  }

  void _selectOption(String? value, String type) {
    setState(() {
      if (type == 'income') {
        _selectedIncomeRange = value;
      } else if (type == 'savings') {
        _selectedSavingsManagement = value;
      } else if (type == 'percentage') {
        _selectedSavingsPercentage = value;
      } else if (type == 'spending') {
        _selectedSpendingCategory = value;
      }
    });
  }

  void _next() {
    final data = widget.existingData ?? OnboardingData();

    if (widget.questionSet == 1) {
      if (_selectedIncomeRange == null || _selectedSavingsManagement == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer both questions'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      data.monthlyIncomeRange = _selectedIncomeRange;
      data.savingsManagement = _selectedSavingsManagement;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OnboardingFinancialInfoScreen(questionSet: 2, existingData: data),
        ),
      );
    } else {
      if (_selectedSavingsPercentage == null ||
          _selectedSpendingCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer both questions'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      data.monthlySavingsPercentage = _selectedSavingsPercentage;
      data.spendingCategory = _selectedSpendingCategory;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingSetupProfileScreen(),
        ),
      );
    }
  }

  Widget _buildRadioOption(String value, String type, String label) {
    bool isSelected;
    if (type == 'income') {
      isSelected = _selectedIncomeRange == value;
    } else if (type == 'savings') {
      isSelected = _selectedSavingsManagement == value;
    } else if (type == 'percentage') {
      isSelected = _selectedSavingsPercentage == value;
    } else {
      isSelected = _selectedSpendingCategory == value;
    }

    return InkWell(
      onTap: () => _selectOption(value, type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey[100],
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue[900] : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Illustration placeholder
                    Container(
                      height: 150,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.questionSet == 1
                            ? Icons.account_balance_wallet
                            : Icons.savings,
                        size: 80,
                        color: Colors.blue,
                      ),
                    ),

                    // Question 1
                    if (widget.questionSet == 1) ...[
                      const Text(
                        'What is your current monthly income range?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...IncomeRange.all.map(
                        (option) => _buildRadioOption(option, 'income', option),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'How do you manage your savings currently?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...SavingsManagement.all.map(
                        (option) =>
                            _buildRadioOption(option, 'savings', option),
                      ),
                    ] else ...[
                      const Text(
                        'How much of your monthly income do you save?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...SavingsPercentage.all.map(
                        (option) =>
                            _buildRadioOption(option, 'percentage', option),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Which categories do you spend the most on each month?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...SpendingCategory.all.map(
                        (option) =>
                            _buildRadioOption(option, 'spending', option),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Progress indicator and Next button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.questionSet == 1
                              ? Colors.blue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.questionSet == 2
                              ? Colors.blue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
