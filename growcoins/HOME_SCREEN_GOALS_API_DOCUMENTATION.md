# Home Screen Goals API Documentation

This document describes the backend API requirements for displaying user goals dynamically on the Home Screen.

## Overview

The Home Screen displays user goals in a horizontal scrolling list. The backend needs to provide goal data with all necessary information for rendering goal cards, including progress calculations, category information, and time-based metrics.

---

## API Endpoint

**Endpoint:** `GET /api/goals/user/:user_id`

**Description:** Get all active goals for a user with complete information for home screen display

**URL Parameters:**
- `user_id` (required): Integer - The user's ID

**Query Parameters:**
- `status` (optional): String - Filter by status (`active`, `completed`, `paused`, `cancelled`)
  - **Default**: Returns all non-cancelled goals
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
    }
  ],
  "total": 2,
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

| Field | Type | Description | Example | Frontend Usage |
|-------|------|-------------|---------|----------------|
| `id` | Integer | Unique goal identifier | `1` | Goal identification |
| `user_id` | Integer | User who owns the goal | `1` | User association |
| `category_id` | Integer | Goal category ID | `1` | Category reference |
| `category_name` | String | Name of the goal category | `"Phone"` | Display in goal card |
| `category_icon` | String | Icon identifier for the category | `"phone"` | Icon display |
| `goal_name` | String | Name of the goal | `"iPhone 15 Pro"` | Main title in card |
| `target_amount` | Number (Float) | Target amount to save | `80000.00` | Target display |
| `current_amount` | Number (Float) | Current amount saved | `25000.00` | Progress calculation |
| `target_date` | String (ISO Date) | Target completion date | `"2025-06-15"` | Days remaining calculation |
| `status` | String | Goal status | `"active"` | Filtering |
| `created_at` | String (ISO DateTime) | Creation timestamp | `"2025-01-15T10:30:00.000Z"` | Sorting |
| `updated_at` | String (ISO DateTime) | Last update timestamp | `"2025-01-15T10:30:00.000Z"` | Sorting |
| `progress_percentage` | Number (Float) | Progress percentage (0-100) | `31.25` | Progress bar display |

### Optional but Recommended Fields

| Field | Type | Description | Example | Frontend Usage |
|-------|------|-------------|---------|----------------|
| `days_remaining` | Integer or null | Days until target date | `151` | "X days left" badge |
| `monthly_savings_needed` | Number (Float) or null | Monthly savings needed | `3636.36` | Future feature |

---

## Calculation Formulas

### 1. Progress Percentage

**Formula:**
```sql
progress_percentage = ROUND((current_amount / target_amount * 100)::numeric, 2)
```

**Important:**
- Cap at 100% if `current_amount` exceeds `target_amount`
- Return as a **number** (not a string)
- Round to 2 decimal places
- Minimum value: 0

**Example:**
- `current_amount` = 25000.00
- `target_amount` = 80000.00
- `progress_percentage` = (25000 / 80000) * 100 = 31.25%

### 2. Days Remaining

**Formula:**
```sql
days_remaining = CASE 
  WHEN target_date >= CURRENT_DATE 
  THEN EXTRACT(DAY FROM (target_date - CURRENT_DATE))
  ELSE NULL 
END
```

**JavaScript Alternative:**
```javascript
const targetDate = new Date(target_date);
const today = new Date();
today.setHours(0, 0, 0, 0);
targetDate.setHours(0, 0, 0, 0);

const daysRemaining = targetDate >= today 
  ? Math.ceil((targetDate - today) / (1000 * 60 * 60 * 24))
  : null;
```

**Important:**
- Return `null` if target date is in the past
- Return as an **integer** (not a string)
- Use `>=` to include today (0 days remaining if target is today)

**Example:**
- `target_date` = "2025-06-15"
- Today = "2025-01-15"
- `days_remaining` = 151 days

### 3. Monthly Savings Needed (Optional)

**Formula:**
```sql
monthly_savings_needed = CASE 
  WHEN target_date >= CURRENT_DATE AND days_remaining > 0
  THEN ROUND(
    ((target_amount - current_amount) / 
     (EXTRACT(DAY FROM (target_date - CURRENT_DATE)) / 30.44))::numeric, 
    2
  )
  ELSE NULL 
END
```

**Important:**
- Return `null` if `days_remaining` is null or <= 0
- Round to 2 decimal places
- Return as a **number** (not a string)

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

    // Build query with all calculations
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

## Frontend Display Logic

### Goal Cards Display

The frontend displays goals in a horizontal scrolling list:

1. **If no goals**: The goals section is hidden
2. **If goals exist**: Shows "My Goals" section with horizontal scrollable cards
3. **Card Layout**:
   - **Header**: Category icon + Goal name + Category name
   - **Progress Bar**: Visual progress indicator with percentage
   - **Amount Info**: Saved amount vs Target amount
   - **Days Remaining Badge**: Shows if `days_remaining` is not null and > 0

### Goal Card Dimensions

- **Card Width**: 280 pixels
- **Card Height**: 200 pixels
- **Spacing**: 16 pixels between cards
- **Scroll Direction**: Horizontal

### Icon Mapping

The frontend maps `category_icon` values to asset images:
- `"phone"` → Phone icon asset
- `"home"` → Home icon asset
- `"directions_car"` or `"car"` → Car icon asset
- `"camera"` or `"gadget"` → Camera/Gadget icon asset
- `"trip"` or `"landscape"` → Trip icon asset
- `"birthday"` or `"cake"` → Birthday icon asset
- `"party"` or `"celebration"` → Party icon asset
- `"other"` or `"person"` → Default icon asset

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
- [x] Join with `goal_categories` table to get category info

---

## Additional Notes

1. **Performance**: Consider caching goal calculations if goals are updated frequently
2. **Real-time Updates**: If goals are updated, the progress will be recalculated on next API call
3. **Icon Mapping**: The frontend maps `category_icon` values to asset images. Ensure icon names match expected values
4. **Date Format**: Always use ISO date format (`YYYY-MM-DD`) for `target_date`
5. **Timezone**: Use UTC for all datetime fields
6. **Null Handling**: Return `null` (not `0` or empty string) for optional fields when not applicable

---

## Questions or Issues?

If you encounter any issues with the API response format or need clarification, please refer to:
- Frontend Model: `lib/models/goal_models.dart`
- Frontend Service: `lib/services/goal_service.dart`
- Frontend Screen: `lib/screens/home_screen.dart`

