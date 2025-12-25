# Video KYC API Documentation

## 📋 Overview

This document describes the backend API endpoints required for the Video KYC (Know Your Customer) feature. Video KYC allows users to complete identity verification by recording a short video of themselves stating their name and date of birth.

---

## 🗄️ Database Schema

### Table: `video_kyc_submissions`

```sql
CREATE TABLE video_kyc_submissions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    video_url VARCHAR(500) NOT NULL,
    video_path VARCHAR(500) NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    rejection_reason TEXT NULL,
    verified_by INT NULL,
    verified_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);
```

### Table Fields Description

- `id`: Primary key, auto-increment
- `user_id`: Foreign key to `users` table
- `video_url`: Public URL to access the video (e.g., S3 URL, CDN URL)
- `video_path`: Server file path where video is stored
- `status`: Current verification status
  - `pending`: Video uploaded, awaiting review
  - `approved`: Video verified and approved
  - `rejected`: Video rejected (requires retry)
- `rejection_reason`: Optional reason for rejection (if status is `rejected`)
- `verified_by`: Admin user ID who verified the video (nullable)
- `verified_at`: Timestamp when verification was completed (nullable)
- `created_at`: Timestamp when video was uploaded
- `updated_at`: Timestamp when record was last updated

---

## 📡 API Endpoints

### 1. Upload Video KYC

**Endpoint:** `POST /api/kyc/video-kyc/upload`

**Description:** Uploads a video file for KYC verification.

**Request:**
- **Method:** `POST`
- **Content-Type:** `multipart/form-data`
- **Body:**
  - `user_id` (integer, required): User ID
  - `video` (file, required): Video file (MP4 format, max 50MB)

**Response:**
```json
{
  "success": true,
  "message": "Video uploaded successfully",
  "kyc_id": 123,
  "status": "pending",
  "video_url": "https://cdn.example.com/videos/kyc/user_1_video_1234567890.mp4"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid request or file format
- `401 Unauthorized`: User not authenticated
- `413 Payload Too Large`: Video file exceeds size limit
- `500 Internal Server Error`: Server error

**cURL Example:**
```bash
curl -X POST http://localhost:3001/api/kyc/video-kyc/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "user_id=1" \
  -F "video=@/path/to/video.mp4"
```

---

### 2. Get Video KYC Status

**Endpoint:** `GET /api/kyc/video-kyc/status/:kyc_id`

**Description:** Retrieves the current status of a video KYC submission.

**Request:**
- **Method:** `GET`
- **Query Parameters:**
  - `user_id` (integer, required): User ID (for authorization)

**Response:**
```json
{
  "success": true,
  "kyc": {
    "id": 123,
    "user_id": 1,
    "status": "pending",
    "video_url": "https://cdn.example.com/videos/kyc/user_1_video_1234567890.mp4",
    "rejection_reason": null,
    "created_at": "2024-01-15T10:30:00.000Z",
    "updated_at": "2024-01-15T10:30:00.000Z"
  }
}
```

**Status Values:**
- `pending`: Under review
- `approved`: Verified and approved
- `rejected`: Rejected (check `rejection_reason`)

**Error Responses:**
- `401 Unauthorized`: User not authenticated
- `403 Forbidden`: User doesn't have access to this KYC submission
- `404 Not Found`: KYC submission not found
- `500 Internal Server Error`: Server error

**cURL Example:**
```bash
curl -X GET "http://localhost:3001/api/kyc/video-kyc/status/123?user_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### 3. Get Video KYC Details

**Endpoint:** `GET /api/kyc/video-kyc/:kyc_id`

**Description:** Retrieves detailed information about a video KYC submission.

**Request:**
- **Method:** `GET`
- **Query Parameters:**
  - `user_id` (integer, required): User ID (for authorization)

**Response:**
```json
{
  "success": true,
  "kyc": {
    "id": 123,
    "user_id": 1,
    "video_url": "https://cdn.example.com/videos/kyc/user_1_video_1234567890.mp4",
    "status": "approved",
    "rejection_reason": null,
    "verified_by": 5,
    "verified_at": "2024-01-16T14:20:00.000Z",
    "created_at": "2024-01-15T10:30:00.000Z",
    "updated_at": "2024-01-16T14:20:00.000Z"
  }
}
```

**Error Responses:**
- `401 Unauthorized`: User not authenticated
- `403 Forbidden`: User doesn't have access to this KYC submission
- `404 Not Found`: KYC submission not found
- `500 Internal Server Error`: Server error

**cURL Example:**
```bash
curl -X GET "http://localhost:3001/api/kyc/video-kyc/123?user_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### 4. Delete/Retry Video KYC

**Endpoint:** `DELETE /api/kyc/video-kyc/:kyc_id`

**Description:** Deletes a video KYC submission, allowing the user to retry.

**Request:**
- **Method:** `DELETE`
- **Query Parameters:**
  - `user_id` (integer, required): User ID (for authorization)

**Response:**
```json
{
  "success": true,
  "message": "Video KYC submission deleted successfully"
}
```

**Error Responses:**
- `401 Unauthorized`: User not authenticated
- `403 Forbidden`: User doesn't have access to this KYC submission
- `404 Not Found`: KYC submission not found
- `500 Internal Server Error`: Server error

**cURL Example:**
```bash
curl -X DELETE "http://localhost:3001/api/kyc/video-kyc/123?user_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### 5. Admin: Approve Video KYC

**Endpoint:** `PUT /api/kyc/video-kyc/:kyc_id/approve`

**Description:** Admin endpoint to approve a video KYC submission.

**Request:**
- **Method:** `PUT`
- **Headers:**
  - `Authorization: Bearer ADMIN_TOKEN`
- **Body:**
```json
{
  "verified_by": 5
}
```

**Response:**
```json
{
  "success": true,
  "message": "Video KYC approved successfully",
  "kyc": {
    "id": 123,
    "user_id": 1,
    "status": "approved",
    "verified_by": 5,
    "verified_at": "2024-01-16T14:20:00.000Z"
  }
}
```

**Error Responses:**
- `401 Unauthorized`: Admin not authenticated
- `403 Forbidden`: Not an admin user
- `404 Not Found`: KYC submission not found
- `500 Internal Server Error`: Server error

---

### 6. Admin: Reject Video KYC

**Endpoint:** `PUT /api/kyc/video-kyc/:kyc_id/reject`

**Description:** Admin endpoint to reject a video KYC submission.

**Request:**
- **Method:** `PUT`
- **Headers:**
  - `Authorization: Bearer ADMIN_TOKEN`
- **Body:**
```json
{
  "rejection_reason": "Face not clearly visible",
  "verified_by": 5
}
```

**Response:**
```json
{
  "success": true,
  "message": "Video KYC rejected",
  "kyc": {
    "id": 123,
    "user_id": 1,
    "status": "rejected",
    "rejection_reason": "Face not clearly visible",
    "verified_by": 5,
    "verified_at": "2024-01-16T14:20:00.000Z"
  }
}
```

**Error Responses:**
- `401 Unauthorized`: Admin not authenticated
- `403 Forbidden`: Not an admin user
- `404 Not Found`: KYC submission not found
- `500 Internal Server Error`: Server error

---

## 🔧 Implementation Guide

### 1. File Upload Handling

**Using Multer (Node.js/Express):**

```javascript
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/video_kyc/';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const userId = req.body.user_id;
    const timestamp = Date.now();
    const filename = `user_${userId}_video_${timestamp}.mp4`;
    cb(null, filename);
  },
});

// File filter
const fileFilter = (req, file, cb) => {
  if (file.mimetype === 'video/mp4' || file.mimetype === 'video/quicktime') {
    cb(null, true);
  } else {
    cb(new Error('Only MP4 videos are allowed'), false);
  }
};

// Configure multer
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB max
  },
  fileFilter: fileFilter,
});

// Route handler
router.post('/upload', upload.single('video'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'Video file is required',
      });
    }

    const userId = parseInt(req.body.user_id);
    const videoPath = req.file.path;
    const videoUrl = `${process.env.CDN_BASE_URL}/video_kyc/${req.file.filename}`;

    // Save to database
    const [result] = await db.query(
      'INSERT INTO video_kyc_submissions (user_id, video_url, video_path, status) VALUES (?, ?, ?, ?)',
      [userId, videoUrl, videoPath, 'pending']
    );

    res.status(201).json({
      success: true,
      message: 'Video uploaded successfully',
      kyc_id: result.insertId,
      status: 'pending',
      video_url: videoUrl,
    });
  } catch (error) {
    console.error('Error uploading video:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to upload video',
    });
  }
});
```

### 2. Video Storage Options

**Option A: Local Storage (Development)**
- Store videos in `uploads/video_kyc/` directory
- Serve via static file server

**Option B: Cloud Storage (Production)**
- **AWS S3**: Upload to S3 bucket, generate presigned URLs
- **Google Cloud Storage**: Similar to S3
- **Azure Blob Storage**: Microsoft cloud storage

**Example S3 Upload:**
```javascript
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

const uploadToS3 = async (file, userId) => {
  const params = {
    Bucket: process.env.S3_BUCKET_NAME,
    Key: `video_kyc/user_${userId}_${Date.now()}.mp4`,
    Body: fs.createReadStream(file.path),
    ContentType: 'video/mp4',
    ACL: 'private', // Or 'public-read' if public access needed
  };

  const result = await s3.upload(params).promise();
  return result.Location; // Public URL
};
```

### 3. Video Processing (Optional)

Consider processing videos for:
- **Thumbnail Generation**: Extract a frame for preview
- **Compression**: Reduce file size while maintaining quality
- **Format Conversion**: Ensure consistent format (MP4)

**Using FFmpeg:**
```javascript
const ffmpeg = require('fluent-ffmpeg');

const generateThumbnail = (videoPath, outputPath) => {
  return new Promise((resolve, reject) => {
    ffmpeg(videoPath)
      .screenshots({
        timestamps: ['00:00:01'],
        filename: 'thumbnail.jpg',
        folder: outputPath,
      })
      .on('end', resolve)
      .on('error', reject);
  });
};
```

### 4. Security Considerations

1. **File Validation:**
   - Check file type (MIME type, not just extension)
   - Validate file size (max 50MB)
   - Scan for malware (optional)

2. **Access Control:**
   - Verify `user_id` matches authenticated user
   - Only allow users to access their own videos
   - Admin endpoints require admin role

3. **Video Privacy:**
   - Store videos in private storage (not publicly accessible)
   - Use presigned URLs for temporary access
   - Implement video expiration (delete after verification)

4. **Rate Limiting:**
   - Limit uploads per user (e.g., 3 attempts per day)
   - Prevent abuse and spam

### 5. Notification System

When video KYC status changes, send notifications:

```javascript
// After approval
await NotificationService.create({
  user_id: kyc.user_id,
  type: 'kyc_approved',
  title: 'KYC Verification Approved',
  message: 'Your video KYC has been verified and approved.',
});

// After rejection
await NotificationService.create({
  user_id: kyc.user_id,
  type: 'kyc_rejected',
  title: 'KYC Verification Rejected',
  message: `Your video KYC was rejected: ${rejection_reason}`,
});
```

---

## 📊 Database Queries

### Get User's Latest Video KYC

```sql
SELECT * FROM video_kyc_submissions
WHERE user_id = ?
ORDER BY created_at DESC
LIMIT 1;
```

### Get All Pending Video KYCs (Admin)

```sql
SELECT 
  vk.*,
  u.full_name,
  u.email
FROM video_kyc_submissions vk
JOIN users u ON vk.user_id = u.id
WHERE vk.status = 'pending'
ORDER BY vk.created_at ASC;
```

### Update KYC Status

```sql
UPDATE video_kyc_submissions
SET 
  status = ?,
  rejection_reason = ?,
  verified_by = ?,
  verified_at = NOW()
WHERE id = ? AND user_id = ?;
```

---

## 🧪 Testing

### Test Video Upload

```bash
# Create a test video (using ffmpeg)
ffmpeg -f lavfi -i testsrc=duration=10:size=640x480:rate=30 -c:v libx264 test_video.mp4

# Upload via cURL
curl -X POST http://localhost:3001/api/kyc/video-kyc/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "user_id=1" \
  -F "video=@test_video.mp4"
```

### Test Status Check

```bash
curl -X GET "http://localhost:3001/api/kyc/video-kyc/status/123?user_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 📝 Notes

1. **Video Format:** Accept MP4 format (H.264 codec recommended)
2. **File Size:** Maximum 50MB per video
3. **Duration:** Recommended 10-30 seconds
4. **Storage:** Use cloud storage (S3, GCS) in production
5. **Security:** Implement proper authentication and authorization
6. **Compliance:** Ensure compliance with data protection regulations (GDPR, etc.)
7. **Retention:** Define video retention policy (e.g., delete after 90 days if approved)

---

## 🔄 Integration with Existing KYC

The video KYC can be integrated with the existing KYC system:

1. **Update `users` table:**
   - Add `kyc_method` field: `ENUM('traditional', 'video')`
   - Add `kyc_status` field: `ENUM('pending', 'approved', 'rejected')`

2. **Link to existing KYC:**
   - When video KYC is approved, update user's `kyc_status` to `approved`
   - Mark `kyc_method` as `'video'`

3. **Unified KYC Status:**
   - Check both traditional and video KYC when determining user's KYC status

---

## 📞 Support

For questions or issues, contact the development team or refer to the main API documentation.

