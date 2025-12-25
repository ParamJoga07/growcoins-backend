# Investment Plan API - Complete Backend Documentation

## 📋 Overview

The Investment Plan API allows users to generate personalized investment plans based on their risk profile, configure auto-save settings, create payment mandates, and complete the investment setup process.

---

## 🗄️ Database Schema

### Required Tables

#### 1. `investment_plans` Table

```sql
CREATE TABLE IF NOT EXISTS investment_plans (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
  goal_id INTEGER REFERENCES goals(id) ON DELETE SET NULL,
  risk_profile VARCHAR(50) NOT NULL, -- 'Conservative', 'Moderate', 'Moderately Aggressive', 'Aggressive'
  risk_profile_display VARCHAR(100), -- e.g., "Capital Protection Investor"
  auto_save_config JSONB NOT NULL, -- Stores frequency, monthly_amount, duration_months, etc.
  portfolio_allocation JSONB NOT NULL, -- Stores mutual fund allocations
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'cancelled'
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, goal_id)
);

CREATE INDEX idx_investment_plans_user_id ON investment_plans(user_id);
CREATE INDEX idx_investment_plans_goal_id ON investment_plans(goal_id);
```

**auto_save_config JSONB Structure:**
```json
{
  "frequency": "monthly", // 'monthly', 'weekly', 'daily'
  "monthly_amount": 5000.00,
  "duration_months": 18,
  "weekly_amount": 1153.81, // Optional: calculated from monthly
  "daily_amount": 166.67 // Optional: calculated from monthly
}
```

**portfolio_allocation JSONB Structure:**
```json
{
  "description": "According to your Risk Folio, We have curated the best investment portfolio",
  "allocations": [
    {
      "scheme_code": 123456,
      "scheme_name": "HDFC Equity Fund - Direct Plan",
      "category": "Equity",
      "percentage": 60.0,
      "amount": 3000.00,
      "fund_details": {
        "scheme_code": 123456,
        "scheme_name": "HDFC Equity Fund - Direct Plan",
        "fund_house": "HDFC Mutual Fund",
        "scheme_type": "Open Ended",
        "scheme_category": "Equity",
        "category": "Equity",
        "risk_level": "Moderately High",
        "annualized_return": 15.5,
        "latest_nav": 125.50,
        "plan_type": "Direct",
        "rating": 4.5
      }
    },
    {
      "scheme_code": 789012,
      "scheme_name": "ICICI Prudential Debt Fund - Direct Plan",
      "category": "Debt",
      "percentage": 40.0,
      "amount": 2000.00,
      "fund_details": {
        "scheme_code": 789012,
        "scheme_name": "ICICI Prudential Debt Fund - Direct Plan",
        "fund_house": "ICICI Prudential Mutual Fund",
        "scheme_type": "Open Ended",
        "scheme_category": "Debt",
        "category": "Debt",
        "risk_level": "Low",
        "annualized_return": 7.2,
        "latest_nav": 45.30,
        "plan_type": "Direct",
        "rating": 4.0
      }
    }
  ]
}
```

#### 2. `payment_mandates` Table

```sql
CREATE TABLE IF NOT EXISTS payment_mandates (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
  goal_id INTEGER REFERENCES goals(id) ON DELETE SET NULL,
  investment_plan_id INTEGER REFERENCES investment_plans(id) ON DELETE CASCADE,
  bank_account_number VARCHAR(50) NOT NULL,
  ifsc_code VARCHAR(11) NOT NULL,
  account_holder_name VARCHAR(255) NOT NULL,
  mandate_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'active', 'cancelled', 'expired'
  mandate_reference VARCHAR(100), -- Reference from payment gateway
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  activated_at TIMESTAMP
);

CREATE INDEX idx_payment_mandates_user_id ON payment_mandates(user_id);
CREATE INDEX idx_payment_mandates_goal_id ON payment_mandates(goal_id);
CREATE INDEX idx_payment_mandates_plan_id ON payment_mandates(investment_plan_id);
```

---

## 📡 API Endpoints

### Base URL
```
http://localhost:3001/api/investment-plan
```

---

### 1. Generate Investment Plan

**Endpoint:** `POST /api/investment-plan/generate`

**Description:** Generate a new investment plan or retrieve existing plan for a user based on their risk profile.

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 1,
  "goal_id": 5, // Optional: Link plan to a specific goal
  "frequency": "monthly", // Optional: 'monthly', 'weekly', 'daily'
  "monthly_amount": 5000.00, // Optional: Monthly investment amount
  "duration_months": 18 // Optional: Investment duration in months
}
```

**Validation Rules:**
- `user_id`: Required, must be integer
- `goal_id`: Optional, must be integer
- `frequency`: Optional, must be one of: 'monthly', 'weekly', 'daily'
- `monthly_amount`: Optional, must be positive number
- `duration_months`: Optional, must be positive integer

**Response (Success - 200):**
```json
{
  "success": true,
  "plan": {
    "id": 1,
    "user_id": 1,
    "goal_id": 5,
    "risk_profile": "Moderate",
    "risk_profile_display": "Balanced Growth Investor",
    "auto_save": {
      "frequency": "monthly",
      "monthly_amount": 5000.00,
      "duration_months": 18,
      "weekly_amount": 1153.81,
      "daily_amount": 166.67
    },
    "portfolio": {
      "description": "According to your Risk Folio, We have curated the best investment portfolio",
      "allocations": [
        {
          "scheme_code": 123456,
          "scheme_name": "HDFC Equity Fund - Direct Plan",
          "category": "Equity",
          "percentage": 60.0,
          "amount": 3000.00,
          "fund_details": {
            "scheme_code": 123456,
            "scheme_name": "HDFC Equity Fund - Direct Plan",
            "fund_house": "HDFC Mutual Fund",
            "scheme_type": "Open Ended",
            "scheme_category": "Equity",
            "category": "Equity",
            "risk_level": "Moderately High",
            "annualized_return": 15.5,
            "latest_nav": 125.50,
            "plan_type": "Direct",
            "rating": 4.5
          }
        },
        {
          "scheme_code": 789012,
          "scheme_name": "ICICI Prudential Debt Fund - Direct Plan",
          "category": "Debt",
          "percentage": 40.0,
          "amount": 2000.00,
          "fund_details": {
            "scheme_code": 789012,
            "scheme_name": "ICICI Prudential Debt Fund - Direct Plan",
            "fund_house": "ICICI Prudential Mutual Fund",
            "scheme_type": "Open Ended",
            "scheme_category": "Debt",
            "category": "Debt",
            "risk_level": "Low",
            "annualized_return": 7.2,
            "latest_nav": 45.30,
            "plan_type": "Direct",
            "rating": 4.0
          }
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
      "field": "user_id",
      "msg": "User ID is required and must be an integer"
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
  "error": "Failed to generate investment plan"
}
```

**Implementation Notes:**
1. Check if user exists in `authentication` table
2. Get user's risk profile from `risk_assessments` table (latest assessment)
3. If `goal_id` provided, check if goal exists and belongs to user
4. If plan already exists for user/goal combination, return existing plan
5. Otherwise, generate new plan:
   - Get recommended mutual funds based on risk profile (use `/api/mutual-funds/recommendations/:user_id`)
   - Calculate portfolio allocation percentages based on risk profile:
     - Conservative: 30% Equity, 70% Debt
     - Moderate: 60% Equity, 40% Debt
     - Moderately Aggressive: 75% Equity, 25% Debt
     - Aggressive: 90% Equity, 10% Debt
   - Calculate amounts based on monthly_amount
   - Save to `investment_plans` table

---

### 2. Get Investment Plan

**Endpoint:** `GET /api/investment-plan/user/:userId`

**Description:** Get existing investment plan for a user.

**Query Parameters:**
- `goal_id` (optional): Filter by specific goal ID

**Request Example:**
```
GET /api/investment-plan/user/1
GET /api/investment-plan/user/1?goal_id=5
```

**Response (Success - 200):**
```json
{
  "success": true,
  "plan": {
    "id": 1,
    "user_id": 1,
    "goal_id": 5,
    "risk_profile": "Moderate",
    "risk_profile_display": "Balanced Growth Investor",
    "auto_save": {
      "frequency": "monthly",
      "monthly_amount": 5000.00,
      "duration_months": 18,
      "weekly_amount": 1153.81,
      "daily_amount": 166.67
    },
    "portfolio": {
      "description": "According to your Risk Folio, We have curated the best investment portfolio",
      "allocations": [...]
    },
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z"
  }
}
```

**Response (Not Found - 200):**
```json
{
  "success": true,
  "plan": null
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "error": "User not found"
}
```

**Implementation Notes:**
1. Check if user exists
2. Query `investment_plans` table with `user_id` and optional `goal_id`
3. Return plan if found, otherwise return `plan: null`

---

### 3. Update Auto-Save Configuration

**Endpoint:** `PUT /api/investment-plan/auto-save`

**Description:** Update the auto-save configuration (frequency, amount, duration) for an existing investment plan.

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 1,
  "frequency": "weekly", // 'monthly', 'weekly', 'daily'
  "monthly_amount": 6000.00, // Optional
  "duration_months": 24, // Optional
  "goal_id": 5 // Optional
}
```

**Validation Rules:**
- `user_id`: Required, must be integer
- `frequency`: Required, must be one of: 'monthly', 'weekly', 'daily'
- `monthly_amount`: Optional, must be positive number
- `duration_months`: Optional, must be positive integer
- `goal_id`: Optional, must be integer

**Response (Success - 200):**
```json
{
  "success": true,
  "plan": {
    "id": 1,
    "user_id": 1,
    "goal_id": 5,
    "risk_profile": "Moderate",
    "risk_profile_display": "Balanced Growth Investor",
    "auto_save": {
      "frequency": "weekly",
      "monthly_amount": 6000.00,
      "duration_months": 24,
      "weekly_amount": 1384.62,
      "daily_amount": 200.00
    },
    "portfolio": {
      "description": "...",
      "allocations": [...]
    },
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T11:00:00.000Z"
  }
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "error": "Investment plan not found"
}
```

**Implementation Notes:**
1. Check if user exists
2. Find investment plan for user (and goal_id if provided)
3. Update `auto_save_config` JSONB field
4. Recalculate weekly/daily amounts if monthly_amount changed
5. Recalculate portfolio allocation amounts based on new monthly_amount
6. Update `updated_at` timestamp

---

### 4. Create Payment Mandate

**Endpoint:** `POST /api/investment-plan/payment-mandate`

**Description:** Create a payment mandate (eMandate) for auto-debit from user's bank account.

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 1,
  "goal_id": 5, // Optional
  "bank_account_number": "1234567890123456",
  "ifsc_code": "HDFC0001234",
  "account_holder_name": "John Doe"
}
```

**Validation Rules:**
- `user_id`: Required, must be integer
- `bank_account_number`: Required, must be string (9-18 digits)
- `ifsc_code`: Required, must be exactly 11 characters (alphanumeric)
- `account_holder_name`: Required, must be non-empty string
- `goal_id`: Optional, must be integer

**Response (Success - 200):**
```json
{
  "success": true,
  "mandate": {
    "id": 1,
    "user_id": 1,
    "goal_id": 5,
    "investment_plan_id": 1,
    "bank_account_number": "1234567890123456",
    "ifsc_code": "HDFC0001234",
    "account_holder_name": "John Doe",
    "mandate_status": "pending",
    "mandate_reference": "MANDATE_REF_123456", // From payment gateway
    "created_at": "2025-01-15T11:00:00.000Z",
    "updated_at": "2025-01-15T11:00:00.000Z"
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
      "field": "ifsc_code",
      "msg": "IFSC code must be exactly 11 characters"
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

**Implementation Notes:**
1. Check if user exists
2. Get user's investment plan (for user_id and optional goal_id)
3. Validate bank account details (IFSC format, account number format)
4. Create mandate record in `payment_mandates` table
5. Link to `investment_plan_id` if plan exists
6. Generate mandate reference (can integrate with payment gateway like Razorpay, PayU, etc.)
7. Set status as 'pending' initially

---

### 5. Complete Investment Setup

**Endpoint:** `POST /api/investment-plan/complete-setup`

**Description:** Complete the investment setup process after payment mandate is created.

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 1,
  "mandate_id": 1,
  "goal_id": 5 // Optional
}
```

**Validation Rules:**
- `user_id`: Required, must be integer
- `mandate_id`: Required, must be integer
- `goal_id`: Optional, must be integer

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Investment setup completed successfully",
  "plan": {
    "id": 1,
    "user_id": 1,
    "goal_id": 5,
    "status": "active",
    ...
  },
  "mandate": {
    "id": 1,
    "mandate_status": "active",
    "activated_at": "2025-01-15T11:05:00.000Z",
    ...
  }
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "error": "Payment mandate not found"
}
```

**Implementation Notes:**
1. Check if user exists
2. Verify mandate exists and belongs to user
3. Update mandate status to 'active'
4. Set `activated_at` timestamp
5. Update investment plan status to 'active' (if was 'pending')
6. Return updated plan and mandate

---

## 🔧 Implementation Guide

### Step 1: Create Database Tables

Run the SQL scripts above to create the required tables.

### Step 2: Create Route File

Create `routes/investmentPlan.js`:

```javascript
const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { body, param, query: queryCheck, validationResult } = require('express-validator');
const mutualFundService = require('../services/mutualFundService');

// Helper function to get user's risk profile
async function getUserRiskProfile(userId) {
  const result = await query(
    `SELECT risk_profile FROM risk_assessments 
     WHERE user_id = $1 
     ORDER BY completed_at DESC 
     LIMIT 1`,
    [userId]
  );
  return result.rows[0]?.risk_profile || 'Moderate';
}

// Helper function to calculate portfolio allocation
function calculatePortfolioAllocation(riskProfile, monthlyAmount, funds) {
  let equityPercentage, debtPercentage;
  
  switch (riskProfile) {
    case 'Conservative':
      equityPercentage = 30;
      debtPercentage = 70;
      break;
    case 'Moderate':
      equityPercentage = 60;
      debtPercentage = 40;
      break;
    case 'Moderately Aggressive':
      equityPercentage = 75;
      debtPercentage = 25;
      break;
    case 'Aggressive':
      equityPercentage = 90;
      debtPercentage = 10;
      break;
    default:
      equityPercentage = 60;
      debtPercentage = 40;
  }
  
  const equityFunds = funds.filter(f => f.category === 'Equity');
  const debtFunds = funds.filter(f => f.category === 'Debt');
  
  const allocations = [];
  
  // Allocate equity funds
  if (equityFunds.length > 0) {
    const equityAmount = (monthlyAmount * equityPercentage) / 100;
    const perFundAmount = equityAmount / equityFunds.length;
    equityFunds.forEach(fund => {
      allocations.push({
        scheme_code: fund.scheme_code,
        scheme_name: fund.scheme_name,
        category: 'Equity',
        percentage: equityPercentage / equityFunds.length,
        amount: perFundAmount,
        fund_details: fund
      });
    });
  }
  
  // Allocate debt funds
  if (debtFunds.length > 0) {
    const debtAmount = (monthlyAmount * debtPercentage) / 100;
    const perFundAmount = debtAmount / debtFunds.length;
    debtFunds.forEach(fund => {
      allocations.push({
        scheme_code: fund.scheme_code,
        scheme_name: fund.scheme_name,
        category: 'Debt',
        percentage: debtPercentage / debtFunds.length,
        amount: perFundAmount,
        fund_details: fund
      });
    });
  }
  
  return allocations;
}

// POST /api/investment-plan/generate
router.post('/generate', [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
  body('goal_id').optional().isInt().withMessage('Goal ID must be an integer'),
  body('frequency').optional().isIn(['monthly', 'weekly', 'daily']).withMessage('Frequency must be monthly, weekly, or daily'),
  body('monthly_amount').optional().isFloat({ min: 0 }).withMessage('Monthly amount must be a positive number'),
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

    const { user_id, goal_id, frequency = 'monthly', monthly_amount = 5000, duration_months = 18 } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Check if plan already exists
    let existingPlan;
    if (goal_id) {
      const planResult = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id = $2',
        [user_id, goal_id]
      );
      existingPlan = planResult.rows[0];
    } else {
      const planResult = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id IS NULL',
        [user_id]
      );
      existingPlan = planResult.rows[0];
    }

    if (existingPlan) {
      return res.json({
        success: true,
        plan: {
          id: existingPlan.id,
          user_id: existingPlan.user_id,
          goal_id: existingPlan.goal_id,
          risk_profile: existingPlan.risk_profile,
          risk_profile_display: existingPlan.risk_profile_display,
          auto_save: existingPlan.auto_save_config,
          portfolio: existingPlan.portfolio_allocation,
          created_at: existingPlan.created_at,
          updated_at: existingPlan.updated_at
        }
      });
    }

    // Get user's risk profile
    const riskProfile = await getUserRiskProfile(user_id);
    const riskProfileDisplay = {
      'Conservative': 'Capital Protection Investor',
      'Moderate': 'Balanced Growth Investor',
      'Moderately Aggressive': 'Growth Seeker',
      'Aggressive': 'Wealth Builder'
    }[riskProfile] || riskProfile;

    // Get recommended mutual funds
    const fundsResponse = await mutualFundService.getBestPerformingFunds({
      riskProfile,
      investmentHorizon: 'long-term',
      limit: 10
    });

    // Calculate portfolio allocation
    const allocations = calculatePortfolioAllocation(riskProfile, monthly_amount, fundsResponse);

    // Calculate weekly and daily amounts
    const weeklyAmount = monthly_amount / 4.33;
    const dailyAmount = monthly_amount / 30;

    const autoSaveConfig = {
      frequency,
      monthly_amount,
      duration_months,
      weekly_amount: weeklyAmount,
      daily_amount: dailyAmount
    };

    const portfolioAllocation = {
      description: "According to your Risk Folio, We have curated the best investment portfolio",
      allocations
    };

    // Insert new plan
    const result = await query(
      `INSERT INTO investment_plans 
       (user_id, goal_id, risk_profile, risk_profile_display, auto_save_config, portfolio_allocation)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [user_id, goal_id || null, riskProfile, riskProfileDisplay, JSON.stringify(autoSaveConfig), JSON.stringify(portfolioAllocation)]
    );

    const plan = result.rows[0];

    res.json({
      success: true,
      plan: {
        id: plan.id,
        user_id: plan.user_id,
        goal_id: plan.goal_id,
        risk_profile: plan.risk_profile,
        risk_profile_display: plan.risk_profile_display,
        auto_save: plan.auto_save_config,
        portfolio: plan.portfolio_allocation,
        created_at: plan.created_at,
        updated_at: plan.updated_at
      }
    });
  } catch (error) {
    console.error('Generate investment plan error:', error);
    res.status(500).json({ success: false, error: 'Failed to generate investment plan' });
  }
});

// GET /api/investment-plan/user/:userId
router.get('/user/:userId', [
  param('userId').isInt().withMessage('User ID must be an integer'),
  queryCheck('goal_id').optional().isInt().withMessage('Goal ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { userId } = req.params;
    const goalId = req.query.goal_id;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [userId]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    let result;
    if (goalId) {
      result = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id = $2',
        [userId, goalId]
      );
    } else {
      result = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id IS NULL',
        [userId]
      );
    }

    if (result.rows.length === 0) {
      return res.json({ success: true, plan: null });
    }

    const plan = result.rows[0];
    res.json({
      success: true,
      plan: {
        id: plan.id,
        user_id: plan.user_id,
        goal_id: plan.goal_id,
        risk_profile: plan.risk_profile,
        risk_profile_display: plan.risk_profile_display,
        auto_save: plan.auto_save_config,
        portfolio: plan.portfolio_allocation,
        created_at: plan.created_at,
        updated_at: plan.updated_at
      }
    });
  } catch (error) {
    console.error('Get investment plan error:', error);
    res.status(500).json({ success: false, error: 'Failed to get investment plan' });
  }
});

// PUT /api/investment-plan/auto-save
router.put('/auto-save', [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
  body('frequency').isIn(['monthly', 'weekly', 'daily']).withMessage('Frequency must be monthly, weekly, or daily'),
  body('monthly_amount').optional().isFloat({ min: 0 }).withMessage('Monthly amount must be a positive number'),
  body('duration_months').optional().isInt({ min: 1 }).withMessage('Duration must be a positive integer'),
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

    const { user_id, frequency, monthly_amount, duration_months, goal_id } = req.body;

    // Find existing plan
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
      return res.status(404).json({ success: false, error: 'Investment plan not found' });
    }

    const existingPlan = result.rows[0];
    const currentAutoSave = existingPlan.auto_save_config;
    
    // Update auto-save config
    const updatedAutoSave = {
      frequency,
      monthly_amount: monthly_amount || currentAutoSave.monthly_amount,
      duration_months: duration_months || currentAutoSave.duration_months,
      weekly_amount: (monthly_amount || currentAutoSave.monthly_amount) / 4.33,
      daily_amount: (monthly_amount || currentAutoSave.monthly_amount) / 30
    };

    // Recalculate portfolio amounts if monthly_amount changed
    let portfolioAllocation = existingPlan.portfolio_allocation;
    if (monthly_amount && monthly_amount !== currentAutoSave.monthly_amount) {
      const newAmount = monthly_amount;
      portfolioAllocation.allocations = portfolioAllocation.allocations.map(alloc => ({
        ...alloc,
        amount: (newAmount * alloc.percentage) / 100
      }));
    }

    // Update plan
    const updateResult = await query(
      `UPDATE investment_plans 
       SET auto_save_config = $1, 
           portfolio_allocation = $2,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $3
       RETURNING *`,
      [JSON.stringify(updatedAutoSave), JSON.stringify(portfolioAllocation), existingPlan.id]
    );

    const plan = updateResult.rows[0];
    res.json({
      success: true,
      plan: {
        id: plan.id,
        user_id: plan.user_id,
        goal_id: plan.goal_id,
        risk_profile: plan.risk_profile,
        risk_profile_display: plan.risk_profile_display,
        auto_save: plan.auto_save_config,
        portfolio: plan.portfolio_allocation,
        created_at: plan.created_at,
        updated_at: plan.updated_at
      }
    });
  } catch (error) {
    console.error('Update auto-save error:', error);
    res.status(500).json({ success: false, error: 'Failed to update auto-save' });
  }
});

// POST /api/investment-plan/payment-mandate
router.post('/payment-mandate', [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
  body('bank_account_number').isLength({ min: 9, max: 18 }).withMessage('Account number must be between 9 and 18 digits'),
  body('ifsc_code').isLength({ min: 11, max: 11 }).withMessage('IFSC code must be exactly 11 characters'),
  body('account_holder_name').notEmpty().withMessage('Account holder name is required'),
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

    const { user_id, goal_id, bank_account_number, ifsc_code, account_holder_name } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Get investment plan
    let planResult;
    if (goal_id) {
      planResult = await query(
        'SELECT id FROM investment_plans WHERE user_id = $1 AND goal_id = $2',
        [user_id, goal_id]
      );
    } else {
      planResult = await query(
        'SELECT id FROM investment_plans WHERE user_id = $1 AND goal_id IS NULL',
        [user_id]
      );
    }

    const investmentPlanId = planResult.rows[0]?.id || null;

    // Generate mandate reference (integrate with payment gateway)
    const mandateReference = `MANDATE_REF_${Date.now()}_${user_id}`;

    // Create mandate
    const result = await query(
      `INSERT INTO payment_mandates 
       (user_id, goal_id, investment_plan_id, bank_account_number, ifsc_code, account_holder_name, mandate_reference)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [user_id, goal_id || null, investmentPlanId, bank_account_number, ifsc_code, account_holder_name, mandateReference]
    );

    const mandate = result.rows[0];
    res.json({
      success: true,
      mandate: {
        id: mandate.id,
        user_id: mandate.user_id,
        goal_id: mandate.goal_id,
        investment_plan_id: mandate.investment_plan_id,
        bank_account_number: mandate.bank_account_number,
        ifsc_code: mandate.ifsc_code,
        account_holder_name: mandate.account_holder_name,
        mandate_status: mandate.mandate_status,
        mandate_reference: mandate.mandate_reference,
        created_at: mandate.created_at,
        updated_at: mandate.updated_at
      }
    });
  } catch (error) {
    console.error('Create payment mandate error:', error);
    res.status(500).json({ success: false, error: 'Failed to create payment mandate' });
  }
});

// POST /api/investment-plan/complete-setup
router.post('/complete-setup', [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
  body('mandate_id').isInt().withMessage('Mandate ID is required and must be an integer'),
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

    const { user_id, mandate_id, goal_id } = req.body;

    // Check if mandate exists and belongs to user
    const mandateResult = await query(
      'SELECT * FROM payment_mandates WHERE id = $1 AND user_id = $2',
      [mandate_id, user_id]
    );

    if (mandateResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Payment mandate not found' });
    }

    // Update mandate status
    await query(
      `UPDATE payment_mandates 
       SET mandate_status = 'active', 
           activated_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [mandate_id]
    );

    // Update investment plan status
    let planResult;
    if (goal_id) {
      planResult = await query(
        `UPDATE investment_plans 
         SET status = 'active', updated_at = CURRENT_TIMESTAMP
         WHERE user_id = $1 AND goal_id = $2
         RETURNING *`,
        [user_id, goal_id]
      );
    } else {
      planResult = await query(
        `UPDATE investment_plans 
         SET status = 'active', updated_at = CURRENT_TIMESTAMP
         WHERE user_id = $1 AND goal_id IS NULL
         RETURNING *`,
        [user_id]
      );
    }

    const plan = planResult.rows[0];
    const mandate = mandateResult.rows[0];

    res.json({
      success: true,
      message: 'Investment setup completed successfully',
      plan: {
        id: plan.id,
        user_id: plan.user_id,
        goal_id: plan.goal_id,
        status: plan.status,
        risk_profile: plan.risk_profile,
        risk_profile_display: plan.risk_profile_display,
        auto_save: plan.auto_save_config,
        portfolio: plan.portfolio_allocation
      },
      mandate: {
        id: mandate.id,
        mandate_status: mandate.mandate_status,
        activated_at: mandate.activated_at
      }
    });
  } catch (error) {
    console.error('Complete setup error:', error);
    res.status(500).json({ success: false, error: 'Failed to complete setup' });
  }
});

module.exports = router;
```

### Step 3: Register Route in server.js

Add to `server.js`:

```javascript
const investmentPlanRoutes = require('./routes/investmentPlan');
app.use('/api/investment-plan', investmentPlanRoutes);
```

---

## 📝 Testing

### Test Generate Plan
```bash
curl -X POST http://localhost:3001/api/investment-plan/generate \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "frequency": "monthly",
    "monthly_amount": 5000,
    "duration_months": 18
  }'
```

### Test Get Plan
```bash
curl http://localhost:3001/api/investment-plan/user/1
```

### Test Update Auto-Save
```bash
curl -X PUT http://localhost:3001/api/investment-plan/auto-save \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "frequency": "weekly",
    "monthly_amount": 6000
  }'
```

### Test Create Mandate
```bash
curl -X POST http://localhost:3001/api/investment-plan/payment-mandate \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "bank_account_number": "1234567890123456",
    "ifsc_code": "HDFC0001234",
    "account_holder_name": "John Doe"
  }'
```

### Test Complete Setup
```bash
curl -X POST http://localhost:3001/api/investment-plan/complete-setup \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "mandate_id": 1
  }'
```

---

## 🔗 Integration with Mutual Funds API

The investment plan generation uses the Mutual Funds API to get recommended funds. Ensure the `/api/mutual-funds/recommendations/:user_id` endpoint is working properly.

---

## ⚠️ Important Notes

1. **Risk Profile Mapping**: Ensure risk profiles from risk assessment match the expected values: 'Conservative', 'Moderate', 'Moderately Aggressive', 'Aggressive'

2. **Portfolio Allocation**: The allocation percentages should always sum to 100%

3. **Payment Gateway Integration**: The payment mandate creation should integrate with a payment gateway (Razorpay, PayU, etc.) for actual eMandate creation

4. **Data Validation**: Always validate user ownership of goals and mandates before operations

5. **Error Handling**: Return appropriate HTTP status codes and error messages

---

This documentation provides everything needed to implement the investment plan backend API endpoints.

