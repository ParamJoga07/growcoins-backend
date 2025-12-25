# Profile Route Fix Guide

## Issue
Frontend is getting "Route not found" error when trying to access `/api/users/profile/:user_id`

## Solution

### 1. Verify Server Port

Check `growcoins-be/server.js` line 6:
```javascript
const PORT = process.env.PORT || 3000;
```

**IMPORTANT:** The default port is 3000, but Flutter app is calling port 3001!

**Fix Option A:** Update server.js to use port 3001:
```javascript
const PORT = process.env.PORT || 3001;
```

**Fix Option B:** Set environment variable:
```bash
export PORT=3001
# or create .env file with:
# PORT=3001
```

### 2. Verify Route is Registered

The route exists in `growcoins-be/routes/users.js`:
- Line 7: `router.get('/profile/:id', ...)`
- Line 137: `router.put('/profile/:id', ...)`

And it's mounted in `server.js` line 36:
```javascript
app.use('/api/users', require('./routes/users'));
```

So the full path should be: `/api/users/profile/:id`

### 3. Restart Backend Server

After making any changes, restart the server:
```bash
cd growcoins-be
npm start
# or
node server.js
```

### 4. Test the Route

Test with cURL:
```bash
# Replace 1 with actual user ID
curl http://localhost:3001/api/users/profile/1
```

Expected response:
```json
{
  "success": true,
  "profile": {
    "id": 1,
    "username": "...",
    ...
  }
}
```

### 5. Check Server Logs

When you make a request, check the server console for:
- Route registration messages
- Any error messages
- Request logs

### 6. Verify Frontend Base URL

Check `lib/services/api_service.dart`:
- Android Emulator: `http://10.0.2.2:3001`
- iOS Simulator: `http://localhost:3001`
- Physical Device: `http://[YOUR_IP]:3001`

Make sure the port matches your server port!

## Quick Checklist

- [ ] Server is running on port 3001 (or update frontend to match server port)
- [ ] Route `/api/users/profile/:id` exists in `routes/users.js`
- [ ] Route is mounted in `server.js` as `/api/users`
- [ ] Server has been restarted after any changes
- [ ] Tested with cURL and got successful response
- [ ] Frontend base URL matches server port

## Common Issues

### Issue 1: Port Mismatch
**Symptom:** Route not found error
**Solution:** Ensure server port matches frontend base URL port

### Issue 2: Server Not Running
**Symptom:** Connection refused error
**Solution:** Start the backend server

### Issue 3: Route Not Registered
**Symptom:** 404 error
**Solution:** Check `server.js` has `app.use('/api/users', require('./routes/users'))`

### Issue 4: Syntax Error in Route
**Symptom:** Server won't start or route doesn't work
**Solution:** Check `routes/users.js` for syntax errors, ensure all brackets are closed

