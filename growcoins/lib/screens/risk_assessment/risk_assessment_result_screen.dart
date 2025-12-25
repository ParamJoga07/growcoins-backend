import 'package:flutter/material.dart';
import '../../models/risk_assessment_model.dart';
import '../../services/risk_assessment_service.dart';
import '../../services/api_service.dart' show ApiException;
import '../../theme/app_theme.dart';
import '../investment/investment_plan_intro_screen.dart';

class RiskAssessmentResultScreen extends StatefulWidget {
  final RiskAssessmentResult result;

  const RiskAssessmentResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<RiskAssessmentResultScreen> createState() =>
      _RiskAssessmentResultScreenState();
}

class _RiskAssessmentResultScreenState
    extends State<RiskAssessmentResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _saveAssessment();
  }

  Future<void> _saveAssessment() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Convert RiskAssessmentResult to the format expected by the API
      final answers = widget.result.answers.map((a) => a.toJson()).toList();

      await RiskAssessmentService.saveRiskAssessment(
        answers: answers,
        totalScore: widget.result.totalScore,
        riskProfile: widget.result.riskProfile,
        recommendation: widget.result.recommendation,
      );

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Assessment saved successfully!',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        String errorMsg = e.message;
        if (e.errors != null && e.errors!.isNotEmpty) {
          errorMsg = e.errors!.first['msg'] ?? e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save: ${e.toString()}',
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
    }
  }

  Color _getRiskProfileColor(String profile) {
    switch (profile) {
      case 'Conservative':
        return AppTheme.successColor;
      case 'Moderate':
        return AppTheme.primaryColor;
      case 'Moderately Aggressive':
        return AppTheme.warningColor;
      case 'Aggressive':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Risk Assessment Result', style: AppTheme.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isSaving
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    const SizedBox(height: 24),
                    Text(
                      'Saving your results...',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success icon with gradient background
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getRiskProfileColor(widget.result.riskProfile),
                            _getRiskProfileColor(widget.result.riskProfile)
                                .withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _getRiskProfileColor(widget.result.riskProfile)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Risk Profile
                    Text(
                      'Your Risk Profile',
                      style: AppTheme.headingMedium.copyWith(
                        color: _getRiskProfileColor(widget.result.riskProfile),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _getRiskProfileColor(widget.result.riskProfile)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getRiskProfileColor(widget.result.riskProfile),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        widget.result.riskProfile,
                        style: AppTheme.headingLarge.copyWith(
                          color: _getRiskProfileColor(widget.result.riskProfile),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Total Score Card
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Score:',
                            style: AppTheme.labelLarge,
                          ),
                          Text(
                            '${widget.result.totalScore} / 20',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recommendation
                    if (widget.result.recommendation != null) ...[
                      Text(
                        'Recommendation',
                        style: AppTheme.headingSmall,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: AppTheme.cardDecoration,
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          widget.result.recommendation!,
                          style: AppTheme.bodyLarge.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Save status
                    if (_isSaved)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.successColor,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Results saved successfully',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text('Done'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvestmentPlanIntroScreen(
                                    riskProfile: widget.result.riskProfile,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text('View Investment Plan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

