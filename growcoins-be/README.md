# Growcoins Backend

Backend API for Growcoins fintech application built with Express.js and PostgreSQL.

## Prerequisites

- Node.js (v14 or higher)
- PostgreSQL (v12 or higher)
- npm or yarn

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=growcoins

# Server Configuration
PORT=3000
NODE_ENV=development

# JWT Secret (for future authentication)
JWT_SECRET=your_jwt_secret_key_here
```

**Important:** Replace `your_password` with your actual PostgreSQL password.

### 3. Create Database

Run the script to create the `growcoins` database:

```bash
npm run db:create
```

### 4. Run Migrations

Create the database tables:

```bash
npm run db:migrate
```

### 5. Start the Server

For development (with auto-reload):
```bash
npm run dev
```

For production:
```bash
npm start
```

The server will start on `http://localhost:3000` (or the port specified in your `.env` file).

## Database Schema

### Authentication Table
- `id` - Primary key
- `username` - Unique username
- `password` - Hashed password
- `user_id` - Reference to user
- `created_at` - Account creation timestamp
- `updated_at` - Last update timestamp
- `last_login` - Last login timestamp
- `is_active` - Account status

### User Data Table
- `id` - Primary key
- `user_id` - Foreign key to authentication table
- `first_name` - User's first name
- `last_name` - User's last name
- `email` - Unique email address
- `phone_number` - Contact number
- `date_of_birth` - Date of birth
- `address` - Street address
- `city` - City
- `state` - State/Province
- `zip_code` - Postal code
- `country` - Country (default: USA)
- `account_number` - Unique account number
- `routing_number` - Bank routing number
- `account_balance` - Current account balance
- `currency` - Currency code (default: USD)
- `kyc_status` - KYC verification status
- `kyc_verified_at` - KYC verification timestamp
- `profile_picture_url` - Profile picture URL
- `created_at` - Record creation timestamp
- `updated_at` - Last update timestamp

## API Endpoints

### Health Check
- `GET /health` - Check server and database status

### Authentication
- `POST /api/auth/register` - Register a new user
  - Body: `{ username, password, email, first_name, last_name, phone_number?, date_of_birth? }`
  
- `POST /api/auth/login` - Login user
  - Body: `{ username, password }`

### Users
- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user data
- `PATCH /api/users/:id/balance` - Update account balance
  - Body: `{ amount, operation: 'add' | 'subtract' | 'set' }`

## Example API Calls

### Register a User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "password": "password123",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+1234567890"
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "password": "password123"
  }'
```

### Get User
```bash
curl http://localhost:3000/api/users/1
```

### Update Balance
```bash
curl -X PATCH http://localhost:3000/api/users/1/balance \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000.00,
    "operation": "add"
  }'
```

## Project Structure

```
growcoins-be/
├── config/
│   └── database.js          # Database configuration
├── routes/
│   ├── auth.js              # Authentication routes
│   └── users.js             # User management routes
├── scripts/
│   ├── createDatabase.js    # Database creation script
│   └── migrate.js           # Database migration script
├── server.js                # Express server setup
├── package.json             # Dependencies and scripts
└── README.md                # This file
```

## Security Notes

- Passwords are hashed using bcryptjs
- Consider adding JWT authentication for protected routes
- Add rate limiting for production
- Implement proper CORS configuration for production
- Use environment variables for sensitive data
- Consider adding input sanitization

## Next Steps

- Add JWT authentication middleware
- Implement transaction history table
- Add email verification
- Implement password reset functionality
- Add API documentation (Swagger/OpenAPI)
- Add unit and integration tests
- Set up logging (Winston/Morgan)

