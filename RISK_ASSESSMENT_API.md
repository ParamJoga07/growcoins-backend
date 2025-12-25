# Risk Assessment API - Complete Documentation

## 📋 Overview

The Risk Assessment API allows users to complete a 5-question survey to determine their investment risk profile. Users can take the assessment multiple times, and all submissions are saved with full history.

---

## 🗄️ Database Schema

### Tables Created

1. **`risk_assessments`** - Stores each assessment submission
2. **`risk_assessment_answers`** - Stores individual question answers

### Run Migration

```bash
npm run db:add-risk-assessment
```

---

## 📡 API Endpoints

### Base URL
```
http://localhost:3001/api/risk-assessment
```

---

### 1. Save Risk Assessment

**Endpoint:** `POST /api/risk-assessment`

**Description:** Save a new risk assessment submission

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 1,
  "answers": [
    {
      "questionId": 1,
      "optionId": "q1_opt2",
      "answerText": "Maintain the capital of my investments with regular income.",
      "score": 2
    },
    {
      "questionId": 2,
      "optionId": "q2_opt3",
      "answerText": "Aware of possible loss, can accept certain degree of fluctuation",
      "score": 3
    },
    {
      "questionId": 3,
      "optionId": "q3_opt2",
      "answerText": "Medium-term: 3-5 years.",
      "score": 2
    },
    {
      "questionId": 4,
      "optionId": "q4_opt3",
      "answerText": "Moderate.",
      "score": 3
    },
    {
      "questionId": 5,
      "optionId": "q5_opt2",
      "answerText": "Concerned: I would be worried but wait for a recovery.",
      "score": 2
    }
  ],
  "total_score": 12,
  "risk_profile": "Moderate",
  "recommendation": "Balance between stocks and bonds. Consider diversified mutual funds.",
  "completed_at": "2025-01-15T10:30:00.000Z"
}
```

**Validation Rules:**
- `user_id`: Required, must be integer
- `answers`: Required, must be array with exactly 5 answers
- Each answer must have: `questionId` (1-5), `optionId`, `answerText`, `score` (1-4)
- `total_score`: Required, must be sum of all answer scores (5-20)
- `risk_profile`: Required, must be one of: "Conservative", "Moderate", "Moderately Aggressive", "Aggressive"
- `recommendation`: Optional
- `completed_at`: Optional, ISO 8601 timestamp

**Success Response (201 Created):**
```json
{
  "message": "Risk assessment saved successfully",
  "assessment": {
    "id": 1,
    "user_id": 1,
    "total_score": 12,
    "risk_profile": "Moderate",
    "recommendation": "Balance between stocks and bonds. Consider diversified mutual funds.",
    "completed_at": "2025-01-15T10:30:00.000Z",
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z",
    "answers": [
      {
        "id": 1,
        "question_id": 1,
        "option_id": "q1_opt2",
        "answer_text": "Maintain the capital of my investments with regular income.",
        "score": 2
      },
      {
        "id": 2,
        "question_id": 2,
        "option_id": "q2_opt3",
        "answer_text": "Aware of possible loss, can accept certain degree of fluctuation",
        "score": 3
      },
      {
        "id": 3,
        "question_id": 3,
        "option_id": "q3_opt2",
        "answer_text": "Medium-term: 3-5 years.",
        "score": 2
      },
      {
        "id": 4,
        "question_id": 4,
        "option_id": "q4_opt3",
        "answer_text": "Moderate.",
        "score": 3
      },
      {
        "id": 5,
        "question_id": 5,
        "option_id": "q5_opt2",
        "answer_text": "Concerned: I would be worried but wait for a recovery.",
        "score": 2
      }
    ]
  }
}
```

**Error Responses:**

**400 Bad Request - Validation Error:**
```json
{
  "errors": [
    {
      "msg": "Answers must contain exactly 5 answers",
      "param": "answers",
      "location": "body"
    }
  ]
}
```

**400 Bad Request - Score Mismatch:**
```json
{
  "error": "Total score does not match sum of answer scores"
}
```

**404 Not Found:**
```json
{
  "error": "User not found"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Failed to save risk assessment"
}
```

---

### 2. Get User's Risk Assessment History

**Endpoint:** `GET /api/risk-assessment/:user_id`

**Description:** Get all risk assessments for a user, ordered by most recent first

**URL Parameters:**
- `user_id` (integer): User ID

**Query Parameters (Optional):**
- `limit` (integer): Number of assessments to return (default: 10, max: 50)
- `offset` (integer): Number of assessments to skip (default: 0)

**Example:**
```
GET /api/risk-assessment/1?limit=10&offset=0
```

**Success Response (200 OK):**
```json
{
  "assessments": [
    {
      "id": 3,
      "user_id": 1,
      "total_score": 15,
      "risk_profile": "Moderately Aggressive",
      "recommendation": "Focus on growth stocks and equity mutual funds.",
      "completed_at": "2025-01-20T14:30:00.000Z",
      "created_at": "2025-01-20T14:30:00.000Z",
      "updated_at": "2025-01-20T14:30:00.000Z",
      "answers": [
        {
          "id": 11,
          "question_id": 1,
          "option_id": "q1_opt4",
          "answer_text": "Maximize the growth of my investments.",
          "score": 4
        }
        // ... other answers
      ]
    },
    {
      "id": 2,
      "user_id": 1,
      "total_score": 12,
      "risk_profile": "Moderate",
      "recommendation": "Balance between stocks and bonds.",
      "completed_at": "2025-01-15T10:30:00.000Z",
      "created_at": "2025-01-15T10:30:00.000Z",
      "updated_at": "2025-01-15T10:30:00.000Z",
      "answers": [
        // ... answers
      ]
    }
  ],
  "total": 3,
  "limit": 10,
  "offset": 0
}
```

**Error Responses:**

**400 Bad Request - Validation Error:**
```json
{
  "errors": [
    {
      "msg": "User ID must be an integer",
      "param": "user_id",
      "location": "params"
    }
  ]
}
```

**404 Not Found:**
```json
{
  "error": "User not found"
}
```

---

### 3. Get Latest Risk Assessment

**Endpoint:** `GET /api/risk-assessment/:user_id/latest`

**Description:** Get the most recent risk assessment for a user

**URL Parameters:**
- `user_id` (integer): User ID

**Success Response (200 OK):**
```json
{
  "assessment": {
    "id": 3,
    "user_id": 1,
    "total_score": 15,
    "risk_profile": "Moderately Aggressive",
    "recommendation": "Focus on growth stocks and equity mutual funds.",
    "completed_at": "2025-01-20T14:30:00.000Z",
    "created_at": "2025-01-20T14:30:00.000Z",
    "updated_at": "2025-01-20T14:30:00.000Z",
    "answers": [
      {
        "id": 11,
        "question_id": 1,
        "option_id": "q1_opt4",
        "answer_text": "Maximize the growth of my investments.",
        "score": 4
      },
      {
        "id": 12,
        "question_id": 2,
        "option_id": "q2_opt3",
        "answer_text": "Aware of possible loss, can accept certain degree of fluctuation",
        "score": 3
      },
      {
        "id": 13,
        "question_id": 3,
        "option_id": "q3_opt3",
        "answer_text": "Long-term: 5-10 years.",
        "score": 3
      },
      {
        "id": 14,
        "question_id": 4,
        "option_id": "q4_opt3",
        "answer_text": "Moderate.",
        "score": 3
      },
      {
        "id": 15,
        "question_id": 5,
        "option_id": "q5_opt2",
        "answer_text": "Concerned: I would be worried but wait for a recovery.",
        "score": 2
      }
    ]
  }
}
```

**Error Responses:**

**404 Not Found - No Assessment:**
```json
{
  "error": "No risk assessment found for this user"
}
```

**404 Not Found - User Not Found:**
```json
{
  "error": "User not found"
}
```

---

### 4. Get Specific Risk Assessment by ID

**Endpoint:** `GET /api/risk-assessment/:user_id/:assessment_id`

**Description:** Get a specific risk assessment by its ID

**URL Parameters:**
- `user_id` (integer): User ID
- `assessment_id` (integer): Assessment ID

**Success Response (200 OK):**
```json
{
  "assessment": {
    "id": 2,
    "user_id": 1,
    "total_score": 12,
    "risk_profile": "Moderate",
    "recommendation": "Balance between stocks and bonds.",
    "completed_at": "2025-01-15T10:30:00.000Z",
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z",
    "answers": [
      // ... all 5 answers
    ]
  }
}
```

**Error Responses:**

**404 Not Found:**
```json
{
  "error": "Risk assessment not found"
}
```

---

## 📱 Flutter Integration

### Step 1: Create Risk Assessment Service

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
        throw Exception('User not logged in');
      }

      final response = await ApiService.post(
        '/api/risk-assessment',
        {
          'user_id': userId,
          'answers': answers,
          'total_score': totalScore,
          'risk_profile': riskProfile,
          'recommendation': recommendation,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );

      return response['assessment'];
    } catch (e) {
      rethrow;
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
      return null;
    }
  }
}
```

### Step 2: Usage Example

```dart
// Save assessment after user completes it
Future<void> _saveAssessment() async {
  try {
    final assessment = await RiskAssessmentService.saveRiskAssessment(
      answers: [
        {
          'questionId': 1,
          'optionId': 'q1_opt2',
          'answerText': 'Maintain the capital...',
          'score': 2,
        },
        // ... other answers
      ],
      totalScore: 12,
      riskProfile: 'Moderate',
      recommendation: 'Balance between stocks and bonds.',
    );

    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assessment saved successfully!')),
    );

    // Navigate to result screen
    Navigator.pushReplacementNamed(context, '/assessment-result');
  } on ApiException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message), backgroundColor: Colors.red),
    );
  }
}

// Get history
Future<void> _loadHistory() async {
  final assessments = await RiskAssessmentService.getAssessmentHistory();
  // Display in list
}

// Get latest
Future<void> _loadLatest() async {
  final latest = await RiskAssessmentService.getLatestAssessment();
  if (latest != null) {
    // Show latest assessment
  }
}
```

---

## 🧪 Testing

### Test Save Assessment

```bash
curl -X POST http://localhost:3001/api/risk-assessment \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "answers": [
      {"questionId": 1, "optionId": "q1_opt2", "answerText": "Maintain capital", "score": 2},
      {"questionId": 2, "optionId": "q2_opt3", "answerText": "Accept fluctuation", "score": 3},
      {"questionId": 3, "optionId": "q3_opt2", "answerText": "3-5 years", "score": 2},
      {"questionId": 4, "optionId": "q4_opt3", "answerText": "Moderate", "score": 3},
      {"questionId": 5, "optionId": "q5_opt2", "answerText": "Wait for recovery", "score": 2}
    ],
    "total_score": 12,
    "risk_profile": "Moderate",
    "recommendation": "Balance stocks and bonds"
  }'
```

### Test Get History

```bash
curl http://localhost:3001/api/risk-assessment/1
```

### Test Get Latest

```bash
curl http://localhost:3001/api/risk-assessment/1/latest
```

---

## ✅ Implementation Checklist

- [x] Database tables created
- [x] API endpoints implemented
- [x] Validation added
- [x] Error handling implemented
- [x] Documentation created
- [ ] Test all endpoints
- [ ] Frontend integration

---

## 📝 Notes

1. **Multiple Assessments:** Each submission creates a new record, allowing users to track changes over time
2. **Data Integrity:** Total score is validated against sum of answer scores
3. **History:** All assessments are preserved with full answer details
4. **Performance:** Indexes added for fast queries by user_id and completed_at

