const express = require('express');
const router = express.Router();
const multer = require('multer');
const { query } = require('../config/database');
const { body, param, validationResult } = require('express-validator');
const pdfParser = require('../services/pdfParser');
const roundoffCalculator = require('../services/roundoffCalculator');
const fs = require('fs');
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'statement-' + uniqueSuffix + '.pdf');
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf') {
      cb(null, true);
    } else {
      cb(new Error('Only PDF files are allowed'));
    }
  }
});

// Set Roundoff Amount (Enhanced with goal_id support)
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

    // Validate roundoff amount (should be 5, 10, 20, 30, or custom)
    const validAmounts = [5, 10, 20, 30];
    if (!validAmounts.includes(roundoff_amount) && roundoff_amount < 1) {
      return res.status(400).json({
        success: false,
        error: 'Invalid roundoff amount. Use 5, 10, 20, 30, or a custom positive number'
      });
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
      [user_id, roundoff_amount, goal_id || null]
    );

    res.json({
      success: true,
      message: 'Roundoff amount updated successfully',
      setting: result.rows[0]
    });
  } catch (error) {
    console.error('Set roundoff error:', error);
    res.status(500).json({ success: false, error: 'Failed to update roundoff amount' });
  }
});

// Upload and Process Bank Statement PDF
router.post('/upload', upload.single('statement'), [
  body('user_id').isInt().withMessage('User ID is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'PDF file is required' });
    }

    const { user_id } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      // Clean up uploaded file
      fs.unlinkSync(req.file.path);
      return res.status(404).json({ error: 'User not found' });
    }

    // Get user's roundoff setting (default to 10 if not set)
    const roundoffResult = await query(
      'SELECT roundoff_amount FROM roundoff_settings WHERE user_id = $1',
      [user_id]
    );
    const roundoffAmount = roundoffResult.rows[0]?.roundoff_amount || 10;

    // Read PDF file
    const pdfBuffer = fs.readFileSync(req.file.path);

    // Parse PDF
    let transactions;
    try {
      transactions = await pdfParser.parseBankStatement(pdfBuffer);
    } catch (parseError) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ 
        error: 'Failed to parse PDF. Please ensure it is a valid bank statement.',
        details: parseError.message
      });
    }

    if (transactions.length === 0) {
      // Don't delete the file yet - might need for debugging
      return res.status(400).json({ 
        error: 'No withdrawal transactions found in PDF',
        message: 'The PDF was parsed successfully, but no withdrawal transactions were detected. Please ensure your bank statement contains transaction details with dates and amounts.',
        suggestion: 'Try uploading a different bank statement or contact support if this issue persists.'
      });
    }

    // IMPORTANT: Clear previous data for this user before inserting new data
    // This ensures each upload replaces previous data instead of accumulating
    console.log(`Clearing previous transactions and savings for user ${user_id}...`);
    
    // Delete all previous transactions for this user
    await query(
      'DELETE FROM transactions WHERE user_id = $1',
      [user_id]
    );
    
    // Delete all previous roundoff savings for this user
    await query(
      'DELETE FROM roundoff_savings WHERE user_id = $1',
      [user_id]
    );
    
    // Mark previous bank statements as replaced (optional - for history)
    await query(
      `UPDATE bank_statements 
       SET status = 'replaced' 
       WHERE user_id = $1 AND status = 'completed'`,
      [user_id]
    );

    // Save bank statement record
    const statementResult = await query(
      `INSERT INTO bank_statements (user_id, file_name, file_path, status)
       VALUES ($1, $2, $3, 'processing')
       RETURNING *`,
      [user_id, req.file.filename, req.file.path]
    );
    const statementId = statementResult.rows[0].id;

    // Calculate roundoff for each transaction
    const transactionsWithRoundoff = roundoffCalculator.calculateRoundoffForTransactions(
      transactions,
      roundoffAmount
    );

    // Debug: Log first few transactions with roundoff
    console.log(`\n=== Roundoff Calculation Debug ===`);
    console.log(`Roundoff Amount Setting: ₹${roundoffAmount}`);
    console.log(`Total Transactions: ${transactionsWithRoundoff.length}`);
    const sampleTransactions = transactionsWithRoundoff.slice(0, 5);
    sampleTransactions.forEach((t, i) => {
      console.log(`Transaction ${i + 1}: Amount=₹${t.amount}, Roundoff=₹${t.roundoff}, Rounded=₹${t.roundedAmount}`);
    });
    const totalRoundoff = transactionsWithRoundoff.reduce((sum, t) => sum + (t.roundoff || 0), 0);
    console.log(`Total Roundoff Calculated: ₹${totalRoundoff.toFixed(2)}`);
    console.log(`==================================\n`);

    // Save transactions to database
    const transactionInserts = transactionsWithRoundoff.map(t => {
      return query(
        `INSERT INTO transactions (user_id, statement_id, transaction_date, description, amount, transaction_type, roundoff_amount, rounded_amount)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [
          user_id,
          statementId,
          t.date,
          t.description || 'Withdrawal',
          t.amount,
          'withdrawal',
          t.roundoff || 0, // Ensure it's never null
          t.roundedAmount || t.amount
        ]
      );
    });

    await Promise.all(transactionInserts);

    // Update statement status
    await query(
      'UPDATE bank_statements SET status = $1, processed_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['completed', statementId]
    );

    // Calculate and save daily roundoff savings
    const savingsByDate = {};
    transactionsWithRoundoff.forEach(t => {
      const dateKey = t.date.toISOString().split('T')[0];
      if (!savingsByDate[dateKey]) {
        savingsByDate[dateKey] = { total: 0, count: 0 };
      }
      savingsByDate[dateKey].total += t.roundoff;
      savingsByDate[dateKey].count += 1;
    });

    // Save daily savings (no conflict since we cleared old data)
    for (const [date, data] of Object.entries(savingsByDate)) {
      await query(
        `INSERT INTO roundoff_savings (user_id, transaction_date, total_roundoff, transaction_count)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [user_id, date, data.total, data.count]
      );
    }

    // Calculate summary
    const summary = roundoffCalculator.calculateTotalSavings(transactionsWithRoundoff);
    const dates = transactions.map(t => t.date);
    const startDate = new Date(Math.min(...dates));
    const endDate = new Date(Math.max(...dates));
    const projections = roundoffCalculator.calculateProjections(summary, startDate, endDate);
    const insights = roundoffCalculator.generateInsights(summary, projections);

    res.json({
      message: 'Bank statement processed successfully',
      statement_id: statementId,
      transactions_processed: transactions.length,
      summary: {
        ...summary,
        roundoff_amount: roundoffAmount
      },
      projections,
      insights
    });
  } catch (error) {
    console.error('Upload error:', error);
    
    // Clean up file if exists
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    
    res.status(500).json({ error: 'Failed to process bank statement' });
  }
});

// Get Savings Summary
router.get('/summary/:user_id', [
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

    // Get roundoff setting
    const roundoffResult = await query(
      'SELECT roundoff_amount FROM roundoff_settings WHERE user_id = $1',
      [user_id]
    );
    const roundoffAmount = roundoffResult.rows[0]?.roundoff_amount || 10;

    // Get all transactions
    const transactionsResult = await query(
      `SELECT transaction_date, amount, roundoff_amount, rounded_amount, description
       FROM transactions
       WHERE user_id = $1 AND transaction_type = 'withdrawal'
       ORDER BY transaction_date DESC`,
      [user_id]
    );

    const transactions = transactionsResult.rows;

    // Also get aggregated savings from roundoff_savings table (more reliable)
    const savingsResult = await query(
      `SELECT 
         SUM(total_roundoff) as total_savings,
         SUM(transaction_count) as total_count
       FROM roundoff_savings
       WHERE user_id = $1`,
      [user_id]
    );

    if (transactions.length === 0) {
      return res.json({
        total_savings: 0,
        transaction_count: 0,
        roundoff_amount: roundoffAmount,
        message: 'No transactions found. Upload a bank statement to get started!'
      });
    }

    // Calculate totals - prefer aggregated savings if available, otherwise calculate from transactions
    const aggregatedSavings = parseFloat(savingsResult.rows[0]?.total_savings || 0);
    const transactionBasedSavings = transactions.reduce((sum, t) => sum + parseFloat(t.roundoff_amount || 0), 0);
    
    // Use aggregated savings if it's greater than 0, otherwise use transaction-based calculation
    const totalSavings = aggregatedSavings > 0 ? aggregatedSavings : transactionBasedSavings;
    
    const totalWithdrawn = transactions.reduce((sum, t) => sum + parseFloat(t.amount), 0);
    const totalRounded = transactions.reduce((sum, t) => sum + parseFloat(t.rounded_amount || t.amount), 0);

    // Debug: Log what we're reading from database
    console.log(`\n=== Summary Endpoint Debug ===`);
    console.log(`Transactions found: ${transactions.length}`);
    console.log(`Roundoff Amount Setting: ₹${roundoffAmount}`);
    console.log(`Aggregated Savings from roundoff_savings table: ₹${aggregatedSavings.toFixed(2)}`);
    console.log(`Transaction-based Savings: ₹${transactionBasedSavings.toFixed(2)}`);
    if (transactions.length > 0) {
      const sampleDbTransactions = transactions.slice(0, 5);
      sampleDbTransactions.forEach((t, i) => {
        console.log(`DB Transaction ${i + 1}: Amount=₹${t.amount}, Roundoff=₹${t.roundoff_amount || 'NULL'}, Rounded=₹${t.rounded_amount || 'NULL'}`);
      });
    }
    console.log(`Final Total Savings: ₹${totalSavings.toFixed(2)}`);
    console.log(`==============================\n`);

    // Get date range
    const dates = transactions.map(t => new Date(t.transaction_date));
    const startDate = new Date(Math.min(...dates));
    const endDate = new Date(Math.max(...dates));
    const daysDiff = Math.max(1, Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24)));

    // Calculate projections
    const transactionsPerDay = transactions.length / daysDiff;
    const savingsPerDay = totalSavings / daysDiff;

    const projections = {
      daily: {
        transactions: transactionsPerDay,
        savings: savingsPerDay
      },
      monthly: {
        transactions: transactionsPerDay * 30,
        savings: savingsPerDay * 30
      },
      yearly: {
        transactions: transactionsPerDay * 365,
        savings: savingsPerDay * 365
      },
      period: {
        days: daysDiff,
        transactions: transactions.length,
        savings: totalSavings
      }
    };

    // Generate insights
    const summary = {
      totalRoundoff: totalSavings,
      transactionCount: transactions.length,
      totalWithdrawn,
      totalRounded,
      averageRoundoff: transactions.length > 0 ? totalSavings / transactions.length : 0
    };
    const insights = roundoffCalculator.generateInsights(summary, projections);

    res.json({
      total_savings: totalSavings,
      transaction_count: transactions.length,
      total_withdrawn: totalWithdrawn,
      total_rounded: totalRounded,
      average_roundoff: summary.averageRoundoff,
      roundoff_amount: roundoffAmount,
      date_range: {
        start: startDate.toISOString().split('T')[0],
        end: endDate.toISOString().split('T')[0],
        days: daysDiff
      },
      projections,
      insights
    });
  } catch (error) {
    console.error('Get summary error:', error);
    res.status(500).json({ error: 'Failed to get savings summary' });
  }
});

// Get Transactions
router.get('/transactions/:user_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id } = req.params;
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    // Get transactions
    const result = await query(
      `SELECT 
        id, transaction_date, description, amount, 
        roundoff_amount, rounded_amount, created_at
       FROM transactions
       WHERE user_id = $1 AND transaction_type = 'withdrawal'
       ORDER BY transaction_date DESC
       LIMIT $2 OFFSET $3`,
      [user_id, limit, offset]
    );

    // Get total count
    const countResult = await query(
      `SELECT COUNT(*) as total 
       FROM transactions 
       WHERE user_id = $1 AND transaction_type = 'withdrawal'`,
      [user_id]
    );

    res.json({
      transactions: result.rows,
      total: parseInt(countResult.rows[0].total),
      limit,
      offset
    });
  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({ error: 'Failed to get transactions' });
  }
});

// Get Insights
router.get('/insights/:user_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id } = req.params;

    // Get all transactions
    const transactionsResult = await query(
      `SELECT transaction_date, amount, roundoff_amount, rounded_amount
       FROM transactions
       WHERE user_id = $1 AND transaction_type = 'withdrawal'
       ORDER BY transaction_date`,
      [user_id]
    );

    const transactions = transactionsResult.rows;

    if (transactions.length === 0) {
      return res.json({
        message: 'No transactions found. Upload a bank statement to see insights!',
        insights: []
      });
    }

    // Calculate summary
    const summary = {
      totalRoundoff: transactions.reduce((sum, t) => sum + parseFloat(t.roundoff_amount || 0), 0),
      transactionCount: transactions.length,
      totalWithdrawn: transactions.reduce((sum, t) => sum + parseFloat(t.amount), 0),
      totalRounded: transactions.reduce((sum, t) => sum + parseFloat(t.rounded_amount || t.amount), 0),
      averageRoundoff: 0
    };
    summary.averageRoundoff = summary.transactionCount > 0 ? summary.totalRoundoff / summary.transactionCount : 0;

    // Get date range
    const dates = transactions.map(t => new Date(t.transaction_date));
    const startDate = new Date(Math.min(...dates));
    const endDate = new Date(Math.max(...dates));
    const projections = roundoffCalculator.calculateProjections(summary, startDate, endDate);
    const insights = roundoffCalculator.generateInsights(summary, projections);

    // Get roundoff setting
    const roundoffResult = await query(
      'SELECT roundoff_amount FROM roundoff_settings WHERE user_id = $1',
      [user_id]
    );
    const roundoffAmount = roundoffResult.rows[0]?.roundoff_amount || 10;

    res.json({
      summary: {
        ...summary,
        roundoff_amount: roundoffAmount
      },
      projections,
      insights: insights.split('\n'),
      date_range: {
        start: startDate.toISOString().split('T')[0],
        end: endDate.toISOString().split('T')[0],
        days: Math.max(1, Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24)))
      }
    });
  } catch (error) {
    console.error('Get insights error:', error);
    res.status(500).json({ error: 'Failed to get insights' });
  }
});

// Debug: Extract PDF text (for troubleshooting)
router.post('/debug/extract-text', upload.single('statement'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'PDF file is required' });
    }

    const pdfBuffer = fs.readFileSync(req.file.path);
    const pdfParser = require('../services/pdfParser');
    
    // Extract text
    const { PDFParse } = require('pdf-parse');
    const pdfParserInstance = new PDFParse({ data: pdfBuffer });
    const textData = await pdfParserInstance.getText();
    const text = textData.text || textData;
    
    // Try to extract transactions
    const transactions = await pdfParser.parseBankStatement(pdfBuffer);
    
    // Clean up file
    fs.unlinkSync(req.file.path);
    
    res.json({
      text_preview: text.substring(0, 2000), // First 2000 chars
      text_length: text.length,
      transactions_found: transactions.length,
      transactions: transactions.slice(0, 10), // First 10 transactions
      sample_lines: text.split('\n').slice(0, 50) // First 50 lines
    });
  } catch (error) {
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ error: 'Failed to extract text', details: error.message });
  }
});

// Get Roundoff Setting
router.get('/roundoff/:user_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id } = req.params;

    const result = await query(
      'SELECT * FROM roundoff_settings WHERE user_id = $1',
      [user_id]
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
    res.status(500).json({ success: false, error: 'Failed to get roundoff setting' });
  }
});

// Update Roundoff Setting
router.put('/roundoff/:user_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
  body('roundoff_amount').optional().isInt({ min: 1 }).withMessage('Roundoff amount must be a positive integer'),
  body('goal_id').optional().isInt().withMessage('Goal ID must be an integer'),
  body('is_active').optional().isBoolean().withMessage('is_active must be a boolean'),
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

    const { user_id } = req.params;
    const { roundoff_amount, goal_id, is_active } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Validate goal if provided
    if (goal_id !== undefined) {
      if (goal_id === null) {
        // Allow setting goal_id to null
      } else {
        const goalCheck = await query('SELECT * FROM goals WHERE id = $1 AND user_id = $2', [goal_id, user_id]);
        if (goalCheck.rows.length === 0) {
          return res.status(404).json({ success: false, error: 'Goal not found' });
        }
      }
    }

    // Check if setting exists
    const existingSetting = await query(
      'SELECT * FROM roundoff_settings WHERE user_id = $1',
      [user_id]
    );

    if (existingSetting.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Roundoff setting not found. Use POST /api/savings/roundoff to create one.'
      });
    }

    // Build update query dynamically
    const updateFields = [];
    const values = [];
    let paramCount = 1;

    if (roundoff_amount !== undefined) {
      updateFields.push(`roundoff_amount = $${paramCount++}`);
      values.push(roundoff_amount);
    }

    if (goal_id !== undefined) {
      updateFields.push(`goal_id = $${paramCount++}`);
      values.push(goal_id);
    }

    if (is_active !== undefined) {
      updateFields.push(`is_active = $${paramCount++}`);
      values.push(is_active);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No fields to update'
      });
    }

    updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(user_id);

    const result = await query(
      `UPDATE roundoff_settings 
       SET ${updateFields.join(', ')}
       WHERE user_id = $${paramCount}
       RETURNING *`,
      values
    );

    res.json({
      success: true,
      message: 'Roundoff setting updated successfully',
      setting: result.rows[0]
    });
  } catch (error) {
    console.error('Update roundoff error:', error);
    res.status(500).json({ success: false, error: 'Failed to update roundoff setting' });
  }
});

module.exports = router;

