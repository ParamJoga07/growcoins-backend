const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { query } = require('../config/database');
const { body, param, query: queryCheck, validationResult } = require('express-validator');
const { createNotification } = require('./notifications');

// Configure multer for video uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads/video_kyc');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const userId = req.body.user_id;
    const timestamp = Date.now();
    const filename = `user_${userId}_video_${timestamp}${path.extname(file.originalname)}`;
    cb(null, filename);
  }
});

// File filter for videos
const fileFilter = (req, file, cb) => {
  // Accept MP4 and QuickTime videos
  const allowedMimes = ['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm'];
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only video files (MP4, MOV, AVI, WEBM) are allowed'), false);
  }
};

// Configure multer
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB max
  },
  fileFilter: fileFilter
});

// Helper function to generate video URL
function generateVideoUrl(filename) {
  const baseUrl = process.env.CDN_BASE_URL || process.env.BASE_URL || 'http://localhost:3001';
  return `${baseUrl}/uploads/video_kyc/${filename}`;
}

// 1. Upload Video KYC
router.post('/upload', upload.single('video'), [
  body('user_id').isInt().withMessage('User ID is required and must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: errors.array().map(e => ({ field: e.param, msg: e.msg }))
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'Video file is required'
      });
    }

    const { user_id } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT id FROM authentication WHERE id = $1', [user_id]);
    if (userCheck.rows.length === 0) {
      // Clean up uploaded file
      fs.unlinkSync(req.file.path);
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const videoPath = req.file.path;
    const videoUrl = generateVideoUrl(req.file.filename);

    // Save to database
    const result = await query(
      `INSERT INTO video_kyc_submissions (user_id, video_url, video_path, status)
       VALUES ($1, $2, $3, 'pending')
       RETURNING *`,
      [user_id, videoUrl, videoPath]
    );

    const kyc = result.rows[0];

    res.status(201).json({
      success: true,
      message: 'Video uploaded successfully',
      kyc_id: kyc.id,
      status: kyc.status,
      video_url: kyc.video_url
    });
  } catch (error) {
    console.error('Error uploading video:', error);
    // Clean up uploaded file if database insert failed
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({
      success: false,
      error: 'Failed to upload video'
    });
  }
});

// 2. Get Video KYC Status
router.get('/status/:kyc_id', [
  param('kyc_id').isInt().withMessage('KYC ID must be an integer'),
  queryCheck('user_id').isInt().withMessage('User ID is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: errors.array()
      });
    }

    const { kyc_id } = req.params;
    const { user_id } = req.query;

    const result = await query(
      `SELECT 
        id,
        user_id,
        status,
        video_url,
        rejection_reason,
        created_at,
        updated_at
       FROM video_kyc_submissions
       WHERE id = $1 AND user_id = $2`,
      [kyc_id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'KYC submission not found or access denied'
      });
    }

    const kyc = result.rows[0];

    res.json({
      success: true,
      kyc: {
        id: parseInt(kyc.id),
        user_id: parseInt(kyc.user_id),
        status: kyc.status,
        video_url: kyc.video_url,
        rejection_reason: kyc.rejection_reason,
        created_at: kyc.created_at,
        updated_at: kyc.updated_at
      }
    });
  } catch (error) {
    console.error('Get KYC status error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get KYC status'
    });
  }
});

// 3. Get Video KYC Details
router.get('/:kyc_id', [
  param('kyc_id').isInt().withMessage('KYC ID must be an integer'),
  queryCheck('user_id').isInt().withMessage('User ID is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: errors.array()
      });
    }

    const { kyc_id } = req.params;
    const { user_id } = req.query;

    const result = await query(
      `SELECT 
        id,
        user_id,
        video_url,
        status,
        rejection_reason,
        verified_by,
        verified_at,
        created_at,
        updated_at
       FROM video_kyc_submissions
       WHERE id = $1 AND user_id = $2`,
      [kyc_id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'KYC submission not found or access denied'
      });
    }

    const kyc = result.rows[0];

    res.json({
      success: true,
      kyc: {
        id: parseInt(kyc.id),
        user_id: parseInt(kyc.user_id),
        video_url: kyc.video_url,
        status: kyc.status,
        rejection_reason: kyc.rejection_reason,
        verified_by: kyc.verified_by ? parseInt(kyc.verified_by) : null,
        verified_at: kyc.verified_at,
        created_at: kyc.created_at,
        updated_at: kyc.updated_at
      }
    });
  } catch (error) {
    console.error('Get KYC details error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get KYC details'
    });
  }
});

// 4. Delete/Retry Video KYC
router.delete('/:kyc_id', [
  param('kyc_id').isInt().withMessage('KYC ID must be an integer'),
  queryCheck('user_id').isInt().withMessage('User ID is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: errors.array()
      });
    }

    const { kyc_id } = req.params;
    const { user_id } = req.query;

    // Get KYC submission to access video path
    const kycResult = await query(
      'SELECT video_path FROM video_kyc_submissions WHERE id = $1 AND user_id = $2',
      [kyc_id, user_id]
    );

    if (kycResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'KYC submission not found or access denied'
      });
    }

    const videoPath = kycResult.rows[0].video_path;

    // Delete from database
    await query(
      'DELETE FROM video_kyc_submissions WHERE id = $1 AND user_id = $2',
      [kyc_id, user_id]
    );

    // Delete video file
    if (videoPath && fs.existsSync(videoPath)) {
      try {
        fs.unlinkSync(videoPath);
      } catch (fileError) {
        console.error('Error deleting video file:', fileError);
        // Continue even if file deletion fails
      }
    }

    res.json({
      success: true,
      message: 'Video KYC submission deleted successfully'
    });
  } catch (error) {
    console.error('Delete KYC error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete KYC submission'
    });
  }
});

// 5. Admin: Approve Video KYC
router.put('/:kyc_id/approve', [
  param('kyc_id').isInt().withMessage('KYC ID must be an integer'),
  body('verified_by').isInt().withMessage('Verified by (admin user ID) is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: errors.array()
      });
    }

    const { kyc_id } = req.params;
    const { verified_by } = req.body;

    // Check if admin user exists
    const adminCheck = await query('SELECT id FROM authentication WHERE id = $1', [verified_by]);
    if (adminCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Admin user not found'
      });
    }

    // Update KYC status
    const result = await query(
      `UPDATE video_kyc_submissions
       SET status = 'approved',
           verified_by = $1,
           verified_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING *`,
      [verified_by, kyc_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'KYC submission not found'
      });
    }

    const kyc = result.rows[0];

    // Update user's KYC status if needed
    try {
      await query(
        `UPDATE user_data 
         SET kyc_status = 'approved', 
             kyc_verified_at = CURRENT_TIMESTAMP,
             updated_at = CURRENT_TIMESTAMP
         WHERE user_id = $1`,
        [kyc.user_id]
      );
    } catch (updateError) {
      console.error('Error updating user KYC status:', updateError);
      // Don't fail the approval if user update fails
    }

    // Create notification for approval
    try {
      await createNotification(
        kyc.user_id,
        'kyc_approved',
        'KYC Verification Approved',
        'Your video KYC has been verified and approved.',
        {
          kyc_id: kyc.id,
          verified_by: verified_by,
          verified_at: kyc.verified_at
        }
      );
    } catch (notifError) {
      console.error('Error creating notification:', notifError);
      // Don't fail the approval if notification fails
    }

    res.json({
      success: true,
      message: 'Video KYC approved successfully',
      kyc: {
        id: parseInt(kyc.id),
        user_id: parseInt(kyc.user_id),
        status: kyc.status,
        verified_by: parseInt(kyc.verified_by),
        verified_at: kyc.verified_at
      }
    });
  } catch (error) {
    console.error('Approve KYC error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to approve KYC'
    });
  }
});

// 6. Admin: Reject Video KYC
router.put('/:kyc_id/reject', [
  param('kyc_id').isInt().withMessage('KYC ID must be an integer'),
  body('verified_by').isInt().withMessage('Verified by (admin user ID) is required'),
  body('rejection_reason').notEmpty().withMessage('Rejection reason is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: errors.array()
      });
    }

    const { kyc_id } = req.params;
    const { verified_by, rejection_reason } = req.body;

    // Check if admin user exists
    const adminCheck = await query('SELECT id FROM authentication WHERE id = $1', [verified_by]);
    if (adminCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Admin user not found'
      });
    }

    // Update KYC status
    const result = await query(
      `UPDATE video_kyc_submissions
       SET status = 'rejected',
           rejection_reason = $1,
           verified_by = $2,
           verified_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $3
       RETURNING *`,
      [rejection_reason, verified_by, kyc_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'KYC submission not found'
      });
    }

    const kyc = result.rows[0];

    // Create notification for rejection
    try {
      await createNotification(
        kyc.user_id,
        'kyc_rejected',
        'KYC Verification Rejected',
        `Your video KYC was rejected: ${rejection_reason}`,
        {
          kyc_id: kyc.id,
          rejection_reason: rejection_reason,
          verified_by: verified_by,
          verified_at: kyc.verified_at
        }
      );
    } catch (notifError) {
      console.error('Error creating notification:', notifError);
      // Don't fail the rejection if notification fails
    }

    res.json({
      success: true,
      message: 'Video KYC rejected',
      kyc: {
        id: parseInt(kyc.id),
        user_id: parseInt(kyc.user_id),
        status: kyc.status,
        rejection_reason: kyc.rejection_reason,
        verified_by: parseInt(kyc.verified_by),
        verified_at: kyc.verified_at
      }
    });
  } catch (error) {
    console.error('Reject KYC error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to reject KYC'
    });
  }
});

// 7. Get User's Latest Video KYC
router.get('/user/:user_id/latest', [
  param('user_id').isInt().withMessage('User ID must be an integer'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        errors: errors.array()
      });
    }

    const { user_id } = req.params;

    const result = await query(
      `SELECT *
       FROM video_kyc_submissions
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 1`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.json({
        success: true,
        kyc: null,
        message: 'No video KYC submission found'
      });
    }

    const kyc = result.rows[0];

    res.json({
      success: true,
      kyc: {
        id: parseInt(kyc.id),
        user_id: parseInt(kyc.user_id),
        video_url: kyc.video_url,
        status: kyc.status,
        rejection_reason: kyc.rejection_reason,
        verified_by: kyc.verified_by ? parseInt(kyc.verified_by) : null,
        verified_at: kyc.verified_at,
        created_at: kyc.created_at,
        updated_at: kyc.updated_at
      }
    });
  } catch (error) {
    console.error('Get latest KYC error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get latest KYC'
    });
  }
});

module.exports = router;

