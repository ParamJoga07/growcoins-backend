const { query } = require("../config/database");
require("dotenv").config();

async function createGoalsTables() {
  try {
    console.log("Creating goals tables...");

    // Create goal_categories table
    await query(`
      CREATE TABLE IF NOT EXISTS goal_categories (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE,
        icon VARCHAR(50) NOT NULL,
        icon_type VARCHAR(20) DEFAULT 'material',
        color VARCHAR(20) NOT NULL,
        description TEXT,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log("Goal categories table created successfully");

    // Create goals table
    await query(`
      CREATE TABLE IF NOT EXISTS goals (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        goal_name VARCHAR(100) NOT NULL,
        target_amount DECIMAL(15, 2) NOT NULL,
        current_amount DECIMAL(15, 2) DEFAULT 0.00,
        target_date DATE NOT NULL,
        status VARCHAR(20) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES goal_categories(id) ON DELETE RESTRICT,
        CHECK (target_amount > 0),
        CHECK (current_amount >= 0)
      )
    `);
    console.log("Goals table created successfully");

    // Create invest_profiles table
    await query(`
      CREATE TABLE IF NOT EXISTS invest_profiles (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL UNIQUE,
        risk_profile VARCHAR(50) NOT NULL,
        investment_preference VARCHAR(50),
        auto_invest_enabled BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE
      )
    `);
    console.log("Invest profiles table created successfully");

    // Create indexes
    await query(`
      CREATE INDEX IF NOT EXISTS idx_goals_user_id ON goals(user_id);
      CREATE INDEX IF NOT EXISTS idx_goals_category_id ON goals(category_id);
      CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status);
      CREATE INDEX IF NOT EXISTS idx_goals_target_date ON goals(target_date);
      CREATE INDEX IF NOT EXISTS idx_invest_profiles_user_id ON invest_profiles(user_id);
      CREATE INDEX IF NOT EXISTS idx_goal_categories_active ON goal_categories(is_active);
    `);
    console.log("Indexes created successfully");

    // Create trigger for updated_at
    await query(`
      DROP TRIGGER IF EXISTS update_goal_categories_updated_at ON goal_categories;
      CREATE TRIGGER update_goal_categories_updated_at
      BEFORE UPDATE ON goal_categories
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);

    await query(`
      DROP TRIGGER IF EXISTS update_goals_updated_at ON goals;
      CREATE TRIGGER update_goals_updated_at
      BEFORE UPDATE ON goals
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);

    await query(`
      DROP TRIGGER IF EXISTS update_invest_profiles_updated_at ON invest_profiles;
      CREATE TRIGGER update_invest_profiles_updated_at
      BEFORE UPDATE ON invest_profiles
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log("Triggers created successfully");

    // Insert default goal categories
    const categories = [
      { name: "Phone", icon: "phone", color: "#2196F3", description: "Save for a new phone" },
      { name: "Gadget", icon: "camera", color: "#9C27B0", description: "Save for gadgets and electronics" },
      { name: "Car", icon: "directions_car", color: "#FF5722", description: "Save for a car" },
      { name: "Domestic Trip", icon: "landscape", color: "#4CAF50", description: "Save for domestic travel" },
      { name: "International Trip", icon: "flight", color: "#00BCD4", description: "Save for international travel" },
      { name: "Party", icon: "celebration", color: "#FF9800", description: "Save for parties and events" },
      { name: "Home", icon: "home", color: "#795548", description: "Save for home-related expenses" },
      { name: "Birthday", icon: "cake", color: "#E91E63", description: "Save for birthday celebrations" },
      { name: "Other", icon: "person", color: "#607D8B", description: "Custom goal category" }
    ];

    for (const category of categories) {
      await query(`
        INSERT INTO goal_categories (name, icon, icon_type, color, description, is_active)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (name) DO UPDATE SET
          icon = EXCLUDED.icon,
          color = EXCLUDED.color,
          description = EXCLUDED.description,
          is_active = EXCLUDED.is_active,
          updated_at = CURRENT_TIMESTAMP
      `, [
        category.name,
        category.icon,
        "material",
        category.color,
        category.description,
        true
      ]);
    }
    console.log("Default goal categories inserted successfully");

    console.log("Goals tables setup completed successfully!");
    process.exit(0);
  } catch (error) {
    console.error("Error creating goals tables:", error);
    process.exit(1);
  }
}

createGoalsTables();

