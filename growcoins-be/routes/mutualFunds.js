const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { param, query: queryCheck, validationResult } = require('express-validator');
const mutualFundService = require('../services/mutualFundService');

// Get Recommended Mutual Funds for User
router.get('/recommendations/:user_id', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
  queryCheck('horizon').optional().isIn(['short-term', 'long-term']).withMessage('Horizon must be short-term or long-term'),
  queryCheck('limit').optional().isInt({ min: 1, max: 20 }).withMessage('Limit must be between 1 and 20'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { user_id } = req.params;
    const investmentHorizon = req.query.horizon || 'long-term';
    const limit = parseInt(req.query.limit) || 10;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }

    // Get user's investment profile
    const profileResult = await query(
      'SELECT * FROM invest_profiles WHERE user_id = $1',
      [user_id]
    );

    const riskProfile = profileResult.rows[0]?.risk_profile || 'Moderate';
    const investmentPreference = profileResult.rows[0]?.investment_preference || null;

    // Get recommended funds
    const funds = await mutualFundService.getBestPerformingFunds({
      riskProfile,
      investmentHorizon,
      category: investmentPreference,
      limit
    });

    res.json({
      success: true,
      user_id: parseInt(user_id),
      risk_profile: riskProfile,
      investment_horizon: investmentHorizon,
      recommendations: funds,
      count: funds.length
    });
  } catch (error) {
    console.error('Get recommendations error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to get mutual fund recommendations',
      message: error.message 
    });
  }
});

// Search Mutual Funds
router.get('/search', [
  queryCheck('q').notEmpty().withMessage('Search query is required'),
  queryCheck('limit').optional().isInt({ min: 1, max: 50 }),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const searchQuery = req.query.q;
    const limit = parseInt(req.query.limit) || 20;

    const results = await mutualFundService.searchSchemes(searchQuery);

    res.json({
      success: true,
      query: searchQuery,
      results: results.slice(0, limit).map(scheme => ({
        scheme_code: scheme.schemeCode,
        scheme_name: scheme.schemeName,
        category: mutualFundService.categorizeScheme(scheme.schemeName),
        risk_level: mutualFundService.getRiskLevel(scheme.schemeName)
      })),
      count: Math.min(results.length, limit)
    });
  } catch (error) {
    console.error('Search mutual funds error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to search mutual funds',
      message: error.message 
    });
  }
});

// Get Scheme Details
router.get('/scheme/:scheme_code', [
  param('scheme_code').isInt().withMessage('Scheme code must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { scheme_code } = req.params;

    const schemeDetails = await mutualFundService.getSchemeDetails(scheme_code);
    const navHistory = await mutualFundService.getNAVHistory(scheme_code, 365);
    const returns = mutualFundService.calculateReturns(navHistory);

    res.json({
      success: true,
      scheme: {
        scheme_code: parseInt(scheme_code),
        scheme_name: schemeDetails.meta?.scheme_name || 'N/A',
        fund_house: schemeDetails.meta?.fund_house || 'N/A',
        scheme_type: schemeDetails.meta?.scheme_type || 'N/A',
        scheme_category: schemeDetails.meta?.scheme_category || 'N/A',
        category: mutualFundService.categorizeScheme(schemeDetails.meta?.scheme_name),
        risk_level: mutualFundService.getRiskLevel(schemeDetails.meta?.scheme_name),
        returns: returns,
        nav_history: navHistory.slice(-30), // Last 30 days
        latest_nav: navHistory.length > 0 ? parseFloat(navHistory[navHistory.length - 1].nav) : null
      }
    });
  } catch (error) {
    console.error('Get scheme details error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to get scheme details',
      message: error.message 
    });
  }
});

// Get Best Performing Funds (General)
router.get('/best-performing', [
  queryCheck('horizon').optional().isIn(['short-term', 'long-term']),
  queryCheck('category').optional().isString(),
  queryCheck('risk_profile').optional().isIn(['Conservative', 'Moderate', 'Aggressive']),
  queryCheck('limit').optional().isInt({ min: 1, max: 20 }),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const investmentHorizon = req.query.horizon || 'long-term';
    const category = req.query.category || null;
    const riskProfile = req.query.risk_profile || 'Moderate';
    const limit = parseInt(req.query.limit) || 10;

    const funds = await mutualFundService.getBestPerformingFunds({
      riskProfile,
      investmentHorizon,
      category,
      limit
    });

    res.json({
      success: true,
      filters: {
        horizon: investmentHorizon,
        category: category,
        risk_profile: riskProfile
      },
      funds: funds,
      count: funds.length
    });
  } catch (error) {
    console.error('Get best performing funds error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to get best performing funds',
      message: error.message 
    });
  }
});

module.exports = router;

