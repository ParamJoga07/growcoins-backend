# Flutter Integration Guide - Roundoff Savings API

This guide shows you how to integrate the Roundoff Savings API into your Flutter application.

## Table of Contents

1. [Setup](#setup)
2. [Service Class](#service-class)
3. [Models](#models)
4. [Usage Examples](#usage-examples)
5. [Complete Example Screen](#complete-example-screen)

---

## Setup

### 1. Add Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  file_picker: ^6.1.1
  path_provider: ^2.1.1
```

### 2. Update API Service

Make sure your `api_service.dart` has the base URL configured:

```dart
class ApiService {
  // For Android Emulator
  static const String baseUrl = 'http://10.0.2.2:3001';

  // For iOS Simulator
  // static const String baseUrl = 'http://localhost:3001';

  // For Physical Device (replace with your computer's IP)
  // static const String baseUrl = 'http://192.168.1.100:3001';

  static Future<Map<String, String>> get headers => Future.value({
    'Content-Type': 'application/json',
  });
}
```

---

## Service Class

Create `lib/services/savings_service.dart`:

```dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/savings_models.dart';
import '../services/api_service.dart';

class SavingsService {
  static const String baseUrl = ApiService.baseUrl;

  // Set Roundoff Amount
  static Future<Map<String, dynamic>> setRoundoffAmount({
    required int userId,
    required int roundoffAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/savings/roundoff'),
        headers: await ApiService.headers,
        body: jsonEncode({
          'user_id': userId,
          'roundoff_amount': roundoffAmount,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to set roundoff amount: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error setting roundoff amount: $e');
    }
  }

  // Upload Bank Statement PDF
  static Future<SavingsUploadResponse> uploadBankStatement({
    required int userId,
    required File pdfFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/savings/upload'),
      );

      request.fields['user_id'] = userId.toString();
      request.files.add(
        await http.MultipartFile.fromPath('statement', pdfFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SavingsUploadResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to upload statement');
      }
    } catch (e) {
      throw Exception('Error uploading statement: $e');
    }
  }

  // Get Savings Summary
  static Future<SavingsSummary> getSavingsSummary(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/savings/summary/$userId'),
        headers: await ApiService.headers,
      );

      if (response.statusCode == 200) {
        return SavingsSummary.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get savings summary: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting savings summary: $e');
    }
  }

  // Get Transactions
  static Future<TransactionsResponse> getTransactions({
    required int userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/savings/transactions/$userId?limit=$limit&offset=$offset'),
        headers: await ApiService.headers,
      );

      if (response.statusCode == 200) {
        return TransactionsResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get transactions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting transactions: $e');
    }
  }

  // Get Insights
  static Future<SavingsInsights> getInsights(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/savings/insights/$userId'),
        headers: await ApiService.headers,
      );

      if (response.statusCode == 200) {
        return SavingsInsights.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get insights: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting insights: $e');
    }
  }

  // Get Roundoff Setting
  static Future<RoundoffSetting> getRoundoffSetting(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/savings/roundoff/$userId'),
        headers: await ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['setting'] != null) {
          return RoundoffSetting.fromJson(data['setting']);
        } else {
          // Return default setting
          return RoundoffSetting(
            userId: userId,
            roundoffAmount: 10,
            isActive: true,
          );
        }
      } else {
        throw Exception('Failed to get roundoff setting: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting roundoff setting: $e');
    }
  }

  // Pick PDF File
  static Future<File?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Error picking PDF file: $e');
    }
  }
}
```

---

## Models

Create `lib/models/savings_models.dart`:

```dart
import 'dart:convert';

// Roundoff Setting Model
class RoundoffSetting {
  final int? id;
  final int userId;
  final int roundoffAmount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RoundoffSetting({
    this.id,
    required this.userId,
    required this.roundoffAmount,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory RoundoffSetting.fromJson(Map<String, dynamic> json) {
    return RoundoffSetting(
      id: json['id'],
      userId: json['user_id'],
      roundoffAmount: json['roundoff_amount'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'roundoff_amount': roundoffAmount,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// Transaction Model
class Transaction {
  final int id;
  final DateTime transactionDate;
  final String description;
  final double amount;
  final double roundoffAmount;
  final double roundedAmount;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.transactionDate,
    required this.description,
    required this.amount,
    required this.roundoffAmount,
    required this.roundedAmount,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      transactionDate: DateTime.parse(json['transaction_date']),
      description: json['description'] ?? '',
      amount: double.parse(json['amount'].toString()),
      roundoffAmount: double.parse(json['roundoff_amount']?.toString() ?? '0'),
      roundedAmount: double.parse(json['rounded_amount']?.toString() ?? json['amount'].toString()),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Transactions Response Model
class TransactionsResponse {
  final List<Transaction> transactions;
  final int total;
  final int limit;
  final int offset;

  TransactionsResponse({
    required this.transactions,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    return TransactionsResponse(
      transactions: (json['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList(),
      total: json['total'],
      limit: json['limit'],
      offset: json['offset'],
    );
  }
}

// Projections Model
class Projections {
  final DailyProjection daily;
  final MonthlyProjection monthly;
  final YearlyProjection yearly;
  final PeriodProjection period;

  Projections({
    required this.daily,
    required this.monthly,
    required this.yearly,
    required this.period,
  });

  factory Projections.fromJson(Map<String, dynamic> json) {
    return Projections(
      daily: DailyProjection.fromJson(json['daily']),
      monthly: MonthlyProjection.fromJson(json['monthly']),
      yearly: YearlyProjection.fromJson(json['yearly']),
      period: PeriodProjection.fromJson(json['period']),
    );
  }
}

class DailyProjection {
  final double transactions;
  final double savings;

  DailyProjection({required this.transactions, required this.savings});

  factory DailyProjection.fromJson(Map<String, dynamic> json) {
    return DailyProjection(
      transactions: json['transactions'].toDouble(),
      savings: json['savings'].toDouble(),
    );
  }
}

class MonthlyProjection {
  final double transactions;
  final double savings;

  MonthlyProjection({required this.transactions, required this.savings});

  factory MonthlyProjection.fromJson(Map<String, dynamic> json) {
    return MonthlyProjection(
      transactions: json['transactions'].toDouble(),
      savings: json['savings'].toDouble(),
    );
  }
}

class YearlyProjection {
  final double transactions;
  final double savings;

  YearlyProjection({required this.transactions, required this.savings});

  factory YearlyProjection.fromJson(Map<String, dynamic> json) {
    return YearlyProjection(
      transactions: json['transactions'].toDouble(),
      savings: json['savings'].toDouble(),
    );
  }
}

class PeriodProjection {
  final int days;
  final int transactions;
  final double savings;

  PeriodProjection({
    required this.days,
    required this.transactions,
    required this.savings,
  });

  factory PeriodProjection.fromJson(Map<String, dynamic> json) {
    return PeriodProjection(
      days: json['days'],
      transactions: json['transactions'],
      savings: json['savings'].toDouble(),
    );
  }
}

// Savings Summary Model
class SavingsSummary {
  final double totalSavings;
  final int transactionCount;
  final double totalWithdrawn;
  final double totalRounded;
  final double averageRoundoff;
  final int roundoffAmount;
  final DateRange? dateRange;
  final Projections? projections;
  final String? insights;
  final String? message;

  SavingsSummary({
    required this.totalSavings,
    required this.transactionCount,
    required this.totalWithdrawn,
    required this.totalRounded,
    required this.averageRoundoff,
    required this.roundoffAmount,
    this.dateRange,
    this.projections,
    this.insights,
    this.message,
  });

  factory SavingsSummary.fromJson(Map<String, dynamic> json) {
    return SavingsSummary(
      totalSavings: json['total_savings']?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] ?? 0,
      totalWithdrawn: json['total_withdrawn']?.toDouble() ?? 0.0,
      totalRounded: json['total_rounded']?.toDouble() ?? 0.0,
      averageRoundoff: json['average_roundoff']?.toDouble() ?? 0.0,
      roundoffAmount: json['roundoff_amount'] ?? 10,
      dateRange: json['date_range'] != null
          ? DateRange.fromJson(json['date_range'])
          : null,
      projections: json['projections'] != null
          ? Projections.fromJson(json['projections'])
          : null,
      insights: json['insights'],
      message: json['message'],
    );
  }
}

class DateRange {
  final String start;
  final String end;
  final int days;

  DateRange({
    required this.start,
    required this.end,
    required this.days,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      start: json['start'],
      end: json['end'],
      days: json['days'],
    );
  }
}

// Savings Upload Response Model
class SavingsUploadResponse {
  final String message;
  final int statementId;
  final int transactionsProcessed;
  final SavingsSummary summary;
  final Projections projections;
  final String insights;

  SavingsUploadResponse({
    required this.message,
    required this.statementId,
    required this.transactionsProcessed,
    required this.summary,
    required this.projections,
    required this.insights,
  });

  factory SavingsUploadResponse.fromJson(Map<String, dynamic> json) {
    return SavingsUploadResponse(
      message: json['message'],
      statementId: json['statement_id'],
      transactionsProcessed: json['transactions_processed'],
      summary: SavingsSummary.fromJson(json['summary']),
      projections: Projections.fromJson(json['projections']),
      insights: json['insights'],
    );
  }
}

// Savings Insights Model
class SavingsInsights {
  final SavingsSummary summary;
  final Projections projections;
  final List<String> insights;
  final DateRange dateRange;

  SavingsInsights({
    required this.summary,
    required this.projections,
    required this.insights,
    required this.dateRange,
  });

  factory SavingsInsights.fromJson(Map<String, dynamic> json) {
    return SavingsInsights(
      summary: SavingsSummary.fromJson(json['summary']),
      projections: Projections.fromJson(json['projections']),
      insights: List<String>.from(json['insights']),
      dateRange: DateRange.fromJson(json['date_range']),
    );
  }
}
```

---

## Usage Examples

### 1. Set Roundoff Amount

```dart
try {
  final result = await SavingsService.setRoundoffAmount(
    userId: 1,
    roundoffAmount: 10, // ₹5, ₹10, ₹20, ₹30, or custom
  );
  print('Roundoff amount set: ${result['message']}');
} catch (e) {
  print('Error: $e');
}
```

### 2. Upload Bank Statement

```dart
try {
  // Pick PDF file
  File? pdfFile = await SavingsService.pickPdfFile();

  if (pdfFile != null) {
    // Upload and process
    final response = await SavingsService.uploadBankStatement(
      userId: 1,
      pdfFile: pdfFile,
    );

    print('Transactions processed: ${response.transactionsProcessed}');
    print('Total savings: ₹${response.summary.totalSavings}');
    print('Insights: ${response.insights}');
  }
} catch (e) {
  print('Error: $e');
}
```

### 3. Get Savings Summary

```dart
try {
  final summary = await SavingsService.getSavingsSummary(1);

  print('Total Savings: ₹${summary.totalSavings}');
  print('Transactions: ${summary.transactionCount}');
  print('Monthly Projection: ₹${summary.projections?.monthly.savings}');
} catch (e) {
  print('Error: $e');
}
```

### 4. Get Transactions

```dart
try {
  final response = await SavingsService.getTransactions(
    userId: 1,
    limit: 20,
    offset: 0,
  );

  for (var transaction in response.transactions) {
    print('${transaction.transactionDate}: ₹${transaction.amount} (Roundoff: ₹${transaction.roundoffAmount})');
  }
} catch (e) {
  print('Error: $e');
}
```

### 5. Get Insights

```dart
try {
  final insights = await SavingsService.getInsights(1);

  print('Total Savings: ₹${insights.summary.totalSavings}');
  for (var insight in insights.insights) {
    print(insight);
  }
} catch (e) {
  print('Error: $e');
}
```

---

## Complete Example Screen

Create `lib/screens/savings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/savings_service.dart';
import '../models/savings_models.dart';

class SavingsScreen extends StatefulWidget {
  final int userId;

  const SavingsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  SavingsSummary? _summary;
  RoundoffSetting? _roundoffSetting;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await SavingsService.getSavingsSummary(widget.userId);
      final setting = await SavingsService.getRoundoffSetting(widget.userId);

      setState(() {
        _summary = summary;
        _roundoffSetting = setting;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadStatement() async {
    try {
      File? pdfFile = await SavingsService.pickPdfFile();

      if (pdfFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No file selected')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final response = await SavingsService.uploadBankStatement(
        userId: widget.userId,
        pdfFile: pdfFile,
      );

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Success!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transactions Processed: ${response.transactionsProcessed}'),
              SizedBox(height: 8),
              Text('Total Savings: ₹${response.summary.totalSavings.toStringAsFixed(2)}'),
              SizedBox(height: 16),
              Text('Insights:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(response.insights),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadData();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setRoundoffAmount(int amount) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await SavingsService.setRoundoffAmount(
        userId: widget.userId,
        roundoffAmount: amount,
      );

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Roundoff amount set to ₹$amount')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Roundoff Savings'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Roundoff Amount Setting
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Roundoff Amount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Current: ₹${_roundoffSetting?.roundoffAmount ?? 10}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  children: [5, 10, 20, 30].map((amount) {
                                    return ElevatedButton(
                                      onPressed: () => _setRoundoffAmount(amount),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _roundoffSetting?.roundoffAmount == amount
                                            ? Colors.green
                                            : null,
                                      ),
                                      child: Text('₹$amount'),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Upload Button
                        ElevatedButton.icon(
                          onPressed: _uploadStatement,
                          icon: Icon(Icons.upload_file),
                          label: Text('Upload Bank Statement PDF'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Savings Summary
                        if (_summary != null) ...[
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Savings Summary',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildSummaryRow(
                                    'Total Savings',
                                    '₹${_summary!.totalSavings.toStringAsFixed(2)}',
                                    Colors.green,
                                  ),
                                  _buildSummaryRow(
                                    'Transactions',
                                    '${_summary!.transactionCount}',
                                    Colors.blue,
                                  ),
                                  _buildSummaryRow(
                                    'Average Roundoff',
                                    '₹${_summary!.averageRoundoff.toStringAsFixed(2)}',
                                    Colors.orange,
                                  ),
                                  if (_summary!.projections != null) ...[
                                    Divider(),
                                    Text(
                                      'Projections',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    _buildSummaryRow(
                                      'Monthly',
                                      '₹${_summary!.projections!.monthly.savings.toStringAsFixed(2)}',
                                      Colors.purple,
                                    ),
                                    _buildSummaryRow(
                                      'Yearly',
                                      '₹${_summary!.projections!.yearly.savings.toStringAsFixed(2)}',
                                      Colors.teal,
                                    ),
                                  ],
                                  if (_summary!.insights != null) ...[
                                    Divider(),
                                    Text(
                                      _summary!.insights!,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                _summary?.message ?? 'Upload a bank statement to see your savings!',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Testing

### Test with cURL

```bash
# Set roundoff amount
curl -X POST http://localhost:3001/api/savings/roundoff \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "roundoff_amount": 10}'

# Upload PDF (replace with actual PDF path)
curl -X POST http://localhost:3001/api/savings/upload \
  -F "statement=@/path/to/bank_statement.pdf" \
  -F "user_id=1"

# Get summary
curl http://localhost:3001/api/savings/summary/1

# Get insights
curl http://localhost:3001/api/savings/insights/1
```

---

## Notes

1. **PDF Format**: The PDF parser works with common bank statement formats. You may need to customize the extraction logic in `services/pdfParser.js` based on your bank's specific format.

2. **File Size**: Maximum PDF file size is 10MB.

3. **Roundoff Amounts**: Common values are ₹5, ₹10, ₹20, ₹30, but any positive integer is accepted.

4. **Network Configuration**: Make sure to configure the correct base URL for your environment (emulator, simulator, or physical device).

5. **Error Handling**: Always wrap API calls in try-catch blocks and show user-friendly error messages.

---

## Next Steps

1. Customize the PDF parser for your specific bank's statement format
2. Add more visualizations (charts, graphs) for savings trends
3. Implement push notifications for savings milestones
4. Add export functionality for savings reports
5. Integrate with payment gateways to actually collect roundoff amounts
