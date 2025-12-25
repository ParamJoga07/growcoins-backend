import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/risk_assessment_service.dart';
import '../../theme/app_theme.dart';
import '../../models/risk_assessment_model.dart';

class RiskAssessmentDetailScreen extends StatefulWidget {
  final int assessmentId;

  const RiskAssessmentDetailScreen({
    super.key,
    required this.assessmentId,
  });

  @override
  State<RiskAssessmentDetailScreen> createState() =>
      _RiskAssessmentDetailScreenState();
}

class _RiskAssessmentDetailScreenState
    extends State<RiskAssessmentDetailScreen> {
  Map<String, dynamic>? _assessment;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<RiskAssessmentQuestion>? _questions;

  @override
  void initState() {
    super.initState();
    _loadAssessment();
    _questions = RiskAssessmentData.getQuestions();
  }

  Future<void> _loadAssessment() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final assessment =
          await RiskAssessmentService.getAssessmentById(widget.assessmentId);
      setState(() {
        _assessment = assessment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
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

  Map<String, dynamic>? _getAnswerForQuestion(int questionId) {
    if (_assessment == null || _questions == null) return null;

    final answers = _assessment!['answers'] as List<dynamic>?;
    if (answers == null) return null;

    for (var answer in answers) {
      if (answer['question_id'] == questionId) {
        return answer as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Assessment Details', style: AppTheme.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _hasError
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
                          'Error loading assessment',
                          style: AppTheme.headingSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Unknown error',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadAssessment,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _assessment == null
                    ? Center(
                        child: Text(
                          'Assessment not found',
                          style: AppTheme.headingSmall,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Risk Profile Header
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _getRiskProfileColor(
                                        _assessment!['risk_profile'] ?? ''),
                                    _getRiskProfileColor(
                                            _assessment!['risk_profile'] ?? '')
                                        .withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getRiskProfileColor(
                                            _assessment!['risk_profile'] ?? '')
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _assessment!['risk_profile'] ?? 'Unknown',
                                    style: AppTheme.headingLarge.copyWith(
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Score: ${_assessment!['total_score'] ?? 0} / 20',
                                    style: AppTheme.bodyLarge.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Date
                            if (_assessment!['completed_at'] != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: AppTheme.cardDecoration,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Completed on',
                                            style: AppTheme.labelMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMMM dd, yyyy • hh:mm a')
                                                .format(DateTime.parse(
                                                    _assessment!['completed_at'])),
                                            style: AppTheme.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Recommendation
                            if (_assessment!['recommendation'] != null) ...[
                              Text(
                                'Recommendation',
                                style: AppTheme.headingSmall,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: AppTheme.cardDecoration,
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  _assessment!['recommendation'],
                                  style: AppTheme.bodyLarge.copyWith(
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Answers Section
                            Text(
                              'Your Answers',
                              style: AppTheme.headingSmall,
                            ),
                            const SizedBox(height: 16),

                            // Questions and Answers
                            if (_questions != null)
                              ..._questions!.asMap().entries.map((entry) {
                                final question = entry.value;
                                final questionNumber = entry.key + 1;
                                final answer = _getAnswerForQuestion(question.id);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Container(
                                    decoration: AppTheme.cardDecoration,
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Question
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Q$questionNumber',
                                                style: AppTheme.labelMedium
                                                    .copyWith(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          question.question,
                                          style: AppTheme.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Answer
                                        if (answer != null)
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.05),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    answer['answer_text'] ?? '',
                                                    style: AppTheme.bodyMedium,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'Score: ${answer['score'] ?? 0}',
                                                    style: AppTheme.bodySmall
                                                        .copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Text(
                                            'Answer not found',
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: AppTheme.textSecondary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
      ),
    );
  }
}

