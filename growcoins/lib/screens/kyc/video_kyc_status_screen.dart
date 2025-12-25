import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/kyc_service.dart';
import '../onboarding/onboarding_financial_info_screen.dart';

class VideoKycStatusScreen extends StatefulWidget {
  final int kycId;
  final String status; // 'pending', 'approved', 'rejected'

  const VideoKycStatusScreen({
    super.key,
    required this.kycId,
    required this.status,
  });

  @override
  State<VideoKycStatusScreen> createState() => _VideoKycStatusScreenState();
}

class _VideoKycStatusScreenState extends State<VideoKycStatusScreen> {
  String _currentStatus = 'pending';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // Poll for status updates (in production, use WebSocket or push notifications)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await KycService.getVideoKycStatus(widget.kycId);
      if (mounted) {
        setState(() {
          _currentStatus = status['status'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking status: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _handleContinue() {
    if (_currentStatus == 'approved') {
      // Navigate to next onboarding step
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingFinancialInfoScreen(
            questionSet: 1,
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'KYC Verification',
          style: AppTheme.headingSmall.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Status Icon
              _buildStatusIcon(),

              const SizedBox(height: 32),

              // Status Title
              Text(
                _getStatusTitle(),
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Status Message
              Text(
                _getStatusMessage(),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Status Details Card
              _buildStatusDetailsCard(),

              const SizedBox(height: 32),

              // Action Button
              if (_currentStatus == 'approved')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: AppTheme.buttonText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (_currentStatus == 'rejected')
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Retry Video KYC',
                          style: AppTheme.buttonText.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _refreshStatus,
                      child: Text(
                        'Refresh Status',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _refreshStatus,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          _isLoading ? 'Checking...' : 'Refresh Status',
                          style: AppTheme.buttonText.copyWith(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We\'ll notify you once verification is complete',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    Color backgroundColor;

    switch (_currentStatus) {
      case 'approved':
        icon = Icons.check_circle_rounded;
        color = AppTheme.successColor;
        backgroundColor = AppTheme.successColor.withOpacity(0.1);
        break;
      case 'rejected':
        icon = Icons.cancel_rounded;
        color = AppTheme.errorColor;
        backgroundColor = AppTheme.errorColor.withOpacity(0.1);
        break;
      default:
        icon = Icons.pending_rounded;
        color = AppTheme.accentColor;
        backgroundColor = AppTheme.accentColor.withOpacity(0.1);
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 64,
        color: color,
      ),
    );
  }

  String _getStatusTitle() {
    switch (_currentStatus) {
      case 'approved':
        return 'Verification Approved!';
      case 'rejected':
        return 'Verification Rejected';
      default:
        return 'Verification Pending';
    }
  }

  String _getStatusMessage() {
    switch (_currentStatus) {
      case 'approved':
        return 'Your identity has been successfully verified. You can now proceed with setting up your financial goals.';
      case 'rejected':
        return 'Your video KYC could not be verified. Please ensure your video is clear and try again.';
      default:
        return 'Your video is under review. Our team will verify your identity and notify you once complete.';
    }
  }

  Widget _buildStatusDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'What\'s Next?',
                style: AppTheme.headingSmall.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_currentStatus == 'pending') ...[
            _buildNextStepItem(
              'Our verification team will review your video',
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              'This usually takes 1-2 business days',
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              'You\'ll receive a notification once verified',
            ),
          ] else if (_currentStatus == 'approved') ...[
            _buildNextStepItem(
              'You can now complete your financial profile',
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              'Start setting up your savings goals',
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              'Access all features of the app',
            ),
          ] else ...[
            _buildNextStepItem(
              'Please ensure your face is clearly visible',
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              'Make sure audio is clear and audible',
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              'State your name and date of birth clearly',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextStepItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

