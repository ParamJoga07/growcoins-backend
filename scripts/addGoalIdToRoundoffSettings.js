const { query } = require('../config/database');
require('dotenv').config();

async function addGoalIdToRoundoffSettings() {
  try {
    console.log('Adding goal_id column to roundoff_settings table...');

    // Check if column already exists
    const checkColumn = await query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'roundoff_settings' AND column_name = 'goal_id'
    `);

    if (checkColumn.rows.length === 0) {
      // Add goal_id column
      await query(`
        ALTER TABLE roundoff_settings
        ADD COLUMN goal_id INTEGER REFERENCES goals(id) ON DELETE SET NULL
      `);
      console.log('Added goal_id column to roundoff_settings table');

      // Create index for faster lookups
      await query(`
        CREATE INDEX IF NOT EXISTS idx_roundoff_settings_goal_id 
        ON roundoff_settings(goal_id)
      `);
      console.log('Created index on goal_id column');
    } else {
      console.log('goal_id column already exists in roundoff_settings table');
    }

    console.log('Migration completed successfully');
  } catch (error) {
    console.error('Migration error:', error);
    throw error;
  }
}

// Run migration
if (require.main === module) {
  addGoalIdToRoundoffSettings()
    .then(() => {
      console.log('Migration script completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { addGoalIdToRoundoffSettings };

