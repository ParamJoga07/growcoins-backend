# Goal Details API Documentation

## Overview
This document describes the API endpoint required to fetch complete goal details including goal information, investment plan, auto-save settings, and auto-roundoff settings.

## Endpoint

### GET /api/goals/:goal_id

Fetches complete details for a specific goal, including all related configurations.

**URL Parameters:**
- `goal_id` (integer, required): The ID of the goal to fetch

**Response Format:**
```json
{
  "success": true,
  "goal": {
    "id": 13,
    "user_id": 1,
    "category_id": 1,
    "category_name": "Vacation",
    "category_icon": "flight",
    "goal_name": "Europe Trip",
    "target_amount": 500000,
    "current_amount": 50000,
    "target_date": "2025-12-31",
    "status": "active",
    "progress_percentage": 10.0,
    "days_remaining": 365,
    "monthly_savings_needed": 37500,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-20T14:45:00Z",
    "investment_plan": {
      "id": 5,
      "user_id": 1,
      "goal_id": 13,
      "risk_profile": "Moderate",
      "risk_profile_display": "Balanced Growth Investor",
      "auto_save": {
        "frequency": "monthly",
        "monthly_amount": 37500,
        "weekly_amount": 8653.85,
        "daily_amount": 1250,
        "duration_months": 12
      },
      "portfolio": {
        "description": "According to your Risk Folio, We have curated the best investment portfolio",
        "allocations": [
          {
            "scheme_code": 100123,
            "scheme_name": "HDFC Equity Fund - Growth",
            "scheme_type": "Equity",
            "percentage": 40.0,
            "amount": 200000
          },
          {
            "scheme_code": 100456,
            "scheme_name": "ICICI Balanced Advantage Fund",
            "scheme_type": "Hybrid",
            "percentage": 35.0,
            "amount": 175000
          },
          {
            "scheme_code": 100789,
            "scheme_name": "SBI Debt Fund - Regular",
            "scheme_type": "Debt",
            "percentage": 25.0,
            "amount": 125000
          }
        ]
      },
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-20T14:45:00Z"
    }
  },
  "roundoff_setting": {
    "id": 3,
    "user_id": 1,
    "goal_id": 13,
    "roundoff_amount": 10,
    "is_active": true,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-20T14:45:00Z"
  }
}
```

## Response Fields

### Goal Object
- `id` (integer): Goal ID
- `user_id` (integer): User ID who owns the goal
- `category_id` (integer): Goal category ID
- `category_name` (string): Name of the goal category
- `category_icon` (string): Icon identifier for the category
- `goal_name` (string): Name of the goal
- `target_amount` (number): Target amount for the goal
- `current_amount` (number): Current amount saved
- `target_date` (string, ISO 8601): Target date for the goal
- `status` (string): Goal status (e.g., "active", "completed", "paused")
- `progress_percentage` (number): Progress percentage (0-100)
- `days_remaining` (integer, nullable): Days remaining until target date
- `monthly_savings_needed` (number, nullable): Monthly savings amount needed
- `created_at` (string, ISO 8601): Creation timestamp
- `updated_at` (string, ISO 8601): Last update timestamp
- `investment_plan` (object, nullable): Investment plan object (see below)

### Investment Plan Object (nested in goal)
- `id` (integer): Investment plan ID
- `user_id` (integer): User ID
- `goal_id` (integer, nullable): Linked goal ID
- `risk_profile` (string): Risk profile (e.g., "Conservative", "Moderate", "Aggressive")
- `risk_profile_display` (string): Human-readable risk profile name
- `auto_save` (object): Auto-save configuration (see below)
- `portfolio` (object): Portfolio allocation (see below)
- `created_at` (string, ISO 8601): Creation timestamp
- `updated_at` (string, ISO 8601): Last update timestamp

### Auto Save Object
- `frequency` (string): Frequency of auto-save ("monthly", "weekly", or "daily")
- `monthly_amount` (number): Monthly investment amount
- `weekly_amount` (number, nullable): Weekly amount (calculated from monthly)
- `daily_amount` (number, nullable): Daily amount (calculated from monthly)
- `duration_months` (integer): Duration in months

### Portfolio Allocation Object
- `description` (string): Description of the portfolio
- `allocations` (array): Array of mutual fund allocations (see below)

### Mutual Fund Allocation Object
- `scheme_code` (integer): Mutual fund scheme code
- `scheme_name` (string): Name of the mutual fund scheme
- `scheme_type` (string): Type of scheme (e.g., "Equity", "Debt", "Hybrid")
- `percentage` (number): Allocation percentage (0-100)
- `amount` (number): Allocation amount in rupees

### Roundoff Setting Object (top-level)
- `id` (integer): Roundoff setting ID
- `user_id` (integer): User ID
- `goal_id` (integer, nullable): Linked goal ID (null if global setting)
- `roundoff_amount` (integer): Roundoff amount per transaction (e.g., 5, 10, 50)
- `is_active` (boolean): Whether roundoff is active
- `created_at` (string, ISO 8601): Creation timestamp
- `updated_at` (string, ISO 8601): Last update timestamp

## Error Responses

### 404 Not Found
```json
{
  "success": false,
  "error": "Goal not found"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": "Unauthorized access"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Internal server error"
}
```

## Implementation Notes

1. **Investment Plan Inclusion**: The `investment_plan` should be included in the goal response if it exists. If no investment plan is linked to the goal, `investment_plan` should be `null`.

2. **Roundoff Setting**: The `roundoff_setting` should be fetched separately and included at the top level of the response. If the goal has a specific roundoff setting (linked via `goal_id`), return that. Otherwise, return the user's global roundoff setting. If no setting exists, `roundoff_setting` should be `null`.

3. **Progress Calculation**: 
   - `progress_percentage` = (`current_amount` / `target_amount`) * 100
   - `days_remaining` = days between current date and `target_date` (null if target date has passed)

4. **Monthly Savings Calculation**:
   - `monthly_savings_needed` = (`target_amount` - `current_amount`) / months until target date
   - Minimum value should be ₹100

5. **Auto-Save Amounts**:
   - `weekly_amount` = `monthly_amount` / 4.33
   - `daily_amount` = `monthly_amount` / 30

## Database Queries

### Goal Query
```sql
SELECT 
  g.id,
  g.user_id,
  g.category_id,
  gc.name as category_name,
  gc.icon as category_icon,
  g.goal_name,
  g.target_amount,
  g.current_amount,
  g.target_date,
  g.status,
  g.created_at,
  g.updated_at,
  ROUND((g.current_amount / g.target_amount) * 100, 2) as progress_percentage,
  CASE 
    WHEN g.target_date > CURRENT_DATE 
    THEN EXTRACT(DAY FROM (g.target_date - CURRENT_DATE))
    ELSE NULL 
  END as days_remaining,
  CASE 
    WHEN g.target_date > CURRENT_DATE 
    THEN ROUND((g.target_amount - g.current_amount) / 
         GREATEST(1, EXTRACT(MONTH FROM AGE(g.target_date, CURRENT_DATE))), 2)
    ELSE NULL 
  END as monthly_savings_needed
FROM goals g
LEFT JOIN goal_categories gc ON g.category_id = gc.id
WHERE g.id = $1 AND g.user_id = $2;
```

### Investment Plan Query
```sql
SELECT 
  ip.id,
  ip.user_id,
  ip.goal_id,
  ip.risk_profile,
  ip.risk_profile_display,
  ip.auto_save_frequency as frequency,
  ip.monthly_amount,
  ip.weekly_amount,
  ip.daily_amount,
  ip.duration_months,
  ip.created_at,
  ip.updated_at
FROM investment_plans ip
WHERE ip.goal_id = $1;
```

### Portfolio Allocations Query
```sql
SELECT 
  mfa.scheme_code,
  mfa.scheme_name,
  mfa.scheme_type,
  mfa.percentage,
  mfa.amount
FROM mutual_fund_allocations mfa
WHERE mfa.investment_plan_id = $1
ORDER BY mfa.percentage DESC;
```

### Roundoff Setting Query
```sql
SELECT 
  rs.id,
  rs.user_id,
  rs.goal_id,
  rs.roundoff_amount,
  rs.is_active,
  rs.created_at,
  rs.updated_at
FROM roundoff_settings rs
WHERE rs.user_id = $1 
  AND (rs.goal_id = $2 OR rs.goal_id IS NULL)
ORDER BY rs.goal_id DESC NULLS LAST
LIMIT 1;
```

## Example cURL Request

```bash
curl -X GET \
  'http://localhost:3001/api/goals/13' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_TOKEN_HERE'
```

## Frontend Usage

The frontend will call this endpoint when a user clicks on a goal to view its details. The response should include all necessary information to display:

1. Goal header with name, category, amounts, and target date
2. Progress visualization
3. Auto-save configuration status
4. Auto-roundoff configuration status
5. Investment plan details with portfolio allocations

## Notes

- All monetary values should be in rupees (₹)
- All dates should be in ISO 8601 format
- Percentages should be between 0 and 100
- If any related data (investment plan, roundoff setting) doesn't exist, return `null` for that field
- Ensure proper authorization checks - users should only be able to access their own goals

