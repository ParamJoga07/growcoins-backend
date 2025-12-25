const express = require("express");
const router = express.Router();
const { query } = require("../config/database");
const {
  body,
  param,
  query: queryParam,
  validationResult,
} = require("express-validator");

// Save Risk Assessment
router.post(
  "/",
  [
    body("user_id").isInt().withMessage("User ID is required"),
    body("answers")
      .isArray({ min: 5, max: 5 })
      .withMessage("Answers must contain exactly 5 answers"),
    body("answers.*.questionId").isInt().withMessage("Question ID is required"),
    body("answers.*.optionId").notEmpty().withMessage("Option ID is required"),
    body("answers.*.answerText")
      .notEmpty()
      .withMessage("Answer text is required"),
    body("answers.*.score")
      .isInt({ min: 1, max: 4 })
      .withMessage("Score must be between 1 and 4"),
    body("total_score")
      .isInt({ min: 5, max: 20 })
      .withMessage("Total score must be between 5 and 20"),
    body("risk_profile")
      .isIn(["Conservative", "Moderate", "Moderately Aggressive", "Aggressive"])
      .withMessage("Invalid risk profile"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const {
        user_id,
        answers,
        total_score,
        risk_profile,
        recommendation,
        completed_at,
      } = req.body;

      // Verify total score matches sum of answer scores
      const calculatedScore = answers.reduce(
        (sum, answer) => sum + answer.score,
        0
      );
      if (calculatedScore !== total_score) {
        return res
          .status(400)
          .json({ error: "Total score does not match sum of answer scores" });
      }

      // Check if user exists
      const userCheck = await query(
        "SELECT id FROM authentication WHERE id = $1",
        [user_id]
      );
      if (userCheck.rows.length === 0) {
        return res.status(404).json({ error: "User not found" });
      }

      // Insert risk assessment
      const assessmentResult = await query(
        `INSERT INTO risk_assessments (user_id, total_score, risk_profile, recommendation, completed_at)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
        [
          user_id,
          total_score,
          risk_profile,
          recommendation || null,
          completed_at || new Date(),
        ]
      );

      const assessment = assessmentResult.rows[0];

      // Insert answers
      const answerInserts = answers.map((answer) =>
        query(
          `INSERT INTO risk_assessment_answers (assessment_id, question_id, option_id, answer_text, score)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
          [
            assessment.id,
            answer.questionId,
            answer.optionId,
            answer.answerText,
            answer.score,
          ]
        )
      );

      const answerResults = await Promise.all(answerInserts);
      const savedAnswers = answerResults.map((result) => result.rows[0]);

      res.status(201).json({
        message: "Risk assessment saved successfully",
        assessment: {
          ...assessment,
          answers: savedAnswers.map((a) => ({
            id: a.id,
            question_id: a.question_id,
            option_id: a.option_id,
            answer_text: a.answer_text,
            score: a.score,
          })),
        },
      });
    } catch (error) {
      console.error("Save risk assessment error:", error);
      res.status(500).json({ error: "Failed to save risk assessment" });
    }
  }
);

// Get User's Risk Assessment History
router.get(
  "/:user_id",
  [
    param("user_id").isInt().withMessage("User ID must be an integer"),
    queryParam("limit")
      .optional()
      .isInt({ min: 1, max: 50 })
      .withMessage("Limit must be between 1 and 50"),
    queryParam("offset")
      .optional()
      .isInt({ min: 0 })
      .withMessage("Offset must be a non-negative integer"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { user_id } = req.params;
      const limit = parseInt(req.query.limit) || 10;
      const offset = parseInt(req.query.offset) || 0;

      // Check if user exists
      const userCheck = await query(
        "SELECT id FROM authentication WHERE id = $1",
        [user_id]
      );
      if (userCheck.rows.length === 0) {
        return res.status(404).json({ error: "User not found" });
      }

      // Get assessments
      const assessmentsResult = await query(
        `SELECT * FROM risk_assessments
       WHERE user_id = $1
       ORDER BY completed_at DESC
       LIMIT $2 OFFSET $3`,
        [user_id, limit, offset]
      );

      // Get total count
      const countResult = await query(
        "SELECT COUNT(*) as total FROM risk_assessments WHERE user_id = $1",
        [user_id]
      );

      const total = parseInt(countResult.rows[0].total);

      // Get answers for each assessment
      const assessments = await Promise.all(
        assessmentsResult.rows.map(async (assessment) => {
          const answersResult = await query(
            `SELECT id, question_id, option_id, answer_text, score
           FROM risk_assessment_answers
           WHERE assessment_id = $1
           ORDER BY question_id`,
            [assessment.id]
          );

          return {
            ...assessment,
            answers: answersResult.rows,
          };
        })
      );

      res.json({
        assessments,
        total,
        limit,
        offset,
      });
    } catch (error) {
      console.error("Get risk assessment history error:", error);
      res
        .status(500)
        .json({ error: "Failed to fetch risk assessment history" });
    }
  }
);

// Get Latest Risk Assessment
router.get(
  "/:user_id/latest",
  [param("user_id").isInt().withMessage("User ID must be an integer")],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { user_id } = req.params;

      // Check if user exists
      const userCheck = await query(
        "SELECT id FROM authentication WHERE id = $1",
        [user_id]
      );
      if (userCheck.rows.length === 0) {
        return res.status(404).json({ error: "User not found" });
      }

      // Get latest assessment
      const assessmentResult = await query(
        `SELECT * FROM risk_assessments
       WHERE user_id = $1
       ORDER BY completed_at DESC
       LIMIT 1`,
        [user_id]
      );

      if (assessmentResult.rows.length === 0) {
        return res
          .status(404)
          .json({ error: "No risk assessment found for this user" });
      }

      const assessment = assessmentResult.rows[0];

      // Get answers
      const answersResult = await query(
        `SELECT id, question_id, option_id, answer_text, score
       FROM risk_assessment_answers
       WHERE assessment_id = $1
       ORDER BY question_id`,
        [assessment.id]
      );

      res.json({
        assessment: {
          ...assessment,
          answers: answersResult.rows,
        },
      });
    } catch (error) {
      console.error("Get latest risk assessment error:", error);
      res.status(500).json({ error: "Failed to fetch latest risk assessment" });
    }
  }
);

// Get Specific Risk Assessment by ID
router.get(
  "/:user_id/:assessment_id",
  [
    param("user_id").isInt().withMessage("User ID must be an integer"),
    param("assessment_id")
      .isInt()
      .withMessage("Assessment ID must be an integer"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { user_id, assessment_id } = req.params;

      // Get assessment
      const assessmentResult = await query(
        `SELECT * FROM risk_assessments
       WHERE id = $1 AND user_id = $2`,
        [assessment_id, user_id]
      );

      if (assessmentResult.rows.length === 0) {
        return res.status(404).json({ error: "Risk assessment not found" });
      }

      const assessment = assessmentResult.rows[0];

      // Get answers
      const answersResult = await query(
        `SELECT id, question_id, option_id, answer_text, score
       FROM risk_assessment_answers
       WHERE assessment_id = $1
       ORDER BY question_id`,
        [assessment.id]
      );

      res.json({
        assessment: {
          ...assessment,
          answers: answersResult.rows,
        },
      });
    } catch (error) {
      console.error("Get risk assessment error:", error);
      res.status(500).json({ error: "Failed to fetch risk assessment" });
    }
  }
);

module.exports = router;
