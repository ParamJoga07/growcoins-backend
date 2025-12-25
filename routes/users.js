const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { body, validationResult } = require('express-validator');

// Get user profile by ID
router.get('/profile/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT 
        a.id, 
        a.username, 
        a.created_at as account_created_at, 
        a.last_login,
        a.is_active,
        a.biometric_enabled,
        u.id as user_data_id,
        u.first_name,
        u.last_name,
        u.full_legal_name,
        u.email,
        u.phone_number,
        u.date_of_birth,
        u.address,
        u.city,
        u.state,
        u.zip_code,
        u.country,
        u.account_number,
        u.routing_number,
        u.account_balance,
        u.currency,
        u.kyc_status,
        u.kyc_verified_at,
        u.profile_picture_url,
        u.pan_number,
        u.aadhar_number,
        u.created_at,
        u.updated_at
       FROM authentication a
       LEFT JOIN user_data u ON a.id = u.user_id
       WHERE a.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }

    const user = result.rows[0];
    
    // Format the response with proper data types
    res.json({ 
      success: true,
      profile: {
        id: user.id,
        username: user.username,
        account_created_at: user.account_created_at,
        last_login: user.last_login,
        is_active: user.is_active,
        biometric_enabled: user.biometric_enabled,
        personal_info: {
          first_name: user.first_name,
          last_name: user.last_name,
          full_legal_name: user.full_legal_name,
          email: user.email,
          phone_number: user.phone_number,
          date_of_birth: user.date_of_birth,
          profile_picture_url: user.profile_picture_url
        },
        address: {
          address: user.address,
          city: user.city,
          state: user.state,
          zip_code: user.zip_code,
          country: user.country
        },
        financial_info: {
          account_number: user.account_number,
          routing_number: user.routing_number,
          account_balance: parseFloat(user.account_balance || 0),
          currency: user.currency || 'INR'
        },
        kyc_info: {
          kyc_status: user.kyc_status,
          kyc_verified_at: user.kyc_verified_at,
          pan_number: user.pan_number,
          aadhar_number: user.aadhar_number
        },
        timestamps: {
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch user profile' 
    });
  }
});

// Get user by ID (legacy endpoint - kept for backward compatibility)
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT 
        a.id, a.username, a.created_at as account_created_at, a.last_login,
        u.*
       FROM authentication a
       LEFT JOIN user_data u ON a.id = u.user_id
       WHERE a.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: result.rows[0] });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// Update user profile
router.put('/profile/:id', [
  body('email').optional().isEmail().withMessage('Please provide a valid email'),
  body('phone_number').optional().isMobilePhone().withMessage('Please provide a valid phone number'),
  body('date_of_birth').optional().isISO8601().toDate().withMessage('Invalid date format (YYYY-MM-DD)'),
  body('pan_number').optional().matches(/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/).withMessage('Invalid PAN number format'),
  body('aadhar_number').optional().matches(/^[0-9]{12}$/).withMessage('Aadhar number must be 12 digits'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const {
      first_name,
      last_name,
      full_legal_name,
      email,
      phone_number,
      date_of_birth,
      address,
      city,
      state,
      zip_code,
      country,
      profile_picture_url,
      pan_number,
      aadhar_number
    } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM user_data WHERE user_id = $1', [id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Build update query dynamically
    const updateFields = [];
    const values = [];
    let paramCount = 1;

    if (first_name !== undefined) {
      updateFields.push(`first_name = $${paramCount++}`);
      values.push(first_name);
    }
    if (last_name !== undefined) {
      updateFields.push(`last_name = $${paramCount++}`);
      values.push(last_name);
    }
    if (email !== undefined) {
      // Check if email is already taken by another user
      const emailCheck = await query('SELECT user_id FROM user_data WHERE email = $1 AND user_id != $2', [email, id]);
      if (emailCheck.rows.length > 0) {
        return res.status(400).json({ error: 'Email already in use' });
      }
      updateFields.push(`email = $${paramCount++}`);
      values.push(email);
    }
    if (phone_number !== undefined) {
      updateFields.push(`phone_number = $${paramCount++}`);
      values.push(phone_number);
    }
    if (date_of_birth !== undefined) {
      updateFields.push(`date_of_birth = $${paramCount++}`);
      values.push(date_of_birth);
    }
    if (address !== undefined) {
      updateFields.push(`address = $${paramCount++}`);
      values.push(address);
    }
    if (city !== undefined) {
      updateFields.push(`city = $${paramCount++}`);
      values.push(city);
    }
    if (state !== undefined) {
      updateFields.push(`state = $${paramCount++}`);
      values.push(state);
    }
    if (zip_code !== undefined) {
      updateFields.push(`zip_code = $${paramCount++}`);
      values.push(zip_code);
    }
    if (country !== undefined) {
      updateFields.push(`country = $${paramCount++}`);
      values.push(country);
    }
    if (profile_picture_url !== undefined) {
      updateFields.push(`profile_picture_url = $${paramCount++}`);
      values.push(profile_picture_url);
    }
    if (full_legal_name !== undefined) {
      updateFields.push(`full_legal_name = $${paramCount++}`);
      values.push(full_legal_name);
    }
    if (pan_number !== undefined) {
      // Validate PAN format
      if (!/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(pan_number)) {
        return res.status(400).json({ error: 'Invalid PAN number format' });
      }
      // Check if PAN is already taken
      const panCheck = await query('SELECT user_id FROM user_data WHERE pan_number = $1 AND user_id != $2', [pan_number, id]);
      if (panCheck.rows.length > 0) {
        return res.status(400).json({ error: 'PAN number already in use' });
      }
      updateFields.push(`pan_number = $${paramCount++}`);
      values.push(pan_number);
    }
    if (aadhar_number !== undefined) {
      // Validate Aadhar format
      if (!/^[0-9]{12}$/.test(aadhar_number)) {
        return res.status(400).json({ error: 'Aadhar number must be 12 digits' });
      }
      // Check if Aadhar is already taken
      const aadharCheck = await query('SELECT user_id FROM user_data WHERE aadhar_number = $1 AND user_id != $2', [aadhar_number, id]);
      if (aadharCheck.rows.length > 0) {
        return res.status(400).json({ error: 'Aadhar number already in use' });
      }
      updateFields.push(`aadhar_number = $${paramCount++}`);
      values.push(aadhar_number);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    values.push(id);
    const updateQuery = `UPDATE user_data SET ${updateFields.join(', ')} WHERE user_id = $${paramCount}`;

    await query(updateQuery, values);

    // Fetch updated user data
    const result = await query(
      `SELECT 
        a.id, 
        a.username, 
        a.created_at as account_created_at, 
        a.last_login,
        a.is_active,
        a.biometric_enabled,
        u.id as user_data_id,
        u.first_name,
        u.last_name,
        u.full_legal_name,
        u.email,
        u.phone_number,
        u.date_of_birth,
        u.address,
        u.city,
        u.state,
        u.zip_code,
        u.country,
        u.account_number,
        u.routing_number,
        u.account_balance,
        u.currency,
        u.kyc_status,
        u.kyc_verified_at,
        u.profile_picture_url,
        u.pan_number,
        u.aadhar_number,
        u.created_at,
        u.updated_at
       FROM authentication a
       LEFT JOIN user_data u ON a.id = u.user_id
       WHERE a.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }

    const user = result.rows[0];

    res.json({
      success: true,
      message: 'Profile updated successfully',
      profile: {
        id: user.id,
        username: user.username,
        account_created_at: user.account_created_at,
        last_login: user.last_login,
        is_active: user.is_active,
        biometric_enabled: user.biometric_enabled,
        personal_info: {
          first_name: user.first_name,
          last_name: user.last_name,
          full_legal_name: user.full_legal_name,
          email: user.email,
          phone_number: user.phone_number,
          date_of_birth: user.date_of_birth,
          profile_picture_url: user.profile_picture_url
        },
        address: {
          address: user.address,
          city: user.city,
          state: user.state,
          zip_code: user.zip_code,
          country: user.country
        },
        financial_info: {
          account_number: user.account_number,
          routing_number: user.routing_number,
          account_balance: parseFloat(user.account_balance || 0),
          currency: user.currency || 'INR'
        },
        kyc_info: {
          kyc_status: user.kyc_status,
          kyc_verified_at: user.kyc_verified_at,
          pan_number: user.pan_number,
          aadhar_number: user.aadhar_number
        },
        timestamps: {
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      }
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// Get all users (for admin purposes - you may want to add authentication/authorization)
router.get('/', async (req, res) => {
  try {
    const result = await query(
      `SELECT 
        a.id, a.username, a.created_at as account_created_at, a.last_login, a.is_active,
        u.first_name, u.last_name, u.email, u.account_number, u.account_balance
       FROM authentication a
       LEFT JOIN user_data u ON a.id = u.user_id
       ORDER BY a.created_at DESC`
    );

    res.json({ users: result.rows });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Update account balance (for fintech operations)
router.patch('/:id/balance', [
  body('amount').isFloat({ min: 0 }).withMessage('Amount must be a positive number'),
  body('operation').isIn(['add', 'subtract', 'set']).withMessage('Operation must be add, subtract, or set'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const { amount, operation } = req.body;

    // Get current balance
    const currentBalance = await query('SELECT account_balance FROM user_data WHERE user_id = $1', [id]);
    if (currentBalance.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    let newBalance;
    const current = parseFloat(currentBalance.rows[0].account_balance);

    switch (operation) {
      case 'add':
        newBalance = current + amount;
        break;
      case 'subtract':
        if (current < amount) {
          return res.status(400).json({ error: 'Insufficient balance' });
        }
        newBalance = current - amount;
        break;
      case 'set':
        newBalance = amount;
        break;
    }

    await query('UPDATE user_data SET account_balance = $1 WHERE user_id = $2', [newBalance, id]);

    res.json({
      message: 'Balance updated successfully',
      previous_balance: current,
      new_balance: newBalance
    });
  } catch (error) {
    console.error('Update balance error:', error);
    res.status(500).json({ error: 'Failed to update balance' });
  }
});

module.exports = router;

