const { query } = require("../config/database");
require("dotenv").config();

async function createNotificationsTable() {
  try {
    console.log("Creating notifications table...");

    // Create notifications table
    await query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES authentication(id) ON DELETE CASCADE,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        data JSONB,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        read_at TIMESTAMP,
        CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE
      )
    `);
    console.log("Notifications table created successfully");

    // Create indexes for better performance
    await query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
      CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
      CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
    `);
    console.log("Indexes created successfully");

    console.log("Notifications table setup completed successfully!");
    process.exit(0);
  } catch (error) {
    console.error("Error creating notifications table:", error);
    process.exit(1);
  }
}

createNotificationsTable();

