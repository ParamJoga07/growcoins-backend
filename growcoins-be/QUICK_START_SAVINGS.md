# Quick Start - Roundoff Savings API

## 🚀 Quick Setup

### 1. Database Setup (Already Done)
```bash
npm run db:add-roundoff
```

### 2. Install Dependencies (Already Done)
```bash
npm install pdf-parse multer
```

### 3. Start Server
```bash
npm start
```

---

## 📡 API Endpoints

### 1. Set Roundoff Amount
```bash
curl -X POST http://localhost:3001/api/savings/roundoff \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "roundoff_amount": 10
  }'
```

**Response:**
```json
{
  "message": "Roundoff amount updated successfully",
  "setting": {
    "id": 1,
    "user_id": 1,
    "roundoff_amount": 10,
    "is_active": true
  }
}
```

---

### 2. Upload Bank Statement PDF
```bash
curl -X POST http://localhost:3001/api/savings/upload \
  -F "statement=@/path/to/bank_statement.pdf" \
  -F "user_id=1"
```

**Response:**
```json
{
  "message": "Bank statement processed successfully",
  "statement_id": 1,
  "transactions_processed": 25,
  "summary": {
    "totalRoundoff": 125.50,
    "transactionCount": 25,
    "roundoff_amount": 10
  },
  "insights": "🎉 In 30 days, you could have saved ₹125.50..."
}
```

---

### 3. Get Savings Summary
```bash
curl http://localhost:3001/api/savings/summary/1
```

**Response:**
```json
{
  "total_savings": 125.50,
  "transaction_count": 25,
  "roundoff_amount": 10,
  "projections": {
    "monthly": { "savings": 125.50 },
    "yearly": { "savings": 1525.70 }
  },
  "insights": "🎉 In 30 days..."
}
```

---

### 4. Get Transactions
```bash
curl http://localhost:3001/api/savings/transactions/1?limit=10&offset=0
```

---

### 5. Get Insights
```bash
curl http://localhost:3001/api/savings/insights/1
```

---

### 6. Get Roundoff Setting
```bash
curl http://localhost:3001/api/savings/roundoff/1
```

---

## 🎯 How It Works

1. **User sets roundoff amount** (₹5, ₹10, ₹20, ₹30, or custom)
2. **Upload bank statement PDF** → Extracts withdrawals
3. **Calculate roundoff** for each withdrawal
4. **Accumulate savings** → Show total potential savings
5. **Generate insights** → Projections and fun comparisons

**Example:**
- Withdrawal: ₹175.50
- Roundoff: ₹10
- Rounded: ₹180.00
- Savings: ₹4.50 ✨

---

## 📱 Flutter Integration

See `SAVINGS_FLUTTER.md` for complete Flutter integration guide.

**Quick Example:**
```dart
// Set roundoff amount
await SavingsService.setRoundoffAmount(
  userId: 1,
  roundoffAmount: 10,
);

// Upload PDF
File? pdfFile = await SavingsService.pickPdfFile();
await SavingsService.uploadBankStatement(
  userId: 1,
  pdfFile: pdfFile!,
);

// Get summary
final summary = await SavingsService.getSavingsSummary(1);
print('Total Savings: ₹${summary.totalSavings}');
```

---

## 📊 Database Tables

- `roundoff_settings` - User roundoff preferences
- `bank_statements` - Uploaded PDF records
- `transactions` - Extracted withdrawal transactions
- `roundoff_savings` - Daily aggregated savings

---

## ⚠️ Notes

1. **PDF Format**: The parser works with common bank statement formats. You may need to customize `services/pdfParser.js` for your specific bank.

2. **File Size**: Maximum 10MB per PDF

3. **Roundoff Amounts**: Common values: 5, 10, 20, 30. Custom amounts also supported.

4. **File Storage**: PDFs are stored in `uploads/` directory (excluded from git)

---

## 🔧 Customization

### Custom PDF Parser
Edit `services/pdfParser.js` to match your bank's statement format.

### Custom Roundoff Logic
Edit `services/roundoffCalculator.js` to change calculation logic.

### Custom Insights
Edit `services/roundoffCalculator.js` → `generateInsights()` function.

---

## 📚 Full Documentation

- **API Documentation**: See `API_DOCUMENTATION.md` → Roundoff Savings APIs
- **Flutter Guide**: See `SAVINGS_FLUTTER.md`
- **Models**: See `SAVINGS_FLUTTER.md` → Models section

---

## ✅ Testing Checklist

- [ ] Set roundoff amount (5, 10, 20, 30, custom)
- [ ] Upload bank statement PDF
- [ ] Verify transactions extracted
- [ ] Check savings summary
- [ ] View insights
- [ ] Get transaction list
- [ ] Test with different roundoff amounts

---

## 🎉 Ready to Use!

The API is fully functional and ready to integrate with your Flutter app!

