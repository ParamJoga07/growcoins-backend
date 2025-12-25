const { query } = require('../config/database');
require('dotenv').config();

async function createVideoKycTable() {
  try {
    console.log('Creating video KYC table...');

    // Create video_kyc_submissions table
    await query(`
      CREATE TABLE IF NOT EXISTS video_kyc_submissions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
        video_url VARCHAR(500) NOT NULL,
        video_path VARCHAR(500) NOT NULL,
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
        rejection_reason TEXT,
        verified_by INTEGER REFERENCES authentication(id) ON DELETE SET NULL,
        verified_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('Video KYC submissions table created successfully');

    // Create indexes
    await query(`
      CREATE INDEX IF NOT EXISTS idx_video_kyc_user_id ON video_kyc_submissions(user_id);
      CREATE INDEX IF NOT EXISTS idx_video_kyc_status ON video_kyc_submissions(status);
      CREATE INDEX IF NOT EXISTS idx_video_kyc_created_at ON video_kyc_submissions(created_at DESC);
    `);
    console.log('Indexes created successfully');

    // Create trigger for updated_at
    await query(`
      DROP TRIGGER IF EXISTS update_video_kyc_submissions_updated_at ON video_kyc_submissions;
      CREATE TRIGGER update_video_kyc_submissions_updated_at
      BEFORE UPDATE ON video_kyc_submissions
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log('Trigger created successfully');

    console.log('Video KYC table setup completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error creating video KYC table:', error);
    process.exit(1);
  }
}

createVideoKycTable();

