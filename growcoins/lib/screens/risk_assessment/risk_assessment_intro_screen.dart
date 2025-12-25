import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/risk_assessment_service.dart';
import 'risk_assessment_question_screen.dart';
import 'risk_assessment_history_screen.dart';

class RiskAssessmentIntroScreen extends StatefulWidget {
  const RiskAssessmentIntroScreen({super.key});

  @override
  State<RiskAssessmentIntroScreen> createState() =>
      _RiskAssessmentIntroScreenState();
}

class _RiskAssessmentIntroScreenState extends State<RiskAssessmentIntroScreen> {
  bool _isChecking = true;
  bool _hasPreviousAssessment = false;

  @override
  void initState() {
    super.initState();
    _checkPreviousAssessment();
  }

  Future<void> _checkPreviousAssessment() async {
    try {
      final hasPrevious = await RiskAssessmentService.hasAssessments();
      setState(() {
        _hasPreviousAssessment = hasPrevious;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _showPreviousAssessmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Previous Assessment Found',
          style: AppTheme.headingSmall,
        ),
        content: Text(
          'You have completed a risk assessment before. Would you like to start a new one or view your previous results?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiskAssessmentHistoryScreen(),
                ),
              );
            },
            child: Text(
              'View Previous',
              style: AppTheme.labelLarge.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiskAssessmentQuestionScreen(
                    questionIndex: 0,
                  ),
                ),
              );
            },
            child: const Text('Start New'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Risk Assessment', style: AppTheme.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: _hasPreviousAssessment
            ? [
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RiskAssessmentHistoryScreen(),
                      ),
                    );
                  },
                  tooltip: 'View History',
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: _isChecking
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Illustration with gradient
                            Container(
                              height: 220,
                              width: 220,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.assessment_rounded,
                                size: 120,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              'We will help you analyze your risk tolerance and suggest an investment plan accordingly',
                              style: AppTheme.headingSmall.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom section with gradient
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Complete this short survey for the best investment plans',
                            style: AppTheme.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_hasPreviousAssessment) {
                                  _showPreviousAssessmentDialog();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RiskAssessmentQuestionScreen(
                                        questionIndex: 0,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _hasPreviousAssessment
                                    ? 'Start New Assessment'
                                    : 'Continue',
                              ),
                            ),
                          ),
                          if (_hasPreviousAssessment) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RiskAssessmentHistoryScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'View Previous Assessments',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

