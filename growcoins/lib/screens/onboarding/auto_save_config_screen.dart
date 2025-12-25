import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/goal_models.dart';
import '../../models/investment_plan_model.dart';
import '../../services/investment_plan_service.dart';
import '../../services/api_service.dart' show ApiException;

class AutoSaveConfigScreen extends StatefulWidget {
  final Goal goal;
  final InvestmentPlan? existingPlan;

  const AutoSaveConfigScreen({
    super.key,
    required this.goal,
    this.existingPlan,
  });

  @override
  State<AutoSaveConfigScreen> createState() => _AutoSaveConfigScreenState();
}

class _AutoSaveConfigScreenState extends State<AutoSaveConfigScreen>
    with SingleTickerProviderStateMixin {
  double _amount = 3000.0;
  String _frequency = 'daily'; // 'daily', 'weekly', 'monthly'
  bool _isLoading = false;
  late TextEditingController _amountController;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Load existing configuration if available
    if (widget.existingPlan != null) {
      _amount = widget.existingPlan!.autoSave.monthlyAmount;
      _frequency = widget.existingPlan!.autoSave.frequency;
    }

    // Initialize amount controller with current amount
    _amountController = TextEditingController(text: _amount.toStringAsFixed(0));

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
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Color _getCategoryColor() {
    // Use primary color as default, can be enhanced to fetch from category
    return AppTheme.primaryColor;
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update or create investment plan with auto-save config
      await InvestmentPlanService.updateAutoSave(
        frequency: _frequency,
        monthlyAmount: _amount,
        goalId: widget.goal.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Auto Save configured successfully!',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    final categoryGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [categoryColor.withOpacity(0.8), categoryColor.withOpacity(0.6)],
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: categoryColor.withOpacity(0.7),
          ),
          onPressed: () => Navigator.pop(context),
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
                // Title
                Text(
                  'Configure Auto Save',
                  style: AppTheme.headingLarge.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Configuration Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: categoryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Section
                      Text(
                        'Amount',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme:
                                    const TextSelectionThemeData(
                                      cursorColor: Colors.white,
                                      selectionColor: Colors.white38,
                                      selectionHandleColor: Colors.white,
                                    ),
                                inputDecorationTheme: InputDecorationTheme(
                                  fillColor: Colors.transparent,
                                ),
                              ),
                              child: TextField(
                                controller: _amountController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: false,
                                    ),
                                cursorColor: Colors.white,
                                cursorWidth: 3,
                                decoration: InputDecoration(
                                  hintText: '3000',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.only(
                                    bottom: 2,
                                  ),
                                  filled: false,
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    final amount = double.tryParse(value);
                                    if (amount != null && amount > 0) {
                                      setState(() {
                                        _amount = amount;
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      _amount = 0.0;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(
                        color: Colors.white.withOpacity(0.3),
                        thickness: 1,
                      ),
                      const SizedBox(height: 24),

                      // Recurrence Section
                      Text(
                        'Set Recurrence',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFrequencyOption(
                              'daily',
                              'Daily',
                              categoryColor,
                              categoryGradient,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFrequencyOption(
                              'weekly',
                              'Weekly',
                              categoryColor,
                              categoryGradient,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFrequencyOption(
                              'monthly',
                              'Monthly',
                              categoryColor,
                              categoryGradient,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Changes Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: AppTheme.buttonText.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // Information Section
                Text(
                  'Introducing Auto Save:',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Boost your goals faster! Configure recurring payments linked to your targets. Select daily, weekly, or monthly contributions to accelerate your financial aspirations. Auto Save helps you stay on track and achieve your goals more efficiently. Start automating your savings today!',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(
    String value,
    String label,
    Color categoryColor,
    LinearGradient categoryGradient,
  ) {
    final isSelected = _frequency == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _frequency = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: isSelected ? categoryColor : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
