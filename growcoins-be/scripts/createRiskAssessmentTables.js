const { query } = require('../config/database');
require('dotenv').config();

async function createRiskAssessmentTables() {
  try {
    console.log('Creating risk assessment tables...');

    // Create risk_assessments table
    await query(`
      CREATE TABLE IF NOT EXISTS risk_assessments (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        total_score INTEGER NOT NULL,
        risk_profile VARCHAR(50) NOT NULL,
        recommendation TEXT,
        completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES authentication(id) ON DELETE CASCADE
      )
    `);
    console.log('Risk assessments table created successfully');

    // Create risk_assessment_answers table
    await query(`
      CREATE TABLE IF NOT EXISTS risk_assessment_answers (
        id SERIAL PRIMARY KEY,
        assessment_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        option_id VARCHAR(50) NOT NULL,
        answer_text TEXT NOT NULL,
        score INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (assessment_id) REFERENCES risk_assessments(id) ON DELETE CASCADE
      )
    `);
    console.log('Risk assessment answers table created successfully');

    // Create indexes for better performance
    await query(`
      CREATE INDEX IF NOT EXISTS idx_risk_assessments_user_id ON risk_assessments(user_id);
      CREATE INDEX IF NOT EXISTS idx_risk_assessments_completed_at ON risk_assessments(completed_at DESC);
      CREATE INDEX IF NOT EXISTS idx_risk_assessment_answers_assessment_id ON risk_assessment_answers(assessment_id);
      CREATE INDEX IF NOT EXISTS idx_risk_assessment_answers_question_id ON risk_assessment_answers(question_id);
    `);
    console.log('Indexes created successfully');

    // Create trigger for updated_at
    await query(`
      DROP TRIGGER IF EXISTS update_risk_assessments_updated_at ON risk_assessments;
      CREATE TRIGGER update_risk_assessments_updated_at
      BEFORE UPDATE ON risk_assessments
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log('Triggers created successfully');

    console.log('Risk assessment tables setup completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error creating risk assessment tables:', error);
    process.exit(1);
  }
}

createRiskAssessmentTables();

