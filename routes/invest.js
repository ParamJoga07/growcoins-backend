const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { body, param, validationResult } = require('express-validator');

// Get Invest Profile
router.get('/profile/:user_id', [
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
      'SELECT * FROM invest_profiles WHERE user_id = $1',
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.json({
        profile: null
      });
    }

    res.json({
      profile: result.rows[0]
    });
  } catch (error) {
    console.error('Get invest profile error:', error);
    res.status(500).json({ error: 'Failed to get invest profile' });
  }
});

// Create or Update Invest Profile
router.post('/profile', [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
  body('risk_profile').isIn(['Conservative', 'Moderate', 'Aggressive']).withMessage('Risk profile must be Conservative, Moderate, or Aggressive'),
  body('investment_preference').optional().isString(),
  body('auto_invest_enabled').optional().isBoolean(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: errors.array().map(e => ({
          field: e.param,
          msg: e.msg
        }))
      });
    }

    const { user_id, risk_profile, investment_preference, auto_invest_enabled = false } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Insert or update profile
    const result = await query(
      `INSERT INTO invest_profiles (user_id, risk_profile, investment_preference, auto_invest_enabled)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id)
       DO UPDATE SET
         risk_profile = EXCLUDED.risk_profile,
         investment_preference = EXCLUDED.investment_preference,
         auto_invest_enabled = EXCLUDED.auto_invest_enabled,
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [user_id, risk_profile, investment_preference || null, auto_invest_enabled]
    );

    res.json({
      success: true,
      message: 'Invest profile saved successfully',
      profile: result.rows[0]
    });
  } catch (error) {
    console.error('Save invest profile error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to save invest profile'
    });
  }
});

module.exports = router;

