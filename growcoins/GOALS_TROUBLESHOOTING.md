# Goals API Troubleshooting Guide

## Error: "Network error: Failed to get user goals"

This error occurs when the Flutter app cannot successfully fetch goals from the backend. Follow these steps to diagnose and fix:

---

## Step 1: Verify Backend Server is Running

**Check if server is running:**

```bash
curl http://localhost:3001/health
```

**Expected response:**

```json
{
  "status": "OK",
  "message": "Server is running and database is connected"
}
```

**If server is not running:**

```bash
cd growcoins-be
npm start
# or
node server.js
```

---

## Step 2: Verify Goals Route is Registered

**Check `server.js`:**

```javascript
app.use("/api/goals", require("./routes/goals"));
```

This line should be present in `growcoins-be/server.js`.

---

## Step 3: Test Goals Endpoint Directly

**Test with cURL (replace `1` with your actual user ID):**

```bash
curl http://localhost:3001/api/goals/user/1
```

**Expected response (if user has goals):**

```json
{
  "goals": [...],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

**Expected response (if user has no goals):**

```json
{
  "goals": [],
  "total": 0,
  "limit": 50,
  "offset": 0
}
```

**If you get 404:**

- Route is not registered or path is wrong
- Check `routes/goals.js` exists
- Check route is mounted in `server.js`

**If you get 500:**

- Check backend console for error messages
- Verify database connection
- Check if `goals` table exists

---

## Step 4: Verify Database Tables Exist

**Check if goals table exists:**

```sql
SELECT * FROM goals LIMIT 1;
```

**If table doesn't exist, run migration:**

```bash
cd growcoins-be
node scripts/createGoalsTables.js
```

**Check if goal_categories table exists:**

```sql
SELECT * FROM goal_categories LIMIT 1;
```

---

## Step 5: Check User ID

**In Flutter app, verify user is logged in:**

- Check `BackendAuthService.getUserId()` returns a valid user ID
- Verify user exists in database:
  ```sql
  SELECT id FROM authentication WHERE id = YOUR_USER_ID;
  ```

---

## Step 6: Check Network Configuration

**Verify base URL in `lib/services/api_service.dart`:**

- Android Emulator: `http://10.0.2.2:3001`
- iOS Simulator: `http://localhost:3001`
- Physical Device: `http://[YOUR_COMPUTER_IP]:3001`

**Find your computer's IP:**

- Mac/Linux: `ifconfig | grep "inet " | grep -v 127.0.0.1`
- Windows: `ipconfig` (look for IPv4 Address)

---

## Step 7: Check Backend Logs

**Look for errors in backend console:**

- Database connection errors
- SQL query errors
- Route registration errors

**Common errors:**

1. **"relation 'goals' does not exist"** → Run database migration
2. **"relation 'goal_categories' does not exist"** → Run database migration
3. **"Connection refused"** → Database not running or wrong credentials
4. **"Route not found"** → Route not registered in server.js

---

## Step 8: Verify Response Format

**Backend should return:**

```json
{
  "goals": [
    {
      "id": 1,
      "user_id": 1,
      "category_id": 1,
      "category_name": "Phone",
      "category_icon": "phone",
      "goal_name": "iPhone 15 Pro",
      "target_amount": 80000.0,
      "current_amount": 25000.0,
      "target_date": "2025-06-15",
      "status": "active",
      "created_at": "2025-01-15T10:30:00.000Z",
      "updated_at": "2025-01-15T10:30:00.000Z",
      "progress_percentage": 31.25,
      "days_remaining": 151,
      "monthly_savings_needed": 3636.36
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

**Important:** All numeric fields must be numbers, not strings!

---

## Quick Fix Checklist

- [ ] Backend server is running on port 3001
- [ ] `/api/goals` route is registered in `server.js`
- [ ] `goals` table exists in database
- [ ] `goal_categories` table exists in database
- [ ] User ID is valid and user exists in database
- [ ] Base URL in Flutter matches your environment
- [ ] Test endpoint with cURL returns valid JSON
- [ ] Backend logs show no errors
- [ ] Database connection is working

---

## Common Solutions

### Solution 1: Restart Backend Server

```bash
# Stop server (Ctrl+C)
# Then restart
cd growcoins-be
npm start
```

### Solution 2: Run Database Migrations

```bash
cd growcoins-be
node scripts/createGoalsTables.js
```

### Solution 3: Check Port Configuration

- Backend: `server.js` should use port 3001 (or set PORT=3001)
- Flutter: `api_service.dart` should match backend port

### Solution 4: Verify Route Path

- Backend route: `/api/goals/user/:user_id`
- Flutter calls: `/api/goals/user/$userId`
- Should match exactly!

---

## Still Not Working?

1. **Check Flutter console** for detailed error messages
2. **Check backend console** for server errors
3. **Test with Postman/Insomnia** to verify backend works
4. **Check network tab** in browser (if testing web)
5. **Verify user authentication** - user must be logged in

---

## Debug Mode

Add debug logging to `goal_service.dart`:

```dart
debugPrint('Fetching goals for user: $userId');
debugPrint('Endpoint: $endpoint');
debugPrint('Base URL: ${ApiService.baseUrl}');
```

Check what URL is being called and verify it matches your backend.
