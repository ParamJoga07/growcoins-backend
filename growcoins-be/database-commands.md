# Database Connection Commands

## Direct PostgreSQL Connection (psql)

### Connect to Database
```bash
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
psql -h localhost -p 5432 -U param_joga -d growcoins
```

### Quick Commands (without entering psql)
```bash
# List all tables
psql -h localhost -p 5432 -U param_joga -d growcoins -c "\dt"

# View authentication table structure
psql -h localhost -p 5432 -U param_joga -d growcoins -c "\d authentication"

# View user_data table structure
psql -h localhost -p 5432 -U param_joga -d growcoins -c "\d user_data"

# Select all from authentication table
psql -h localhost -p 5432 -U param_joga -d growcoins -c "SELECT * FROM authentication;"

# Select all from user_data table
psql -h localhost -p 5432 -U param_joga -d growcoins -c "SELECT * FROM user_data;"

# Count records
psql -h localhost -p 5432 -U param_joga -d growcoins -c "SELECT COUNT(*) FROM authentication;"
psql -h localhost -p 5432 -U param_joga -d growcoins -c "SELECT COUNT(*) FROM user_data;"
```

## API Endpoints (curl) - These connect to database via API

### Health Check (tests database connection)
```bash
curl http://localhost:3001/health
```

### Register a User
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123",
    "email": "test@example.com",
    "first_name": "Test",
    "last_name": "User"
  }'
```

### Login
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

### Get All Users
```bash
curl http://localhost:3001/api/users
```

### Get User by ID
```bash
curl http://localhost:3001/api/users/1
```

### Update User Balance
```bash
curl -X PATCH http://localhost:3001/api/users/1/balance \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000.00,
    "operation": "add"
  }'
```

