import 'package:flutter/material.dart';
import '../../models/risk_assessment_model.dart';
import '../../theme/app_theme.dart';
import 'risk_assessment_result_screen.dart';

class RiskAssessmentQuestionScreen extends StatefulWidget {
  final int questionIndex;
  final Map<int, RiskAssessmentAnswer>? previousAnswers;

  const RiskAssessmentQuestionScreen({
    super.key,
    required this.questionIndex,
    this.previousAnswers,
  });

  @override
  State<RiskAssessmentQuestionScreen> createState() =>
      _RiskAssessmentQuestionScreenState();
}

class _RiskAssessmentQuestionScreenState
    extends State<RiskAssessmentQuestionScreen> {
  final List<RiskAssessmentQuestion> _questions =
      RiskAssessmentData.getQuestions();
  Map<int, RiskAssessmentAnswer> _answers = {};
  String? _selectedOptionId;

  @override
  void initState() {
    super.initState();
    _answers = Map<int, RiskAssessmentAnswer>.from(
        widget.previousAnswers ?? {});
    
    // Pre-select if already answered
    final currentQuestion = _questions[widget.questionIndex];
    final existingAnswer = _answers[currentQuestion.id];
    if (existingAnswer != null) {
      _selectedOptionId = existingAnswer.optionId;
    }
  }

  void _selectOption(RiskAssessmentOption option) {
    setState(() {
      _selectedOptionId = option.id;
    });
  }

  void _nextQuestion() {
    if (_selectedOptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an option to continue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentQuestion = _questions[widget.questionIndex];
    final selectedOption = currentQuestion.options
        .firstWhere((opt) => opt.id == _selectedOptionId);

    // Save answer
    _answers[currentQuestion.id] = RiskAssessmentAnswer(
      questionId: currentQuestion.id,
      optionId: selectedOption.id,
      answerText: selectedOption.text,
      score: selectedOption.score,
    );

    // Navigate to next question or result
    if (widget.questionIndex < _questions.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RiskAssessmentQuestionScreen(
            questionIndex: widget.questionIndex + 1,
            previousAnswers: _answers,
          ),
        ),
      );
    } else {
      // Calculate result and navigate to result screen
      _navigateToResult();
    }
  }

  void _previousQuestion() {
    if (widget.questionIndex > 0) {
      Navigator.pop(context);
    }
  }

  void _navigateToResult() {
    // Calculate total score
    int totalScore = _answers.values.fold(0, (sum, answer) => sum + answer.score);
    
    // Determine risk profile
    String riskProfile = RiskAssessmentData.calculateRiskProfile(totalScore);
    String recommendation = RiskAssessmentData.getRecommendation(riskProfile);

    final result = RiskAssessmentResult(
      answers: _answers.values.toList(),
      totalScore: totalScore,
      riskProfile: riskProfile,
      recommendation: recommendation,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RiskAssessmentResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[widget.questionIndex];
    final questionNumber = widget.questionIndex + 1;
    final totalQuestions = _questions.length;
    final progress = questionNumber / totalQuestions;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Risk Assessment', style: AppTheme.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '$questionNumber of $totalQuestions',
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Illustration with gradient
                    Container(
                      height: 160,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),

                    // Question text
                    Text(
                      currentQuestion.question,
                      style: AppTheme.headingSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Options
                    ...currentQuestion.options.map((option) {
                      final isSelected = _selectedOptionId == option.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _selectOption(option),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryLight.withOpacity(0.1)
                                  : AppTheme.surfaceColor,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.text,
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.primaryColor,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.questionIndex > 0
                          ? _previousQuestion
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_back_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('Previous', style: AppTheme.buttonText.copyWith(color: AppTheme.primaryColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedOptionId != null ? _nextQuestion : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.questionIndex < _questions.length - 1
                                ? 'Next'
                                : 'Submit',
                            style: AppTheme.buttonText,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
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

