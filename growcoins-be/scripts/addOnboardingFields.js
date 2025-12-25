const { query } = require('../config/database');
require('dotenv').config();

async function addOnboardingFields() {
  try {
    // Add new columns to user_data table for onboarding
    console.log('Adding onboarding fields to user_data table...');

    // Add full_legal_name column
    await query(`
      ALTER TABLE user_data 
      ADD COLUMN IF NOT EXISTS full_legal_name VARCHAR(255)
    `);
    console.log('Added full_legal_name column');

    // Add PAN number column
    await query(`
      ALTER TABLE user_data 
      ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10) UNIQUE
    `);
    console.log('Added pan_number column');

    // Add Aadhar number column
    await query(`
      ALTER TABLE user_data 
      ADD COLUMN IF NOT EXISTS aadhar_number VARCHAR(12) UNIQUE
    `);
    console.log('Added aadhar_number column');

    // Create indexes for KYC fields
    await query(`
      CREATE INDEX IF NOT EXISTS idx_user_data_pan ON user_data(pan_number);
      CREATE INDEX IF NOT EXISTS idx_user_data_aadhar ON user_data(aadhar_number);
    `);
    console.log('Created indexes for KYC fields');

    console.log('Onboarding fields added successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error adding onboarding fields:', error);
    process.exit(1);
  }
}

addOnboardingFields();

