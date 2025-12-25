const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { body, param, query: queryCheck, validationResult } = require('express-validator');
const { createNotification } = require('./notifications');

// Import investment plan helper functions
const {
  getUserRiskProfile,
  getCuratedPortfolioFunds,
  getPortfolioPercentages,
  calculatePortfolioAllocation
} = require('./investmentPlan');

// Helper function to convert goal object numeric fields from strings to numbers
function formatGoal(goal) {
  return {
    ...goal,
    target_amount: parseFloat(goal.target_amount) || 0,
    current_amount: parseFloat(goal.current_amount) || 0,
    progress_percentage: goal.progress_percentage ? parseFloat(goal.progress_percentage) : 0
  };
}

// Helper function to calculate progress percentage
function calculateProgress(currentAmount, targetAmount) {
  const current = typeof currentAmount === 'string' ? parseFloat(currentAmount) : currentAmount;
  const target = typeof targetAmount === 'string' ? parseFloat(targetAmount) : targetAmount;
  if (target <= 0) return 0;
  return Math.min(100, (current / target) * 100);
}

// Helper function to calculate days remaining
function calculateDaysRemaining(targetDate) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const target = new Date(targetDate);
  target.setHours(0, 0, 0, 0);
  const diffTime = target - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return Math.max(0, diffDays);
}

// Helper function to calculate monthly savings needed
function calculateMonthlySavingsNeeded(currentAmount, targetAmount, targetDate) {
  const current = typeof currentAmount === 'string' ? parseFloat(currentAmount) : currentAmount;
  const target = typeof targetAmount === 'string' ? parseFloat(targetAmount) : targetAmount;
  const daysRemaining = calculateDaysRemaining(targetDate);
  if (daysRemaining <= 0) return 0;
  const monthsRemaining = daysRemaining / 30.44; // Average days per month
  const remainingAmount = target - current;
  if (remainingAmount <= 0) return 0;
  return remainingAmount / monthsRemaining;
}

// 1. Check User Setup Status
router.get('/setup-status/:user_id', [
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

    // Check goals
    const goalsResult = await query(
      'SELECT COUNT(*) as count FROM goals WHERE user_id = $1 AND status != $2',
      [user_id, 'cancelled']
    );
    const goalsCount = parseInt(goalsResult.rows[0].count);
    const hasGoal = goalsCount > 0;

    // Check roundoff setting
    const roundoffResult = await query(
      'SELECT * FROM roundoff_settings WHERE user_id = $1',
      [user_id]
    );
    const hasRoundoffSetting = roundoffResult.rows.length > 0;
    const roundoffSetting = hasRoundoffSetting ? roundoffResult.rows[0] : null;

    // Check invest profile
    const investResult = await query(
      'SELECT * FROM invest_profiles WHERE user_id = $1',
      [user_id]
    );
    const hasInvestProfile = investResult.rows.length > 0;
    const investProfile = hasInvestProfile ? investResult.rows[0] : null;

    const setupComplete = hasGoal && hasRoundoffSetting && hasInvestProfile;

    res.json({
      user_id: parseInt(user_id),
      has_goal: hasGoal,
      has_roundoff_setting: hasRoundoffSetting,
      has_invest_profile: hasInvestProfile,
      setup_complete: setupComplete,
      goals_count: goalsCount,
      roundoff_setting: roundoffSetting,
      invest_profile: investProfile
    });
  } catch (error) {
    console.error('Setup status error:', error);
    res.status(500).json({ error: 'Failed to get setup status' });
  }
});

// 2. Get Goal Categories
router.get('/categories', async (req, res) => {
  try {
    const result = await query(
      'SELECT * FROM goal_categories WHERE is_active = TRUE ORDER BY id'
    );

    res.json({
      categories: result.rows
    });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({ error: 'Failed to get goal categories' });
  }
});

// 3. Get User Goals
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

    // Build query with all calculated fields
    let queryText = `
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
        -- Calculate days remaining (DATE - DATE returns integer days)
        CASE 
          WHEN g.target_date >= CURRENT_DATE 
          THEN (g.target_date - CURRENT_DATE)::INTEGER
          ELSE NULL 
        END as days_remaining,
        -- Calculate monthly savings needed
        CASE 
          WHEN g.target_date >= CURRENT_DATE AND g.current_amount < g.target_amount
          THEN ROUND(
            ((g.target_amount - g.current_amount) / 
             ((g.target_date - CURRENT_DATE)::NUMERIC / 30.44))::numeric, 
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

    // Format goals - ensure all numeric fields are numbers, not strings
    const goalIds = result.rows.map(g => g.id);
    
    // Fetch investment plans for all goals
    let investmentPlans = {};
    if (goalIds.length > 0) {
      const planResult = await query(
        `SELECT * FROM investment_plans WHERE goal_id = ANY($1::int[])`,
        [goalIds]
      );
      planResult.rows.forEach(plan => {
        investmentPlans[plan.goal_id] = plan;
      });
    }

    const goals = await Promise.all(result.rows.map(async (goal) => {
      const goalData = {
        id: parseInt(goal.id),
        user_id: parseInt(goal.user_id),
        category_id: parseInt(goal.category_id),
        category_name: goal.category_name,
        category_icon: goal.category_icon,
        goal_name: goal.goal_name,
        target_amount: parseFloat(goal.target_amount) || 0,
        current_amount: parseFloat(goal.current_amount) || 0,
        target_date: goal.target_date,
        status: goal.status,
        created_at: goal.created_at,
        updated_at: goal.updated_at,
        progress_percentage: parseFloat(goal.progress_percentage) || 0,
        days_remaining: goal.days_remaining !== null ? parseInt(goal.days_remaining) : null,
        monthly_savings_needed: goal.monthly_savings_needed !== null 
          ? parseFloat(goal.monthly_savings_needed) 
          : null
      };

      // Add investment plan if exists
      if (investmentPlans[goal.id]) {
        const plan = investmentPlans[goal.id];
        goalData.investment_plan = {
          id: plan.id,
          risk_profile: plan.risk_profile,
          risk_profile_display: plan.risk_profile_display,
          auto_save: plan.auto_save_config,
          portfolio: plan.portfolio_allocation
        };
      }

      return goalData;
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

// 4. Create Goal (with automatic investment plan creation)
router.post('/', [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
  body('category_id').isInt().withMessage('Category ID is required and must be an integer'),
  body('goal_name').trim().isLength({ min: 3, max: 100 }).withMessage('Goal name must be between 3 and 100 characters'),
  body('target_amount').isFloat({ min: 100 }).withMessage('Target amount must be at least ₹100'),
  body('target_date').isISO8601().toDate().withMessage('Target date must be a valid future date (YYYY-MM-DD)'),
  body('initial_amount').optional().isFloat({ min: 0 }).withMessage('Initial amount must be non-negative'),
  // Investment plan fields (optional - will use defaults if not provided)
  body('frequency').optional().isIn(['monthly', 'weekly', 'daily']).withMessage('Frequency must be monthly, weekly, or daily'),
  body('monthly_amount').optional().isFloat({ min: 100 }).withMessage('Monthly amount must be at least ₹100'),
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

    const { user_id, category_id, goal_name, target_amount, target_date, initial_amount = 0, frequency, monthly_amount } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Check if category exists
    const categoryCheck = await query('SELECT * FROM goal_categories WHERE id = $1 AND is_active = TRUE', [category_id]);
    if (categoryCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Category not found or inactive'
      });
    }

    // Validate target date is in the future
    const targetDateObj = new Date(target_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    targetDateObj.setHours(0, 0, 0, 0);
    if (targetDateObj <= today) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: [{
          field: 'target_date',
          msg: 'Target date must be a future date'
        }]
      });
    }

    // Insert goal
    const result = await query(
      `INSERT INTO goals (user_id, category_id, goal_name, target_amount, current_amount, target_date, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'active')
       RETURNING *`,
      [user_id, category_id, goal_name, target_amount, initial_amount, target_date]
    );

    const goal = result.rows[0];
    const progressPercentage = calculateProgress(goal.current_amount, goal.target_amount);

    // Calculate duration from target date (reuse targetDateObj from validation above)
    const monthsDiff = (targetDateObj.getFullYear() - today.getFullYear()) * 12 + 
                      (targetDateObj.getMonth() - today.getMonth());
    const durationMonths = Math.max(1, monthsDiff);

    // Calculate monthly amount if not provided (based on remaining amount and duration)
    let finalMonthlyAmount = monthly_amount;
    if (!finalMonthlyAmount) {
      const remainingAmount = parseFloat(target_amount) - parseFloat(initial_amount);
      finalMonthlyAmount = Math.max(100, Math.ceil(remainingAmount / durationMonths));
    }

    // Default frequency to monthly if not provided
    const finalFrequency = frequency || 'monthly';

    // Calculate weekly and daily amounts
    const weeklyAmount = parseFloat((finalMonthlyAmount / 4.33).toFixed(2));
    const dailyAmount = parseFloat((finalMonthlyAmount / 30).toFixed(2));

    // Get user's risk profile
    const riskProfile = await getUserRiskProfile(user_id);
    const riskProfileDisplay = {
      'Conservative': 'Capital Protection Investor',
      'Moderate': 'Balanced Growth Investor',
      'Moderately Aggressive': 'Growth Seeker',
      'Aggressive': 'Wealth Builder'
    }[riskProfile] || riskProfile;

    // Generate portfolio allocation
    let allocations = calculatePortfolioAllocation(riskProfile, finalMonthlyAmount, []);
    if (!allocations || allocations.length === 0) {
      const portfolio = getCuratedPortfolioFunds(riskProfile);
      const percentages = getPortfolioPercentages(riskProfile);
      allocations = [];
      
      const allFunds = [
        ...portfolio.largeCap.map(f => ({ ...f, allocationPercent: portfolio.largeCap.length > 0 ? percentages.largeCap / portfolio.largeCap.length : 0 })),
        ...portfolio.midCap.map(f => ({ ...f, allocationPercent: portfolio.midCap.length > 0 ? percentages.midCap / portfolio.midCap.length : 0 })),
        ...portfolio.smallCap.map(f => ({ ...f, allocationPercent: portfolio.smallCap.length > 0 ? percentages.smallCap / portfolio.smallCap.length : 0 })),
        ...portfolio.debt.map(f => ({ ...f, allocationPercent: portfolio.debt.length > 0 ? percentages.debt / portfolio.debt.length : 0 })),
        ...portfolio.hybrid.map(f => ({ ...f, allocationPercent: portfolio.hybrid.length > 0 ? percentages.hybrid / portfolio.hybrid.length : 0 })),
        ...portfolio.elss.map(f => ({ ...f, allocationPercent: portfolio.elss.length > 0 ? percentages.elss / portfolio.elss.length : 0 }))
      ].filter(f => f.allocationPercent > 0);
      
      allFunds.forEach(fund => {
        allocations.push({
          scheme_code: fund.scheme_code,
          scheme_name: fund.scheme_name,
          category: fund.category,
          sub_category: fund.sub_category,
          percentage: parseFloat(fund.allocationPercent.toFixed(2)),
          amount: parseFloat((finalMonthlyAmount * fund.allocationPercent / 100).toFixed(2)),
          fund_details: {
            scheme_code: fund.scheme_code,
            scheme_name: fund.scheme_name,
            category: fund.category,
            sub_category: fund.sub_category,
            risk_level: fund.risk_level,
            returns: fund.returns,
            latest_nav: fund.latest_nav
          }
        });
      });
    }

    const autoSaveConfig = {
      frequency: finalFrequency,
      monthly_amount: parseFloat(finalMonthlyAmount),
      weekly_amount: weeklyAmount,
      daily_amount: dailyAmount,
      duration_months: durationMonths
    };

    const portfolioAllocation = {
      description: "According to your Risk Folio, We have curated the best investment portfolio",
      allocations
    };

    // Create investment plan for this goal
    let investmentPlan = null;
    try {
      const planResult = await query(
        `INSERT INTO investment_plans 
         (user_id, goal_id, risk_profile, risk_profile_display, auto_save_config, portfolio_allocation, status)
         VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, 'active')
         RETURNING *`,
        [user_id, goal.id, riskProfile, riskProfileDisplay, JSON.stringify(autoSaveConfig), JSON.stringify(portfolioAllocation)]
      );
      investmentPlan = planResult.rows[0];
      console.log(`Investment plan created for goal ${goal.id}`);
    } catch (error) {
      console.error('Error creating investment plan:', error);
      // Don't fail goal creation if investment plan creation fails
    }

    // Create notification for goal creation
    try {
      await createNotification(
        user_id,
        'goal_created',
        'Goal Created!',
        `Your goal '${goal_name}' has been created successfully.`,
        {
          goal_id: goal.id,
          goal_name: goal_name,
          target_amount: parseFloat(target_amount),
          target_date: target_date
        }
      );
    } catch (error) {
      console.error('Error creating notification:', error);
      // Don't fail the goal creation if notification fails
    }

    // Format goal response with investment plan
    const goalResponse = formatGoal({
      ...goal,
      category_name: categoryCheck.rows[0].name,
      category_icon: categoryCheck.rows[0].icon,
      progress_percentage: progressPercentage
    });

    // Add investment plan to response if created
    if (investmentPlan) {
      goalResponse.investment_plan = {
        id: investmentPlan.id,
        risk_profile: investmentPlan.risk_profile,
        risk_profile_display: investmentPlan.risk_profile_display,
        auto_save: investmentPlan.auto_save_config,
        portfolio: investmentPlan.portfolio_allocation
      };
    }

    res.json({
      success: true,
      message: 'Goal created successfully',
      goal: goalResponse
    });
  } catch (error) {
    console.error('Create goal error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create goal'
    });
  }
});

// 5. Update Goal
router.put('/:goal_id', [
  param('goal_id').isInt().withMessage('Goal ID must be an integer'),
  body('goal_name').optional().trim().isLength({ min: 3, max: 100 }),
  body('target_amount').optional().isFloat({ min: 100 }),
  body('target_date').optional().isISO8601().toDate(),
  body('status').optional().isIn(['active', 'completed', 'paused', 'cancelled']),
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

    const { goal_id } = req.params;
    const { goal_name, target_amount, target_date, status } = req.body;

    // Check if goal exists
    const goalCheck = await query(
      `SELECT g.*, gc.name as category_name, gc.icon as category_icon
       FROM goals g
       JOIN goal_categories gc ON g.category_id = gc.id
       WHERE g.id = $1`,
      [goal_id]
    );

    if (goalCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Goal not found'
      });
    }

    const existingGoal = goalCheck.rows[0];

    // Build update query dynamically
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (goal_name !== undefined) {
      updates.push(`goal_name = $${paramIndex}`);
      values.push(goal_name);
      paramIndex++;
    }

    if (target_amount !== undefined) {
      updates.push(`target_amount = $${paramIndex}`);
      values.push(target_amount);
      paramIndex++;
    }

    if (target_date !== undefined) {
      // Validate future date if status is active
      if (status === 'active' || status === undefined) {
        const targetDateObj = new Date(target_date);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        targetDateObj.setHours(0, 0, 0, 0);
        if (targetDateObj <= today) {
          return res.status(400).json({
            success: false,
            error: 'Validation error',
            errors: [{
              field: 'target_date',
              msg: 'Target date must be a future date for active goals'
            }]
          });
        }
      }
      updates.push(`target_date = $${paramIndex}`);
      values.push(target_date);
      paramIndex++;
    }

    if (status !== undefined) {
      updates.push(`status = $${paramIndex}`);
      values.push(status);
      paramIndex++;
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No fields to update'
      });
    }

    values.push(goal_id);
    const updateQuery = `
      UPDATE goals
      SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $${paramIndex}
      RETURNING *
    `;

    const result = await query(updateQuery, values);
    const updatedGoal = result.rows[0];
    const progressPercentage = calculateProgress(updatedGoal.current_amount, updatedGoal.target_amount);

    // Check for goal completion or progress milestones
    try {
      const milestones = [10, 25, 50, 75, 90];
      const currentMilestone = milestones.find(m => progressPercentage >= m && progressPercentage < m + 5);
      
      if (progressPercentage >= 100 && existingGoal.status !== 'completed') {
        // Goal completed
        await createNotification(
          existingGoal.user_id,
          'goal_completed',
          'Goal Completed! 🎉',
          `Congratulations! You've completed your '${updatedGoal.goal_name}' goal!`,
          {
            goal_id: updatedGoal.id,
            goal_name: updatedGoal.goal_name,
            target_amount: parseFloat(updatedGoal.target_amount),
            current_amount: parseFloat(updatedGoal.current_amount),
            progress_percentage: progressPercentage
          }
        );
      } else if (currentMilestone) {
        // Progress milestone reached
        await createNotification(
          existingGoal.user_id,
          'goal_progress',
          'Great Progress!',
          `You've reached ${currentMilestone}% of your '${updatedGoal.goal_name}' goal!`,
          {
            goal_id: updatedGoal.id,
            goal_name: updatedGoal.goal_name,
            progress_percentage: progressPercentage,
            current_amount: parseFloat(updatedGoal.current_amount),
            target_amount: parseFloat(updatedGoal.target_amount)
          }
        );
      }
    } catch (error) {
      console.error('Error creating notification:', error);
      // Don't fail the goal update if notification fails
    }

    res.json({
      success: true,
      message: 'Goal updated successfully',
      goal: formatGoal({
        ...updatedGoal,
        category_name: existingGoal.category_name,
        category_icon: existingGoal.category_icon,
        progress_percentage: progressPercentage
      })
    });
  } catch (error) {
    console.error('Update goal error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update goal'
    });
  }
});

// 6. Delete Goal (Soft delete)
router.delete('/:goal_id', [
  param('goal_id').isInt().withMessage('Goal ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { goal_id } = req.params;

    // Check if goal exists
    const goalCheck = await query('SELECT id FROM goals WHERE id = $1', [goal_id]);
    if (goalCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Goal not found'
      });
    }

    // Soft delete by setting status to cancelled
    await query(
      'UPDATE goals SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['cancelled', goal_id]
    );

    res.json({
      success: true,
      message: 'Goal deleted successfully'
    });
  } catch (error) {
    console.error('Delete goal error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete goal'
    });
  }
});

// 7. Get Goal Details
// 7. Get Goal Details (with investment plan and roundoff setting)
router.get('/:goal_id', [
  param('goal_id').isInt().withMessage('Goal ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        error: 'Validation error',
        errors: errors.array() 
      });
    }

    const { goal_id } = req.params;

    // Fetch goal with category information
    const result = await query(
      `SELECT 
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
        g.updated_at
       FROM goals g
       JOIN goal_categories gc ON g.category_id = gc.id
       WHERE g.id = $1`,
      [goal_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Goal not found' 
      });
    }

    const goal = result.rows[0];
    const user_id = goal.user_id;
    
    // Calculate progress metrics
    const progressPercentage = calculateProgress(goal.current_amount, goal.target_amount);
    const daysRemaining = calculateDaysRemaining(goal.target_date);
    const monthlySavingsNeeded = calculateMonthlySavingsNeeded(
      goal.current_amount,
      goal.target_amount,
      goal.target_date
    );

    // Fetch investment plan for this goal
    const planResult = await query(
      `SELECT 
        id,
        user_id,
        goal_id,
        risk_profile,
        risk_profile_display,
        auto_save_config,
        portfolio_allocation,
        status,
        created_at,
        updated_at
       FROM investment_plans 
       WHERE goal_id = $1`,
      [goal_id]
    );

    // Fetch roundoff setting - prioritize goal-specific, then user's global setting
    const roundoffResult = await query(
      `SELECT 
        id,
        user_id,
        goal_id,
        roundoff_amount,
        is_active,
        created_at,
        updated_at
       FROM roundoff_settings 
       WHERE user_id = $1 
         AND (goal_id = $2 OR goal_id IS NULL)
       ORDER BY 
         CASE WHEN goal_id = $2 THEN 0 ELSE 1 END,
         created_at DESC
       LIMIT 1`,
      [user_id, goal_id]
    );

    // Format goal response
    const goalResponse = {
      id: parseInt(goal.id),
      user_id: parseInt(goal.user_id),
      category_id: parseInt(goal.category_id),
      category_name: goal.category_name,
      category_icon: goal.category_icon,
      goal_name: goal.goal_name,
      target_amount: parseFloat(goal.target_amount) || 0,
      current_amount: parseFloat(goal.current_amount) || 0,
      target_date: goal.target_date,
      status: goal.status,
      progress_percentage: parseFloat(progressPercentage.toFixed(2)),
      days_remaining: daysRemaining,
      monthly_savings_needed: monthlySavingsNeeded !== null 
        ? parseFloat(monthlySavingsNeeded.toFixed(2)) 
        : null,
      created_at: goal.created_at,
      updated_at: goal.updated_at,
      investment_plan: null
    };

    // Add investment plan if exists
    if (planResult.rows.length > 0) {
      const plan = planResult.rows[0];
      goalResponse.investment_plan = {
        id: parseInt(plan.id),
        user_id: parseInt(plan.user_id),
        goal_id: plan.goal_id ? parseInt(plan.goal_id) : null,
        risk_profile: plan.risk_profile,
        risk_profile_display: plan.risk_profile_display,
        auto_save: plan.auto_save_config,
        portfolio: plan.portfolio_allocation,
        created_at: plan.created_at,
        updated_at: plan.updated_at
      };
    }

    // Format roundoff setting response
    let roundoffSetting = null;
    if (roundoffResult.rows.length > 0) {
      const setting = roundoffResult.rows[0];
      roundoffSetting = {
        id: parseInt(setting.id),
        user_id: parseInt(setting.user_id),
        goal_id: setting.goal_id ? parseInt(setting.goal_id) : null,
        roundoff_amount: parseInt(setting.roundoff_amount),
        is_active: setting.is_active,
        created_at: setting.created_at,
        updated_at: setting.updated_at
      };
    }

    res.json({
      success: true,
      goal: goalResponse,
      roundoff_setting: roundoffSetting
    });
  } catch (error) {
    console.error('Get goal details error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to get goal details' 
    });
  }
});

// Get Goal Configuration Status
router.get('/:goalId/configuration', [
  param('goalId').isInt().withMessage('Goal ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { goalId } = req.params;

    // Check if goal exists
    const goalResult = await query(
      'SELECT * FROM goals WHERE id = $1',
      [goalId]
    );

    if (goalResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Goal not found' });
    }

    const goal = goalResult.rows[0];
    const user_id = goal.user_id;

    // Check for auto-save (investment plan)
    const planResult = await query(
      'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id = $2',
      [user_id, goalId]
    );

    // Check for auto-roundoff
    const roundoffResult = await query(
      'SELECT * FROM roundoff_settings WHERE user_id = $1 AND goal_id = $2',
      [user_id, goalId]
    );

    const hasAutoSave = planResult.rows.length > 0;
    const hasAutoRoundoff = roundoffResult.rows.length > 0;
    const hasInvestmentPlan = hasAutoSave;

    const response = {
      success: true,
      goal_id: parseInt(goalId),
      has_auto_save: hasAutoSave,
      has_auto_roundoff: hasAutoRoundoff,
      has_investment_plan: hasInvestmentPlan,
      auto_save: null,
      auto_roundoff: null,
      investment_plan: null
    };

    if (hasAutoSave) {
      const plan = planResult.rows[0];
      response.auto_save = plan.auto_save_config;
      response.investment_plan = {
        id: plan.id,
        risk_profile: plan.risk_profile,
        risk_profile_display: plan.risk_profile_display,
        portfolio_funds_count: plan.portfolio_allocation?.allocations?.length || 0
      };
    }

    if (hasAutoRoundoff) {
      const roundoff = roundoffResult.rows[0];
      response.auto_roundoff = {
        roundoff_amount: roundoff.roundoff_amount,
        is_active: roundoff.is_active,
        goal_id: roundoff.goal_id
      };
    }

    res.json(response);
  } catch (error) {
    console.error('Get goal configuration error:', error);
    res.status(500).json({ success: false, error: 'Failed to get goal configuration' });
  }
});

module.exports = router;

