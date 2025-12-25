const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { body, param, query: queryCheck, validationResult } = require('express-validator');

/**
 * Helper function to create notification
 * Can be used by other routes to create notifications
 */
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

// 1. Get User Notifications
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
    const isReadParam = req.query.is_read;
    const isRead = isReadParam === 'true' ? true : isReadParam === 'false' ? false : null;
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

// 2. Get Unread Notification Count
router.get('/user/:user_id/unread-count', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id } = req.params;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const result = await query(
      'SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = $1 AND is_read = false',
      [user_id]
    );

    res.json({ 
      unread_count: parseInt(result.rows[0].unread_count) 
    });
  } catch (error) {
    console.error('Get unread count error:', error);
    res.status(500).json({ error: 'Failed to get unread count' });
  }
});

// 3. Mark Notification as Read
router.put('/:notification_id/read', [
  param('notification_id').isInt().withMessage('Notification ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { notification_id } = req.params;

    const result = await query(
      `UPDATE notifications
       SET is_read = true, read_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [notification_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Notification not found' 
      });
    }

    res.json({
      success: true,
      message: 'Notification marked as read',
    });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to mark notification as read' 
    });
  }
});

// 4. Mark All Notifications as Read
router.put('/user/:user_id/read-all', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id } = req.params;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

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
    res.status(500).json({ 
      success: false,
      error: 'Failed to mark all notifications as read' 
    });
  }
});

// 5. Delete Notification
router.delete('/:notification_id', [
  param('notification_id').isInt().withMessage('Notification ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { notification_id } = req.params;

    const result = await query(
      'DELETE FROM notifications WHERE id = $1 RETURNING id',
      [notification_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Notification not found' 
      });
    }

    res.json({
      success: true,
      message: 'Notification deleted',
    });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to delete notification' 
    });
  }
});

// 6. Delete All Notifications
router.delete('/user/:user_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id } = req.params;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

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
    res.status(500).json({ 
      success: false,
      error: 'Failed to delete all notifications' 
    });
  }
});

// 7. Create Notification (Internal/Backend Use)
router.post('/', [
  body('user_id').isInt().withMessage('User ID must be an integer'),
  body('type').isIn(['goal_created', 'goal_progress', 'goal_completed', 'savings_update', 'system'])
    .withMessage('Invalid notification type'),
  body('title').trim().notEmpty().withMessage('Title is required'),
  body('message').trim().notEmpty().withMessage('Message is required'),
  body('data').optional().isObject().withMessage('Data must be an object'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id, type, title, message, data } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }

    const notification = await createNotification(user_id, type, title, message, data);

    res.status(201).json({
      success: true,
      notification,
    });
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to create notification' 
    });
  }
});

// Export helper function for use in other routes
module.exports = router;
module.exports.createNotification = createNotification;

