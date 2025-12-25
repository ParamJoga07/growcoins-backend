import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/investment_plan_model.dart';
import '../../services/investment_plan_service.dart';
import '../../services/api_service.dart' show ApiException;
import '../../widgets/portfolio_donut_chart.dart';
import 'payment_mandate_screen.dart';

class InvestmentPlanDetailsScreen extends StatefulWidget {
  final String? riskProfile;
  final int? goalId;

  const InvestmentPlanDetailsScreen({
    super.key,
    this.riskProfile,
    this.goalId,
  });

  @override
  State<InvestmentPlanDetailsScreen> createState() =>
      _InvestmentPlanDetailsScreenState();
}

class _InvestmentPlanDetailsScreenState
    extends State<InvestmentPlanDetailsScreen> {
  InvestmentPlan? _plan;
  bool _isLoading = true;
  String? _error;
  String _selectedFrequency = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to get existing plan first
      InvestmentPlan? existingPlan = await InvestmentPlanService.getPlan(
        goalId: widget.goalId,
      );

      if (existingPlan != null) {
        setState(() {
          _plan = existingPlan;
          _selectedFrequency = existingPlan.autoSave.frequency;
          _isLoading = false;
        });
      } else {
        // Generate new plan
        final plan = await InvestmentPlanService.generatePlan(
          goalId: widget.goalId,
          frequency: _selectedFrequency,
        );
        setState(() {
          _plan = plan;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load investment plan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFrequency(String frequency) async {
    if (_plan == null) return;

    setState(() {
      _selectedFrequency = frequency;
      _isLoading = true;
    });

    try {
      final updatedPlan = await InvestmentPlanService.updateAutoSave(
        frequency: frequency,
        monthlyAmount: _plan!.autoSave.monthlyAmount,
        durationMonths: _plan!.autoSave.durationMonths,
        goalId: widget.goalId,
      );

      setState(() {
        _plan = updatedPlan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update frequency: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _navigateToPaymentMandate() {
    if (_plan == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMandateScreen(
          plan: _plan!,
          goalId: widget.goalId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Investment Planning',
          style: AppTheme.headingSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: AppTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadPlan,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _plan == null
                  ? const Center(child: Text('No plan available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Risk Profile Section
                          _buildRiskProfileSection(),
                          const SizedBox(height: 24),

                          // Personalized Plan Text
                          Text(
                            _plan!.portfolio.description.isNotEmpty
                                ? _plan!.portfolio.description
                                : 'Here is your personalized investment plan',
                            style: AppTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Auto Save Card
                          _buildAutoSaveCard(),
                          const SizedBox(height: 24),

                          // Edit Goal Button
                          OutlinedButton(
                            onPressed: () {
                              // Navigate to edit goal screen
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Edit Goal'),
                          ),
                          const SizedBox(height: 24),

                          // Portfolio Allocation
                          Text(
                            'According to your Risk Folio, We have curated the best investment portfolio',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Portfolio Chart
                          Center(
                            child: PortfolioDonutChart(
                              allocations: _plan!.portfolio.allocations,
                              size: 220,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Allocation Legend
                          _buildAllocationLegend(),
                          const SizedBox(height: 24),

                          // Mutual Fund Details
                          ..._plan!.portfolio.allocations
                              .map((alloc) => _buildMutualFundCard(alloc))
                              .toList(),

                          const SizedBox(height: 24),

                          // Next Button
                          ElevatedButton(
                            onPressed: _navigateToPaymentMandate,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                            child: const Text('Next >'),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildRiskProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are a',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _plan!.riskProfileDisplay,
            style: AppTheme.headingMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              // Navigate to retake assessment
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text('Retake Assessment'),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSaveCard() {
    final autoSave = _plan!.autoSave;
    final amount = autoSave.getAmountForFrequency();
    final amountText = _selectedFrequency == 'monthly'
        ? '₹${amount.toStringAsFixed(0)} /month'
        : _selectedFrequency == 'weekly'
            ? '₹${amount.toStringAsFixed(0)} /week'
            : '₹${amount.toStringAsFixed(0)} /day';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auto Save',
            style: AppTheme.headingSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          // Frequency Selector
          Row(
            children: [
              Expanded(
                child: _FrequencyButton(
                  label: 'Monthly',
                  isSelected: _selectedFrequency == 'monthly',
                  onTap: () => _updateFrequency('monthly'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FrequencyButton(
                  label: 'Weekly',
                  isSelected: _selectedFrequency == 'weekly',
                  onTap: () => _updateFrequency('weekly'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FrequencyButton(
                  label: 'Daily',
                  isSelected: _selectedFrequency == 'daily',
                  onTap: () => _updateFrequency('daily'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                amountText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'for ${autoSave.durationMonths} Months',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _plan!.portfolio.allocations.map((alloc) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: alloc.getCategoryColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${alloc.percentage.toStringAsFixed(0)}% ${alloc.category}',
              style: AppTheme.bodyMedium,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMutualFundCard(MutualFundAllocation allocation) {
    final fundDetails = allocation.fundDetails;
    final color = allocation.getCategoryColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allocation.schemeName,
                      style: AppTheme.headingSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${allocation.amount.toStringAsFixed(0)}',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (fundDetails != null) ...[
                          Text(
                            ' ${fundDetails.planType ?? 'Direct'}',
                            style: AppTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            fundDetails.getRatingStars(),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (fundDetails?.annualizedReturn != null)
                    Text(
                      '${fundDetails!.annualizedReturn!.toStringAsFixed(1)}% p.a.',
                      style: AppTheme.headingSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    allocation.category,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FrequencyButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

