# Onboarding APIs - Summary

## ✅ What Was Added

### 1. Database Changes

**New Fields Added to `user_data` Table:**
- `full_legal_name` (VARCHAR 255) - Full legal name from onboarding screen 1
- `pan_number` (VARCHAR 10, UNIQUE) - PAN number for KYC (format: ABCDE1234F)
- `aadhar_number` (VARCHAR 12, UNIQUE) - Aadhar number for KYC (12 digits)

**Indexes Created:**
- Index on `pan_number` for faster lookups
- Index on `aadhar_number` for faster lookups

### 2. New API Endpoints

#### POST `/api/onboarding/personal-details`
- Saves personal details from onboarding screen 1
- Fields: `full_legal_name`, `email`, `date_of_birth`
- Automatically splits full name into `first_name` and `last_name`
- Creates user_data record if it doesn't exist

#### POST `/api/onboarding/kyc-details`
- Saves KYC details from onboarding screen 2
- Fields: `pan_number`, `aadhar_number`
- Validates PAN format (ABCDE1234F)
- Validates Aadhar format (12 digits)
- Updates KYC status to "submitted"

#### GET `/api/onboarding/status/:user_id`
- Checks onboarding completion status
- Returns which steps are completed
- Returns current KYC status

#### POST `/api/onboarding/complete/:user_id`
- Marks onboarding as complete
- Validates all required fields are filled
- Updates KYC verification timestamp

### 3. Updated Endpoints

#### PUT `/api/users/:id`
- Now supports updating `full_legal_name`
- Now supports updating `pan_number` (with validation)
- Now supports updating `aadhar_number` (with validation)

## 📋 Migration Command

To add the new fields to your database, run:

```bash
npm run db:add-onboarding
```

## 🔄 Onboarding Flow

1. **User Registration** → `POST /api/auth/register`
   - Returns `user_id`

2. **Personal Details** → `POST /api/onboarding/personal-details`
   - Input: `user_id`, `full_legal_name`, `email`, `date_of_birth`
   - Creates/updates user profile

3. **KYC Details** → `POST /api/onboarding/kyc-details`
   - Input: `user_id`, `pan_number`, `aadhar_number`
   - Updates KYC information

4. **Complete Onboarding** → `POST /api/onboarding/complete/:user_id`
   - Validates all fields are complete
   - Marks onboarding as done

## 📱 Flutter Integration

New service class: `OnboardingService`

**Methods:**
- `savePersonalDetails()` - Save screen 1 data
- `saveKycDetails()` - Save screen 2 data
- `getOnboardingStatus()` - Check completion status
- `completeOnboarding()` - Mark as complete

See `FLUTTER_INTEGRATION.md` for complete implementation details.

## ✅ Validation Rules

### PAN Number
- Format: `ABCDE1234F`
- 5 uppercase letters + 4 digits + 1 uppercase letter
- Must be unique

### Aadhar Number
- Format: 12 digits
- Example: `123456789012`
- Must be unique

### Date of Birth
- Format: `YYYY-MM-DD`
- Example: `1990-01-15`

## 🧪 Testing

Test the new endpoints:

```bash
# Save Personal Details
curl -X POST http://localhost:3001/api/onboarding/personal-details \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "full_legal_name": "John Doe",
    "email": "john@example.com",
    "date_of_birth": "1990-01-15"
  }'

# Save KYC Details
curl -X POST http://localhost:3001/api/onboarding/kyc-details \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "pan_number": "ABCDE1234F",
    "aadhar_number": "123456789012"
  }'

# Check Status
curl http://localhost:3001/api/onboarding/status/1

# Complete Onboarding
curl -X POST http://localhost:3001/api/onboarding/complete/1
```

## 📚 Documentation

- Full API documentation: `API_DOCUMENTATION.md`
- Flutter integration guide: `FLUTTER_INTEGRATION.md`

