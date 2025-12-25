# Risk Assessment API - Quick Start

## ✅ What's Ready

- ✅ Database tables created (`risk_assessments`, `risk_assessment_answers`)
- ✅ All 4 API endpoints implemented and tested
- ✅ Full Flutter integration guide created

---

## 🚀 Quick Setup

### 1. Run Database Migration

```bash
npm run db:add-risk-assessment
```

### 2. Restart Server

```bash
npm start
```

### 3. Test API

```bash
# Save assessment
curl -X POST http://localhost:3001/api/risk-assessment \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "answers": [
      {"questionId": 1, "optionId": "q1_opt2", "answerText": "Test", "score": 2},
      {"questionId": 2, "optionId": "q2_opt3", "answerText": "Test", "score": 3},
      {"questionId": 3, "optionId": "q3_opt2", "answerText": "Test", "score": 2},
      {"questionId": 4, "optionId": "q4_opt3", "answerText": "Test", "score": 3},
      {"questionId": 5, "optionId": "q5_opt2", "answerText": "Test", "score": 2}
    ],
    "total_score": 12,
    "risk_profile": "Moderate",
    "recommendation": "Test recommendation"
  }'
```

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/risk-assessment` | Save new assessment |
| GET | `/api/risk-assessment/:user_id` | Get assessment history |
| GET | `/api/risk-assessment/:user_id/latest` | Get latest assessment |
| GET | `/api/risk-assessment/:user_id/:assessment_id` | Get specific assessment |

---

## 💻 Flutter Integration

### Copy Service Class

See `RISK_ASSESSMENT_FLUTTER.md` for complete `RiskAssessmentService` implementation.

### Quick Usage

```dart
// Save assessment
await RiskAssessmentService.saveRiskAssessment(
  answers: answers,
  totalScore: 12,
  riskProfile: 'Moderate',
  recommendation: 'Balance stocks and bonds.',
);

// Get history
final history = await RiskAssessmentService.getAssessmentHistory();

// Get latest
final latest = await RiskAssessmentService.getLatestAssessment();
```

---

## 📚 Documentation Files

- `RISK_ASSESSMENT_API.md` - Complete API documentation
- `RISK_ASSESSMENT_FLUTTER.md` - Flutter integration guide
- `API_DOCUMENTATION.md` - Updated with risk assessment endpoints

---

## ✅ Status

- [x] Database tables created
- [x] All API endpoints working
- [x] Tested and verified
- [x] Documentation complete
- [x] Flutter integration guide ready

**Ready for frontend integration!**

