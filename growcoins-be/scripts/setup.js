const { execSync } = require('child_process');
const path = require('path');

console.log('🚀 Starting database setup...\n');

try {
  // Step 1: Create database
  console.log('📦 Step 1: Creating database...');
  execSync('npm run db:create', { 
    stdio: 'inherit',
    cwd: path.join(__dirname, '..')
  });
  
  console.log('\n✅ Database created successfully!\n');
  
  // Step 2: Run migrations
  console.log('📊 Step 2: Creating tables and indexes...');
  execSync('npm run db:migrate', { 
    stdio: 'inherit',
    cwd: path.join(__dirname, '..')
  });
  
  console.log('\n✅ All tables created successfully!');
  console.log('\n🎉 Database setup complete!');
  console.log('\nYou can now start the server with: npm start');
  
} catch (error) {
  console.error('\n❌ Error during setup:', error.message);
  process.exit(1);
}

