class RiskAssessmentQuestion {
  final int id;
  final String question;
  final List<RiskAssessmentOption> options;

  RiskAssessmentQuestion({
    required this.id,
    required this.question,
    required this.options,
  });
}

class RiskAssessmentOption {
  final String id;
  final String text;
  final int score; // Risk score for this option

  RiskAssessmentOption({
    required this.id,
    required this.text,
    required this.score,
  });
}

class RiskAssessmentAnswer {
  final int questionId;
  final String optionId;
  final String answerText;
  final int score;

  RiskAssessmentAnswer({
    required this.questionId,
    required this.optionId,
    required this.answerText,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'optionId': optionId,
      'answerText': answerText,
      'score': score,
    };
  }
}

class RiskAssessmentResult {
  final List<RiskAssessmentAnswer> answers;
  final int totalScore;
  final String riskProfile; // Conservative, Moderate, Aggressive, etc.
  final String? recommendation;

  RiskAssessmentResult({
    required this.answers,
    required this.totalScore,
    required this.riskProfile,
    this.recommendation,
  });

  Map<String, dynamic> toJson() {
    return {
      'answers': answers.map((a) => a.toJson()).toList(),
      'totalScore': totalScore,
      'riskProfile': riskProfile,
      'recommendation': recommendation,
    };
  }
}

// Predefined questions for the risk assessment
class RiskAssessmentData {
  static List<RiskAssessmentQuestion> getQuestions() {
    return [
      RiskAssessmentQuestion(
        id: 1,
        question: 'What is your primary investment objective?',
        options: [
          RiskAssessmentOption(
            id: 'q1_opt1',
            text: 'Avoid major fluctuation in the value of my investments',
            score: 1,
          ),
          RiskAssessmentOption(
            id: 'q1_opt2',
            text: 'Maintain the capital of my investments with regular income.',
            score: 2,
          ),
          RiskAssessmentOption(
            id: 'q1_opt3',
            text: 'Maintain regular income with some exposure to capital growth.',
            score: 3,
          ),
          RiskAssessmentOption(
            id: 'q1_opt4',
            text: 'Maximize the growth of my investments.',
            score: 4,
          ),
        ],
      ),
      RiskAssessmentQuestion(
        id: 2,
        question: 'If you were to invest in high-return but high-risk assets, how would you feel?',
        options: [
          RiskAssessmentOption(
            id: 'q2_opt1',
            text: 'Worried, and fearful of possible loss',
            score: 1,
          ),
          RiskAssessmentOption(
            id: 'q2_opt2',
            text: 'Uneasy, but could come to terms with it',
            score: 2,
          ),
          RiskAssessmentOption(
            id: 'q2_opt3',
            text: 'Aware of possible loss, can accept certain degree of fluctuation',
            score: 3,
          ),
          RiskAssessmentOption(
            id: 'q2_opt4',
            text: 'Unconcerned of high-risk loss, and looking forward to higher returns',
            score: 4,
          ),
        ],
      ),
      RiskAssessmentQuestion(
        id: 3,
        question: 'What is your investment time horizon?',
        options: [
          RiskAssessmentOption(
            id: 'q3_opt1',
            text: 'Short-term: Less than 3 years.',
            score: 1,
          ),
          RiskAssessmentOption(
            id: 'q3_opt2',
            text: 'Medium-term: 3-5 years.',
            score: 2,
          ),
          RiskAssessmentOption(
            id: 'q3_opt3',
            text: 'Long-term: 5-10 years.',
            score: 3,
          ),
          RiskAssessmentOption(
            id: 'q3_opt4',
            text: 'Very long-term: More than 10 years.',
            score: 4,
          ),
        ],
      ),
      RiskAssessmentQuestion(
        id: 4,
        question: 'What is your willingness to risk shorter-term losses for the prospect of higher longer-term returns?',
        options: [
          RiskAssessmentOption(
            id: 'q4_opt1',
            text: 'Low.',
            score: 1,
          ),
          RiskAssessmentOption(
            id: 'q4_opt2',
            text: 'Not sure.',
            score: 2,
          ),
          RiskAssessmentOption(
            id: 'q4_opt3',
            text: 'Moderate.',
            score: 3,
          ),
          RiskAssessmentOption(
            id: 'q4_opt4',
            text: 'High.',
            score: 4,
          ),
        ],
      ),
      RiskAssessmentQuestion(
        id: 5,
        question: 'How would you emotionally react if your investment portfolio experienced a significant decline in value?',
        options: [
          RiskAssessmentOption(
            id: 'q5_opt1',
            text: 'Panic: I would feel extremely anxious and consider selling.',
            score: 1,
          ),
          RiskAssessmentOption(
            id: 'q5_opt2',
            text: 'Concerned: I would be worried but wait for a recovery.',
            score: 2,
          ),
          RiskAssessmentOption(
            id: 'q5_opt3',
            text: 'Calm: I would review my strategy and stay the course.',
            score: 3,
          ),
          RiskAssessmentOption(
            id: 'q5_opt4',
            text: 'Opportunistic: I would see it as a buying opportunity.',
            score: 4,
          ),
        ],
      ),
    ];
  }

  static String calculateRiskProfile(int totalScore) {
    if (totalScore <= 8) {
      return 'Conservative';
    } else if (totalScore <= 12) {
      return 'Moderate';
    } else if (totalScore <= 16) {
      return 'Moderately Aggressive';
    } else {
      return 'Aggressive';
    }
  }

  static String getRecommendation(String riskProfile) {
    switch (riskProfile) {
      case 'Conservative':
        return 'Focus on low-risk investments like bonds, fixed deposits, and blue-chip stocks.';
      case 'Moderate':
        return 'Balance between stocks and bonds. Consider diversified mutual funds.';
      case 'Moderately Aggressive':
        return 'Focus on growth stocks and equity mutual funds with some bond allocation.';
      case 'Aggressive':
        return 'Focus on high-growth stocks, sector funds, and emerging markets.';
      default:
        return 'Consult with a financial advisor for personalized recommendations.';
    }
  }
}

