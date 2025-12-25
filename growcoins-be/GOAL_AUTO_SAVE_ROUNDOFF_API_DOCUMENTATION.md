# Goal Auto-Save and Auto-Roundoff API Documentation

This document describes the backend API requirements for configuring Auto-Save and Auto-Roundoff features for goals.

---

## Table of Contents

1. [Auto-Save Configuration](#auto-save-configuration)
2. [Auto-Roundoff Configuration](#auto-roundoff-configuration)
3. [Goal Configuration Status](#goal-configuration-status)
4. [Database Schema](#database-schema)
5. [Implementation Guide](#implementation-guide)

---

## Auto-Save Configuration

### Overview
Auto-Save allows users to configure recurring payments (daily, weekly, or monthly) linked to their goals. The system automatically debits the specified amount at the selected frequency to accelerate goal achievement.

### 1. Update/Create Auto-Save Configuration

**Endpoint:** `PUT /api/investment-plan/auto-save`

**Description:** Updates or creates an auto-save configuration for a goal. If an investment plan doesn't exist for the goal, it should be created first.

**Request Body:**
```json
{
  "user_id": 1,
  "goal_id": 123,
  "frequency": "daily",  // Required: "daily", "weekly", or "monthly"
  "monthly_amount": 3000.0,  // Required: Amount in INR
  "duration_months": 18  // Optional: Duration in months (default: calculated from goal target date)
}
```

**Request Parameters:**
- `user_id` (integer, required): User ID
- `goal_id` (integer, optional): Goal ID to link auto-save to a specific goal
- `frequency` (string, required): Recurrence frequency - must be one of: "daily", "weekly", "monthly"
- `monthly_amount` (float, required): Monthly savings amount in INR (minimum: 100)
- `duration_months` (integer, optional): Duration in months (if not provided, calculated from goal's target date)

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Auto-save configuration updated successfully",
  "plan": {
    "id": 1,
    "user_id": 1,
    "goal_id": 123,
    "risk_profile": "moderate",
    "risk_profile_display": "Moderate Risk Investor",
    "auto_save": {
      "frequency": "daily",
      "monthly_amount": 3000.0,
      "weekly_amount": 692.31,
      "daily_amount": 100.0,
      "duration_months": 18
    },
    "portfolio": {
      "allocations": [
        {
          "fund_id": 1,
          "fund_name": "Mutual Fund Equity 1",
          "fund_type": "Equity",
          "percentage": 40.0,
          "amount": 1200.0
        },
        {
          "fund_id": 2,
          "fund_name": "Mutual Fund Debt 2",
          "fund_type": "Debt",
          "percentage": 35.0,
          "amount": 1050.0
        },
        {
          "fund_id": 3,
          "fund_name": "Mutual Fund Balanced 3",
          "fund_type": "Balanced",
          "percentage": 25.0,
          "amount": 750.0
        }
      ]
    },
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "error": "Validation error",
  "errors": [
    {
      "field": "frequency",
      "msg": "Frequency must be daily, weekly, or monthly"
    }
  ]
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "error": "Goal not found"
}
```

**Response (Error - 500):**
```json
{
  "success": false,
  "error": "Failed to update auto-save configuration"
}
```

**Implementation Notes:**
1. If `goal_id` is provided, check if the goal exists and belongs to the user
2. Calculate `weekly_amount` = `monthly_amount / 4.33`
3. Calculate `daily_amount` = `monthly_amount / 30`
4. If `duration_months` is not provided, calculate from goal's target date:
   ```javascript
   const targetDate = new Date(goal.target_date);
   const today = new Date();
   const monthsDiff = (targetDate.getFullYear() - today.getFullYear()) * 12 + 
                      (targetDate.getMonth() - today.getMonth());
   duration_months = Math.max(1, monthsDiff);
   ```
5. If investment plan doesn't exist for the goal, create one with default risk profile or user's risk profile
6. Update the investment plan's `auto_save` configuration
7. Recalculate portfolio allocation if needed based on the new monthly amount

---

### 2. Get Auto-Save Configuration

**Endpoint:** `GET /api/investment-plan/user/:userId?goal_id=:goalId`

**Description:** Retrieves the auto-save configuration for a user, optionally filtered by goal ID.

**Query Parameters:**
- `goal_id` (integer, optional): Filter by specific goal ID

**Response (Success - 200):**
```json
{
  "success": true,
  "plan": {
    "id": 1,
    "user_id": 1,
    "goal_id": 123,
    "risk_profile": "moderate",
    "risk_profile_display": "Moderate Risk Investor",
    "auto_save": {
      "frequency": "daily",
      "monthly_amount": 3000.0,
      "weekly_amount": 692.31,
      "daily_amount": 100.0,
      "duration_months": 18
    },
    "portfolio": {
      "allocations": [...]
    },
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z"
  }
}
```

**Response (Not Found - 404):**
```json
{
  "success": false,
  "error": "Investment plan not found"
}
```

---

## Auto-Roundoff Configuration

### Overview
Auto-Roundoff automatically rounds up transaction amounts to the nearest specified value (e.g., ₹5, ₹10, ₹50) and invests the difference into the linked goal. This feature helps users save small amounts with every transaction.

### 1. Set Auto-Roundoff Amount

**Endpoint:** `POST /api/savings/roundoff`

**Description:** Sets or updates the auto-roundoff amount for a user. This is a user-level setting that applies to all transactions.

**Request Body:**
```json
{
  "user_id": 1,
  "roundoff_amount": 5,  // Required: 5, 10, 20, 30, or custom positive integer
  "goal_id": 123  // Optional: Link roundoff savings to a specific goal
}
```

**Request Parameters:**
- `user_id` (integer, required): User ID
- `roundoff_amount` (integer, required): Roundoff amount in INR. Valid values: 5, 10, 20, 30, or any custom positive integer
- `goal_id` (integer, optional): Goal ID to link roundoff savings to a specific goal

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Roundoff amount updated successfully",
  "setting": {
    "id": 1,
    "user_id": 1,
    "roundoff_amount": 5,
    "goal_id": 123,
    "is_active": true,
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "error": "Validation error",
  "errors": [
    {
      "field": "roundoff_amount",
      "msg": "Roundoff amount must be a positive integer"
    }
  ]
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "error": "User not found"
}
```

**Response (Error - 500):**
```json
{
  "success": false,
  "error": "Failed to update roundoff amount"
}
```

**Implementation Notes:**
1. Validate that `roundoff_amount` is a positive integer (minimum: 1)
2. If `goal_id` is provided, verify the goal exists and belongs to the user
3. Use `INSERT ... ON CONFLICT` to update existing setting or create new one
4. If `goal_id` is provided, link the roundoff savings to that goal
5. Set `is_active` to `true` by default

---

### 2. Get Auto-Roundoff Setting

**Endpoint:** `GET /api/savings/roundoff/:userId`

**Description:** Retrieves the auto-roundoff setting for a user.

**Response (Success - 200):**
```json
{
  "success": true,
  "setting": {
    "id": 1,
    "user_id": 1,
    "roundoff_amount": 5,
    "goal_id": 123,
    "is_active": true,
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z"
  }
}
```

**Response (Not Found - 404):**
```json
{
  "success": false,
  "setting": null,
  "message": "Roundoff setting not found"
}
```

---

### 3. Update Auto-Roundoff Setting

**Endpoint:** `PUT /api/savings/roundoff/:userId`

**Description:** Updates the auto-roundoff setting for a user.

**Request Body:**
```json
{
  "roundoff_amount": 10,
  "goal_id": 123,
  "is_active": true
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Roundoff setting updated successfully",
  "setting": {
    "id": 1,
    "user_id": 1,
    "roundoff_amount": 10,
    "goal_id": 123,
    "is_active": true,
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T11:00:00.000Z"
  }
}
```

---

## Goal Configuration Status

### Get Goal Configuration Status

**Endpoint:** `GET /api/goals/:goalId/configuration`

**Description:** Retrieves the configuration status for a goal, including auto-save, auto-roundoff, and investment plan status.

**Response (Success - 200):**
```json
{
  "success": true,
  "goal_id": 123,
  "has_auto_save": true,
  "has_auto_roundoff": true,
  "has_investment_plan": true,
  "auto_save": {
    "frequency": "daily",
    "monthly_amount": 3000.0,
    "weekly_amount": 692.31,
    "daily_amount": 100.0
  },
  "auto_roundoff": {
    "roundoff_amount": 5,
    "is_active": true,
    "goal_id": 123
  },
  "investment_plan": {
    "id": 1,
    "risk_profile": "moderate",
    "portfolio_funds_count": 3
  }
}
```

**Response (Not Found - 404):**
```json
{
  "success": false,
  "error": "Goal not found"
}
```

---

## Database Schema

### Investment Plans Table
```sql
CREATE TABLE IF NOT EXISTS investment_plans (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
  goal_id INTEGER REFERENCES goals(id) ON DELETE SET NULL,
  risk_profile VARCHAR(50) NOT NULL,
  risk_profile_display VARCHAR(100),
  auto_save_config JSONB,
  portfolio_allocation JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, goal_id)
);

-- Index for faster lookups
CREATE INDEX idx_investment_plans_user_id ON investment_plans(user_id);
CREATE INDEX idx_investment_plans_goal_id ON investment_plans(goal_id);
```

### Roundoff Settings Table
```sql
CREATE TABLE IF NOT EXISTS roundoff_settings (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE REFERENCES authentication(id) ON DELETE CASCADE,
  roundoff_amount INTEGER NOT NULL CHECK (roundoff_amount > 0),
  goal_id INTEGER REFERENCES goals(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster lookups
CREATE INDEX idx_roundoff_settings_user_id ON roundoff_settings(user_id);
CREATE INDEX idx_roundoff_settings_goal_id ON roundoff_settings(goal_id);
```

### Auto-Save Config JSON Structure
```json
{
  "frequency": "daily" | "weekly" | "monthly",
  "monthly_amount": 3000.0,
  "weekly_amount": 692.31,
  "daily_amount": 100.0,
  "duration_months": 18
}
```

---

## Implementation Guide

### Backend Routes

#### 1. Auto-Save Routes (in `routes/investmentPlan.js`)

```javascript
// Update/Create Auto-Save Configuration
router.put('/auto-save', [
  body('user_id').isInt().withMessage('User ID is required'),
  body('goal_id').optional().isInt().withMessage('Goal ID must be an integer'),
  body('frequency').isIn(['daily', 'weekly', 'monthly']).withMessage('Frequency must be daily, weekly, or monthly'),
  body('monthly_amount').isFloat({ min: 100 }).withMessage('Monthly amount must be at least ₹100'),
  body('duration_months').optional().isInt({ min: 1 }).withMessage('Duration must be a positive integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: errors.array().map(e => ({ field: e.param, msg: e.msg }))
      });
    }

    const { user_id, goal_id, frequency, monthly_amount, duration_months } = req.body;

    // Validate goal if provided
    if (goal_id) {
      const goalCheck = await query('SELECT * FROM goals WHERE id = $1 AND user_id = $2', [goal_id, user_id]);
      if (goalCheck.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Goal not found' });
      }
    }

    // Calculate weekly and daily amounts
    const weekly_amount = monthly_amount / 4.33;
    const daily_amount = monthly_amount / 30;

    // Calculate duration if not provided
    let finalDuration = duration_months;
    if (!finalDuration && goal_id) {
      const goal = await query('SELECT target_date FROM goals WHERE id = $1', [goal_id]);
      if (goal.rows.length > 0) {
        const targetDate = new Date(goal.rows[0].target_date);
        const today = new Date();
        const monthsDiff = (targetDate.getFullYear() - today.getFullYear()) * 12 + 
                          (targetDate.getMonth() - today.getMonth());
        finalDuration = Math.max(1, monthsDiff);
      }
    }

    const autoSaveConfig = {
      frequency,
      monthly_amount,
      weekly_amount: Math.round(weekly_amount * 100) / 100,
      daily_amount: Math.round(daily_amount * 100) / 100,
      duration_months: finalDuration || 18
    };

    // Find or create investment plan
    let result;
    if (goal_id) {
      result = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id = $2',
        [user_id, goal_id]
      );
    } else {
      result = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id IS NULL',
        [user_id]
      );
    }

    if (result.rows.length === 0) {
      // Create new investment plan
      // Get user's risk profile or use default
      const userProfile = await query(
        'SELECT risk_profile FROM invest_profiles WHERE user_id = $1',
        [user_id]
      );
      const riskProfile = userProfile.rows.length > 0 
        ? userProfile.rows[0].risk_profile 
        : 'moderate';

      // Create plan with default portfolio (you'll need to implement portfolio generation)
      const newPlan = await query(
        `INSERT INTO investment_plans (user_id, goal_id, risk_profile, auto_save_config, portfolio_allocation)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [user_id, goal_id, riskProfile, JSON.stringify(autoSaveConfig), JSON.stringify({ allocations: [] })]
      );
      
      return res.json({
        success: true,
        message: 'Auto-save configuration created successfully',
        plan: formatInvestmentPlan(newPlan.rows[0])
      });
    } else {
      // Update existing plan
      const updatedPlan = await query(
        `UPDATE investment_plans 
         SET auto_save_config = $1, updated_at = CURRENT_TIMESTAMP
         WHERE user_id = $2 AND (goal_id = $3 OR (goal_id IS NULL AND $3 IS NULL))
         RETURNING *`,
        [JSON.stringify(autoSaveConfig), user_id, goal_id]
      );

      return res.json({
        success: true,
        message: 'Auto-save configuration updated successfully',
        plan: formatInvestmentPlan(updatedPlan.rows[0])
      });
    }
  } catch (error) {
    console.error('Update auto-save error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update auto-save configuration'
    });
  }
});
```

#### 2. Auto-Roundoff Routes (in `routes/savings.js`)

```javascript
// Set Roundoff Amount (Enhanced with goal_id)
router.post('/roundoff', [
  body('user_id').isInt().withMessage('User ID is required'),
  body('roundoff_amount').isInt({ min: 1 }).withMessage('Roundoff amount must be a positive integer'),
  body('goal_id').optional().isInt().withMessage('Goal ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: errors.array().map(e => ({ field: e.param, msg: e.msg }))
      });
    }

    const { user_id, roundoff_amount, goal_id } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Validate goal if provided
    if (goal_id) {
      const goalCheck = await query('SELECT * FROM goals WHERE id = $1 AND user_id = $2', [goal_id, user_id]);
      if (goalCheck.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Goal not found' });
      }
    }

    // Insert or update roundoff setting
    const result = await query(
      `INSERT INTO roundoff_settings (user_id, roundoff_amount, goal_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id) 
       DO UPDATE SET 
         roundoff_amount = $2, 
         goal_id = $3,
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [user_id, roundoff_amount, goal_id]
    );

    res.json({
      success: true,
      message: 'Roundoff amount updated successfully',
      setting: result.rows[0]
    });
  } catch (error) {
    console.error('Set roundoff error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update roundoff amount'
    });
  }
});

// Get Roundoff Setting (Enhanced)
router.get('/roundoff/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const result = await query(
      'SELECT * FROM roundoff_settings WHERE user_id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.json({
        success: true,
        setting: null,
        message: 'Roundoff setting not found'
      });
    }

    res.json({
      success: true,
      setting: result.rows[0]
    });
  } catch (error) {
    console.error('Get roundoff error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get roundoff setting'
    });
  }
});
```

---

## cURL Examples

### Update Auto-Save Configuration
```bash
curl -X PUT http://localhost:3001/api/investment-plan/auto-save \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "goal_id": 123,
    "frequency": "daily",
    "monthly_amount": 3000.0
  }'
```

### Set Auto-Roundoff Amount
```bash
curl -X POST http://localhost:3001/api/savings/roundoff \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "roundoff_amount": 5,
    "goal_id": 123
  }'
```

### Get Roundoff Setting
```bash
curl -X GET http://localhost:3001/api/savings/roundoff/1
```

---

## Error Handling

All endpoints should handle the following error cases:

1. **Validation Errors (400)**: Invalid input parameters
2. **Not Found (404)**: User, goal, or resource not found
3. **Unauthorized (401)**: User not authenticated
4. **Server Error (500)**: Internal server errors

All error responses should follow this format:
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

---

## Notes

1. **Auto-Save Frequency**: The system calculates `weekly_amount` and `daily_amount` from `monthly_amount` automatically
2. **Goal Linking**: Both auto-save and auto-roundoff can be linked to specific goals
3. **User-Level Settings**: Auto-roundoff is a user-level setting (one per user), while auto-save can be configured per goal
4. **Transaction Processing**: The actual processing of auto-save and auto-roundoff transactions should be handled by a separate service/cron job
5. **Portfolio Recalculation**: When auto-save amount changes, the portfolio allocation may need to be recalculated based on the new monthly investment amount

---

## Testing Checklist

- [ ] Create auto-save configuration for a goal
- [ ] Update existing auto-save configuration
- [ ] Get auto-save configuration for a goal
- [ ] Set auto-roundoff amount (5, 10, 20, 30, custom)
- [ ] Link auto-roundoff to a specific goal
- [ ] Get roundoff setting for a user
- [ ] Update roundoff setting
- [ ] Validate error handling for invalid inputs
- [ ] Validate error handling for non-existent resources
- [ ] Test with and without goal_id parameter

