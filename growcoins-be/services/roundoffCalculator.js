/**
 * Calculate roundoff savings for a transaction
 * @param {number} amount - Transaction amount
 * @param {number} roundoffAmount - Roundoff amount (5, 10, 20, 30, or custom)
 * @returns {Object} Roundoff calculation result
 */
function calculateRoundoff(amount, roundoffAmount) {
  if (amount <= 0 || roundoffAmount <= 0) {
    return {
      originalAmount: amount,
      roundedAmount: amount,
      roundoff: 0
    };
  }

  // Round up to nearest roundoff amount
  const roundedAmount = Math.ceil(amount / roundoffAmount) * roundoffAmount;
  const roundoff = roundedAmount - amount;

  return {
    originalAmount: amount,
    roundedAmount: roundedAmount,
    roundoff: roundoff
  };
}

/**
 * Calculate roundoff for multiple transactions
 * @param {Array} transactions - Array of transaction objects with amount
 * @param {number} roundoffAmount - Roundoff amount
 * @returns {Array} Transactions with roundoff calculations
 */
function calculateRoundoffForTransactions(transactions, roundoffAmount) {
  return transactions.map(transaction => {
    const calculation = calculateRoundoff(transaction.amount, roundoffAmount);
    return {
      ...transaction,
      roundoff: calculation.roundoff,
      roundedAmount: calculation.roundedAmount
    };
  });
}

/**
 * Calculate total savings from transactions
 * @param {Array} transactions - Array of transactions with roundoff
 * @returns {Object} Savings summary
 */
function calculateTotalSavings(transactions) {
  const totalRoundoff = transactions.reduce((sum, t) => sum + (t.roundoff || 0), 0);
  const transactionCount = transactions.length;
  const totalWithdrawn = transactions.reduce((sum, t) => sum + t.amount, 0);
  const totalRounded = transactions.reduce((sum, t) => sum + (t.roundedAmount || t.amount), 0);

  return {
    totalRoundoff,
    transactionCount,
    totalWithdrawn,
    totalRounded,
    averageRoundoff: transactionCount > 0 ? totalRoundoff / transactionCount : 0
  };
}

/**
 * Calculate time-based savings projections
 * @param {Object} savingsSummary - Current savings summary
 * @param {Date} startDate - Start date of transactions
 * @param {Date} endDate - End date of transactions
 * @returns {Object} Projected savings
 */
function calculateProjections(savingsSummary, startDate, endDate) {
  const daysDiff = Math.max(1, Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24)));
  const transactionsPerDay = savingsSummary.transactionCount / daysDiff;
  const roundoffPerDay = savingsSummary.totalRoundoff / daysDiff;

  return {
    daily: {
      transactions: transactionsPerDay,
      savings: roundoffPerDay
    },
    monthly: {
      transactions: transactionsPerDay * 30,
      savings: roundoffPerDay * 30
    },
    yearly: {
      transactions: transactionsPerDay * 365,
      savings: roundoffPerDay * 365
    },
    period: {
      days: daysDiff,
      transactions: savingsSummary.transactionCount,
      savings: savingsSummary.totalRoundoff
    }
  };
}

/**
 * Generate insights text
 * @param {Object} savingsSummary - Savings summary
 * @param {Object} projections - Projected savings
 * @returns {String} Insight message
 */
function generateInsights(savingsSummary, projections) {
  const insights = [];
  
  // Current period insights
  if (projections.period.days > 0) {
    insights.push(
      `🎉 In ${projections.period.days} day${projections.period.days > 1 ? 's' : ''}, you could have saved ₹${savingsSummary.totalRoundoff.toFixed(2)} through ${savingsSummary.transactionCount} transaction${savingsSummary.transactionCount > 1 ? 's' : ''}!`
    );
  }

  // Monthly projection
  if (projections.monthly.savings > 0) {
    insights.push(
      `📈 At this rate, you could save ₹${projections.monthly.savings.toFixed(2)} per month!`
    );
  }

  // Yearly projection
  if (projections.yearly.savings > 0) {
    insights.push(
      `💰 That's ₹${projections.yearly.savings.toFixed(2)} in a year!`
    );
  }

  // Fun comparisons
  const coffeePrice = 150; // ₹150 per coffee
  const moviePrice = 250; // ₹250 per movie ticket
  const mealPrice = 300; // ₹300 per meal
  
  if (projections.yearly.savings >= coffeePrice) {
    const coffees = Math.floor(projections.yearly.savings / coffeePrice);
    insights.push(`☕ That's enough for ${coffees} coffee${coffees > 1 ? 's' : ''}!`);
  }
  
  if (projections.yearly.savings >= moviePrice) {
    const movies = Math.floor(projections.yearly.savings / moviePrice);
    insights.push(`🎬 Or ${movies} movie ticket${movies > 1 ? 's' : ''}!`);
  }
  
  if (projections.yearly.savings >= mealPrice) {
    const meals = Math.floor(projections.yearly.savings / mealPrice);
    insights.push(`🍽️ Or ${meals} meal${meals > 1 ? 's' : ''} out!`);
  }

  return insights.join('\n');
}

module.exports = {
  calculateRoundoff,
  calculateRoundoffForTransactions,
  calculateTotalSavings,
  calculateProjections,
  generateInsights
};

