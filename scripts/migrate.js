const { query } = require('../config/database');
require('dotenv').config();

async function createTables() {
  try {
    // Create authentication table
    await query(`
      CREATE TABLE IF NOT EXISTS authentication (
        id SERIAL PRIMARY KEY,
        username VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login TIMESTAMP,
        is_active BOOLEAN DEFAULT TRUE,
        biometric_enabled BOOLEAN DEFAULT FALSE
      )
    `);
    console.log('Authentication table created successfully');

    // Add biometric_enabled column if it doesn't exist (for existing databases)
    await query(`
      DO $$ 
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = 'authentication' 
          AND column_name = 'biometric_enabled'
        ) THEN
          ALTER TABLE authentication ADD COLUMN biometric_enabled BOOLEAN DEFAULT FALSE;
        END IF;
      END $$;
    `);
    console.log('Biometric enabled column added/verified');

    // Create user_data table
    await query(`
      CREATE TABLE IF NOT EXISTS user_data (
        id SERIAL PRIMARY KEY,
        user_id INTEGER UNIQUE NOT NULL,
        first_name VARCHAR(255) NOT NULL,
        last_name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        phone_number VARCHAR(20),
        date_of_birth DATE,
        address TEXT,
        city VARCHAR(100),
        state VARCHAR(100),
        zip_code VARCHAR(20),
        country VARCHAR(100) DEFAULT 'USA',
        account_number VARCHAR(50) UNIQUE,
        routing_number VARCHAR(50),
        account_balance DECIMAL(15, 2) DEFAULT 0.00,
        currency VARCHAR(10) DEFAULT 'USD',
        kyc_status VARCHAR(50) DEFAULT 'pending',
        kyc_verified_at TIMESTAMP,
        profile_picture_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE
      )
    `);
    console.log('User data table created successfully');

    // Create indexes for better performance
    await query(`
      CREATE INDEX IF NOT EXISTS idx_auth_username ON authentication(username);
      CREATE INDEX IF NOT EXISTS idx_user_data_email ON user_data(email);
      CREATE INDEX IF NOT EXISTS idx_user_data_account_number ON user_data(account_number);
    `);
    console.log('Indexes created successfully');

    // Create function to update updated_at timestamp
    await query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    `);

    // Create triggers for updated_at
    await query(`
      DROP TRIGGER IF EXISTS update_auth_updated_at ON authentication;
      CREATE TRIGGER update_auth_updated_at
      BEFORE UPDATE ON authentication
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);

    await query(`
      DROP TRIGGER IF EXISTS update_user_data_updated_at ON user_data;
      CREATE TRIGGER update_user_data_updated_at
      BEFORE UPDATE ON user_data
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log('Triggers created successfully');

    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration error:', error);
    process.exit(1);
  }
}

createTables();

