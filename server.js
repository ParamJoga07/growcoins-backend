const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Test database connection
const { query } = require('./config/database');

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await query('SELECT NOW()');
    res.status(200).json({
      status: 'OK',
      message: 'Server is running and database is connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      message: 'Database connection failed',
      error: error.message
    });
  }
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/onboarding', require('./routes/onboarding'));
app.use('/api/risk-assessment', require('./routes/riskAssessment'));
app.use('/api/savings', require('./routes/savings'));
app.use('/api/goals', require('./routes/goals'));
app.use('/api/invest', require('./routes/invest'));
app.use('/api/mutual-funds', require('./routes/mutualFunds'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/investment-plan', require('./routes/investmentPlan'));
app.use('/api/kyc/video-kyc', require('./routes/videoKyc'));

// Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Growcoins API Documentation',
  explorer: true
}));

// Swagger JSON endpoint
app.get('/api-docs.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

// Serve uploaded files statically
app.use('/uploads', express.static('uploads'));

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Route not found'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;

