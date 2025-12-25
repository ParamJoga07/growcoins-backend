const { Client } = require('pg');
const os = require('os');
require('dotenv').config();

const dbUser = process.env.DB_USER || process.env.USER || os.userInfo().username || 'postgres';

const client = new Client({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: dbUser,
  password: process.env.DB_PASSWORD || undefined,
  database: 'postgres', // Connect to default postgres database first
});

async function createDatabase() {
  try {
    await client.connect();
    console.log('Connected to PostgreSQL');

    // Check if database exists
    const dbCheck = await client.query(
      `SELECT 1 FROM pg_database WHERE datname = '${process.env.DB_NAME || 'growcoins'}'`
    );

    if (dbCheck.rows.length === 0) {
      // Create database
      await client.query(`CREATE DATABASE ${process.env.DB_NAME || 'growcoins'}`);
      console.log(`Database '${process.env.DB_NAME || 'growcoins'}' created successfully`);
    } else {
      console.log(`Database '${process.env.DB_NAME || 'growcoins'}' already exists`);
    }

    await client.end();
    console.log('Database setup complete');
  } catch (error) {
    console.error('Error creating database:', error);
    process.exit(1);
  }
}

createDatabase();

