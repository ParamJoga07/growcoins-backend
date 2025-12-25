# Mutual Fund API Documentation

## 📋 Overview

The Mutual Fund API provides access to real-time mutual fund data from the Indian market using the MFapi.in free API. It helps users discover best-performing mutual funds based on their risk profile and investment horizon (short-term vs long-term).

---

## 🔗 Base URL

```
http://localhost:3001/api/mutual-funds
```

**Note:** For Android Emulator, use `http://10.0.2.2:3001/api/mutual-funds`  
**Note:** For iOS Simulator, use `http://localhost:3001/api/mutual-funds`  
**Note:** For physical devices, use your computer's IP address: `http://YOUR_IP:3001/api/mutual-funds`

---

## 📡 API Endpoints

### 1. Get Recommended Mutual Funds for User

**Endpoint:** `GET /api/mutual-funds/recommendations/:user_id`

**Description:** Get personalized mutual fund recommendations based on user's risk profile and investment horizon.

**URL Parameters:**
- `user_id` (required): Integer - The user's ID

**Query Parameters:**
- `horizon` (optional): String - Investment horizon (`short-term` or `long-term`, default: `long-term`)
- `limit` (optional): Integer - Number of recommendations (1-20, default: 10)

**Success Response (200 OK):**
```json
{
  "success": true,
  "user_id": 1,
  "risk_profile": "Moderate",
  "investment_horizon": "long-term",
  "recommendations": [
    {
      "scheme_code": 120503,
      "scheme_name": "Quant Small Cap Fund Direct Plan Growth",
      "category": "Equity",
      "returns": {
        "absolute_return": 45.23,
        "annualized_return": 38.50,
        "period_days": 365,
        "latest_nav": 125.45,
        "oldest_nav": 86.35
      },
      "risk_level": "High",
      "suitability": "Highly Suitable",
      "latest_nav": 125.45,
      "period_days": 365
    },
    {
      "scheme_code": 120465,
      "scheme_name": "Nippon India Small Cap Fund Direct Growth",
      "category": "Equity",
      "returns": {
        "absolute_return": 38.93,
        "annualized_return": 35.20,
        "period_days": 365,
        "latest_nav": 98.32,
        "oldest_nav": 70.85
      },
      "risk_level": "High",
      "suitability": "Suitable",
      "latest_nav": 98.32,
      "period_days": 365
    }
  ],
  "count": 10
}
```

**Error Responses:**
- `400 Bad Request`: Validation errors
- `404 Not Found`: User not found
- `500 Internal Server Error`: Server error or API failure

---

### 2. Search Mutual Funds

**Endpoint:** `GET /api/mutual-funds/search`

**Description:** Search for mutual funds by name.

**Query Parameters:**
- `q` (required): String - Search query (fund name)
- `limit` (optional): Integer - Number of results (1-50, default: 20)

**Success Response (200 OK):**
```json
{
  "success": true,
  "query": "small cap",
  "results": [
    {
      "scheme_code": 120503,
      "scheme_name": "Quant Small Cap Fund Direct Plan Growth",
      "category": "Equity",
      "risk_level": "High"
    },
    {
      "scheme_code": 120465,
      "scheme_name": "Nippon India Small Cap Fund Direct Growth",
      "category": "Equity",
      "risk_level": "High"
    }
  ],
  "count": 2
}
```

---

### 3. Get Scheme Details

**Endpoint:** `GET /api/mutual-funds/scheme/:scheme_code`

**Description:** Get detailed information about a specific mutual fund scheme.

**URL Parameters:**
- `scheme_code` (required): Integer - The scheme code

**Success Response (200 OK):**
```json
{
  "success": true,
  "scheme": {
    "scheme_code": 120503,
    "scheme_name": "Quant Small Cap Fund Direct Plan Growth",
    "fund_house": "Quant Mutual Fund",
    "scheme_type": "Open Ended Schemes",
    "scheme_category": "Equity Scheme - Small Cap Fund",
    "category": "Equity",
    "risk_level": "High",
    "returns": {
      "absolute_return": 45.23,
      "annualized_return": 38.50,
      "period_days": 365,
      "latest_nav": 125.45,
      "oldest_nav": 86.35
    },
    "nav_history": [
      {
        "date": "15-01-2025",
        "nav": "125.45"
      },
      {
        "date": "14-01-2025",
        "nav": "124.89"
      }
    ],
    "latest_nav": 125.45
  }
}
```

---

### 4. Get Best Performing Funds (General)

**Endpoint:** `GET /api/mutual-funds/best-performing`

**Description:** Get best performing funds with custom filters.

**Query Parameters:**
- `horizon` (optional): String - Investment horizon (`short-term` or `long-term`, default: `long-term`)
- `category` (optional): String - Fund category filter (e.g., `equity`, `debt`, `hybrid`)
- `risk_profile` (optional): String - Risk profile (`Conservative`, `Moderate`, `Aggressive`, default: `Moderate`)
- `limit` (optional): Integer - Number of results (1-20, default: 10)

**Success Response (200 OK):**
```json
{
  "success": true,
  "filters": {
    "horizon": "long-term",
    "category": null,
    "risk_profile": "Moderate"
  },
  "funds": [
    {
      "scheme_code": 120503,
      "scheme_name": "Quant Small Cap Fund Direct Plan Growth",
      "category": "Equity",
      "returns": {
        "absolute_return": 45.23,
        "annualized_return": 38.50,
        "period_days": 365,
        "latest_nav": 125.45,
        "oldest_nav": 86.35
      },
      "risk_level": "High",
      "suitability": "Highly Suitable",
      "latest_nav": 125.45,
      "period_days": 365
    }
  ],
  "count": 10
}
```

---

## 🎯 Investment Horizon Guide

### Long-Term Investment (> 3 years)
- **Recommended Categories:** Equity, ELSS, Hybrid
- **Risk Tolerance:** Moderate to Aggressive
- **Returns Focus:** Annualized returns over 1+ years
- **Best For:** Goals like retirement, child education, home purchase

### Short-Term Investment (< 3 years)
- **Recommended Categories:** Debt, Liquid, Income
- **Risk Tolerance:** Conservative to Moderate
- **Returns Focus:** Absolute returns over recent period
- **Best For:** Emergency fund, short-term goals, capital preservation

---

## 📊 Risk Profile Mapping

| Risk Profile | Suitable Risk Levels | Recommended Categories |
|-------------|---------------------|----------------------|
| **Conservative** | Low, Moderate | Debt, Liquid, Income, Hybrid |
| **Moderate** | Moderate, Moderate-High | Large Cap Equity, Hybrid, Balanced |
| **Aggressive** | Moderate, Moderate-High, High | Small Cap, Mid Cap, Sectoral, Thematic |

---

## 📱 Flutter Integration Guide

### 1. Create Mutual Fund Service

Create a new file `lib/services/mutual_fund_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class MutualFundService {
  static const String baseUrl = 'http://localhost:3001/api/mutual-funds';
  // For Android Emulator: 'http://10.0.2.2:3001/api/mutual-funds'
  // For iOS Simulator: 'http://localhost:3001/api/mutual-funds'
  // For physical device: 'http://YOUR_IP:3001/api/mutual-funds'

  // Get recommended funds for user
  static Future<Map<String, dynamic>> getRecommendations(
    int userId, {
    String horizon = 'long-term',
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recommendations/$userId?horizon=$horizon&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to get recommendations',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Search mutual funds
  static Future<Map<String, dynamic>> searchFunds(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to search funds',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get scheme details
  static Future<Map<String, dynamic>> getSchemeDetails(int schemeCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/scheme/$schemeCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to get scheme details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get best performing funds
  static Future<Map<String, dynamic>> getBestPerforming({
    String horizon = 'long-term',
    String? category,
    String riskProfile = 'Moderate',
    int limit = 10,
  }) async {
    try {
      String url = '$baseUrl/best-performing?horizon=$horizon&risk_profile=$riskProfile&limit=$limit';
      if (category != null) {
        url += '&category=$category';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to get best performing funds',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
```

### 2. Create Mutual Fund Model

Create a new file `lib/models/mutual_fund_model.dart`:

```dart
class MutualFund {
  final int schemeCode;
  final String schemeName;
  final String category;
  final String riskLevel;
  final String suitability;
  final FundReturns returns;
  final double latestNav;
  final int periodDays;

  MutualFund({
    required this.schemeCode,
    required this.schemeName,
    required this.category,
    required this.riskLevel,
    required this.suitability,
    required this.returns,
    required this.latestNav,
    required this.periodDays,
  });

  factory MutualFund.fromJson(Map<String, dynamic> json) {
    return MutualFund(
      schemeCode: json['scheme_code'],
      schemeName: json['scheme_name'],
      category: json['category'],
      riskLevel: json['risk_level'],
      suitability: json['suitability'],
      returns: FundReturns.fromJson(json['returns']),
      latestNav: (json['latest_nav'] as num).toDouble(),
      periodDays: json['period_days'],
    );
  }
}

class FundReturns {
  final double absoluteReturn;
  final double? annualizedReturn;
  final int periodDays;
  final double latestNav;
  final double oldestNav;

  FundReturns({
    required this.absoluteReturn,
    this.annualizedReturn,
    required this.periodDays,
    required this.latestNav,
    required this.oldestNav,
  });

  factory FundReturns.fromJson(Map<String, dynamic> json) {
    return FundReturns(
      absoluteReturn: (json['absolute_return'] as num).toDouble(),
      annualizedReturn: json['annualized_return'] != null
          ? (json['annualized_return'] as num).toDouble()
          : null,
      periodDays: json['period_days'],
      latestNav: (json['latest_nav'] as num).toDouble(),
      oldestNav: (json['oldest_nav'] as num).toDouble(),
    );
  }
}
```

### 3. Usage Example

```dart
import 'package:flutter/material.dart';
import 'services/mutual_fund_service.dart';
import 'models/mutual_fund_model.dart';

class MutualFundRecommendationsScreen extends StatefulWidget {
  final int userId;

  const MutualFundRecommendationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MutualFundRecommendationsScreenState createState() => _MutualFundRecommendationsScreenState();
}

class _MutualFundRecommendationsScreenState extends State<MutualFundRecommendationsScreen> {
  List<MutualFund>? funds;
  bool isLoading = true;
  String? error;
  String selectedHorizon = 'long-term';

  @override
  void initState() {
    super.initState();
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final result = await MutualFundService.getRecommendations(
      widget.userId,
      horizon: selectedHorizon,
    );

    setState(() {
      isLoading = false;
      if (result['success']) {
        funds = (result['recommendations'] as List)
            .map((f) => MutualFund.fromJson(f))
            .toList();
      } else {
        error = result['error'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mutual Fund Recommendations')),
      body: Column(
        children: [
          // Horizon selector
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedHorizon == 'long-term'
                        ? null
                        : () {
                            setState(() => selectedHorizon = 'long-term');
                            loadRecommendations();
                          },
                    child: Text('Long Term'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedHorizon == 'short-term'
                        ? null
                        : () {
                            setState(() => selectedHorizon = 'short-term');
                            loadRecommendations();
                          },
                    child: Text('Short Term'),
                  ),
                ),
              ],
            ),
          ),
          // Fund list
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text('Error: $error'))
                    : funds == null || funds!.isEmpty
                        ? Center(child: Text('No recommendations found'))
                        : ListView.builder(
                            itemCount: funds!.length,
                            itemBuilder: (context, index) {
                              final fund = funds![index];
                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  title: Text(fund.schemeName),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Category: ${fund.category}'),
                                      Text('Risk: ${fund.riskLevel}'),
                                      Text(
                                        'Returns: ${fund.returns.annualizedReturn?.toStringAsFixed(2) ?? fund.returns.absoluteReturn.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text('₹${fund.latestNav.toStringAsFixed(2)}'),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🧪 Testing with cURL

### Get Recommendations
```bash
curl -X GET "http://localhost:3001/api/mutual-funds/recommendations/1?horizon=long-term&limit=10"
```

### Search Funds
```bash
curl -X GET "http://localhost:3001/api/mutual-funds/search?q=small%20cap&limit=10"
```

### Get Scheme Details
```bash
curl -X GET "http://localhost:3001/api/mutual-funds/scheme/120503"
```

### Get Best Performing
```bash
curl -X GET "http://localhost:3001/api/mutual-funds/best-performing?horizon=long-term&risk_profile=Moderate&limit=10"
```

---

## 📝 Notes

1. **API Source**: Uses MFapi.in free API (no authentication required)
2. **Data Updates**: Mutual fund data is updated 3 times daily
3. **Performance**: Calculations are based on available NAV history
4. **Risk Matching**: Funds are filtered based on user's risk profile from `invest_profiles` table
5. **Caching**: Consider implementing caching for better performance
6. **Rate Limiting**: Be mindful of API rate limits when making multiple requests

---

## 🔒 Important Considerations

1. **Disclaimer**: Mutual fund investments are subject to market risks. Past performance doesn't guarantee future returns.
2. **User Education**: Always display appropriate disclaimers in your app
3. **Data Accuracy**: Verify NAV data with official sources before making investment decisions
4. **Regulatory Compliance**: Ensure compliance with SEBI regulations for investment advisory services

---

## 🚀 Future Enhancements

1. **Caching Layer**: Implement Redis or in-memory caching for frequently accessed data
2. **SIP Calculator**: Add SIP (Systematic Investment Plan) calculator
3. **Portfolio Tracking**: Allow users to track their mutual fund investments
4. **Alerts**: Set up alerts for NAV changes or fund performance milestones
5. **Comparison Tool**: Allow users to compare multiple funds side-by-side

