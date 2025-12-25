# Notifications API Documentation

This document describes the backend API requirements for implementing in-app notifications in the Growcoins application.

## Overview

The notification system allows the app to send and store notifications for various events like goal creation, goal progress updates, savings updates, etc. Notifications are stored in the database and can be retrieved, marked as read, and deleted.

---

## Database Schema

### Table: `notifications`

```sql
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE
);

-- Indexes for better performance
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read);
```

### Notification Types

- `goal_created` - When a new goal is created
- `goal_progress` - When progress is made on a goal
- `goal_completed` - When a goal is completed
- `savings_update` - When savings/roundoff amount is updated
- `system` - System notifications

---

## API Endpoints

### Base URL
```
http://localhost:3001/api/notifications
```

---

### 1. Get User Notifications

**Endpoint:** `GET /api/notifications/user/:user_id`

**Description:** Get all notifications for a user with pagination and filtering options.

**URL Parameters:**
- `user_id` (required): Integer - The user's ID

**Query Parameters:**
- `is_read` (optional): Boolean - Filter by read status (`true` or `false`)
- `limit` (optional): Integer - Number of notifications to return (default: 50, max: 100)
- `offset` (optional): Integer - Pagination offset (default: 0)

**Success Response (200 OK):**
```json
{
  "notifications": [
    {
      "id": 1,
      "user_id": 1,
      "type": "goal_created",
      "title": "Goal Created!",
      "message": "Your goal 'iPhone 15 Pro' has been created successfully.",
      "data": {
        "goal_id": 5,
        "goal_name": "iPhone 15 Pro",
        "target_amount": 80000
      },
      "is_read": false,
      "created_at": "2025-01-20T10:30:00.000Z",
      "read_at": null
    },
    {
      "id": 2,
      "user_id": 1,
      "type": "goal_progress",
      "title": "Great Progress!",
      "message": "You've saved ₹5,000 towards your 'iPhone 15 Pro' goal (6.25% complete).",
      "data": {
        "goal_id": 5,
        "goal_name": "iPhone 15 Pro",
        "progress_percentage": 6.25,
        "current_amount": 5000,
        "target_amount": 80000
      },
      "is_read": false,
      "created_at": "2025-01-21T14:20:00.000Z",
      "read_at": null
    }
  ],
  "total": 15,
  "unread_count": 8,
  "limit": 50,
  "offset": 0
}
```

**SQL Query Example:**
```sql
SELECT 
  n.*,
  COUNT(*) OVER() as total,
  COUNT(*) FILTER (WHERE n.is_read = false) OVER() as unread_count
FROM notifications n
WHERE n.user_id = $1
  AND ($2::boolean IS NULL OR n.is_read = $2)
ORDER BY n.created_at DESC
LIMIT $3 OFFSET $4;
```

---

### 2. Get Unread Notification Count

**Endpoint:** `GET /api/notifications/user/:user_id/unread-count`

**Description:** Get the count of unread notifications for a user (for badge display).

**URL Parameters:**
- `user_id` (required): Integer - The user's ID

**Success Response (200 OK):**
```json
{
  "unread_count": 8
}
```

**SQL Query Example:**
```sql
SELECT COUNT(*) as unread_count
FROM notifications
WHERE user_id = $1 AND is_read = false;
```

---

### 3. Mark Notification as Read

**Endpoint:** `PUT /api/notifications/:notification_id/read`

**Description:** Mark a specific notification as read.

**URL Parameters:**
- `notification_id` (required): Integer - The notification's ID

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

**SQL Query Example:**
```sql
UPDATE notifications
SET is_read = true, read_at = CURRENT_TIMESTAMP
WHERE id = $1 AND user_id = $2
RETURNING *;
```

---

### 4. Mark All Notifications as Read

**Endpoint:** `PUT /api/notifications/user/:user_id/read-all`

**Description:** Mark all notifications for a user as read.

**URL Parameters:**
- `user_id` (required): Integer - The user's ID

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "All notifications marked as read",
  "updated_count": 8
}
```

**SQL Query Example:**
```sql
UPDATE notifications
SET is_read = true, read_at = CURRENT_TIMESTAMP
WHERE user_id = $1 AND is_read = false
RETURNING id;
```

---

### 5. Delete Notification

**Endpoint:** `DELETE /api/notifications/:notification_id`

**Description:** Delete a specific notification.

**URL Parameters:**
- `notification_id` (required): Integer - The notification's ID

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Notification deleted"
}
```

**SQL Query Example:**
```sql
DELETE FROM notifications
WHERE id = $1 AND user_id = $2;
```

---

### 6. Delete All Notifications

**Endpoint:** `DELETE /api/notifications/user/:user_id`

**Description:** Delete all notifications for a user.

**URL Parameters:**
- `user_id` (required): Integer - The user's ID

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "All notifications deleted",
  "deleted_count": 15
}
```

**SQL Query Example:**
```sql
DELETE FROM notifications
WHERE user_id = $1;
```

---

### 7. Create Notification (Internal/Backend Use)

**Endpoint:** `POST /api/notifications`

**Description:** Create a new notification (typically called by backend when events occur).

**Request Body:**
```json
{
  "user_id": 1,
  "type": "goal_created",
  "title": "Goal Created!",
  "message": "Your goal 'iPhone 15 Pro' has been created successfully.",
  "data": {
    "goal_id": 5,
    "goal_name": "iPhone 15 Pro",
    "target_amount": 80000
  }
}
```

**Success Response (201 Created):**
```json
{
  "success": true,
  "notification": {
    "id": 1,
    "user_id": 1,
    "type": "goal_created",
    "title": "Goal Created!",
    "message": "Your goal 'iPhone 15 Pro' has been created successfully.",
    "data": {
      "goal_id": 5,
      "goal_name": "iPhone 15 Pro",
      "target_amount": 80000
    },
    "is_read": false,
    "created_at": "2025-01-20T10:30:00.000Z",
    "read_at": null
  }
}
```

**SQL Query Example:**
```sql
INSERT INTO notifications (user_id, type, title, message, data)
VALUES ($1, $2, $3, $4, $5::jsonb)
RETURNING *;
```

---

## Backend Implementation Guide

### Step 1: Create Database Migration

Create a migration file `migrations/add_notifications_table.js`:

```javascript
const { query } = require('../config/database');

async function up() {
  await query(`
    CREATE TABLE IF NOT EXISTS notifications (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
      type VARCHAR(50) NOT NULL,
      title VARCHAR(255) NOT NULL,
      message TEXT NOT NULL,
      data JSONB,
      is_read BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      read_at TIMESTAMP,
      CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
    CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
    CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
  `);
  console.log('Notifications table created');
}

async function down() {
  await query('DROP TABLE IF EXISTS notifications CASCADE');
  console.log('Notifications table dropped');
}

module.exports = { up, down };
```

### Step 2: Create Notifications Route

Create `routes/notifications.js`:

```javascript
const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { body, param, query: queryCheck, validationResult } = require('express-validator');

// Helper function to create notification
async function createNotification(userId, type, title, message, data = null) {
  try {
    const result = await query(
      `INSERT INTO notifications (user_id, type, title, message, data)
       VALUES ($1, $2, $3, $4, $5::jsonb)
       RETURNING *`,
      [userId, type, title, message, data ? JSON.stringify(data) : null]
    );
    return result.rows[0];
  } catch (error) {
    console.error('Error creating notification:', error);
    throw error;
  }
}

// Get user notifications
router.get('/user/:user_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
  queryCheck('is_read').optional().isBoolean().withMessage('is_read must be boolean'),
  queryCheck('limit').optional().isInt({ min: 1, max: 100 }),
  queryCheck('offset').optional().isInt({ min: 0 }),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id } = req.params;
    const isRead = req.query.is_read === 'true' ? true : req.query.is_read === 'false' ? false : null;
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    // Build query
    let queryText = `
      SELECT 
        n.*,
        COUNT(*) OVER() as total,
        COUNT(*) FILTER (WHERE n.is_read = false) OVER() as unread_count
      FROM notifications n
      WHERE n.user_id = $1
    `;
    const params = [user_id];
    let paramIndex = 2;

    if (isRead !== null) {
      queryText += ` AND n.is_read = $${paramIndex}`;
      params.push(isRead);
      paramIndex++;
    }

    queryText += ` ORDER BY n.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const result = await query(queryText, params);

    const notifications = result.rows.map(row => ({
      id: row.id,
      user_id: row.user_id,
      type: row.type,
      title: row.title,
      message: row.message,
      data: row.data,
      is_read: row.is_read,
      created_at: row.created_at,
      read_at: row.read_at,
    }));

    res.json({
      notifications,
      total: result.rows.length > 0 ? parseInt(result.rows[0].total) : 0,
      unread_count: result.rows.length > 0 ? parseInt(result.rows[0].unread_count) : 0,
      limit,
      offset,
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ error: 'Failed to get notifications' });
  }
});

// Get unread count
router.get('/user/:user_id/unread-count', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const { user_id } = req.params;
    const result = await query(
      'SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = $1 AND is_read = false',
      [user_id]
    );
    res.json({ unread_count: parseInt(result.rows[0].unread_count) });
  } catch (error) {
    console.error('Get unread count error:', error);
    res.status(500).json({ error: 'Failed to get unread count' });
  }
});

// Mark notification as read
router.put('/:notification_id/read', [
  param('notification_id').isInt().withMessage('Notification ID must be an integer'),
], async (req, res) => {
  try {
    const { notification_id } = req.params;
    const result = await query(
      `UPDATE notifications
       SET is_read = true, read_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [notification_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    res.json({
      success: true,
      message: 'Notification marked as read',
    });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ error: 'Failed to mark notification as read' });
  }
});

// Mark all as read
router.put('/user/:user_id/read-all', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const { user_id } = req.params;
    const result = await query(
      `UPDATE notifications
       SET is_read = true, read_at = CURRENT_TIMESTAMP
       WHERE user_id = $1 AND is_read = false
       RETURNING id`,
      [user_id]
    );

    res.json({
      success: true,
      message: 'All notifications marked as read',
      updated_count: result.rows.length,
    });
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({ error: 'Failed to mark all notifications as read' });
  }
});

// Delete notification
router.delete('/:notification_id', [
  param('notification_id').isInt().withMessage('Notification ID must be an integer'),
], async (req, res) => {
  try {
    const { notification_id } = req.params;
    const result = await query(
      'DELETE FROM notifications WHERE id = $1 RETURNING id',
      [notification_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    res.json({
      success: true,
      message: 'Notification deleted',
    });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({ error: 'Failed to delete notification' });
  }
});

// Delete all notifications
router.delete('/user/:user_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const { user_id } = req.params;
    const result = await query(
      'DELETE FROM notifications WHERE user_id = $1 RETURNING id',
      [user_id]
    );

    res.json({
      success: true,
      message: 'All notifications deleted',
      deleted_count: result.rows.length,
    });
  } catch (error) {
    console.error('Delete all notifications error:', error);
    res.status(500).json({ error: 'Failed to delete all notifications' });
  }
});

// Create notification (internal use)
router.post('/', [
  body('user_id').isInt().withMessage('User ID must be an integer'),
  body('type').isIn(['goal_created', 'goal_progress', 'goal_completed', 'savings_update', 'system'])
    .withMessage('Invalid notification type'),
  body('title').notEmpty().withMessage('Title is required'),
  body('message').notEmpty().withMessage('Message is required'),
  body('data').optional().isObject(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id, type, title, message, data } = req.body;

    const notification = await createNotification(user_id, type, title, message, data);

    res.status(201).json({
      success: true,
      notification,
    });
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({ error: 'Failed to create notification' });
  }
});

// Export helper function for use in other routes
module.exports = router;
module.exports.createNotification = createNotification;
```

### Step 3: Register Route in server.js

Add to `server.js`:

```javascript
app.use('/api/notifications', require('./routes/notifications'));
```

### Step 4: Integrate with Goal Creation

Update `routes/goals.js` to create notifications when goals are created:

```javascript
const { createNotification } = require('./notifications');

// In the POST /api/goals route, after goal creation:
const goal = result.rows[0];

// Create notification
try {
  await createNotification(
    user_id,
    'goal_created',
    'Goal Created!',
    `Your goal '${goal.goal_name}' has been created successfully.`,
    {
      goal_id: goal.id,
      goal_name: goal.goal_name,
      target_amount: goal.target_amount,
    }
  );
} catch (error) {
  console.error('Error creating notification:', error);
  // Don't fail the goal creation if notification fails
}
```

### Step 5: Integrate with Goal Progress Updates

When goal progress is updated (e.g., when savings are added), create progress notifications:

```javascript
// When goal progress reaches milestones (10%, 25%, 50%, 75%, 90%)
const progressPercentage = (currentAmount / targetAmount) * 100;
const milestones = [10, 25, 50, 75, 90];

if (milestones.includes(Math.floor(progressPercentage))) {
  await createNotification(
    user_id,
    'goal_progress',
    'Great Progress!',
    `You've reached ${Math.floor(progressPercentage)}% of your '${goalName}' goal!`,
    {
      goal_id: goalId,
      goal_name: goalName,
      progress_percentage: progressPercentage,
      current_amount: currentAmount,
      target_amount: targetAmount,
    }
  );
}
```

### Step 6: Integrate with Goal Completion

When a goal is completed:

```javascript
if (progressPercentage >= 100) {
  await createNotification(
    user_id,
    'goal_completed',
    'Goal Completed! 🎉',
    `Congratulations! You've completed your '${goalName}' goal!`,
    {
      goal_id: goalId,
      goal_name: goalName,
      target_amount: targetAmount,
    }
  );
}
```

---

## Testing

### Test with cURL

```bash
# Get notifications
curl http://localhost:3001/api/notifications/user/1

# Get unread count
curl http://localhost:3001/api/notifications/user/1/unread-count

# Mark as read
curl -X PUT http://localhost:3001/api/notifications/1/read

# Mark all as read
curl -X PUT http://localhost:3001/api/notifications/user/1/read-all

# Create notification
curl -X POST http://localhost:3001/api/notifications \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "type": "goal_created",
    "title": "Goal Created!",
    "message": "Your goal has been created.",
    "data": {"goal_id": 5}
  }'

# Delete notification
curl -X DELETE http://localhost:3001/api/notifications/1
```

---

## Summary Checklist

- [ ] Create `notifications` table with migration
- [ ] Create `routes/notifications.js` with all endpoints
- [ ] Register route in `server.js`
- [ ] Export `createNotification` helper function
- [ ] Integrate notification creation in goal creation endpoint
- [ ] Integrate notification creation in goal progress updates
- [ ] Integrate notification creation in goal completion
- [ ] Test all endpoints with cURL
- [ ] Verify notifications appear in Flutter app

---

## Notes

1. **Performance**: Indexes are created for optimal query performance
2. **Cascading Deletes**: When a user is deleted, all their notifications are automatically deleted
3. **Data Field**: The `data` field stores JSON for additional context (goal_id, amounts, etc.)
4. **Read Timestamps**: `read_at` is automatically set when marking as read
5. **Error Handling**: Notification creation failures should not break the main operation (goal creation, etc.)

