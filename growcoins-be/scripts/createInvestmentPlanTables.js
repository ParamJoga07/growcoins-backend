const { query } = require("../config/database");
require("dotenv").config();

async function createInvestmentPlanTables() {
  try {
    console.log("Creating investment plan tables...");

    // Create investment_plans table
    await query(`
      CREATE TABLE IF NOT EXISTS investment_plans (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
        goal_id INTEGER REFERENCES goals(id) ON DELETE SET NULL,
        risk_profile VARCHAR(50) NOT NULL,
        risk_profile_display VARCHAR(100),
        auto_save_config JSONB NOT NULL,
        portfolio_allocation JSONB NOT NULL,
        status VARCHAR(20) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, goal_id)
      )
    `);
    console.log("Investment plans table created successfully");

    // Create payment_mandates table
    await query(`
      CREATE TABLE IF NOT EXISTS payment_mandates (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
        goal_id INTEGER REFERENCES goals(id) ON DELETE SET NULL,
        investment_plan_id INTEGER REFERENCES investment_plans(id) ON DELETE CASCADE,
        bank_account_number VARCHAR(50) NOT NULL,
        ifsc_code VARCHAR(11) NOT NULL,
        account_holder_name VARCHAR(255) NOT NULL,
        mandate_status VARCHAR(20) DEFAULT 'pending',
        mandate_reference VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        activated_at TIMESTAMP
      )
    `);
    console.log("Payment mandates table created successfully");

    // Create indexes
    await query(`
      CREATE INDEX IF NOT EXISTS idx_investment_plans_user_id ON investment_plans(user_id);
      CREATE INDEX IF NOT EXISTS idx_investment_plans_goal_id ON investment_plans(goal_id);
      CREATE INDEX IF NOT EXISTS idx_payment_mandates_user_id ON payment_mandates(user_id);
      CREATE INDEX IF NOT EXISTS idx_payment_mandates_goal_id ON payment_mandates(goal_id);
      CREATE INDEX IF NOT EXISTS idx_payment_mandates_plan_id ON payment_mandates(investment_plan_id);
    `);
    console.log("Indexes created successfully");

    // Create trigger for updated_at
    await query(`
      DROP TRIGGER IF EXISTS update_investment_plans_updated_at ON investment_plans;
      CREATE TRIGGER update_investment_plans_updated_at
      BEFORE UPDATE ON investment_plans
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);

    await query(`
      DROP TRIGGER IF EXISTS update_payment_mandates_updated_at ON payment_mandates;
      CREATE TRIGGER update_payment_mandates_updated_at
      BEFORE UPDATE ON payment_mandates
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log("Triggers created successfully");

    console.log("Investment plan tables setup completed successfully!");
    process.exit(0);
  } catch (error) {
    console.error("Error creating investment plan tables:", error);
    process.exit(1);
  }
}

createInvestmentPlanTables();

