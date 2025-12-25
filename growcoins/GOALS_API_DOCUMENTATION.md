# Goals API Documentation

## 📋 Overview

The Goals API allows users to create, manage, and track financial goals. Users can select from predefined categories, set target amounts and timelines, and track their progress.

---

## 🗄️ Database Schema

### Tables Required

1. **`goal_categories`** - Stores available goal categories
2. **`goals`** - Stores user goals
3. **`roundoff_settings`** - Stores user roundoff preferences (already exists)
4. **`invest_profiles`** - Stores user investment profile settings

---

## 📡 API Endpoints

### Base URL
```
http://localhost:3001/api/goals
```

---

## 1. Check User Setup Status

**Endpoint:** `GET /api/goals/setup-status/{userId}`

**Description:** Check if user has completed goal setup, roundoff setup, and invest profile setup

**Response:**
```json
{
  "user_id": 1,
  "has_goal": false,
  "has_roundoff_setting": false,
  "has_invest_profile": false,
  "setup_complete": false,
  "goals_count": 0,
  "roundoff_setting": null,
  "invest_profile": null
}
```

**Response (User with all setups):**
```json
{
  "user_id": 1,
  "has_goal": true,
  "has_roundoff_setting": true,
  "has_invest_profile": true,
  "setup_complete": true,
  "goals_count": 2,
  "roundoff_setting": {
    "id": 1,
    "user_id": 1,
    "roundoff_amount": 10,
    "is_active": true,
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z"
  },
  "invest_profile": {
    "id": 1,
    "user_id": 1,
    "risk_profile": "Moderate",
    "investment_preference": "Balanced",
    "created_at": "2025-01-15T10:30:00.000Z"
  }
}
```

---

## 2. Get Goal Categories

**Endpoint:** `GET /api/goals/categories`

**Description:** Get all available goal categories

**Response:**
```json
{
  "categories": [
    {
      "id": 1,
      "name": "Phone",
      "icon": "phone",
      "icon_type": "material",
      "color": "#2196F3",
      "description": "Save for a new phone",
      "is_active": true
    },
    {
      "id": 2,
      "name": "Gadget",
      "icon": "camera",
      "icon_type": "material",
      "color": "#9C27B0",
      "description": "Save for gadgets and electronics",
      "is_active": true
    },
    {
      "id": 3,
      "name": "Car",
      "icon": "directions_car",
      "icon_type": "material",
      "color": "#FF5722",
      "description": "Save for a car",
      "is_active": true
    },
    {
      "id": 4,
      "name": "Domestic Trip",
      "icon": "landscape",
      "icon_type": "material",
      "color": "#4CAF50",
      "description": "Save for domestic travel",
      "is_active": true
    },
    {
      "id": 5,
      "name": "International Trip",
      "icon": "flight",
      "icon_type": "material",
      "color": "#00BCD4",
      "description": "Save for international travel",
      "is_active": true
    },
    {
      "id": 6,
      "name": "Party",
      "icon": "celebration",
      "icon_type": "material",
      "color": "#FF9800",
      "description": "Save for parties and events",
      "is_active": true
    },
    {
      "id": 7,
      "name": "Home",
      "icon": "home",
      "icon_type": "material",
      "color": "#795548",
      "description": "Save for home-related expenses",
      "is_active": true
    },
    {
      "id": 8,
      "name": "Birthday",
      "icon": "cake",
      "icon_type": "material",
      "color": "#E91E63",
      "description": "Save for birthday celebrations",
      "is_active": true
    },
    {
      "id": 9,
      "name": "Other",
      "icon": "person",
      "icon_type": "material",
      "color": "#607D8B",
      "description": "Custom goal category",
      "is_active": true
    }
  ]
}
```

---

## 3. Get User Goals

**Endpoint:** `GET /api/goals/user/{userId}`

**Description:** Get all goals for a user

**Query Parameters:**
- `status` (optional): Filter by status (`active`, `completed`, `paused`, `cancelled`)
- `limit` (optional): Number of results (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
  "goals": [
    {
      "id": 1,
      "user_id": 1,
      "category_id": 1,
      "category_name": "Phone",
      "category_icon": "phone",
      "goal_name": "iPhone 15 Pro",
      "target_amount": 80000,
      "current_amount": 25000,
      "target_date": "2025-06-15",
      "status": "active",
      "created_at": "2025-01-15T10:30:00.000Z",
      "updated_at": "2025-01-15T10:30:00.000Z",
      "progress_percentage": 31.25
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

**Response (No goals):**
```json
{
  "goals": [],
  "total": 0,
  "limit": 50,
  "offset": 0
}
```

---

## 4. Create Goal

**Endpoint:** `POST /api/goals`

**Description:** Create a new goal

**Request Body:**
```json
{
  "user_id": 1,
  "category_id": 1,
  "goal_name": "iPhone 15 Pro",
  "target_amount": 80000,
  "target_date": "2025-06-15",
  "initial_amount": 0
}
```

**Validation Rules:**
- `user_id`: Required, must be integer
- `category_id`: Required, must be valid category ID
- `goal_name`: Required, string, min 3 characters, max 100 characters
- `target_amount`: Required, must be positive number, min 100
- `target_date`: Required, must be future date (ISO 8601 format: YYYY-MM-DD)
- `initial_amount`: Optional, default 0, must be non-negative

**Response:**
```json
{
  "success": true,
  "message": "Goal created successfully",
  "goal": {
    "id": 1,
    "user_id": 1,
    "category_id": 1,
    "category_name": "Phone",
    "category_icon": "phone",
    "goal_name": "iPhone 15 Pro",
    "target_amount": 80000,
    "current_amount": 0,
    "target_date": "2025-06-15",
    "status": "active",
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z",
    "progress_percentage": 0
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Validation error",
  "errors": [
    {
      "field": "target_amount",
      "msg": "Target amount must be at least ₹100"
    }
  ]
}
```

---

## 5. Update Goal

**Endpoint:** `PUT /api/goals/{goalId}`

**Description:** Update an existing goal

**Request Body:**
```json
{
  "goal_name": "iPhone 15 Pro Max",
  "target_amount": 100000,
  "target_date": "2025-07-15",
  "status": "active"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Goal updated successfully",
  "goal": {
    "id": 1,
    "user_id": 1,
    "category_id": 1,
    "goal_name": "iPhone 15 Pro Max",
    "target_amount": 100000,
    "current_amount": 25000,
    "target_date": "2025-07-15",
    "status": "active",
    "updated_at": "2025-01-15T11:00:00.000Z",
    "progress_percentage": 25
  }
}
```

---

## 6. Delete Goal

**Endpoint:** `DELETE /api/goals/{goalId}`

**Description:** Delete a goal (soft delete by setting status to 'cancelled')

**Response:**
```json
{
  "success": true,
  "message": "Goal deleted successfully"
}
```

---

## 7. Get Goal Details

**Endpoint:** `GET /api/goals/{goalId}`

**Description:** Get detailed information about a specific goal

**Response:**
```json
{
  "goal": {
    "id": 1,
    "user_id": 1,
    "category_id": 1,
    "category_name": "Phone",
    "category_icon": "phone",
    "goal_name": "iPhone 15 Pro",
    "target_amount": 80000,
    "current_amount": 25000,
    "target_date": "2025-06-15",
    "status": "active",
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z",
    "progress_percentage": 31.25,
    "days_remaining": 151,
    "monthly_savings_needed": 3636.36
  }
}
```

---

## 8. Check Roundoff Setting

**Endpoint:** `GET /api/savings/roundoff/{userId}`

**Description:** Check if user has roundoff setting configured (already exists)

**Response:**
```json
{
  "setting": {
    "id": 1,
    "user_id": 1,
    "roundoff_amount": 10,
    "is_active": true,
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z"
  }
}
```

**Response (No setting):**
```json
{
  "setting": null
}
```

---

## 9. Check Invest Profile

**Endpoint:** `GET /api/invest/profile/{userId}`

**Description:** Check if user has investment profile configured

**Response:**
```json
{
  "profile": {
    "id": 1,
    "user_id": 1,
    "risk_profile": "Moderate",
    "investment_preference": "Balanced",
    "auto_invest_enabled": true,
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z"
  }
}
```

**Response (No profile):**
```json
{
  "profile": null
}
```

---

## 📊 Goal Status Values

- `active` - Goal is active and being tracked
- `completed` - Goal target has been reached
- `paused` - Goal is temporarily paused
- `cancelled` - Goal has been cancelled

---

## 🔄 Frontend Flow

1. **Home Screen** → Check setup status
   - If no goal → Show "Onboarding Setup Profile" screen
   - If has goal → Show normal home screen

2. **Onboarding Setup Profile Screen** → User can:
   - Setup Goal → Navigate to Category Selection
   - Setup Roundoff → Navigate to Roundoff Settings (Savings Screen)
   - Setup Invest Profile → Navigate to Investment Profile Setup

3. **Category Selection Screen** → User selects category → Navigate to Goal Configuration

4. **Goal Configuration Screen** → User enters:
   - Goal Name (pre-filled with category name)
   - Target Amount
   - Target Time (6M, 9M, 1Y) → Converts to target_date
   - Submit → Create goal → Navigate back to Home

---

## 💡 Implementation Notes

1. **Target Time Conversion:**
   - "6M" = 6 months from today
   - "9M" = 9 months from today
   - "1Y" = 1 year from today

2. **Progress Calculation:**
   - `progress_percentage = (current_amount / target_amount) * 100`

3. **Monthly Savings Calculation:**
   - `monthly_savings_needed = (target_amount - current_amount) / months_remaining`

4. **Days Remaining:**
   - `days_remaining = target_date - today`

5. **Default Values:**
   - `status`: "active"
   - `current_amount`: 0
   - `initial_amount`: 0

---

## 🚨 Error Handling

All endpoints should return appropriate HTTP status codes:
- `200` - Success
- `400` - Bad Request (validation errors)
- `401` - Unauthorized
- `404` - Not Found
- `500` - Internal Server Error

Error response format:
```json
{
  "success": false,
  "error": "Error message",
  "errors": [
    {
      "field": "field_name",
      "msg": "Error message for this field"
    }
  ]
}
```

