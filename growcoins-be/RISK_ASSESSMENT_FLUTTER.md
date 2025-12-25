# Risk Assessment - Flutter Integration Guide

## 📋 Overview

Complete guide for integrating the Risk Assessment API into your Flutter app.

---

## 🔧 Step 1: Create Risk Assessment Service

Create `lib/services/risk_assessment_service.dart`:

```dart
import 'api_service.dart';
import 'auth_service.dart';
import 'api_service.dart' show ApiException;

class RiskAssessmentService {
  // Save Risk Assessment
  static Future<Map<String, dynamic>> saveRiskAssessment({
    required List<Map<String, dynamic>> answers,
    required int totalScore,
    required String riskProfile,
    String? recommendation,
  }) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in. Please login first.');
      }

      // Prepare answers in the correct format
      final formattedAnswers = answers.map((answer) => {
        'questionId': answer['questionId'],
        'optionId': answer['optionId'],
        'answerText': answer['answerText'],
        'score': answer['score'],
      }).toList();

      final response = await ApiService.post(
        '/api/risk-assessment',
        {
          'user_id': userId,
          'answers': formattedAnswers,
          'total_score': totalScore,
          'risk_profile': riskProfile,
          'recommendation': recommendation,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );

      return response['assessment'];
    } on ApiException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('Failed to save risk assessment: ${e.toString()}');
    }
  }

  // Get Assessment History
  static Future<List<Map<String, dynamic>>> getAssessmentHistory({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        return [];
      }

      final response = await ApiService.get(
        '/api/risk-assessment/$userId?limit=$limit&offset=$offset',
      );

      return List<Map<String, dynamic>>.from(response['assessments'] ?? []);
    } catch (e) {
      print('Error fetching assessment history: $e');
      return [];
    }
  }

  // Get Latest Assessment
  static Future<Map<String, dynamic>?> getLatestAssessment() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        return null;
      }

      final response = await ApiService.get(
        '/api/risk-assessment/$userId/latest',
      );

      return response['assessment'];
    } catch (e) {
      print('Error fetching latest assessment: $e');
      return null;
    }
  }

  // Get Specific Assessment by ID
  static Future<Map<String, dynamic>?> getAssessmentById(int assessmentId) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        return null;
      }

      final response = await ApiService.get(
        '/api/risk-assessment/$userId/$assessmentId',
      );

      return response['assessment'];
    } catch (e) {
      print('Error fetching assessment: $e');
      return null;
    }
  }

  // Check if user has any assessments
  static Future<bool> hasAssessments() async {
    final latest = await getLatestAssessment();
    return latest != null;
  }
}
```

---

## 📱 Step 2: Usage in Your Risk Assessment Screen

### Save Assessment After Completion

```dart
import 'package:flutter/material.dart';
import '../services/risk_assessment_service.dart';
import '../services/api_service.dart' show ApiException;

class RiskAssessmentResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> answers;
  final int totalScore;
  final String riskProfile;
  final String recommendation;

  const RiskAssessmentResultScreen({
    required this.answers,
    required this.totalScore,
    required this.riskProfile,
    required this.recommendation,
  });

  @override
  _RiskAssessmentResultScreenState createState() => _RiskAssessmentResultScreenState();
}

class _RiskAssessmentResultScreenState extends State<RiskAssessmentResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  Future<void> _saveAssessment() async {
    setState(() => _isSaving = true);

    try {
      await RiskAssessmentService.saveRiskAssessment(
        answers: widget.answers,
        totalScore: widget.totalScore,
        riskProfile: widget.riskProfile,
        recommendation: widget.recommendation,
      );

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assessment saved successfully!'),
            backgroundColor: Colors.green,
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
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Risk Assessment Result')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display results
            Text(
              'Your Risk Profile: ${widget.riskProfile}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Total Score: ${widget.totalScore}'),
            SizedBox(height: 20),
            Text('Recommendation: ${widget.recommendation}'),
            SizedBox(height: 40),

            // Save button
            ElevatedButton(
              onPressed: _isSaved || _isSaving ? null : _saveAssessment,
              child: _isSaving
                  ? CircularProgressIndicator()
                  : Text(_isSaved ? 'Saved ✓' : 'Save Assessment'),
            ),

            SizedBox(height: 20),

            // Done button
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📜 Step 3: View Assessment History

### Create History Screen

```dart
import 'package:flutter/material.dart';
import '../services/risk_assessment_service.dart';

class RiskAssessmentHistoryScreen extends StatefulWidget {
  @override
  _RiskAssessmentHistoryScreenState createState() => _RiskAssessmentHistoryScreenState();
}

class _RiskAssessmentHistoryScreenState extends State<RiskAssessmentHistoryScreen> {
  List<Map<String, dynamic>> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final assessments = await RiskAssessmentService.getAssessmentHistory();
      setState(() {
        _assessments = assessments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assessment History')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _assessments.isEmpty
              ? Center(child: Text('No assessments found'))
              : ListView.builder(
                  itemCount: _assessments.length,
                  itemBuilder: (context, index) {
                    final assessment = _assessments[index];
                    final date = DateTime.parse(assessment['completed_at']);

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Risk Profile: ${assessment['risk_profile']}'),
                        subtitle: Text(
                          'Score: ${assessment['total_score']} | ${date.toString().split(' ')[0]}',
                        ),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to detail view
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssessmentDetailScreen(
                                assessment: assessment,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
```

---

## 🔍 Step 4: Check for Previous Assessment

### Before Starting New Assessment

```dart
Future<void> _checkPreviousAssessment() async {
  final hasPrevious = await RiskAssessmentService.hasAssessments();

  if (hasPrevious) {
    // Show dialog: "You have a previous assessment. Start new or view previous?"
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Previous Assessment Found'),
        content: Text('You have completed a risk assessment before. Would you like to start a new one or view your previous results?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/assessment-history');
            },
            child: Text('View Previous'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/risk-assessment');
            },
            child: Text('Start New'),
          ),
        ],
      ),
    );
  } else {
    // No previous assessment, start new one
    Navigator.pushNamed(context, '/risk-assessment');
  }
}
```

---

## 📊 Step 5: Format Answers for API

### Convert Your Answer Model to API Format

```dart
// Assuming you have an answer model like this:
class AssessmentAnswer {
  final int questionId;
  final String optionId;
  final String answerText;
  final int score;

  AssessmentAnswer({
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

// When saving:
final answers = [
  AssessmentAnswer(
    questionId: 1,
    optionId: 'q1_opt2',
    answerText: 'Maintain the capital...',
    score: 2,
  ),
  // ... other answers
].map((a) => a.toJson()).toList();

await RiskAssessmentService.saveRiskAssessment(
  answers: answers,
  totalScore: 12,
  riskProfile: 'Moderate',
  recommendation: 'Balance stocks and bonds.',
);
```

---

## ✅ Complete Flow Example

```dart
// 1. User completes assessment
final answers = [
  {'questionId': 1, 'optionId': 'q1_opt2', 'answerText': '...', 'score': 2},
  {'questionId': 2, 'optionId': 'q2_opt3', 'answerText': '...', 'score': 3},
  {'questionId': 3, 'optionId': 'q3_opt2', 'answerText': '...', 'score': 2},
  {'questionId': 4, 'optionId': 'q4_opt3', 'answerText': '...', 'score': 3},
  {'questionId': 5, 'optionId': 'q5_opt2', 'answerText': '...', 'score': 2},
];

final totalScore = answers.fold(0, (sum, a) => sum + a['score'] as int);
final riskProfile = _calculateRiskProfile(totalScore);
final recommendation = _getRecommendation(riskProfile);

// 2. Save to backend
try {
  final savedAssessment = await RiskAssessmentService.saveRiskAssessment(
    answers: answers,
    totalScore: totalScore,
    riskProfile: riskProfile,
    recommendation: recommendation,
  );

  // 3. Navigate to result screen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => RiskAssessmentResultScreen(
        assessment: savedAssessment,
      ),
    ),
  );
} catch (e) {
  // Handle error
  showError('Failed to save assessment: $e');
}
```

---

## 🧪 Testing

### Test Save

```dart
// In your test or debug screen
await RiskAssessmentService.saveRiskAssessment(
  answers: [
    {'questionId': 1, 'optionId': 'q1_opt2', 'answerText': 'Test', 'score': 2},
    {'questionId': 2, 'optionId': 'q2_opt3', 'answerText': 'Test', 'score': 3},
    {'questionId': 3, 'optionId': 'q3_opt2', 'answerText': 'Test', 'score': 2},
    {'questionId': 4, 'optionId': 'q4_opt3', 'answerText': 'Test', 'score': 3},
    {'questionId': 5, 'optionId': 'q5_opt2', 'answerText': 'Test', 'score': 2},
  ],
  totalScore: 12,
  riskProfile: 'Moderate',
  recommendation: 'Test recommendation',
);
```

### Test Get History

```dart
final history = await RiskAssessmentService.getAssessmentHistory();
print('Found ${history.length} assessments');
```

### Test Get Latest

```dart
final latest = await RiskAssessmentService.getLatestAssessment();
if (latest != null) {
  print('Latest risk profile: ${latest['risk_profile']}');
}
```

---

## 🎯 Integration Checklist

- [ ] Create `RiskAssessmentService` class
- [ ] Add save method to result screen
- [ ] Create history screen (optional)
- [ ] Add "View Previous" option
- [ ] Test save functionality
- [ ] Test get history functionality
- [ ] Handle errors gracefully
- [ ] Show loading states
- [ ] Update UI after save

---

## 📝 Notes

1. **Answer Format:** Make sure answers array has exactly 5 items
2. **Score Validation:** Total score must match sum of answer scores
3. **User ID:** Automatically retrieved from AuthService
4. **Error Handling:** Always wrap API calls in try-catch
5. **Loading States:** Show loading indicator during API calls
6. **Success Feedback:** Show success message after saving

---

## 🚀 Quick Start

1. Copy `RiskAssessmentService` code above
2. Call `saveRiskAssessment()` after user completes assessment
3. Test with your Flutter app
4. Add history view if needed

See `RISK_ASSESSMENT_API.md` for complete API documentation.
