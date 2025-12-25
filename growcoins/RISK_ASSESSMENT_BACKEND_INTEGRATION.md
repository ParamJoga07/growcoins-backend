# Risk Assessment Backend Integration Guide

## 📋 Overview

This document describes how to implement the backend API and database structure for storing and retrieving risk assessment data. Users can take the assessment multiple times, view their history, and see their previous answers.

---

## 🗄️ Database Schema

### Table: `risk_assessments`

Store each risk assessment submission as a separate record to maintain history.

```sql
CREATE TABLE risk_assessments (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
  total_score INTEGER NOT NULL,
  risk_profile VARCHAR(50) NOT NULL, -- 'Conservative', 'Moderate', 'Moderately Aggressive', 'Aggressive'
  recommendation TEXT,
  completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Indexes for faster queries
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES authentication(id)
);

-- Index for faster user history queries
CREATE INDEX idx_risk_assessments_user_id ON risk_assessments(user_id);
CREATE INDEX idx_risk_assessments_completed_at ON risk_assessments(completed_at DESC);
```

### Table: `risk_assessment_answers`

Store individual question answers for each assessment.

```sql
CREATE TABLE risk_assessment_answers (
  id SERIAL PRIMARY KEY,
  assessment_id INTEGER NOT NULL REFERENCES risk_assessments(id) ON DELETE CASCADE,
  question_id INTEGER NOT NULL,
  option_id VARCHAR(50) NOT NULL,
  answer_text TEXT NOT NULL,
  score INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Index for faster queries
  CONSTRAINT fk_assessment FOREIGN KEY (assessment_id) REFERENCES risk_assessments(id)
);

-- Index for faster answer lookups
CREATE INDEX idx_risk_assessment_answers_assessment_id ON risk_assessment_answers(assessment_id);
CREATE INDEX idx_risk_assessment_answers_question_id ON risk_assessment_answers(question_id);
```

### Alternative: Single Table Design (Simpler)

If you prefer a simpler approach with JSON storage:

```sql
CREATE TABLE risk_assessments (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
  answers JSONB NOT NULL, -- Store all answers as JSON array
  total_score INTEGER NOT NULL,
  risk_profile VARCHAR(50) NOT NULL,
  recommendation TEXT,
  completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES authentication(id)
);

-- Index for faster queries
CREATE INDEX idx_risk_assessments_user_id ON risk_assessments(user_id);
CREATE INDEX idx_risk_assessments_completed_at ON risk_assessments(completed_at DESC);
CREATE INDEX idx_risk_assessments_answers ON risk_assessments USING GIN (answers); -- For JSON queries
```

**Recommendation:** Use the two-table design for better data normalization and easier querying of individual answers.

---

## 📡 API Endpoints

### 1. Save Risk Assessment

**Endpoint:** `POST /api/risk-assessment`

**Description:** Save a new risk assessment submission for a user.

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
- `user_id`: Required, must be a valid integer
- `answers`: Required, must be an array with exactly 5 answers
- Each answer must have: `questionId`, `optionId`, `answerText`, `score`
- `total_score`: Required, must be sum of all answer scores (1-20)
- `risk_profile`: Required, must be one of: "Conservative", "Moderate", "Moderately Aggressive", "Aggressive"
- `recommendation`: Optional, string
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
    "answers": [
      {
        "id": 1,
        "question_id": 1,
        "option_id": "q1_opt2",
        "answer_text": "Maintain the capital of my investments with regular income.",
        "score": 2
      },
      // ... other answers
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
      "msg": "Answers array must contain exactly 5 answers",
      "param": "answers",
      "location": "body"
    }
  ]
}
```

**400 Bad Request - Invalid Total Score:**
```json
{
  "error": "Total score does not match sum of answer scores"
}
```

**404 Not Found - User Not Found:**
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

**Description:** Get all risk assessments for a specific user, ordered by most recent first.

**Request Headers:**
```
Content-Type: application/json
```

**URL Parameters:**
- `user_id` (integer): User ID

**Query Parameters (Optional):**
- `limit` (integer): Number of assessments to return (default: 10, max: 50)
- `offset` (integer): Number of assessments to skip (default: 0)

**Success Response (200 OK):**
```json
{
  "assessments": [
    {
      "id": 3,
      "user_id": 1,
      "total_score": 15,
      "risk_profile": "Moderately Aggressive",
      "recommendation": "Focus on growth stocks and equity mutual funds with some bond allocation.",
      "completed_at": "2025-01-20T14:30:00.000Z",
      "created_at": "2025-01-20T14:30:00.000Z",
      "answers": [
        {
          "id": 11,
          "question_id": 1,
          "option_id": "q1_opt4",
          "answer_text": "Maximize the growth of my investments.",
          "score": 4
        },
        // ... other answers
      ]
    },
    {
      "id": 2,
      "user_id": 1,
      "total_score": 12,
      "risk_profile": "Moderate",
      "recommendation": "Balance between stocks and bonds. Consider diversified mutual funds.",
      "completed_at": "2025-01-15T10:30:00.000Z",
      "created_at": "2025-01-15T10:30:00.000Z",
      "answers": [
        // ... answers
      ]
    },
    {
      "id": 1,
      "user_id": 1,
      "total_score": 8,
      "risk_profile": "Conservative",
      "recommendation": "Focus on low-risk investments like bonds, fixed deposits, and blue-chip stocks.",
      "completed_at": "2025-01-10T09:15:00.000Z",
      "created_at": "2025-01-10T09:15:00.000Z",
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

**404 Not Found:**
```json
{
  "error": "User not found"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Failed to fetch risk assessment history"
}
```

---

### 3. Get Latest Risk Assessment

**Endpoint:** `GET /api/risk-assessment/:user_id/latest`

**Description:** Get the most recent risk assessment for a user.

**Request Headers:**
```
Content-Type: application/json
```

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
    "recommendation": "Focus on growth stocks and equity mutual funds with some bond allocation.",
    "completed_at": "2025-01-20T14:30:00.000Z",
    "created_at": "2025-01-20T14:30:00.000Z",
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

**Description:** Get a specific risk assessment by its ID.

**Request Headers:**
```
Content-Type: application/json
```

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
    "recommendation": "Balance between stocks and bonds. Consider diversified mutual funds.",
    "completed_at": "2025-01-15T10:30:00.000Z",
    "created_at": "2025-01-15T10:30:00.000Z",
    "answers": [
      // ... answers
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

## 🔧 Backend Implementation Example (Node.js/Express)

### Route Handler: `routes/riskAssessment.js`

```javascript
const express = require('express');
const router = express.Router();
const { body, param, query, validationResult } = require('express-validator');
const { query: dbQuery } = require('../config/database');

// Save Risk Assessment
router.post('/risk-assessment', [
  body('user_id').isInt().withMessage('User ID is required'),
  body('answers').isArray({ min: 5, max: 5 }).withMessage('Answers must contain exactly 5 answers'),
  body('answers.*.questionId').isInt().withMessage('Question ID is required'),
  body('answers.*.optionId').notEmpty().withMessage('Option ID is required'),
  body('answers.*.answerText').notEmpty().withMessage('Answer text is required'),
  body('answers.*.score').isInt({ min: 1, max: 4 }).withMessage('Score must be between 1 and 4'),
  body('total_score').isInt({ min: 5, max: 20 }).withMessage('Total score must be between 5 and 20'),
  body('risk_profile').isIn(['Conservative', 'Moderate', 'Moderately Aggressive', 'Aggressive']).withMessage('Invalid risk profile'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id, answers, total_score, risk_profile, recommendation, completed_at } = req.body;

    // Verify total score matches sum of answer scores
    const calculatedScore = answers.reduce((sum, answer) => sum + answer.score, 0);
    if (calculatedScore !== total_score) {
      return res.status(400).json({ error: 'Total score does not match sum of answer scores' });
    }

    // Check if user exists
    const userCheck = await dbQuery('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Insert risk assessment
    const assessmentResult = await dbQuery(
      `INSERT INTO risk_assessments (user_id, total_score, risk_profile, recommendation, completed_at)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [user_id, total_score, risk_profile, recommendation || null, completed_at || new Date()]
    );

    const assessment = assessmentResult.rows[0];

    // Insert answers
    const answerInserts = answers.map((answer, index) => 
      dbQuery(
        `INSERT INTO risk_assessment_answers (assessment_id, question_id, option_id, answer_text, score)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [assessment.id, answer.questionId, answer.optionId, answer.answerText, answer.score]
      )
    );

    const answerResults = await Promise.all(answerInserts);
    const savedAnswers = answerResults.map(result => result.rows[0]);

    res.status(201).json({
      message: 'Risk assessment saved successfully',
      assessment: {
        ...assessment,
        answers: savedAnswers.map(a => ({
          id: a.id,
          question_id: a.question_id,
          option_id: a.option_id,
          answer_text: a.answer_text,
          score: a.score
        }))
      }
    });
  } catch (error) {
    console.error('Save risk assessment error:', error);
    res.status(500).json({ error: 'Failed to save risk assessment' });
  }
});

// Get User's Risk Assessment History
router.get('/risk-assessment/:user_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50'),
  query('offset').optional().isInt({ min: 0 }).withMessage('Offset must be a non-negative integer'),
], async (req, res) => {
  try {
    const { user_id } = req.params;
    const limit = parseInt(req.query.limit) || 10;
    const offset = parseInt(req.query.offset) || 0;

    // Check if user exists
    const userCheck = await dbQuery('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get assessments
    const assessmentsResult = await dbQuery(
      `SELECT * FROM risk_assessments
       WHERE user_id = $1
       ORDER BY completed_at DESC
       LIMIT $2 OFFSET $3`,
      [user_id, limit, offset]
    );

    // Get total count
    const countResult = await dbQuery(
      'SELECT COUNT(*) as total FROM risk_assessments WHERE user_id = $1',
      [user_id]
    );
    const total = parseInt(countResult.rows[0].total);

    // Get answers for each assessment
    const assessments = await Promise.all(
      assessmentsResult.rows.map(async (assessment) => {
        const answersResult = await dbQuery(
          `SELECT id, question_id, option_id, answer_text, score
           FROM risk_assessment_answers
           WHERE assessment_id = $1
           ORDER BY question_id`,
          [assessment.id]
        );

        return {
          ...assessment,
          answers: answersResult.rows
        };
      })
    );

    res.json({
      assessments,
      total,
      limit,
      offset
    });
  } catch (error) {
    console.error('Get risk assessment history error:', error);
    res.status(500).json({ error: 'Failed to fetch risk assessment history' });
  }
});

// Get Latest Risk Assessment
router.get('/risk-assessment/:user_id/latest', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const { user_id } = req.params;

    // Check if user exists
    const userCheck = await dbQuery('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get latest assessment
    const assessmentResult = await dbQuery(
      `SELECT * FROM risk_assessments
       WHERE user_id = $1
       ORDER BY completed_at DESC
       LIMIT 1`,
      [user_id]
    );

    if (assessmentResult.rows.length === 0) {
      return res.status(404).json({ error: 'No risk assessment found for this user' });
    }

    const assessment = assessmentResult.rows[0];

    // Get answers
    const answersResult = await dbQuery(
      `SELECT id, question_id, option_id, answer_text, score
       FROM risk_assessment_answers
       WHERE assessment_id = $1
       ORDER BY question_id`,
      [assessment.id]
    );

    res.json({
      assessment: {
        ...assessment,
        answers: answersResult.rows
      }
    });
  } catch (error) {
    console.error('Get latest risk assessment error:', error);
    res.status(500).json({ error: 'Failed to fetch latest risk assessment' });
  }
});

// Get Specific Risk Assessment by ID
router.get('/risk-assessment/:user_id/:assessment_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
  param('assessment_id').isInt().withMessage('Assessment ID must be an integer'),
], async (req, res) => {
  try {
    const { user_id, assessment_id } = req.params;

    // Get assessment
    const assessmentResult = await dbQuery(
      `SELECT * FROM risk_assessments
       WHERE id = $1 AND user_id = $2`,
      [assessment_id, user_id]
    );

    if (assessmentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Risk assessment not found' });
    }

    const assessment = assessmentResult.rows[0];

    // Get answers
    const answersResult = await dbQuery(
      `SELECT id, question_id, option_id, answer_text, score
       FROM risk_assessment_answers
       WHERE assessment_id = $1
       ORDER BY question_id`,
      [assessment.id]
    );

    res.json({
      assessment: {
        ...assessment,
        answers: answersResult.rows
      }
    });
  } catch (error) {
    console.error('Get risk assessment error:', error);
    res.status(500).json({ error: 'Failed to fetch risk assessment' });
  }
});

module.exports = router;
```

---

## 📱 Frontend Integration

### Update `risk_assessment_service.dart`

The service is already set up correctly. Just ensure the endpoints match:

```dart
// Save risk assessment
Future<Map<String, dynamic>> saveRiskAssessment({
  required RiskAssessmentResult result,
}) async {
  final userId = await BackendAuthService.getUserId();
  if (userId == null) {
    throw Exception('User not logged in');
  }

  final response = await ApiService.post('/api/risk-assessment', {
    'user_id': userId,
    'answers': result.answers.map((a) => a.toJson()).toList(),
    'total_score': result.totalScore,
    'risk_profile': result.riskProfile,
    'recommendation': result.recommendation,
    'completed_at': DateTime.now().toIso8601String(),
  });

  return response;
}

// Get assessment history
Future<List<Map<String, dynamic>>> getRiskAssessmentHistory() async {
  final userId = await BackendAuthService.getUserId();
  if (userId == null) {
    return [];
  }

  final response = await ApiService.get('/api/risk-assessment/$userId');
  return List<Map<String, dynamic>>.from(response['assessments'] ?? []);
}

// Get latest assessment
Future<Map<String, dynamic>?> getLatestRiskAssessment() async {
  final userId = await BackendAuthService.getUserId();
  if (userId == null) {
    return null;
  }

  try {
    final response = await ApiService.get('/api/risk-assessment/$userId/latest');
    return response['assessment'];
  } catch (e) {
    return null;
  }
}
```

---

## 🔄 User Flow

### Taking Assessment Again

1. **User clicks "Take Assessment"** → Check if user has previous assessments
2. **If previous assessment exists:**
   - Show option: "Start New Assessment" or "View Previous Results"
   - If "Start New", proceed with new assessment
   - If "View Previous", show history screen
3. **Save new assessment** → Creates new record in database
4. **User can view all previous assessments** → Shows list with dates and risk profiles

### Viewing Previous Answers

1. **User navigates to "Risk Assessment History"**
2. **Shows list of all assessments** with:
   - Date completed
   - Risk profile
   - Total score
3. **User clicks on an assessment** → Shows detailed view with:
   - All questions and selected answers
   - Risk profile
   - Recommendation
   - Date completed

---

## 📊 Data Flow Diagram

```
User Completes Assessment
         ↓
Frontend sends POST /api/risk-assessment
         ↓
Backend validates data
         ↓
Insert into risk_assessments table
         ↓
Insert answers into risk_assessment_answers table
         ↓
Return saved assessment with answers
         ↓
Frontend displays result
```

```
User Views History
         ↓
Frontend sends GET /api/risk-assessment/:user_id
         ↓
Backend queries risk_assessments + risk_assessment_answers
         ↓
Returns list of assessments with answers
         ↓
Frontend displays history
```

---

## ✅ Implementation Checklist

### Database
- [ ] Create `risk_assessments` table
- [ ] Create `risk_assessment_answers` table
- [ ] Add indexes for performance
- [ ] Add foreign key constraints
- [ ] Test database queries

### Backend API
- [ ] Implement `POST /api/risk-assessment` endpoint
- [ ] Implement `GET /api/risk-assessment/:user_id` endpoint
- [ ] Implement `GET /api/risk-assessment/:user_id/latest` endpoint
- [ ] Implement `GET /api/risk-assessment/:user_id/:assessment_id` endpoint
- [ ] Add validation for all endpoints
- [ ] Add error handling
- [ ] Test all endpoints

### Frontend
- [ ] Update `risk_assessment_service.dart` (already done)
- [ ] Create history view screen (optional)
- [ ] Update result screen to show "Take Again" option
- [ ] Test saving and retrieving assessments

---

## 🧪 Testing Examples

### Test Save Assessment (cURL)

```bash
curl -X POST http://localhost:3001/api/risk-assessment \
  -H "Content-Type: application/json" \
  -d '{
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
    "recommendation": "Balance between stocks and bonds. Consider diversified mutual funds."
  }'
```

### Test Get History (cURL)

```bash
curl http://localhost:3001/api/risk-assessment/1
```

### Test Get Latest (cURL)

```bash
curl http://localhost:3001/api/risk-assessment/1/latest
```

---

## 📝 Notes

1. **Multiple Assessments:** Each time a user takes the assessment, a new record is created. This allows users to track how their risk profile changes over time.

2. **Data Retention:** Consider adding a policy for how long to keep assessment history (e.g., keep last 10 assessments, or all assessments).

3. **Privacy:** Ensure that users can only access their own assessments. Always verify `user_id` matches the authenticated user.

4. **Performance:** For users with many assessments, consider pagination when fetching history.

5. **Analytics:** You can track trends by analyzing how a user's risk profile changes over time using the `completed_at` timestamp.

---

## 🚀 Quick Start

1. **Run database migrations** to create tables
2. **Implement backend routes** using the example code above
3. **Test endpoints** with cURL or Postman
4. **Frontend is already configured** - just ensure backend endpoints match
5. **Test full flow** in the app

---

## 📞 Support

For questions or issues:
1. Check API endpoint URLs match between frontend and backend
2. Verify database schema matches the documentation
3. Test endpoints individually with cURL
4. Check server logs for errors
5. Verify user authentication is working

