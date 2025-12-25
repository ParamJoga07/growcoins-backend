const https = require('https');
const http = require('http');

/**
 * Mutual Fund Service
 * Uses MFapi.in free API for Indian mutual fund data
 * API Documentation: https://www.mfapi.in/docs/
 */

const MF_API_BASE = 'https://api.mfapi.in';

/**
 * Fetch data from MFapi.in
 */
function fetchFromAPI(endpoint) {
  return new Promise((resolve, reject) => {
    const url = `${MF_API_BASE}${endpoint}`;
    
    https.get(url, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          resolve(jsonData);
        } catch (error) {
          reject(new Error('Failed to parse API response: ' + error.message));
        }
      });
    }).on('error', (error) => {
      reject(new Error('API request failed: ' + error.message));
    });
  });
}

/**
 * Get all mutual fund schemes
 */
async function getAllSchemes() {
  try {
    const data = await fetchFromAPI('/mf');
    return data;
  } catch (error) {
    console.error('Error fetching all schemes:', error);
    throw error;
  }
}

/**
 * Search mutual funds by name
 */
async function searchSchemes(query) {
  try {
    const allSchemes = await getAllSchemes();
    const searchTerm = query.toLowerCase();
    
    const results = allSchemes
      .filter(scheme => 
        scheme.schemeName && 
        scheme.schemeName.toLowerCase().includes(searchTerm)
      )
      .slice(0, 20); // Limit to 20 results
    
    return results;
  } catch (error) {
    console.error('Error searching schemes:', error);
    throw error;
  }
}

/**
 * Get scheme details by scheme code
 */
async function getSchemeDetails(schemeCode) {
  try {
    const data = await fetchFromAPI(`/mf/${schemeCode}`);
    return data;
  } catch (error) {
    console.error('Error fetching scheme details:', error);
    throw error;
  }
}

/**
 * Get NAV history for a scheme
 */
async function getNAVHistory(schemeCode, limit = 30) {
  try {
    const data = await fetchFromAPI(`/mf/${schemeCode}`);
    
    if (data.data && Array.isArray(data.data)) {
      // Return last N NAV entries
      return data.data.slice(-limit);
    }
    
    return [];
  } catch (error) {
    console.error('Error fetching NAV history:', error);
    throw error;
  }
}

/**
 * Calculate returns for a scheme
 */
function calculateReturns(navHistory) {
  if (!navHistory || navHistory.length < 2) {
    return null;
  }

  const sortedNav = navHistory
    .map(item => ({
      date: new Date(item.date),
      nav: parseFloat(item.nav)
    }))
    .sort((a, b) => a.date - b.date);

  const latestNav = sortedNav[sortedNav.length - 1].nav;
  const oldestNav = sortedNav[0].nav;

  // Calculate absolute return
  const absoluteReturn = ((latestNav - oldestNav) / oldestNav) * 100;

  // Calculate annualized return (if we have at least 365 days of data)
  const daysDiff = (sortedNav[sortedNav.length - 1].date - sortedNav[0].date) / (1000 * 60 * 60 * 24);
  const annualizedReturn = daysDiff >= 365 
    ? (Math.pow(latestNav / oldestNav, 365 / daysDiff) - 1) * 100
    : null;

  return {
    absolute_return: parseFloat(absoluteReturn.toFixed(2)),
    annualized_return: annualizedReturn ? parseFloat(annualizedReturn.toFixed(2)) : null,
    period_days: Math.floor(daysDiff),
    latest_nav: latestNav,
    oldest_nav: oldestNav
  };
}

/**
 * Get best performing funds based on criteria
 */
async function getBestPerformingFunds(options = {}) {
  const {
    riskProfile = 'Moderate',
    investmentHorizon = 'long-term', // 'short-term' or 'long-term'
    category = null, // 'equity', 'debt', 'hybrid', etc.
    limit = 10
  } = options;

  try {
    // Get all schemes
    const allSchemes = await getAllSchemes();
    
    // Filter by category if specified
    let filteredSchemes = allSchemes;
    if (category) {
      filteredSchemes = allSchemes.filter(scheme => {
        const schemeName = (scheme.schemeName || '').toLowerCase();
        return schemeName.includes(category.toLowerCase());
      });
    }

    // Get performance data for each scheme
    const schemesWithReturns = await Promise.all(
      filteredSchemes.slice(0, 50).map(async (scheme) => {
        try {
          const navHistory = await getNAVHistory(scheme.schemeCode, 365);
          const returns = calculateReturns(navHistory);
          
          return {
            schemeCode: scheme.schemeCode,
            schemeName: scheme.schemeName,
            returns: returns,
            navHistory: navHistory.slice(-30) // Last 30 days
          };
        } catch (error) {
          console.error(`Error processing scheme ${scheme.schemeCode}:`, error.message);
          return null;
        }
      })
    );

    // Filter out null results and schemes without returns
    const validSchemes = schemesWithReturns.filter(s => s && s.returns);

    // Sort by returns based on investment horizon
    if (investmentHorizon === 'long-term') {
      // Sort by annualized return (prefer annualized, fallback to absolute)
      validSchemes.sort((a, b) => {
        const aReturn = a.returns.annualized_return || a.returns.absolute_return;
        const bReturn = b.returns.annualized_return || b.returns.absolute_return;
        return bReturn - aReturn;
      });
    } else {
      // Short-term: sort by absolute return
      validSchemes.sort((a, b) => b.returns.absolute_return - a.returns.absolute_return);
    }

    // Filter by risk profile
    const riskFiltered = filterByRiskProfile(validSchemes, riskProfile);

    // Return top N funds
    return riskFiltered.slice(0, limit).map(scheme => ({
      scheme_code: scheme.schemeCode,
      scheme_name: scheme.schemeName,
      category: categorizeScheme(scheme.schemeName),
      returns: scheme.returns,
      risk_level: getRiskLevel(scheme.schemeName),
      suitability: getSuitability(scheme.schemeName, riskProfile, investmentHorizon),
      latest_nav: scheme.returns.latest_nav,
      period_days: scheme.returns.period_days
    }));
  } catch (error) {
    console.error('Error getting best performing funds:', error);
    throw error;
  }
}

/**
 * Categorize scheme by name
 */
function categorizeScheme(schemeName) {
  const name = (schemeName || '').toLowerCase();
  
  if (name.includes('equity') || name.includes('growth') || name.includes('small cap') || name.includes('mid cap') || name.includes('large cap')) {
    return 'Equity';
  } else if (name.includes('debt') || name.includes('income') || name.includes('liquid')) {
    return 'Debt';
  } else if (name.includes('hybrid') || name.includes('balanced')) {
    return 'Hybrid';
  } else if (name.includes('elss') || name.includes('tax')) {
    return 'ELSS';
  } else {
    return 'Other';
  }
}

/**
 * Get risk level based on scheme name
 */
function getRiskLevel(schemeName) {
  const name = (schemeName || '').toLowerCase();
  
  if (name.includes('small cap') || name.includes('sectoral') || name.includes('thematic')) {
    return 'High';
  } else if (name.includes('mid cap') || name.includes('equity')) {
    return 'Moderate-High';
  } else if (name.includes('large cap') || name.includes('hybrid') || name.includes('balanced')) {
    return 'Moderate';
  } else if (name.includes('debt') || name.includes('liquid') || name.includes('income')) {
    return 'Low';
  } else {
    return 'Moderate';
  }
}

/**
 * Filter schemes by risk profile
 */
function filterByRiskProfile(schemes, riskProfile) {
  const riskMapping = {
    'Conservative': ['Low', 'Moderate'],
    'Moderate': ['Moderate', 'Moderate-High'],
    'Aggressive': ['Moderate', 'Moderate-High', 'High']
  };

  const allowedRisks = riskMapping[riskProfile] || ['Moderate'];
  
  return schemes.filter(scheme => {
    const riskLevel = getRiskLevel(scheme.schemeName);
    return allowedRisks.includes(riskLevel);
  });
}

/**
 * Get suitability score
 */
function getSuitability(schemeName, riskProfile, investmentHorizon) {
  const riskLevel = getRiskLevel(schemeName);
  const category = categorizeScheme(schemeName);
  
  let score = 0;
  
  // Risk profile matching
  if (riskProfile === 'Conservative' && riskLevel === 'Low') score += 3;
  else if (riskProfile === 'Moderate' && riskLevel === 'Moderate') score += 3;
  else if (riskProfile === 'Aggressive' && riskLevel === 'High') score += 3;
  
  // Investment horizon matching
  if (investmentHorizon === 'long-term' && (category === 'Equity' || category === 'ELSS')) score += 2;
  else if (investmentHorizon === 'short-term' && category === 'Debt') score += 2;
  
  if (score >= 4) return 'Highly Suitable';
  if (score >= 2) return 'Suitable';
  return 'Moderately Suitable';
}

/**
 * Get recommended funds for user
 */
async function getRecommendedFunds(userId, investmentHorizon = 'long-term') {
  try {
    // This would typically fetch user's risk profile from database
    // For now, we'll use a default and let the API handle it
    const riskProfile = 'Moderate'; // Default, should be fetched from DB
    
    const funds = await getBestPerformingFunds({
      riskProfile,
      investmentHorizon,
      limit: 10
    });
    
    return funds;
  } catch (error) {
    console.error('Error getting recommended funds:', error);
    throw error;
  }
}

module.exports = {
  getAllSchemes,
  searchSchemes,
  getSchemeDetails,
  getNAVHistory,
  calculateReturns,
  getBestPerformingFunds,
  getRecommendedFunds,
  categorizeScheme,
  getRiskLevel
};

