import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/risk_assessment_service.dart';
import '../../theme/app_theme.dart';
import 'risk_assessment_detail_screen.dart';
import 'risk_assessment_intro_screen.dart';

class RiskAssessmentHistoryScreen extends StatefulWidget {
  const RiskAssessmentHistoryScreen({super.key});

  @override
  State<RiskAssessmentHistoryScreen> createState() =>
      _RiskAssessmentHistoryScreenState();
}

class _RiskAssessmentHistoryScreenState
    extends State<RiskAssessmentHistoryScreen> {
  List<Map<String, dynamic>> _assessments = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final assessments = await RiskAssessmentService.getAssessmentHistory();
      setState(() {
        _assessments = assessments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Color _getRiskProfileColor(String profile) {
    switch (profile) {
      case 'Conservative':
        return AppTheme.successColor;
      case 'Moderate':
        return AppTheme.primaryColor;
      case 'Moderately Aggressive':
        return AppTheme.warningColor;
      case 'Aggressive':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Assessment History', style: AppTheme.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading history',
                          style: AppTheme.headingSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Unknown error',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadHistory,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _assessments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.assessment_outlined,
                                size: 64,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Assessments Yet',
                              style: AppTheme.headingMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete your first risk assessment to see it here',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RiskAssessmentIntroScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Take Assessment'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _assessments.length,
                          itemBuilder: (context, index) {
                            final assessment = _assessments[index];
                            final dateStr = assessment['completed_at'] ?? '';
                            DateTime? date;
                            try {
                              date = DateTime.parse(dateStr);
                            } catch (e) {
                              // Handle date parsing error
                            }

                            final riskProfile = assessment['risk_profile'] ?? 'Unknown';
                            final totalScore = assessment['total_score'] ?? 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: AppTheme.elevatedCardDecoration,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RiskAssessmentDetailScreen(
                                            assessmentId: assessment['id'],
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          // Risk Profile Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getRiskProfileColor(
                                                      riskProfile)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getRiskProfileColor(
                                                    riskProfile),
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              riskProfile,
                                              style: AppTheme.labelLarge.copyWith(
                                                color: _getRiskProfileColor(
                                                    riskProfile),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Score: $totalScore / 20',
                                                  style: AppTheme.bodyLarge.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                if (date != null)
                                                  Text(
                                                    DateFormat('MMM dd, yyyy • hh:mm a')
                                                        .format(date),
                                                    style: AppTheme.bodySmall.copyWith(
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    'Date not available',
                                                    style: AppTheme.bodySmall.copyWith(
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Arrow icon
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 18,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

