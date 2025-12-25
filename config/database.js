const { Pool } = require("pg");
const os = require("os");
require("dotenv").config();

// Database connection pool
const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  user:
    process.env.DB_USER ||
    process.env.USER ||
    os.userInfo().username ||
    "postgres",
  password: process.env.DB_PASSWORD || undefined,
  database: process.env.DB_NAME || "growcoins",
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test database connection
pool.on("connect", () => {
  console.log("Connected to PostgreSQL database");
});

pool.on("error", (err) => {
  console.error("Unexpected error on idle client", err);
  process.exit(-1);
});

// Query helper function
const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log("Executed query", { text, duration, rows: res.rowCount });
    return res;
  } catch (error) {
    console.error("Database query error:", error);
    throw error;
  }
};

module.exports = {
  pool,
  query,
};
