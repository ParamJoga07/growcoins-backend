const { query } = require("../config/database");
require("dotenv").config();

async function createRoundoffTables() {
  try {
    console.log("Creating roundoff savings tables...");

    // Create roundoff_settings table
    await query(`
      CREATE TABLE IF NOT EXISTS roundoff_settings (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        roundoff_amount INTEGER NOT NULL DEFAULT 10,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE,
        UNIQUE(user_id)
      )
    `);
    console.log("Roundoff settings table created successfully");

    // Create bank_statements table
    await query(`
      CREATE TABLE IF NOT EXISTS bank_statements (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        file_name VARCHAR(255) NOT NULL,
        file_path TEXT,
        uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        processed_at TIMESTAMP,
        status VARCHAR(50) DEFAULT 'pending',
        FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE
      )
    `);
    console.log("Bank statements table created successfully");

    // Create transactions table
    await query(`
      CREATE TABLE IF NOT EXISTS transactions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        statement_id INTEGER,
        transaction_date DATE NOT NULL,
        description TEXT,
        amount DECIMAL(15, 2) NOT NULL,
        transaction_type VARCHAR(20) NOT NULL,
        roundoff_amount DECIMAL(15, 2) DEFAULT 0.00,
        rounded_amount DECIMAL(15, 2),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE,
        FOREIGN KEY (statement_id) REFERENCES bank_statements(id) ON DELETE SET NULL
      )
    `);
    console.log("Transactions table created successfully");

    // Create roundoff_savings table (aggregated daily savings)
    await query(`
      CREATE TABLE IF NOT EXISTS roundoff_savings (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        transaction_date DATE NOT NULL,
        total_roundoff DECIMAL(15, 2) DEFAULT 0.00,
        transaction_count INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE,
        UNIQUE(user_id, transaction_date)
      )
    `);
    console.log("Roundoff savings table created successfully");

    // Create indexes
    await query(`
      CREATE INDEX IF NOT EXISTS idx_roundoff_settings_user_id ON roundoff_settings(user_id);
      CREATE INDEX IF NOT EXISTS idx_bank_statements_user_id ON bank_statements(user_id);
      CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
      CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(transaction_date);
      CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);
      CREATE INDEX IF NOT EXISTS idx_roundoff_savings_user_id ON roundoff_savings(user_id);
      CREATE INDEX IF NOT EXISTS idx_roundoff_savings_date ON roundoff_savings(transaction_date);
    `);
    console.log("Indexes created successfully");

    // Create trigger for updated_at
    await query(`
      DROP TRIGGER IF EXISTS update_roundoff_settings_updated_at ON roundoff_settings;
      CREATE TRIGGER update_roundoff_settings_updated_at
      BEFORE UPDATE ON roundoff_settings
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);

    await query(`
      DROP TRIGGER IF EXISTS update_roundoff_savings_updated_at ON roundoff_savings;
      CREATE TRIGGER update_roundoff_savings_updated_at
      BEFORE UPDATE ON roundoff_savings
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log("Triggers created successfully");

    console.log("Roundoff savings tables setup completed successfully!");
    process.exit(0);
  } catch (error) {
    console.error("Error creating roundoff tables:", error);
    process.exit(1);
  }
}

createRoundoffTables();
