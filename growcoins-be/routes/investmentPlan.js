const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { body, param, query: queryCheck, validationResult } = require('express-validator');
const mutualFundService = require('../services/mutualFundService');

/**
 * Helper function to get user's risk profile
 */
async function getUserRiskProfile(userId) {
  const result = await query(
    `SELECT risk_profile FROM risk_assessments 
     WHERE user_id = $1 
     ORDER BY completed_at DESC 
     LIMIT 1`,
    [userId]
  );
  return result.rows[0]?.risk_profile || 'Moderate';
}

/**
 * Get curated portfolio funds based on risk profile
 * Returns a comprehensive list of funds across different categories
 */
function getCuratedPortfolioFunds(riskProfile) {
  // Large Cap Equity Funds (Lower risk, stable returns)
  const largeCapFunds = [
    {
      scheme_code: 120466,
      scheme_name: 'SBI Bluechip Fund Direct Plan Growth',
      category: 'Large Cap Equity',
      sub_category: 'Large Cap',
      risk_level: 'Moderate',
      returns: { absolute_return: 29.00, annualized_return: 25.50, latest_nav: 85.20, period_days: 365 },
      latest_nav: 85.20,
      suitability: 'Suitable'
    },
    {
      scheme_code: 120467,
      scheme_name: 'ICICI Prudential Bluechip Fund Direct Growth',
      category: 'Large Cap Equity',
      sub_category: 'Large Cap',
      risk_level: 'Moderate',
      returns: { absolute_return: 27.00, annualized_return: 23.80, latest_nav: 78.50, period_days: 365 },
      latest_nav: 78.50,
      suitability: 'Suitable'
    },
    {
      scheme_code: 120471,
      scheme_name: 'HDFC Top 100 Fund Direct Plan Growth',
      category: 'Large Cap Equity',
      sub_category: 'Large Cap',
      risk_level: 'Moderate',
      returns: { absolute_return: 26.50, annualized_return: 24.20, latest_nav: 92.30, period_days: 365 },
      latest_nav: 92.30,
      suitability: 'Suitable'
    }
  ];

  // Mid Cap Equity Funds (Moderate risk, growth potential)
  const midCapFunds = [
    {
      scheme_code: 120472,
      scheme_name: 'HDFC Mid-Cap Opportunities Fund Direct Growth',
      category: 'Mid Cap Equity',
      sub_category: 'Mid Cap',
      risk_level: 'Moderate-High',
      returns: { absolute_return: 32.50, annualized_return: 28.90, latest_nav: 105.60, period_days: 365 },
      latest_nav: 105.60,
      suitability: 'Suitable'
    },
    {
      scheme_code: 120473,
      scheme_name: 'DSP Midcap Fund Direct Plan Growth',
      category: 'Mid Cap Equity',
      sub_category: 'Mid Cap',
      risk_level: 'Moderate-High',
      returns: { absolute_return: 31.20, annualized_return: 27.50, latest_nav: 88.40, period_days: 365 },
      latest_nav: 88.40,
      suitability: 'Suitable'
    }
  ];

  // Small Cap Equity Funds (High risk, high growth potential)
  const smallCapFunds = [
    {
      scheme_code: 120503,
      scheme_name: 'Quant Small Cap Fund Direct Plan Growth',
      category: 'Small Cap Equity',
      sub_category: 'Small Cap',
      risk_level: 'High',
      returns: { absolute_return: 45.23, annualized_return: 38.50, latest_nav: 125.45, period_days: 365 },
      latest_nav: 125.45,
      suitability: 'Suitable'
    },
    {
      scheme_code: 120465,
      scheme_name: 'Nippon India Small Cap Fund Direct Growth',
      category: 'Small Cap Equity',
      sub_category: 'Small Cap',
      risk_level: 'High',
      returns: { absolute_return: 38.93, annualized_return: 35.20, latest_nav: 98.32, period_days: 365 },
      latest_nav: 98.32,
      suitability: 'Suitable'
    }
  ];

  // Hybrid/Balanced Funds (Mix of equity and debt)
  const hybridFunds = [
    {
      scheme_code: 120474,
      scheme_name: 'HDFC Balanced Advantage Fund Direct Plan Growth',
      category: 'Hybrid',
      sub_category: 'Balanced',
      risk_level: 'Moderate',
      returns: { absolute_return: 22.50, annualized_return: 20.30, latest_nav: 45.80, period_days: 365 },
      latest_nav: 45.80,
      suitability: 'Suitable'
    },
    {
      scheme_code: 120475,
      scheme_name: 'ICICI Prudential Balanced Advantage Fund Direct Growth',
      category: 'Hybrid',
      sub_category: 'Balanced',
      risk_level: 'Moderate',
      returns: { absolute_return: 21.80, annualized_return: 19.60, latest_nav: 42.30, period_days: 365 },
      latest_nav: 42.30,
      suitability: 'Suitable'
    }
  ];

  // Debt/Liquid Funds (Low risk, stable returns)
  const debtFunds = [
    {
      scheme_code: 120468,
      scheme_name: 'HDFC Liquid Fund Direct Plan Growth',
      category: 'Debt',
      sub_category: 'Liquid',
      risk_level: 'Low',
      returns: { absolute_return: 6.50, annualized_return: 6.20, latest_nav: 25.45, period_days: 365 },
      latest_nav: 25.45,
      suitability: 'Suitable'
    },
    {
      scheme_code: 120469,
      scheme_name: 'ICICI Prudential Liquid Fund Direct Plan Growth',
      category: 'Debt',
      sub_category: 'Liquid',
      risk_level: 'Low',
      returns: { absolute_return: 6.20, annualized_return: 5.90, latest_nav: 24.80, period_days: 365 },
      latest_nav: 24.80,
      suitability: 'Suitable'
    },
    {
      scheme_code: 120470,
      scheme_name: 'SBI Magnum Gilt Fund Direct Plan Growth',
      category: 'Debt',
      sub_category: 'Gilt',
      risk_level: 'Low',
      returns: { absolute_return: 7.50, annualized_return: 7.20, latest_nav: 28.50, period_days: 365 },
      latest_nav: 28.50,
      suitability: 'Suitable'
    }
  ];

  // ELSS Funds (Tax-saving equity funds)
  const elssFunds = [
    {
      scheme_code: 120476,
      scheme_name: 'HDFC TaxSaver Fund Direct Plan Growth',
      category: 'ELSS',
      sub_category: 'Tax Saving',
      risk_level: 'Moderate-High',
      returns: { absolute_return: 28.50, annualized_return: 25.80, latest_nav: 95.60, period_days: 365 },
      latest_nav: 95.60,
      suitability: 'Suitable'
    },
    {
      scheme_code: 120477,
      scheme_name: 'ICICI Prudential Long Term Equity Fund Direct Growth',
      category: 'ELSS',
      sub_category: 'Tax Saving',
      risk_level: 'Moderate-High',
      returns: { absolute_return: 27.30, annualized_return: 24.60, latest_nav: 88.20, period_days: 365 },
      latest_nav: 88.20,
      suitability: 'Suitable'
    }
  ];

  // Return curated portfolio based on risk profile
  switch (riskProfile) {
    case 'Conservative':
      // 30% Equity (Large Cap only), 70% Debt
      return {
        largeCap: largeCapFunds.slice(0, 1),
        midCap: [],
        smallCap: [],
        hybrid: [],
        debt: debtFunds.slice(0, 2),
        elss: []
      };

    case 'Moderate':
      // 50% Large Cap, 10% Mid Cap, 40% Debt
      return {
        largeCap: largeCapFunds.slice(0, 2),
        midCap: midCapFunds.slice(0, 1),
        smallCap: [],
        hybrid: [],
        debt: debtFunds.slice(0, 1),
        elss: []
      };

    case 'Moderately Aggressive':
      // 40% Large Cap, 25% Mid Cap, 10% Small Cap, 25% Debt
      return {
        largeCap: largeCapFunds.slice(0, 1),
        midCap: midCapFunds.slice(0, 1),
        smallCap: smallCapFunds.slice(0, 1),
        hybrid: [],
        debt: debtFunds.slice(0, 1),
        elss: []
      };

    case 'Aggressive':
      // 30% Large Cap, 25% Mid Cap, 35% Small Cap, 10% Debt
      return {
        largeCap: largeCapFunds.slice(0, 1),
        midCap: midCapFunds.slice(0, 1),
        smallCap: smallCapFunds.slice(0, 2),
        hybrid: [],
        debt: debtFunds.slice(0, 1),
        elss: []
      };

    default:
      // Default to Moderate
      return {
        largeCap: largeCapFunds.slice(0, 2),
        midCap: midCapFunds.slice(0, 1),
        smallCap: [],
        hybrid: [],
        debt: debtFunds.slice(0, 1),
        elss: []
      };
  }
}

/**
 * Get fallback/default mutual funds when API doesn't return results
 * Uses curated portfolio funds
 */
function getFallbackFunds(riskProfile) {
  const portfolio = getCuratedPortfolioFunds(riskProfile);
  
  // Combine all funds into equity and debt arrays for backward compatibility
  const equity = [
    ...portfolio.largeCap,
    ...portfolio.midCap,
    ...portfolio.smallCap,
    ...portfolio.elss
  ];
  const debt = [
    ...portfolio.debt,
    ...portfolio.hybrid
  ];
  
  return { equity, debt, portfolio };
}

/**
 * Get portfolio allocation percentages based on risk profile
 */
function getPortfolioPercentages(riskProfile) {
  switch (riskProfile) {
    case 'Conservative':
      return {
        largeCap: 30,
        midCap: 0,
        smallCap: 0,
        hybrid: 0,
        debt: 70,
        elss: 0
      };
    case 'Moderate':
      return {
        largeCap: 50,
        midCap: 10,
        smallCap: 0,
        hybrid: 0,
        debt: 40,
        elss: 0
      };
    case 'Moderately Aggressive':
      return {
        largeCap: 40,
        midCap: 25,
        smallCap: 10,
        hybrid: 0,
        debt: 25,
        elss: 0
      };
    case 'Aggressive':
      return {
        largeCap: 30,
        midCap: 25,
        smallCap: 35,
        hybrid: 0,
        debt: 10,
        elss: 0
      };
    default:
      return {
        largeCap: 50,
        midCap: 10,
        smallCap: 0,
        hybrid: 0,
        debt: 40,
        elss: 0
      };
  }
}

/**
 * Helper function to calculate portfolio allocation with curated funds
 */
function calculatePortfolioAllocation(riskProfile, monthlyAmount, funds) {
  // Get curated portfolio structure
  const fallback = getFallbackFunds(riskProfile);
  const portfolio = fallback.portfolio;
  const percentages = getPortfolioPercentages(riskProfile);
  
  // If API funds are available, try to map them to categories
  let largeCapFunds = funds.filter(f => 
    f.category === 'Large Cap Equity' || 
    (f.category === 'Equity' && f.risk_level === 'Moderate' && !f.scheme_name?.toLowerCase().includes('small') && !f.scheme_name?.toLowerCase().includes('mid'))
  );
  let midCapFunds = funds.filter(f => 
    f.category === 'Mid Cap Equity' || 
    (f.category === 'Equity' && f.risk_level === 'Moderate-High' && f.scheme_name?.toLowerCase().includes('mid'))
  );
  let smallCapFunds = funds.filter(f => 
    f.category === 'Small Cap Equity' || 
    (f.category === 'Equity' && (f.risk_level === 'High') && f.scheme_name?.toLowerCase().includes('small'))
  );
  let debtFunds = funds.filter(f => 
    f.category === 'Debt' || 
    f.risk_level === 'Low'
  );
  let hybridFunds = funds.filter(f => 
    f.category === 'Hybrid' || 
    f.category === 'Balanced'
  );
  let elssFunds = funds.filter(f => 
    f.category === 'ELSS' || 
    f.scheme_name?.toLowerCase().includes('tax')
  );
  
  // Use fallback funds if API funds are not available
  if (largeCapFunds.length === 0) largeCapFunds = portfolio.largeCap;
  if (midCapFunds.length === 0) midCapFunds = portfolio.midCap;
  if (smallCapFunds.length === 0) smallCapFunds = portfolio.smallCap;
  if (debtFunds.length === 0) debtFunds = portfolio.debt;
  if (hybridFunds.length === 0) hybridFunds = portfolio.hybrid;
  if (elssFunds.length === 0) elssFunds = portfolio.elss;
  
  const allocations = [];
  
  // Allocate Large Cap funds
  if (largeCapFunds.length > 0 && percentages.largeCap > 0) {
    const amount = (monthlyAmount * percentages.largeCap) / 100;
    const perFundAmount = amount / largeCapFunds.length;
    const perFundPercentage = percentages.largeCap / largeCapFunds.length;
    
    largeCapFunds.forEach(fund => {
      allocations.push({
        scheme_code: fund.scheme_code,
        scheme_name: fund.scheme_name,
        category: fund.category || 'Large Cap Equity',
        sub_category: fund.sub_category || 'Large Cap',
        percentage: parseFloat(perFundPercentage.toFixed(2)),
        amount: parseFloat(perFundAmount.toFixed(2)),
        fund_details: {
          scheme_code: fund.scheme_code,
          scheme_name: fund.scheme_name,
          category: fund.category || 'Large Cap Equity',
          sub_category: fund.sub_category || 'Large Cap',
          risk_level: fund.risk_level || 'Moderate',
          returns: fund.returns || {},
          latest_nav: fund.latest_nav || 0
        }
      });
    });
  }
  
  // Allocate Mid Cap funds
  if (midCapFunds.length > 0 && percentages.midCap > 0) {
    const amount = (monthlyAmount * percentages.midCap) / 100;
    const perFundAmount = amount / midCapFunds.length;
    const perFundPercentage = percentages.midCap / midCapFunds.length;
    
    midCapFunds.forEach(fund => {
      allocations.push({
        scheme_code: fund.scheme_code,
        scheme_name: fund.scheme_name,
        category: fund.category || 'Mid Cap Equity',
        sub_category: fund.sub_category || 'Mid Cap',
        percentage: parseFloat(perFundPercentage.toFixed(2)),
        amount: parseFloat(perFundAmount.toFixed(2)),
        fund_details: {
          scheme_code: fund.scheme_code,
          scheme_name: fund.scheme_name,
          category: fund.category || 'Mid Cap Equity',
          sub_category: fund.sub_category || 'Mid Cap',
          risk_level: fund.risk_level || 'Moderate-High',
          returns: fund.returns || {},
          latest_nav: fund.latest_nav || 0
        }
      });
    });
  }
  
  // Allocate Small Cap funds
  if (smallCapFunds.length > 0 && percentages.smallCap > 0) {
    const amount = (monthlyAmount * percentages.smallCap) / 100;
    const perFundAmount = amount / smallCapFunds.length;
    const perFundPercentage = percentages.smallCap / smallCapFunds.length;
    
    smallCapFunds.forEach(fund => {
      allocations.push({
        scheme_code: fund.scheme_code,
        scheme_name: fund.scheme_name,
        category: fund.category || 'Small Cap Equity',
        sub_category: fund.sub_category || 'Small Cap',
        percentage: parseFloat(perFundPercentage.toFixed(2)),
        amount: parseFloat(perFundAmount.toFixed(2)),
        fund_details: {
          scheme_code: fund.scheme_code,
          scheme_name: fund.scheme_name,
          category: fund.category || 'Small Cap Equity',
          sub_category: fund.sub_category || 'Small Cap',
          risk_level: fund.risk_level || 'High',
          returns: fund.returns || {},
          latest_nav: fund.latest_nav || 0
        }
      });
    });
  }
  
  // Allocate Debt funds
  if (debtFunds.length > 0 && percentages.debt > 0) {
    const amount = (monthlyAmount * percentages.debt) / 100;
    const perFundAmount = amount / debtFunds.length;
    const perFundPercentage = percentages.debt / debtFunds.length;
    
    debtFunds.forEach(fund => {
      allocations.push({
        scheme_code: fund.scheme_code,
        scheme_name: fund.scheme_name,
        category: fund.category || 'Debt',
        sub_category: fund.sub_category || 'Liquid',
        percentage: parseFloat(perFundPercentage.toFixed(2)),
        amount: parseFloat(perFundAmount.toFixed(2)),
        fund_details: {
          scheme_code: fund.scheme_code,
          scheme_name: fund.scheme_name,
          category: fund.category || 'Debt',
          sub_category: fund.sub_category || 'Liquid',
          risk_level: fund.risk_level || 'Low',
          returns: fund.returns || {},
          latest_nav: fund.latest_nav || 0
        }
      });
    });
  }
  
  // Allocate Hybrid funds (if any)
  if (hybridFunds.length > 0 && percentages.hybrid > 0) {
    const amount = (monthlyAmount * percentages.hybrid) / 100;
    const perFundAmount = amount / hybridFunds.length;
    const perFundPercentage = percentages.hybrid / hybridFunds.length;
    
    hybridFunds.forEach(fund => {
      allocations.push({
        scheme_code: fund.scheme_code,
        scheme_name: fund.scheme_name,
        category: fund.category || 'Hybrid',
        sub_category: fund.sub_category || 'Balanced',
        percentage: parseFloat(perFundPercentage.toFixed(2)),
        amount: parseFloat(perFundAmount.toFixed(2)),
        fund_details: {
          scheme_code: fund.scheme_code,
          scheme_name: fund.scheme_name,
          category: fund.category || 'Hybrid',
          sub_category: fund.sub_category || 'Balanced',
          risk_level: fund.risk_level || 'Moderate',
          returns: fund.returns || {},
          latest_nav: fund.latest_nav || 0
        }
      });
    });
  }
  
  // Allocate ELSS funds (if any)
  if (elssFunds.length > 0 && percentages.elss > 0) {
    const amount = (monthlyAmount * percentages.elss) / 100;
    const perFundAmount = amount / elssFunds.length;
    const perFundPercentage = percentages.elss / elssFunds.length;
    
    elssFunds.forEach(fund => {
      allocations.push({
        scheme_code: fund.scheme_code,
        scheme_name: fund.scheme_name,
        category: fund.category || 'ELSS',
        sub_category: fund.sub_category || 'Tax Saving',
        percentage: parseFloat(perFundPercentage.toFixed(2)),
        amount: parseFloat(perFundAmount.toFixed(2)),
        fund_details: {
          scheme_code: fund.scheme_code,
          scheme_name: fund.scheme_name,
          category: fund.category || 'ELSS',
          sub_category: fund.sub_category || 'Tax Saving',
          risk_level: fund.risk_level || 'Moderate-High',
          returns: fund.returns || {},
          latest_nav: fund.latest_nav || 0
        }
      });
    });
  }
  
  return allocations;
}

// 1. Generate Investment Plan
router.post('/generate', [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
  body('goal_id').optional().isInt().withMessage('Goal ID must be an integer'),
  body('frequency').optional().isIn(['monthly', 'weekly', 'daily']).withMessage('Frequency must be monthly, weekly, or daily'),
  body('monthly_amount').optional().isFloat({ min: 0 }).withMessage('Monthly amount must be a positive number'),
  body('duration_months').optional().isInt({ min: 1 }).withMessage('Duration must be a positive integer'),
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

    const { user_id, goal_id, frequency = 'monthly', monthly_amount = 5000, duration_months = 18 } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Check if goal exists (if provided)
    if (goal_id) {
      const goalCheck = await query('SELECT id FROM goals WHERE id = $1 AND user_id = $2', [goal_id, user_id]);
      if (goalCheck.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Goal not found or does not belong to user' });
      }
    }

    // Check if plan already exists
    let existingPlan;
    if (goal_id) {
      const planResult = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id = $2',
        [user_id, goal_id]
      );
      existingPlan = planResult.rows[0];
    } else {
      const planResult = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id IS NULL',
        [user_id]
      );
      existingPlan = planResult.rows[0];
    }

    if (existingPlan) {
      // Check if allocations are empty and regenerate if needed
      const portfolioAllocation = existingPlan.portfolio_allocation;
      if (!portfolioAllocation || !portfolioAllocation.allocations || portfolioAllocation.allocations.length === 0) {
        console.log('Existing plan has empty allocations, regenerating...');
        
        const riskProfile = existingPlan.risk_profile;
        const autoSaveConfig = existingPlan.auto_save_config;
        const monthlyAmount = autoSaveConfig?.monthly_amount || monthly_amount;
        
        // Generate allocations using curated portfolio (empty funds array will trigger fallback)
        let allocations = calculatePortfolioAllocation(riskProfile, monthlyAmount, []);
        
        // If still empty, something went wrong - use direct curated portfolio
        if (!allocations || allocations.length === 0) {
          console.log('Creating allocations directly from curated portfolio');
          const portfolio = getCuratedPortfolioFunds(riskProfile);
          const percentages = getPortfolioPercentages(riskProfile);
          allocations = [];
          
          // Combine all funds with their categories
          const allFunds = [
            ...portfolio.largeCap.map(f => ({ ...f, allocationPercent: percentages.largeCap / portfolio.largeCap.length })),
            ...portfolio.midCap.map(f => ({ ...f, allocationPercent: percentages.midCap / portfolio.midCap.length })),
            ...portfolio.smallCap.map(f => ({ ...f, allocationPercent: percentages.smallCap / portfolio.smallCap.length })),
            ...portfolio.debt.map(f => ({ ...f, allocationPercent: percentages.debt / portfolio.debt.length })),
            ...portfolio.hybrid.map(f => ({ ...f, allocationPercent: percentages.hybrid / portfolio.hybrid.length })),
            ...portfolio.elss.map(f => ({ ...f, allocationPercent: percentages.elss / portfolio.elss.length }))
          ].filter(f => f.allocationPercent > 0);
          
          allFunds.forEach(fund => {
            allocations.push({
              scheme_code: fund.scheme_code,
              scheme_name: fund.scheme_name,
              category: fund.category,
              sub_category: fund.sub_category,
              percentage: parseFloat(fund.allocationPercent.toFixed(2)),
              amount: parseFloat((monthlyAmount * fund.allocationPercent / 100).toFixed(2)),
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
        
        // Update the plan in database
        const updatedPortfolio = {
          description: "According to your Risk Folio, We have curated the best investment portfolio",
          allocations: allocations
        };
        
        const updateResult = await query(
          `UPDATE investment_plans 
           SET portfolio_allocation = $1::jsonb, updated_at = CURRENT_TIMESTAMP 
           WHERE id = $2
           RETURNING *`,
          [JSON.stringify(updatedPortfolio), existingPlan.id]
        );
        
        existingPlan = updateResult.rows[0];
        console.log(`Regenerated ${allocations.length} allocations for existing plan ${existingPlan.id}`);
      }
      
      return res.json({
        success: true,
        plan: {
          id: existingPlan.id,
          user_id: existingPlan.user_id,
          goal_id: existingPlan.goal_id,
          risk_profile: existingPlan.risk_profile,
          risk_profile_display: existingPlan.risk_profile_display,
          auto_save: existingPlan.auto_save_config,
          portfolio: existingPlan.portfolio_allocation,
          status: existingPlan.status,
          created_at: existingPlan.created_at,
          updated_at: existingPlan.updated_at
        }
      });
    }

    // Get user's risk profile
    const riskProfile = await getUserRiskProfile(user_id);
    const riskProfileDisplay = {
      'Conservative': 'Capital Protection Investor',
      'Moderate': 'Balanced Growth Investor',
      'Moderately Aggressive': 'Growth Seeker',
      'Aggressive': 'Wealth Builder'
    }[riskProfile] || riskProfile;

    // Get recommended mutual funds
    let fundsResponse = [];
    try {
      fundsResponse = await mutualFundService.getBestPerformingFunds({
        riskProfile,
        investmentHorizon: 'long-term',
        limit: 10
      });
      console.log(`Fetched ${fundsResponse.length} funds from API`);
    } catch (error) {
      console.error('Error fetching mutual funds:', error);
      console.log('Using fallback funds for portfolio allocation');
      // Will use fallback funds in calculatePortfolioAllocation
    }

    // Calculate portfolio allocation (will use fallback if fundsResponse is empty)
    let allocations = calculatePortfolioAllocation(riskProfile, monthly_amount, fundsResponse);
    
    // Ensure we have allocations - if still empty, use fallback directly
    if (!allocations || allocations.length === 0) {
      console.log('No allocations generated, using fallback funds directly');
      const fallback = getFallbackFunds(riskProfile);
      const allFallbackFunds = [...fallback.equity, ...fallback.debt];
      allocations = calculatePortfolioAllocation(riskProfile, monthly_amount, allFallbackFunds);
    }
    
    // Final check - if still empty, create minimal allocations from fallback
    if (!allocations || allocations.length === 0) {
      console.error('Still no allocations, creating minimal fallback allocations');
      const fallback = getFallbackFunds(riskProfile);
      allocations = [];
      
      // Create equity allocations
      if (fallback.equity.length > 0) {
        const equityPercentage = riskProfile === 'Conservative' ? 30 : riskProfile === 'Moderate' ? 60 : riskProfile === 'Moderately Aggressive' ? 75 : 90;
        const equityAmount = (monthly_amount * equityPercentage) / 100;
        const perFundAmount = equityAmount / fallback.equity.length;
        const perFundPercentage = equityPercentage / fallback.equity.length;
        
        fallback.equity.forEach(fund => {
          allocations.push({
            scheme_code: fund.scheme_code,
            scheme_name: fund.scheme_name,
            category: 'Equity',
            percentage: parseFloat(perFundPercentage.toFixed(2)),
            amount: parseFloat(perFundAmount.toFixed(2)),
            fund_details: fund
          });
        });
      }
      
      // Create debt allocations
      if (fallback.debt.length > 0) {
        const debtPercentage = riskProfile === 'Conservative' ? 70 : riskProfile === 'Moderate' ? 40 : riskProfile === 'Moderately Aggressive' ? 25 : 10;
        const debtAmount = (monthly_amount * debtPercentage) / 100;
        const perFundAmount = debtAmount / fallback.debt.length;
        const perFundPercentage = debtPercentage / fallback.debt.length;
        
        fallback.debt.forEach(fund => {
          allocations.push({
            scheme_code: fund.scheme_code,
            scheme_name: fund.scheme_name,
            category: 'Debt',
            percentage: parseFloat(perFundPercentage.toFixed(2)),
            amount: parseFloat(perFundAmount.toFixed(2)),
            fund_details: fund
          });
        });
      }
    }
    
    console.log(`Generated ${allocations.length} portfolio allocations`);

    // Calculate weekly and daily amounts
    const weeklyAmount = parseFloat((monthly_amount / 4.33).toFixed(2));
    const dailyAmount = parseFloat((monthly_amount / 30).toFixed(2));

    const autoSaveConfig = {
      frequency,
      monthly_amount: parseFloat(monthly_amount),
      duration_months: parseInt(duration_months),
      weekly_amount: weeklyAmount,
      daily_amount: dailyAmount
    };

    const portfolioAllocation = {
      description: "According to your Risk Folio, We have curated the best investment portfolio",
      allocations
    };

    // Insert new plan
    const result = await query(
      `INSERT INTO investment_plans 
       (user_id, goal_id, risk_profile, risk_profile_display, auto_save_config, portfolio_allocation, status)
       VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, 'active')
       ON CONFLICT (user_id, goal_id) 
       DO UPDATE SET
         auto_save_config = EXCLUDED.auto_save_config,
         portfolio_allocation = EXCLUDED.portfolio_allocation,
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [user_id, goal_id || null, riskProfile, riskProfileDisplay, JSON.stringify(autoSaveConfig), JSON.stringify(portfolioAllocation)]
    );

    const plan = result.rows[0];

    res.json({
      success: true,
      plan: {
        id: plan.id,
        user_id: plan.user_id,
        goal_id: plan.goal_id,
        risk_profile: plan.risk_profile,
        risk_profile_display: plan.risk_profile_display,
        auto_save: plan.auto_save_config,
        portfolio: plan.portfolio_allocation,
        status: plan.status,
        created_at: plan.created_at,
        updated_at: plan.updated_at
      }
    });
  } catch (error) {
    console.error('Generate investment plan error:', error);
    res.status(500).json({ success: false, error: 'Failed to generate investment plan', details: error.message });
  }
});

// 2. Get Investment Plan
router.get('/user/:userId', [
  param('userId').isInt().withMessage('User ID must be an integer'),
  queryCheck('goal_id').optional().isInt().withMessage('Goal ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { userId } = req.params;
    const goalId = req.query.goal_id;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [userId]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    let result;
    if (goalId) {
      result = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id = $2',
        [userId, goalId]
      );
    } else {
      result = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id IS NULL',
        [userId]
      );
    }

    if (result.rows.length === 0) {
      return res.json({ success: true, plan: null });
    }

    let plan = result.rows[0];
    const portfolioAllocation = plan.portfolio_allocation;
    
    // Check if allocations are empty and regenerate if needed
    if (!portfolioAllocation || !portfolioAllocation.allocations || portfolioAllocation.allocations.length === 0) {
      console.log('Plan has empty allocations, regenerating...');
      
      const riskProfile = plan.risk_profile;
      const autoSaveConfig = plan.auto_save_config;
      const monthlyAmount = autoSaveConfig?.monthly_amount || 5000;
      
      // Get fallback funds
      const fallback = getFallbackFunds(riskProfile);
      const allFallbackFunds = [...fallback.equity, ...fallback.debt];
      
      // Generate allocations
      let allocations = calculatePortfolioAllocation(riskProfile, monthlyAmount, allFallbackFunds);
      
      // Final check - if still empty, create minimal allocations
      if (!allocations || allocations.length === 0) {
        console.log('Creating allocations directly from curated portfolio');
        const portfolio = getCuratedPortfolioFunds(riskProfile);
        const percentages = getPortfolioPercentages(riskProfile);
        allocations = [];
        
        // Combine all funds with their categories
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
            amount: parseFloat((monthlyAmount * fund.allocationPercent / 100).toFixed(2)),
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
      
      // Update the plan in database with new allocations
      const updatedPortfolio = {
        description: "According to your Risk Folio, We have curated the best investment portfolio",
        allocations: allocations
      };
      
      await query(
        `UPDATE investment_plans 
         SET portfolio_allocation = $1::jsonb, updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2`,
        [JSON.stringify(updatedPortfolio), plan.id]
      );
      
      // Update plan object for response
      plan.portfolio_allocation = updatedPortfolio;
      console.log(`Regenerated ${allocations.length} allocations for plan ${plan.id}`);
    }
    
    res.json({
      success: true,
      plan: {
        id: plan.id,
        user_id: plan.user_id,
        goal_id: plan.goal_id,
        risk_profile: plan.risk_profile,
        risk_profile_display: plan.risk_profile_display,
        auto_save: plan.auto_save_config,
        portfolio: plan.portfolio_allocation,
        status: plan.status,
        created_at: plan.created_at,
        updated_at: plan.updated_at
      }
    });
  } catch (error) {
    console.error('Get investment plan error:', error);
    res.status(500).json({ success: false, error: 'Failed to get investment plan' });
  }
});

// 3. Update/Create Auto-Save Configuration
router.put('/auto-save', [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
  body('frequency').isIn(['monthly', 'weekly', 'daily']).withMessage('Frequency must be monthly, weekly, or daily'),
  body('monthly_amount').isFloat({ min: 100 }).withMessage('Monthly amount must be at least ₹100'),
  body('duration_months').optional().isInt({ min: 1 }).withMessage('Duration must be a positive integer'),
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

    const { user_id, frequency, monthly_amount, duration_months, goal_id } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Validate goal if provided
    let goal = null;
    if (goal_id) {
      const goalCheck = await query('SELECT * FROM goals WHERE id = $1 AND user_id = $2', [goal_id, user_id]);
      if (goalCheck.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Goal not found' });
      }
      goal = goalCheck.rows[0];
    }

    // Calculate duration if not provided
    let finalDuration = duration_months;
    if (!finalDuration && goal) {
      const targetDate = new Date(goal.target_date);
      const today = new Date();
      const monthsDiff = (targetDate.getFullYear() - today.getFullYear()) * 12 + 
                        (targetDate.getMonth() - today.getMonth());
      finalDuration = Math.max(1, monthsDiff);
    } else if (!finalDuration) {
      finalDuration = 18; // Default
    }

    // Calculate weekly and daily amounts
    const weeklyAmount = parseFloat((monthly_amount / 4.33).toFixed(2));
    const dailyAmount = parseFloat((monthly_amount / 30).toFixed(2));

    const autoSaveConfig = {
      frequency,
      monthly_amount: parseFloat(monthly_amount),
      weekly_amount: weeklyAmount,
      daily_amount: dailyAmount,
      duration_months: parseInt(finalDuration)
    };

    // Find existing plan
    let result;
    if (goal_id) {
      result = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id = $2',
        [user_id, goal_id]
      );
    } else {
      result = await query(
        'SELECT * FROM investment_plans WHERE user_id = $1 AND goal_id IS NULL',
        [user_id]
      );
    }

    if (result.rows.length === 0) {
      // Create new investment plan
      const riskProfile = await getUserRiskProfile(user_id);
      const riskProfileDisplay = {
        'Conservative': 'Capital Protection Investor',
        'Moderate': 'Balanced Growth Investor',
        'Moderately Aggressive': 'Growth Seeker',
        'Aggressive': 'Wealth Builder'
      }[riskProfile] || riskProfile;

      // Generate portfolio allocation
      let allocations = calculatePortfolioAllocation(riskProfile, monthly_amount, []);
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
            amount: parseFloat((monthly_amount * fund.allocationPercent / 100).toFixed(2)),
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

      const portfolioAllocation = {
        description: "According to your Risk Folio, We have curated the best investment portfolio",
        allocations
      };

      const newPlan = await query(
        `INSERT INTO investment_plans 
         (user_id, goal_id, risk_profile, risk_profile_display, auto_save_config, portfolio_allocation, status)
         VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, 'active')
         RETURNING *`,
        [user_id, goal_id || null, riskProfile, riskProfileDisplay, JSON.stringify(autoSaveConfig), JSON.stringify(portfolioAllocation)]
      );

      return res.json({
        success: true,
        message: 'Auto-save configuration created successfully',
        plan: {
          id: newPlan.rows[0].id,
          user_id: newPlan.rows[0].user_id,
          goal_id: newPlan.rows[0].goal_id,
          risk_profile: newPlan.rows[0].risk_profile,
          risk_profile_display: newPlan.rows[0].risk_profile_display,
          auto_save: newPlan.rows[0].auto_save_config,
          portfolio: newPlan.rows[0].portfolio_allocation,
          status: newPlan.rows[0].status,
          created_at: newPlan.rows[0].created_at,
          updated_at: newPlan.rows[0].updated_at
        }
      });
    }

    // Update existing plan
    const existingPlan = result.rows[0];
    const currentAutoSave = existingPlan.auto_save_config || {};
    
    // Recalculate portfolio amounts if monthly_amount changed
    let portfolioAllocation = existingPlan.portfolio_allocation || { allocations: [] };
    if (monthly_amount && monthly_amount !== currentAutoSave.monthly_amount) {
      const newAmount = parseFloat(monthly_amount);
      portfolioAllocation.allocations = portfolioAllocation.allocations.map(alloc => ({
        ...alloc,
        amount: parseFloat(((newAmount * alloc.percentage) / 100).toFixed(2))
      }));
    }

    // Update plan
    const updateResult = await query(
      `UPDATE investment_plans 
       SET auto_save_config = $1::jsonb, 
           portfolio_allocation = $2::jsonb,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $3
       RETURNING *`,
      [JSON.stringify(autoSaveConfig), JSON.stringify(portfolioAllocation), existingPlan.id]
    );

    const plan = updateResult.rows[0];
    res.json({
      success: true,
      message: 'Auto-save configuration updated successfully',
      plan: {
        id: plan.id,
        user_id: plan.user_id,
        goal_id: plan.goal_id,
        risk_profile: plan.risk_profile,
        risk_profile_display: plan.risk_profile_display,
        auto_save: plan.auto_save_config,
        portfolio: plan.portfolio_allocation,
        status: plan.status,
        created_at: plan.created_at,
        updated_at: plan.updated_at
      }
    });
  } catch (error) {
    console.error('Update auto-save error:', error);
    res.status(500).json({ success: false, error: 'Failed to update auto-save configuration' });
  }
});

// 4. Create Payment Mandate
router.post('/payment-mandate', [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
  body('bank_account_number').isLength({ min: 9, max: 18 }).withMessage('Account number must be between 9 and 18 digits'),
  body('ifsc_code').isLength({ min: 11, max: 11 }).matches(/^[A-Z]{4}0[A-Z0-9]{6}$/).withMessage('IFSC code must be exactly 11 characters (e.g., HDFC0001234)'),
  body('account_holder_name').trim().notEmpty().withMessage('Account holder name is required'),
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

    const { user_id, goal_id, bank_account_number, ifsc_code, account_holder_name } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Get investment plan
    let planResult;
    if (goal_id) {
      planResult = await query(
        'SELECT id FROM investment_plans WHERE user_id = $1 AND goal_id = $2',
        [user_id, goal_id]
      );
    } else {
      planResult = await query(
        'SELECT id FROM investment_plans WHERE user_id = $1 AND goal_id IS NULL',
        [user_id]
      );
    }

    const investmentPlanId = planResult.rows[0]?.id || null;

    // Generate mandate reference (integrate with payment gateway in production)
    const mandateReference = `MANDATE_REF_${Date.now()}_${user_id}`;

    // Create mandate
    const result = await query(
      `INSERT INTO payment_mandates 
       (user_id, goal_id, investment_plan_id, bank_account_number, ifsc_code, account_holder_name, mandate_reference)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [user_id, goal_id || null, investmentPlanId, bank_account_number, ifsc_code.toUpperCase(), account_holder_name, mandateReference]
    );

    const mandate = result.rows[0];
    res.json({
      success: true,
      mandate: {
        id: mandate.id,
        user_id: mandate.user_id,
        goal_id: mandate.goal_id,
        investment_plan_id: mandate.investment_plan_id,
        bank_account_number: mandate.bank_account_number,
        ifsc_code: mandate.ifsc_code,
        account_holder_name: mandate.account_holder_name,
        mandate_status: mandate.mandate_status,
        mandate_reference: mandate.mandate_reference,
        created_at: mandate.created_at,
        updated_at: mandate.updated_at
      }
    });
  } catch (error) {
    console.error('Create payment mandate error:', error);
    res.status(500).json({ success: false, error: 'Failed to create payment mandate' });
  }
});

// 5. Complete Investment Setup
router.post('/complete-setup', [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
  body('mandate_id').isInt().withMessage('Mandate ID is required and must be an integer'),
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

    const { user_id, mandate_id, goal_id } = req.body;

    // Check if mandate exists and belongs to user
    const mandateResult = await query(
      'SELECT * FROM payment_mandates WHERE id = $1 AND user_id = $2',
      [mandate_id, user_id]
    );

    if (mandateResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Payment mandate not found' });
    }

    const mandate = mandateResult.rows[0];

    // Update mandate status
    await query(
      `UPDATE payment_mandates 
       SET mandate_status = 'active', 
           activated_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [mandate_id]
    );

    // Update investment plan status
    let planResult;
    if (goal_id) {
      planResult = await query(
        `UPDATE investment_plans 
         SET status = 'active', updated_at = CURRENT_TIMESTAMP
         WHERE user_id = $1 AND goal_id = $2
         RETURNING *`,
        [user_id, goal_id]
      );
    } else {
      planResult = await query(
        `UPDATE investment_plans 
         SET status = 'active', updated_at = CURRENT_TIMESTAMP
         WHERE user_id = $1 AND goal_id IS NULL
         RETURNING *`,
        [user_id]
      );
    }

    const plan = planResult.rows[0] || null;

    // Get updated mandate
    const updatedMandateResult = await query(
      'SELECT * FROM payment_mandates WHERE id = $1',
      [mandate_id]
    );
    const updatedMandate = updatedMandateResult.rows[0];

    res.json({
      success: true,
      message: 'Investment setup completed successfully',
      plan: plan ? {
        id: plan.id,
        user_id: plan.user_id,
        goal_id: plan.goal_id,
        status: plan.status,
        risk_profile: plan.risk_profile,
        risk_profile_display: plan.risk_profile_display,
        auto_save: plan.auto_save_config,
        portfolio: plan.portfolio_allocation
      } : null,
      mandate: {
        id: updatedMandate.id,
        mandate_status: updatedMandate.mandate_status,
        activated_at: updatedMandate.activated_at
      }
    });
  } catch (error) {
    console.error('Complete setup error:', error);
    res.status(500).json({ success: false, error: 'Failed to complete setup' });
  }
});

// Export helper functions for use in other routes
module.exports = router;
module.exports.getUserRiskProfile = getUserRiskProfile;
module.exports.getCuratedPortfolioFunds = getCuratedPortfolioFunds;
module.exports.getPortfolioPercentages = getPortfolioPercentages;
module.exports.calculatePortfolioAllocation = calculatePortfolioAllocation;

