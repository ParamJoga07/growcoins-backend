const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const { query } = require("../config/database");
const { body, validationResult } = require("express-validator");

// Register new user
router.post(
  "/register",
  [
    body("username")
      .trim()
      .isLength({ min: 3 })
      .withMessage("Username must be at least 3 characters"),
    body("password")
      .isLength({ min: 6 })
      .withMessage("Password must be at least 6 characters"),
    body("email").isEmail().withMessage("Please provide a valid email"),
    body("first_name").trim().notEmpty().withMessage("First name is required"),
    body("last_name").trim().notEmpty().withMessage("Last name is required"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const {
        username,
        password,
        email,
        first_name,
        last_name,
        phone_number,
        date_of_birth,
      } = req.body;

      // Check if username already exists
      const usernameCheck = await query(
        "SELECT id FROM authentication WHERE username = $1",
        [username]
      );
      if (usernameCheck.rows.length > 0) {
        return res.status(400).json({ error: "Username already exists" });
      }

      // Check if email already exists
      const emailCheck = await query(
        "SELECT id FROM user_data WHERE email = $1",
        [email]
      );
      if (emailCheck.rows.length > 0) {
        return res.status(400).json({ error: "Email already exists" });
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(password, 10);

      // Start transaction - create auth record first
      const authResult = await query(
        "INSERT INTO authentication (username, password) VALUES ($1, $2) RETURNING id",
        [username, hashedPassword]
      );

      const userId = authResult.rows[0].id;

      // Generate account number (simple implementation)
      const accountNumber = `GC${Date.now()}${Math.floor(
        Math.random() * 1000
      )}`;

      // Create user data record
      await query(
        `INSERT INTO user_data (user_id, first_name, last_name, email, phone_number, date_of_birth, account_number)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          userId,
          first_name,
          last_name,
          email,
          phone_number || null,
          date_of_birth || null,
          accountNumber,
        ]
      );

      res.status(201).json({
        message: "User registered successfully",
        user_id: userId,
        account_number: accountNumber,
      });
    } catch (error) {
      console.error("Registration error:", error);
      res.status(500).json({ error: "Failed to register user" });
    }
  }
);

// Login
router.post(
  "/login",
  [
    body("username").trim().notEmpty().withMessage("Username is required"),
    body("password").notEmpty().withMessage("Password is required"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { username, password } = req.body;

      // Find user by username
      const result = await query(
        "SELECT id, username, password, is_active FROM authentication WHERE username = $1",
        [username]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ error: "Invalid username or password" });
      }

      const user = result.rows[0];

      if (!user.is_active) {
        return res.status(403).json({ error: "Account is deactivated" });
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password);
      if (!isValidPassword) {
        return res.status(401).json({ error: "Invalid username or password" });
      }

      // Update last login
      await query(
        "UPDATE authentication SET last_login = CURRENT_TIMESTAMP WHERE id = $1",
        [user.id]
      );

      // Get user data
      const userData = await query(
        "SELECT * FROM user_data WHERE user_id = $1",
        [user.id]
      );

      // Get biometric preference
      const biometricResult = await query(
        "SELECT biometric_enabled FROM authentication WHERE id = $1",
        [user.id]
      );
      const biometricEnabled = biometricResult.rows[0]?.biometric_enabled ?? false;

      res.json({
        message: "Login successful",
        user: {
          id: user.id,
          username: user.username,
          user_data: userData.rows[0] || null,
          biometric_enabled: biometricEnabled,
        },
      });
    } catch (error) {
      console.error("Login error:", error);
      res.status(500).json({ error: "Failed to login" });
    }
  }
);

// Get biometric preference
router.get("/biometric/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const result = await query(
      "SELECT biometric_enabled FROM authentication WHERE id = $1",
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({
      user_id: parseInt(userId),
      biometric_enabled: result.rows[0].biometric_enabled ?? false,
    });
  } catch (error) {
    console.error("Get biometric preference error:", error);
    res.status(500).json({ error: "Failed to get biometric preference" });
  }
});

// Update biometric preference
router.put("/biometric/:userId", [
  body("biometric_enabled").isBoolean().withMessage("biometric_enabled must be a boolean"),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { userId } = req.params;
    const { biometric_enabled } = req.body;

    // Check if user exists
    const userCheck = await query(
      "SELECT id FROM authentication WHERE id = $1",
      [userId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    // Update biometric preference
    await query(
      "UPDATE authentication SET biometric_enabled = $1 WHERE id = $2",
      [biometric_enabled, userId]
    );

    res.json({
      message: "Biometric preference updated successfully",
      user_id: parseInt(userId),
      biometric_enabled: biometric_enabled,
    });
  } catch (error) {
    console.error("Update biometric preference error:", error);
    res.status(500).json({ error: "Failed to update biometric preference" });
  }
});

module.exports = router;
