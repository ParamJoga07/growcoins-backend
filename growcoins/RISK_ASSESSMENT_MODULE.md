# Risk Assessment Module Documentation

## 📋 Overview

The Risk Assessment module allows users to complete a 5-question survey to determine their investment risk profile. The results are saved to the backend database.

## 🏗️ Architecture

### Files Created:

1. **Models** (`lib/models/risk_assessment_model.dart`)
   - `RiskAssessmentQuestion` - Question structure
   - `RiskAssessmentOption` - Answer option with score
   - `RiskAssessmentAnswer` - User's selected answer
   - `RiskAssessmentResult` - Complete assessment result
   - `RiskAssessmentData` - Predefined questions and scoring logic

2. **Services** (`lib/services/risk_assessment_service.dart`)
   - `saveRiskAssessment()` - Saves results to backend API
   - `getRiskAssessmentHistory()` - Fetches user's assessment history
   - `getLatestRiskAssessment()` - Gets most recent assessment

3. **Screens** (`lib/screens/risk_assessment/`)
   - `risk_assessment_intro_screen.dart` - Introduction/onboarding screen
   - `risk_assessment_question_screen.dart` - Dynamic question screen (reusable)
   - `risk_assessment_result_screen.dart` - Results display and save confirmation

## 🔄 Flow

1. **Introduction Screen** → User clicks "Continue"
2. **Question 1** → User selects option → "Next"
3. **Question 2** → User selects option → "Next"
4. **Question 3** → User selects option → "Next"
5. **Question 4** → User selects option → "Next"
6. **Question 5** → User selects option → "Submit"
7. **Result Screen** → Shows risk profile, score, recommendation → Saves to backend → "Done"

## 📊 Questions

1. **What is your primary investment objective?**
   - Options: Conservative to Aggressive (Score: 1-4)

2. **If you were to invest in high-return but high-risk assets, how would you feel?**
   - Options: Worried to Unconcerned (Score: 1-4)

3. **What is your investment time horizon?**
   - Options: Short-term to Very long-term (Score: 1-4)

4. **What is your willingness to risk shorter-term losses for the prospect of higher longer-term returns?**
   - Options: Low to High (Score: 1-4)

5. **How would you emotionally react if your investment portfolio experienced a significant decline in value?**
   - Options: Panic to Opportunistic (Score: 1-4)

## 🎯 Risk Profiles

Based on total score (out of 20):

- **1-8**: Conservative
- **9-12**: Moderate
- **13-16**: Moderately Aggressive
- **17-20**: Aggressive

## 🔌 Backend API Integration

### Save Risk Assessment

**Endpoint:** `POST /api/risk-assessment`

**Request Body:**
```json
{
  "userId": "user_id_here",
  "answers": [
    {
      "questionId": 1,
      "optionId": "q1_opt2",
      "answerText": "Maintain the capital...",
      "score": 2
    },
    // ... more answers
  ],
  "totalScore": 12,
  "riskProfile": "Moderate",
  "recommendation": "Balance between stocks and bonds...",
  "completedAt": "2024-12-22T10:30:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Risk assessment saved successfully",
  "assessmentId": "assessment_id_here"
}
```

### Get Risk Assessment History

**Endpoint:** `GET /api/risk-assessment/{userId}`

**Response:**
```json
{
  "assessments": [
    {
      "assessmentId": "id1",
      "totalScore": 12,
      "riskProfile": "Moderate",
      "completedAt": "2024-12-22T10:30:00Z"
    }
  ]
}
```

## 🚀 How to Start the Module

### Option 1: From Home Screen (Currently Implemented)

The Risk Assessment card is already added to the Home Screen. Users can tap it to start.

### Option 2: Custom Entry Point

To start from a different screen:

```dart
import 'screens/risk_assessment/risk_assessment_intro_screen.dart';

// Navigate to risk assessment
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RiskAssessmentIntroScreen(),
  ),
);
```

## ⚙️ Configuration

### Update Backend URL

Edit `lib/services/risk_assessment_service.dart`:

```dart
static const String baseUrl = 'https://your-api-url.com/api';
```

### Add Authentication Token

If your API requires authentication, update the `saveRiskAssessment()` method:

```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $yourToken',
},
```

## 📱 Features

✅ 5-question risk assessment survey  
✅ Progress indicator (1 of 5, 2 of 5, etc.)  
✅ Previous/Next navigation  
✅ Answer selection with visual feedback  
✅ Automatic score calculation  
✅ Risk profile determination  
✅ Personalized recommendations  
✅ Backend API integration  
✅ Save confirmation  
✅ Error handling  

## 🎨 UI Features

- Clean, modern design matching your app theme
- Progress bar showing completion status
- Selected option highlighting
- Smooth navigation between questions
- Result screen with color-coded risk profile
- Loading states during API calls
- Success/error messages

## 📝 Data Structure

Each answer includes:
- `questionId`: Question number (1-5)
- `optionId`: Selected option ID
- `answerText`: Full text of selected option
- `score`: Risk score (1-4)

Final result includes:
- All answers
- Total score (sum of all scores)
- Risk profile (Conservative/Moderate/Moderately Aggressive/Aggressive)
- Recommendation (personalized investment advice)

## 🔧 Customization

### Add More Questions

Edit `RiskAssessmentData.getQuestions()` in `risk_assessment_model.dart`

### Change Scoring

Modify the `score` values in each `RiskAssessmentOption`

### Update Risk Profiles

Edit `calculateRiskProfile()` method in `RiskAssessmentData`

### Change Recommendations

Edit `getRecommendation()` method in `RiskAssessmentData`

## 🐛 Troubleshooting

### API Not Working

- Check backend URL in `risk_assessment_service.dart`
- Verify API endpoint is correct
- Check authentication tokens if required
- The service will work offline (saves locally) if API fails

### Navigation Issues

- Ensure all screens are imported correctly
- Check that routes are properly set up

## 📦 Dependencies Added

- `http: ^1.2.2` - For API calls

## ✅ Next Steps

1. **Update Backend URL**: Set your actual API endpoint
2. **Add Authentication**: If your API requires auth tokens
3. **Test Flow**: Complete the assessment and verify data is saved
4. **Customize**: Adjust questions, scores, or recommendations as needed
5. **Add Entry Point**: Tell me where you want users to start this module

