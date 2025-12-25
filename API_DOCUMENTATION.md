# Growcoins Backend API Documentation

## Base URL
```
Development: http://localhost:3001
Production: [Your production URL]
```

## Authentication APIs

### 1. Register User

**Endpoint:** `POST /api/auth/register`

**Description:** Register a new user account

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "username": "johndoe",
  "password": "password123",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+1234567890",  // Optional
  "date_of_birth": "1990-01-15"   // Optional (YYYY-MM-DD format)
}
```

**Validation Rules:**
- `username`: Required, minimum 3 characters
- `password`: Required, minimum 6 characters
- `email`: Required, must be valid email format
- `first_name`: Required, cannot be empty
- `last_name`: Required, cannot be empty
- `phone_number`: Optional
- `date_of_birth`: Optional, date format

**Success Response (201 Created):**
```json
{
  "message": "User registered successfully",
  "user_id": 1,
  "account_number": "GC1734890123456"
}
```

**Error Responses:**

**400 Bad Request - Validation Error:**
```json
{
  "errors": [
    {
      "msg": "Username must be at least 3 characters",
      "param": "username",
      "location": "body"
    }
  ]
}
```

**400 Bad Request - Username Exists:**
```json
{
  "error": "Username already exists"
}
```

**400 Bad Request - Email Exists:**
```json
{
  "error": "Email already exists"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Failed to register user"
}
```

---

### 2. Login

**Endpoint:** `POST /api/auth/login`

**Description:** Authenticate user and get user information

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "username": "johndoe",
  "password": "password123"
}
```

**Validation Rules:**
- `username`: Required
- `password`: Required

**Success Response (200 OK):**
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "username": "johndoe",
    "user_data": {
      "id": 1,
      "user_id": 1,
      "first_name": "John",
      "last_name": "Doe",
      "email": "john@example.com",
      "phone_number": "+1234567890",
      "date_of_birth": "1990-01-15",
      "address": null,
      "city": null,
      "state": null,
      "zip_code": null,
      "country": "USA",
      "account_number": "GC1734890123456",
      "routing_number": null,
      "account_balance": "0.00",
      "currency": "USD",
      "kyc_status": "pending",
      "kyc_verified_at": null,
      "profile_picture_url": null,
      "created_at": "2025-12-22T18:00:00.000Z",
      "updated_at": "2025-12-22T18:00:00.000Z"
    }
  }
}
```

**Error Responses:**

**400 Bad Request - Validation Error:**
```json
{
  "errors": [
    {
      "msg": "Username is required",
      "param": "username",
      "location": "body"
    }
  ]
}
```

**401 Unauthorized - Invalid Credentials:**
```json
{
  "error": "Invalid username or password"
}
```

**403 Forbidden - Account Deactivated:**
```json
{
  "error": "Account is deactivated"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Failed to login"
}
```

---

## User Management APIs

### 3. Get User by ID

**Endpoint:** `GET /api/users/:id`

**Description:** Get detailed user information by user ID

**Request Headers:**
```
Content-Type: application/json
```

**URL Parameters:**
- `id` (integer): User ID

**Success Response (200 OK):**
```json
{
  "user": {
    "id": 1,
    "username": "johndoe",
    "account_created_at": "2025-12-22T18:00:00.000Z",
    "last_login": "2025-12-22T19:00:00.000Z",
    "user_id": 1,
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone_number": "+1234567890",
    "date_of_birth": "1990-01-15",
    "address": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zip_code": "10001",
    "country": "USA",
    "account_number": "GC1734890123456",
    "routing_number": null,
    "account_balance": "1000.00",
    "currency": "USD",
    "kyc_status": "pending",
    "kyc_verified_at": null,
    "profile_picture_url": null,
    "created_at": "2025-12-22T18:00:00.000Z",
    "updated_at": "2025-12-22T18:00:00.000Z"
  }
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
  "error": "Failed to fetch user"
}
```

---

### 4. Get All Users

**Endpoint:** `GET /api/users`

**Description:** Get list of all users (for admin purposes)

**Request Headers:**
```
Content-Type: application/json
```

**Success Response (200 OK):**
```json
{
  "users": [
    {
      "id": 1,
      "username": "johndoe",
      "account_created_at": "2025-12-22T18:00:00.000Z",
      "last_login": "2025-12-22T19:00:00.000Z",
      "is_active": true,
      "first_name": "John",
      "last_name": "Doe",
      "email": "john@example.com",
      "account_number": "GC1734890123456",
      "account_balance": "1000.00"
    }
  ]
}
```

**Error Response:**

**500 Internal Server Error:**
```json
{
  "error": "Failed to fetch users"
}
```

---

### 5. Update User

**Endpoint:** `PUT /api/users/:id`

**Description:** Update user profile information

**Request Headers:**
```
Content-Type: application/json
```

**URL Parameters:**
- `id` (integer): User ID

**Request Body (all fields optional):**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.new@example.com",
  "phone_number": "+1234567890",
  "date_of_birth": "1990-01-15",
  "address": "123 Main St",
  "city": "New York",
  "state": "NY",
  "zip_code": "10001",
  "country": "USA"
}
```

**Success Response (200 OK):**
```json
{
  "message": "User updated successfully",
  "user": {
    // Full user object (same as GET /api/users/:id)
  }
}
```

**Error Responses:**

**400 Bad Request - Validation Error:**
```json
{
  "errors": [
    {
      "msg": "Please provide a valid email",
      "param": "email",
      "location": "body"
    }
  ]
}
```

**400 Bad Request - Email Already in Use:**
```json
{
  "error": "Email already in use"
}
```

**400 Bad Request - No Fields to Update:**
```json
{
  "error": "No fields to update"
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
  "error": "Failed to update user"
}
```

---

### 6. Update Account Balance

**Endpoint:** `PATCH /api/users/:id/balance`

**Description:** Update user account balance (add, subtract, or set)

**Request Headers:**
```
Content-Type: application/json
```

**URL Parameters:**
- `id` (integer): User ID

**Request Body:**
```json
{
  "amount": 1000.00,
  "operation": "add"  // Options: "add", "subtract", "set"
}
```

**Validation Rules:**
- `amount`: Required, must be a positive number (float)
- `operation`: Required, must be one of: "add", "subtract", "set"

**Success Response (200 OK):**
```json
{
  "message": "Balance updated successfully",
  "previous_balance": 500.00,
  "new_balance": 1500.00
}
```

**Error Responses:**

**400 Bad Request - Validation Error:**
```json
{
  "errors": [
    {
      "msg": "Amount must be a positive number",
      "param": "amount",
      "location": "body"
    }
  ]
}
```

**400 Bad Request - Insufficient Balance:**
```json
{
  "error": "Insufficient balance"
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
  "error": "Failed to update balance"
}
```

---

## Health Check API

### 7. Health Check

**Endpoint:** `GET /health`

**Description:** Check if server and database are running

**Success Response (200 OK):**
```json
{
  "status": "OK",
  "message": "Server is running and database is connected",
  "timestamp": "2025-12-22T18:00:00.000Z"
}
```

**Error Response (500 Internal Server Error):**
```json
{
  "status": "ERROR",
  "message": "Database connection failed",
  "error": "Connection error message"
}
```

---

## Error Handling

All API endpoints follow consistent error response format:

### Standard Error Response Structure:
```json
{
  "error": "Error message here"
}
```

### Validation Error Response Structure:
```json
{
  "errors": [
    {
      "msg": "Validation error message",
      "param": "field_name",
      "location": "body"
    }
  ]
}
```

### HTTP Status Codes:
- `200 OK` - Success
- `201 Created` - Resource created successfully
- `400 Bad Request` - Validation error or bad request
- `401 Unauthorized` - Authentication required or invalid credentials
- `403 Forbidden` - Account deactivated or insufficient permissions
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

---

---

## Onboarding APIs

### 8. Save Personal Details

**Endpoint:** `POST /api/onboarding/personal-details`

**Description:** Save personal details from onboarding screen 1 (Full Legal Name, Email, Date of Birth)

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 1,
  "full_legal_name": "John Doe",
  "email": "john@example.com",
  "date_of_birth": "1990-01-15"
}
```

**Validation Rules:**
- `user_id`: Required, must be integer
- `full_legal_name`: Required, cannot be empty
- `email`: Required, must be valid email format
- `date_of_birth`: Required, must be valid ISO 8601 date (YYYY-MM-DD)

**Success Response (200 OK):**
```json
{
  "message": "Personal details saved successfully",
  "user": {
    // Full user object with updated personal details
  }
}
```

**Error Responses:**

**400 Bad Request - Validation Error:**
```json
{
  "errors": [
    {
      "msg": "Full legal name is required",
      "param": "full_legal_name",
      "location": "body"
    }
  ]
}
```

**400 Bad Request - Email Already in Use:**
```json
{
  "error": "Email already in use"
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
  "error": "Failed to save personal details"
}
```

---

### 9. Save KYC Details

**Endpoint:** `POST /api/onboarding/kyc-details`

**Description:** Save KYC details from onboarding screen 2 (PAN Number, Aadhar Number)

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 1,
  "pan_number": "ABCDE1234F",
  "aadhar_number": "123456789012"
}
```

**Validation Rules:**
- `user_id`: Required, must be integer
- `pan_number`: Required, must match format: `ABCDE1234F` (5 letters, 4 digits, 1 letter)
- `aadhar_number`: Required, must be exactly 12 digits

**Success Response (200 OK):**
```json
{
  "message": "KYC details saved successfully",
  "user": {
    // Full user object with updated KYC details
  },
  "kyc_status": "submitted"
}
```

**Error Responses:**

**400 Bad Request - Validation Error:**
```json
{
  "errors": [
    {
      "msg": "Invalid PAN number format",
      "param": "pan_number",
      "location": "body"
    }
  ]
}
```

**400 Bad Request - PAN Already in Use:**
```json
{
  "error": "PAN number already in use"
}
```

**400 Bad Request - Aadhar Already in Use:**
```json
{
  "error": "Aadhar number already in use"
}
```

**400 Bad Request - Personal Details Not Completed:**
```json
{
  "error": "Please complete personal details first"
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
  "error": "Failed to save KYC details"
}
```

---

### 10. Get Onboarding Status

**Endpoint:** `GET /api/onboarding/status/:user_id`

**Description:** Check onboarding completion status for a user

**Request Headers:**
```
Content-Type: application/json
```

**URL Parameters:**
- `user_id` (integer): User ID

**Success Response (200 OK):**
```json
{
  "personal_details_completed": true,
  "kyc_details_completed": true,
  "kyc_status": "submitted",
  "user_data": {
    "full_legal_name": "John Doe",
    "email": "john@example.com",
    "date_of_birth": "1990-01-15",
    "pan_number": "ABCDE1234F",
    "aadhar_number": "123456789012",
    "kyc_status": "submitted"
  }
}
```

**Response when no data exists:**
```json
{
  "personal_details_completed": false,
  "kyc_details_completed": false,
  "kyc_status": "pending"
}
```

---

### 11. Complete Onboarding

**Endpoint:** `POST /api/onboarding/complete/:user_id`

**Description:** Mark onboarding as complete (validates all required fields are filled)

**Request Headers:**
```
Content-Type: application/json
```

**URL Parameters:**
- `user_id` (integer): User ID

**Success Response (200 OK):**
```json
{
  "message": "Onboarding completed successfully",
  "user": {
    // Full user object
  }
}
```

**Error Responses:**

**400 Bad Request - Missing Fields:**
```json
{
  "error": "Please complete all required fields",
  "missing_fields": ["pan_number", "aadhar_number"]
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
  "error": "Failed to complete onboarding"
}
```

---

## Notes

1. **CORS**: The API has CORS enabled, so it can be accessed from any origin (including Flutter apps)

2. **Content-Type**: All requests should include `Content-Type: application/json` header

3. **Password Security**: Passwords are hashed using bcrypt before storage. Never send passwords in GET requests.

4. **Account Numbers**: Automatically generated during registration in format: `GC{timestamp}{random}`

5. **Balance Operations**:
   - `add`: Adds amount to current balance
   - `subtract`: Subtracts amount from current balance (checks for sufficient funds)
   - `set`: Sets balance to exact amount

6. **Date Format**: Use ISO 8601 format (YYYY-MM-DD) for dates

7. **Currency**: Default currency is USD

8. **KYC Status**: 
   - `pending`: Initial status
   - `submitted`: KYC details submitted
   - `verified`: KYC verified (manual process)

9. **PAN Number Format**: Must be exactly 10 characters: 5 uppercase letters, 4 digits, 1 uppercase letter (e.g., ABCDE1234F)

10. **Aadhar Number Format**: Must be exactly 12 digits (e.g., 123456789012)

11. **Onboarding Flow**:
    - Step 1: Register user → Get `user_id`
    - Step 2: Save personal details → `POST /api/onboarding/personal-details`
    - Step 3: Save KYC details → `POST /api/onboarding/kyc-details`
    - Step 4: Complete onboarding → `POST /api/onboarding/complete/:user_id`

---

## Risk Assessment APIs

### 12. Save Risk Assessment

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
  "recommendation": "Balance between stocks and bonds. Consider diversified mutual funds."
}
```

**Validation Rules:**
- `user_id`: Required, must be integer
- `answers`: Required, must be array with exactly 5 answers
- Each answer: `questionId` (1-5), `optionId`, `answerText`, `score` (1-4)
- `total_score`: Required, must be sum of answer scores (5-20)
- `risk_profile`: Required, must be: "Conservative", "Moderate", "Moderately Aggressive", or "Aggressive"

**Success Response (201 Created):**
```json
{
  "message": "Risk assessment saved successfully",
  "assessment": {
    "id": 1,
    "user_id": 1,
    "total_score": 12,
    "risk_profile": "Moderate",
    "recommendation": "Balance between stocks and bonds...",
    "completed_at": "2025-01-15T10:30:00.000Z",
    "answers": [
      {
        "id": 1,
        "question_id": 1,
        "option_id": "q1_opt2",
        "answer_text": "Maintain the capital...",
        "score": 2
      }
      // ... other answers
    ]
  }
}
```

---

### 13. Get Risk Assessment History

**Endpoint:** `GET /api/risk-assessment/:user_id`

**Description:** Get all risk assessments for a user (most recent first)

**Query Parameters:**
- `limit` (optional): Number of assessments (default: 10, max: 50)
- `offset` (optional): Skip number (default: 0)

**Success Response (200 OK):**
```json
{
  "assessments": [
    {
      "id": 1,
      "user_id": 1,
      "total_score": 12,
      "risk_profile": "Moderate",
      "recommendation": "...",
      "completed_at": "2025-01-15T10:30:00.000Z",
      "answers": [...]
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}
```

---

### 14. Get Latest Risk Assessment

**Endpoint:** `GET /api/risk-assessment/:user_id/latest`

**Description:** Get the most recent risk assessment for a user

**Success Response (200 OK):**
```json
{
  "assessment": {
    "id": 1,
    "user_id": 1,
    "total_score": 12,
    "risk_profile": "Moderate",
    "recommendation": "...",
    "completed_at": "2025-01-15T10:30:00.000Z",
    "answers": [...]
  }
}
```

---

### 15. Get Specific Risk Assessment

**Endpoint:** `GET /api/risk-assessment/:user_id/:assessment_id`

**Description:** Get a specific risk assessment by ID

**Success Response (200 OK):**
```json
{
  "assessment": {
    "id": 1,
    "user_id": 1,
    "total_score": 12,
    "risk_profile": "Moderate",
    "recommendation": "...",
    "completed_at": "2025-01-15T10:30:00.000Z",
    "answers": [...]
  }
}
```

**See `RISK_ASSESSMENT_API.md` for complete documentation.**

---

## Roundoff Savings APIs

### 1. Set Roundoff Amount

**Endpoint:** `POST /api/savings/roundoff`

**Description:** Set the roundoff amount preference for a user (₹5, ₹10, ₹20, ₹30, or custom)

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 1,
  "roundoff_amount": 10
}
```

**Validation Rules:**
- `user_id`: Required, must be an integer
- `roundoff_amount`: Required, must be a positive integer (common values: 5, 10, 20, 30, or any custom amount)

**Success Response (200 OK):**
```json
{
  "message": "Roundoff amount updated successfully",
  "setting": {
    "id": 1,
    "user_id": 1,
    "roundoff_amount": 10,
    "is_active": true,
    "created_at": "2025-01-15T10:00:00.000Z",
    "updated_at": "2025-01-15T10:00:00.000Z"
  }
}
```

**Error Responses:**
- `400 Bad Request`: Validation errors
- `404 Not Found`: User not found
- `500 Internal Server Error`: Server error

---

### 2. Upload Bank Statement PDF

**Endpoint:** `POST /api/savings/upload`

**Description:** Upload a bank statement PDF and extract withdrawal transactions to calculate roundoff savings

**Request Headers:**
```
Content-Type: multipart/form-data
```

**Request Body (Form Data):**
- `statement`: PDF file (required, max 10MB)
- `user_id`: Integer (required)

**Success Response (200 OK):**
```json
{
  "message": "Bank statement processed successfully",
  "statement_id": 1,
  "transactions_processed": 25,
  "summary": {
    "totalRoundoff": 125.50,
    "transactionCount": 25,
    "totalWithdrawn": 5000.00,
    "totalRounded": 5125.50,
    "averageRoundoff": 5.02,
    "roundoff_amount": 10
  },
  "projections": {
    "daily": {
      "transactions": 0.83,
      "savings": 4.18
    },
    "monthly": {
      "transactions": 25,
      "savings": 125.50
    },
    "yearly": {
      "transactions": 304.17,
      "savings": 1525.70
    },
    "period": {
      "days": 30,
      "transactions": 25,
      "savings": 125.50
    }
  },
  "insights": "🎉 In 30 days, you could have saved ₹125.50 through 25 transactions!\n📈 At this rate, you could save ₹125.50 per month!\n💰 That's ₹1525.70 in a year!\n☕ That's enough for 10 coffees!\n🎬 Or 6 movie tickets!\n🍽️ Or 5 meals out!"
}
```

**Error Responses:**
- `400 Bad Request`: Missing file, invalid PDF, or no transactions found
- `404 Not Found`: User not found
- `500 Internal Server Error`: Server error

**cURL Example:**
```bash
curl -X POST http://localhost:3001/api/savings/upload \
  -F "statement=@/path/to/bank_statement.pdf" \
  -F "user_id=1"
```

---

### 3. Get Savings Summary

**Endpoint:** `GET /api/savings/summary/:user_id`

**Description:** Get total savings summary for a user

**URL Parameters:**
- `user_id`: Integer (required)

**Success Response (200 OK):**
```json
{
  "total_savings": 125.50,
  "transaction_count": 25,
  "total_withdrawn": 5000.00,
  "total_rounded": 5125.50,
  "average_roundoff": 5.02,
  "roundoff_amount": 10,
  "date_range": {
    "start": "2024-12-01",
    "end": "2024-12-30",
    "days": 30
  },
  "projections": {
    "daily": {
      "transactions": 0.83,
      "savings": 4.18
    },
    "monthly": {
      "transactions": 25,
      "savings": 125.50
    },
    "yearly": {
      "transactions": 304.17,
      "savings": 1525.70
    },
    "period": {
      "days": 30,
      "transactions": 25,
      "savings": 125.50
    }
  },
  "insights": "🎉 In 30 days, you could have saved ₹125.50 through 25 transactions!\n📈 At this rate, you could save ₹125.50 per month!\n💰 That's ₹1525.70 in a year!\n☕ That's enough for 10 coffees!\n🎬 Or 6 movie tickets!\n🍽️ Or 5 meals out!"
}
```

**Empty Response (No Transactions):**
```json
{
  "total_savings": 0,
  "transaction_count": 0,
  "roundoff_amount": 10,
  "message": "No transactions found. Upload a bank statement to get started!"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid user_id
- `404 Not Found`: User not found
- `500 Internal Server Error`: Server error

---

### 4. Get Transactions

**Endpoint:** `GET /api/savings/transactions/:user_id`

**Description:** Get paginated list of withdrawal transactions

**URL Parameters:**
- `user_id`: Integer (required)

**Query Parameters:**
- `limit`: Integer (optional, default: 50)
- `offset`: Integer (optional, default: 0)

**Success Response (200 OK):**
```json
{
  "transactions": [
    {
      "id": 1,
      "transaction_date": "2024-12-15",
      "description": "ATM Withdrawal",
      "amount": "250.00",
      "roundoff_amount": "0.00",
      "rounded_amount": "250.00",
      "created_at": "2025-01-15T10:00:00.000Z"
    },
    {
      "id": 2,
      "transaction_date": "2024-12-16",
      "description": "Cash Withdrawal",
      "amount": "175.50",
      "roundoff_amount": "4.50",
      "rounded_amount": "180.00",
      "created_at": "2025-01-15T10:00:00.000Z"
    }
  ],
  "total": 25,
  "limit": 50,
  "offset": 0
}
```

**Error Responses:**
- `400 Bad Request`: Invalid user_id
- `500 Internal Server Error`: Server error

---

### 5. Get Insights

**Endpoint:** `GET /api/savings/insights/:user_id`

**Description:** Get detailed savings insights and projections

**URL Parameters:**
- `user_id`: Integer (required)

**Success Response (200 OK):**
```json
{
  "summary": {
    "totalRoundoff": 125.50,
    "transactionCount": 25,
    "totalWithdrawn": 5000.00,
    "totalRounded": 5125.50,
    "averageRoundoff": 5.02,
    "roundoff_amount": 10
  },
  "projections": {
    "daily": {
      "transactions": 0.83,
      "savings": 4.18
    },
    "monthly": {
      "transactions": 25,
      "savings": 125.50
    },
    "yearly": {
      "transactions": 304.17,
      "savings": 1525.70
    },
    "period": {
      "days": 30,
      "transactions": 25,
      "savings": 125.50
    }
  },
  "insights": [
    "🎉 In 30 days, you could have saved ₹125.50 through 25 transactions!",
    "📈 At this rate, you could save ₹125.50 per month!",
    "💰 That's ₹1525.70 in a year!",
    "☕ That's enough for 10 coffees!",
    "🎬 Or 6 movie tickets!",
    "🍽️ Or 5 meals out!"
  ],
  "date_range": {
    "start": "2024-12-01",
    "end": "2024-12-30",
    "days": 30
  }
}
```

**Error Responses:**
- `400 Bad Request`: Invalid user_id
- `500 Internal Server Error`: Server error

---

### 6. Get Roundoff Setting

**Endpoint:** `GET /api/savings/roundoff/:user_id`

**Description:** Get the current roundoff amount setting for a user

**URL Parameters:**
- `user_id`: Integer (required)

**Success Response (200 OK):**
```json
{
  "setting": {
    "id": 1,
    "user_id": 1,
    "roundoff_amount": 10,
    "is_active": true,
    "created_at": "2025-01-15T10:00:00.000Z",
    "updated_at": "2025-01-15T10:00:00.000Z"
  }
}
```

**Default Response (No Setting):**
```json
{
  "user_id": 1,
  "roundoff_amount": 10,
  "is_active": true
}
```

**Error Responses:**
- `400 Bad Request`: Invalid user_id
- `500 Internal Server Error`: Server error

---

## How Roundoff Savings Works

1. **User sets roundoff amount**: Choose ₹5, ₹10, ₹20, ₹30, or any custom amount
2. **Upload bank statement**: PDF is parsed to extract withdrawal transactions
3. **Calculate roundoff**: For each withdrawal, round up to nearest roundoff amount
4. **Accumulate savings**: All roundoff amounts are summed up
5. **Generate insights**: Show potential savings with projections

**Example:**
- Withdrawal: ₹175.50
- Roundoff amount: ₹10
- Rounded amount: ₹180.00
- Roundoff savings: ₹4.50

This ₹4.50 is added to the user's total savings, and insights show how much they could save over time!

