# Goal Progress Circular Chart - Backend API Documentation

This document describes how the backend should format goal data for the circular progress chart displayed on the Home Screen.

## Overview

The Home Screen displays a circular progress chart showing the overall progress across all user goals. The chart displays:
- **Overall Progress Percentage**: Average of all active goals' progress percentages
- **Goal Icons**: Up to 3 goal category icons representing the user's active goals
- **Visual Progress**: A circular progress indicator filled based on the average progress

---

## API Endpoint

**Endpoint:** `GET /api/goals/user/:user_id`

**Description:** Get all active goals for a user with progress calculations

**URL Parameters:**
- `user_id` (required): Integer - The user's ID

**Query Parameters:**
- `status` (optional): String - Filter by status (`active`, `completed`, `paused`, `cancelled`)
- `limit` (optional): Integer - Number of goals to return (default: 50, max: 100)
- `offset` (optional): Integer - Pagination offset (default: 0)

---

## Required Response Format

### Success Response (200 OK)

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
      "target_amount": 80000.00,
      "current_amount": 25000.00,
      "target_date": "2025-06-15",
      "status": "active",
      "created_at": "2025-01-15T10:30:00.000Z",
      "updated_at": "2025-01-15T10:30:00.000Z",
      "progress_percentage": 31.25,
      "days_remaining": 151,
      "monthly_savings_needed": 3636.36
    },
    {
      "id": 2,
      "user_id": 1,
      "category_id": 3,
      "category_name": "Car",
      "category_icon": "directions_car",
      "goal_name": "Tesla Model 3",
      "target_amount": 500000.00,
      "current_amount": 125000.00,
      "target_date": "2026-12-31",
      "status": "active",
      "created_at": "2025-01-10T08:15:00.000Z",
      "updated_at": "2025-01-20T14:45:00.000Z",
      "progress_percentage": 25.00,
      "days_remaining": 710,
      "monthly_savings_needed": 5281.69
    },
    {
      "id": 3,
      "user_id": 1,
      "category_id": 5,
      "category_name": "Home",
      "category_icon": "home",
      "goal_name": "Down Payment for House",
      "target_amount": 2000000.00,
      "current_amount": 500000.00,
      "target_date": "2027-06-30",
      "status": "active",
      "created_at": "2025-01-05T12:00:00.000Z",
      "updated_at": "2025-01-18T09:30:00.000Z",
      "progress_percentage": 25.00,
      "days_remaining": 897,
      "monthly_savings_needed": 16713.17
    }
  ],
  "total": 3,
  "limit": 50,
  "offset": 0
}
```

### Empty Response (No Goals)

```json
{
  "goals": [],
  "total": 0,
  "limit": 50,
  "offset": 0
}
```

---

## Field Requirements

### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `id` | Integer | Unique goal identifier | `1` |
| `user_id` | Integer | User who owns the goal | `1` |
| `category_id` | Integer | Goal category ID | `1` |
| `category_name` | String | Name of the goal category | `"Phone"` |
| `category_icon` | String | Icon identifier for the category | `"phone"` |
| `goal_name` | String | Name of the goal | `"iPhone 15 Pro"` |
| `target_amount` | Number (Float) | Target amount to save | `80000.00` |
| `current_amount` | Number (Float) | Current amount saved | `25000.00` |
| `target_date` | String (ISO Date) | Target completion date | `"2025-06-15"` |
| `status` | String | Goal status | `"active"` |
| `created_at` | String (ISO DateTime) | Creation timestamp | `"2025-01-15T10:30:00.000Z"` |
| `updated_at` | String (ISO DateTime) | Last update timestamp | `"2025-01-15T10:30:00.000Z"` |
| `progress_percentage` | Number (Float) | Progress percentage (0-100) | `31.25` |

### Optional Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `days_remaining` | Integer | Days until target date | `151` |
| `monthly_savings_needed` | Number (Float) | Monthly savings needed to reach goal | `3636.36` |

---

## Calculation Formulas

### 1. Progress Percentage

**Formula:**
```sql
progress_percentage = ROUND((current_amount / target_amount * 100)::numeric, 2)
```

**Example:**
- `current_amount` = 25000.00
- `target_amount` = 80000.00
- `progress_percentage` = (25000 / 80000) * 100 = 31.25%

**Important Notes:**
- Progress percentage should be between 0 and 100
- If `current_amount` exceeds `target_amount`, cap at 100%
- Always return as a **number** (not a string)
- Round to 2 decimal places

### 2. Days Remaining

**Formula:**
```javascript
const targetDate = new Date(target_date);
const today = new Date();
today.setHours(0, 0, 0, 0);
targetDate.setHours(0, 0, 0, 0);

const daysRemaining = Math.ceil((targetDate - today) / (1000 * 60 * 60 * 24));
```

**Example:**
- `target_date` = "2025-06-15"
- Today = "2025-01-15"
- `days_remaining` = 151 days

**Important Notes:**
- Return `null` if target date is in the past
- Return as an **integer** (not a string)

### 3. Monthly Savings Needed

**Formula:**
```javascript
const remainingAmount = target_amount - current_amount;
const monthsRemaining = days_remaining / 30.44; // Average days per month
const monthlySavingsNeeded = remainingAmount / monthsRemaining;
```

**Example:**
- `target_amount` = 80000.00
- `current_amount` = 25000.00
- `days_remaining` = 151
- `remaining_amount` = 55000.00
- `months_remaining` = 151 / 30.44 = 4.96
- `monthly_savings_needed` = 55000 / 4.96 = 11088.71

**Important Notes:**
- Return `null` if `days_remaining` is null or <= 0
- Round to 2 decimal places
- Return as a **number** (not a string)

---

## Frontend Usage

### Circular Chart Calculation

The frontend calculates the **overall progress** by averaging all active goals:

```dart
double _calculateTotalGoalProgress() {
  if (_goals.isEmpty) return 0.0;
  double totalProgress = _goals.fold(0.0, (sum, goal) => sum + goal.progressPercentage);
  return totalProgress / _goals.length;
}
```

**Example:**
- Goal 1: 31.25%
- Goal 2: 25.00%
- Goal 3: 25.00%
- **Overall Progress** = (31.25 + 25.00 + 25.00) / 3 = **27.08%**

### Goal Icons Display

The frontend displays up to **3 goal icons** next to the circular chart:
- Takes the first 3 goals from the response
- Uses `category_icon` to determine which icon to display
- If less than 3 goals, shows an "Add" button

---

## SQL Query Example

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
  -- Calculate progress percentage
  ROUND((g.current_amount / g.target_amount * 100)::numeric, 2) as progress_percentage,
  -- Calculate days remaining
  CASE 
    WHEN g.target_date >= CURRENT_DATE 
    THEN EXTRACT(DAY FROM (g.target_date - CURRENT_DATE))
    ELSE NULL 
  END as days_remaining,
  -- Calculate monthly savings needed
  CASE 
    WHEN g.target_date >= CURRENT_DATE 
    THEN ROUND(
      ((g.target_amount - g.current_amount) / 
       (EXTRACT(DAY FROM (g.target_date - CURRENT_DATE)) / 30.44))::numeric, 
      2
    )
    ELSE NULL 
  END as monthly_savings_needed
FROM goals g
JOIN goal_categories gc ON g.category_id = gc.id
WHERE g.user_id = $1 
  AND g.status != 'cancelled'
ORDER BY g.created_at DESC
LIMIT $2 OFFSET $3;
```

---

## Backend Implementation Example (Node.js/Express)

```javascript
router.get('/user/:user_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
  queryCheck('status').optional().isIn(['active', 'completed', 'paused', 'cancelled']),
  queryCheck('limit').optional().isInt({ min: 1, max: 100 }),
  queryCheck('offset').optional().isInt({ min: 0 }),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id } = req.params;
    const status = req.query.status;
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Build query
    let queryText = `
      SELECT 
        g.*,
        gc.name as category_name,
        gc.icon as category_icon,
        ROUND((g.current_amount / g.target_amount * 100)::numeric, 2) as progress_percentage,
        CASE 
          WHEN g.target_date >= CURRENT_DATE 
          THEN EXTRACT(DAY FROM (g.target_date - CURRENT_DATE))
          ELSE NULL 
        END as days_remaining,
        CASE 
          WHEN g.target_date >= CURRENT_DATE 
          THEN ROUND(
            ((g.target_amount - g.current_amount) / 
             (EXTRACT(DAY FROM (g.target_date - CURRENT_DATE)) / 30.44))::numeric, 
            2
          )
          ELSE NULL 
        END as monthly_savings_needed
      FROM goals g
      JOIN goal_categories gc ON g.category_id = gc.id
      WHERE g.user_id = $1
    `;
    const queryParams = [user_id];
    let paramIndex = 2;

    if (status) {
      queryText += ` AND g.status = $${paramIndex}`;
      queryParams.push(status);
      paramIndex++;
    } else {
      queryText += ` AND g.status != 'cancelled'`;
    }

    queryText += ` ORDER BY g.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    queryParams.push(limit, offset);

    const result = await query(queryText, queryParams);

    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM goals WHERE user_id = $1';
    const countParams = [user_id];
    if (status) {
      countQuery += ' AND status = $2';
      countParams.push(status);
    } else {
      countQuery += ` AND status != 'cancelled'`;
    }
    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].total);

    // Format goals - ensure numeric fields are numbers, not strings
    const goals = result.rows.map(goal => ({
      ...goal,
      target_amount: parseFloat(goal.target_amount) || 0,
      current_amount: parseFloat(goal.current_amount) || 0,
      progress_percentage: parseFloat(goal.progress_percentage) || 0,
      days_remaining: goal.days_remaining ? parseInt(goal.days_remaining) : null,
      monthly_savings_needed: goal.monthly_savings_needed 
        ? parseFloat(goal.monthly_savings_needed) 
        : null,
    }));

    res.json({
      goals,
      total,
      limit,
      offset
    });
  } catch (error) {
    console.error('Get user goals error:', error);
    res.status(500).json({ error: 'Failed to get user goals' });
  }
});
```

---

## Data Type Requirements

### Critical: Numeric Fields Must Be Numbers

The frontend expects **numeric values as numbers**, not strings. Ensure the following fields are returned as numbers:

- ✅ `target_amount`: `80000.00` (number)
- ✅ `current_amount`: `25000.00` (number)
- ✅ `progress_percentage`: `31.25` (number)
- ✅ `days_remaining`: `151` (number or null)
- ✅ `monthly_savings_needed`: `3636.36` (number or null)

**❌ Wrong:**
```json
{
  "target_amount": "80000.00",  // String - will cause errors
  "progress_percentage": "31.25" // String - will cause errors
}
```

**✅ Correct:**
```json
{
  "target_amount": 80000.00,  // Number
  "progress_percentage": 31.25 // Number
}
```

---

## Error Responses

### 400 Bad Request
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

### 404 Not Found
```json
{
  "error": "User not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Failed to get user goals"
}
```

---

## Testing

### cURL Example

```bash
# Get all active goals for user 1
curl -X GET http://localhost:3001/api/goals/user/1 \
  -H "Content-Type: application/json"

# Get only active goals
curl -X GET "http://localhost:3001/api/goals/user/1?status=active" \
  -H "Content-Type: application/json"

# Get goals with pagination
curl -X GET "http://localhost:3001/api/goals/user/1?limit=10&offset=0" \
  -H "Content-Type: application/json"
```

### Expected Behavior

1. **No Goals**: Returns empty array, frontend shows 0% progress
2. **Single Goal**: Shows that goal's progress percentage
3. **Multiple Goals**: Shows average of all goals' progress percentages
4. **Completed Goals**: Excluded from calculation (status != 'cancelled')
5. **Progress > 100%**: Capped at 100% in frontend

---

## Summary Checklist

- [x] Return `progress_percentage` as a **number** (0-100)
- [x] Calculate progress as `(current_amount / target_amount) * 100`
- [x] Include `category_icon` for each goal
- [x] Include `category_name` for each goal
- [x] Return `days_remaining` as integer or null
- [x] Return `monthly_savings_needed` as number or null
- [x] Ensure all numeric fields are numbers, not strings
- [x] Filter out cancelled goals by default
- [x] Order by `created_at DESC` (newest first)
- [x] Support pagination with `limit` and `offset`
- [x] Return total count for pagination

---

## Additional Notes

1. **Performance**: Consider caching progress calculations if goals are updated frequently
2. **Real-time Updates**: If goals are updated, the progress will be recalculated on next API call
3. **Icon Mapping**: The frontend maps `category_icon` values to asset images. Ensure icon names match expected values:
   - `"phone"`, `"home"`, `"directions_car"`, `"camera"`, `"trip"`, `"birthday"`, `"party"`, `"other"`
4. **Date Format**: Always use ISO date format (`YYYY-MM-DD`) for `target_date`
5. **Timezone**: Use UTC for all datetime fields

---

## Questions or Issues?

If you encounter any issues with the API response format or need clarification, please refer to:
- Frontend Model: `lib/models/goal_models.dart`
- Frontend Service: `lib/services/goal_service.dart`
- Frontend Screen: `lib/screens/home_screen.dart`

