const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { body, validationResult } = require('express-validator');

// Save Personal Details (Screen 1)
router.post('/personal-details', [
  body('user_id').isInt().withMessage('User ID is required'),
  body('full_legal_name').trim().notEmpty().withMessage('Full legal name is required'),
  body('email').isEmail().withMessage('Please provide a valid email'),
  body('date_of_birth').isISO8601().withMessage('Please provide a valid date (YYYY-MM-DD format)'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id, full_legal_name, email, date_of_birth } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if email is already taken by another user
    const emailCheck = await query(
      'SELECT user_id FROM user_data WHERE email = $1 AND user_id != $2',
      [email, user_id]
    );
    if (emailCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Email already in use' });
    }

    // Check if user_data exists, if not create it
    const userDataCheck = await query('SELECT id FROM user_data WHERE user_id = $1', [user_id]);
    
    if (userDataCheck.rows.length === 0) {
      // Create new user_data record
      const accountNumber = `GC${Date.now()}${Math.floor(Math.random() * 1000)}`;
      
      // Split full_legal_name into first_name and last_name
      const nameParts = full_legal_name.trim().split(' ');
      const firstName = nameParts[0] || '';
      const lastName = nameParts.slice(1).join(' ') || '';

      await query(
        `INSERT INTO user_data (user_id, full_legal_name, first_name, last_name, email, date_of_birth, account_number)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [user_id, full_legal_name, firstName, lastName, email, date_of_birth, accountNumber]
      );
    } else {
      // Update existing user_data record
      const nameParts = full_legal_name.trim().split(' ');
      const firstName = nameParts[0] || '';
      const lastName = nameParts.slice(1).join(' ') || '';

      await query(
        `UPDATE user_data 
         SET full_legal_name = $1, first_name = $2, last_name = $3, email = $4, date_of_birth = $5
         WHERE user_id = $6`,
        [full_legal_name, firstName, lastName, email, date_of_birth, user_id]
      );
    }

    // Fetch updated user data
    const result = await query(
      `SELECT 
        a.id, a.username, a.created_at as account_created_at, a.last_login,
        u.*
       FROM authentication a
       LEFT JOIN user_data u ON a.id = u.user_id
       WHERE a.id = $1`,
      [user_id]
    );

    res.json({
      message: 'Personal details saved successfully',
      user: result.rows[0]
    });
  } catch (error) {
    console.error('Save personal details error:', error);
    res.status(500).json({ error: 'Failed to save personal details' });
  }
});

// Save KYC Details (Screen 2)
router.post('/kyc-details', [
  body('user_id').isInt().withMessage('User ID is required'),
  body('pan_number').matches(/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/).withMessage('Invalid PAN number format'),
  body('aadhar_number').matches(/^[0-9]{12}$/).withMessage('Aadhar number must be 12 digits'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id, pan_number, aadhar_number } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if PAN number is already taken by another user
    const panCheck = await query(
      'SELECT user_id FROM user_data WHERE pan_number = $1 AND user_id != $2',
      [pan_number, user_id]
    );
    if (panCheck.rows.length > 0) {
      return res.status(400).json({ error: 'PAN number already in use' });
    }

    // Check if Aadhar number is already taken by another user
    const aadharCheck = await query(
      'SELECT user_id FROM user_data WHERE aadhar_number = $1 AND user_id != $2',
      [aadhar_number, user_id]
    );
    if (aadharCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Aadhar number already in use' });
    }

    // Check if user_data exists
    const userDataCheck = await query('SELECT id FROM user_data WHERE user_id = $1', [user_id]);
    
    if (userDataCheck.rows.length === 0) {
      return res.status(400).json({ error: 'Please complete personal details first' });
    }

    // Update KYC details
    await query(
      `UPDATE user_data 
       SET pan_number = $1, aadhar_number = $2, kyc_status = 'submitted'
       WHERE user_id = $3`,
      [pan_number, aadhar_number, user_id]
    );

    // Fetch updated user data
    const result = await query(
      `SELECT 
        a.id, a.username, a.created_at as account_created_at, a.last_login,
        u.*
       FROM authentication a
       LEFT JOIN user_data u ON a.id = u.user_id
       WHERE a.id = $1`,
      [user_id]
    );

    res.json({
      message: 'KYC details saved successfully',
      user: result.rows[0],
      kyc_status: 'submitted'
    });
  } catch (error) {
    console.error('Save KYC details error:', error);
    res.status(500).json({ error: 'Failed to save KYC details' });
  }
});

// Get onboarding status
router.get('/status/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;

    const result = await query(
      `SELECT 
        u.full_legal_name, u.email, u.date_of_birth,
        u.pan_number, u.aadhar_number, u.kyc_status
       FROM user_data u
       WHERE u.user_id = $1`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.json({
        personal_details_completed: false,
        kyc_details_completed: false,
        kyc_status: 'pending'
      });
    }

    const userData = result.rows[0];
    const personalDetailsCompleted = !!(userData.full_legal_name && userData.email && userData.date_of_birth);
    const kycDetailsCompleted = !!(userData.pan_number && userData.aadhar_number);

    res.json({
      personal_details_completed: personalDetailsCompleted,
      kyc_details_completed: kycDetailsCompleted,
      kyc_status: userData.kyc_status || 'pending',
      user_data: userData
    });
  } catch (error) {
    console.error('Get onboarding status error:', error);
    res.status(500).json({ error: 'Failed to get onboarding status' });
  }
});

// Complete onboarding (mark as complete)
router.post('/complete/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;

    // Check if all required fields are filled
    const result = await query(
      `SELECT 
        full_legal_name, email, date_of_birth, pan_number, aadhar_number
       FROM user_data
       WHERE user_id = $1`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = result.rows[0];
    const missingFields = [];

    if (!userData.full_legal_name) missingFields.push('full_legal_name');
    if (!userData.email) missingFields.push('email');
    if (!userData.date_of_birth) missingFields.push('date_of_birth');
    if (!userData.pan_number) missingFields.push('pan_number');
    if (!userData.aadhar_number) missingFields.push('aadhar_number');

    if (missingFields.length > 0) {
      return res.status(400).json({
        error: 'Please complete all required fields',
        missing_fields: missingFields
      });
    }

    // Update KYC status to verified (or keep as submitted if verification is manual)
    await query(
      `UPDATE user_data 
       SET kyc_status = 'submitted', kyc_verified_at = CURRENT_TIMESTAMP
       WHERE user_id = $1`,
      [user_id]
    );

    // Fetch updated user data
    const updatedResult = await query(
      `SELECT 
        a.id, a.username, a.created_at as account_created_at, a.last_login,
        u.*
       FROM authentication a
       LEFT JOIN user_data u ON a.id = u.user_id
       WHERE a.id = $1`,
      [user_id]
    );

    res.json({
      message: 'Onboarding completed successfully',
      user: updatedResult.rows[0]
    });
  } catch (error) {
    console.error('Complete onboarding error:', error);
    res.status(500).json({ error: 'Failed to complete onboarding' });
  }
});

module.exports = router;

