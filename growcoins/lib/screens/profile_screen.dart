import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/profile_service.dart';
import '../services/backend_auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_state_service.dart';
import '../models/profile_model.dart';
import '../theme/app_theme.dart';
import '../widgets/growcoins_logo.dart';
import 'edit_profile_screen.dart';
import 'login_selection_screen.dart';
import 'onboarding/onboarding_kyc_screen.dart';
import 'kyc/video_kyc_intro_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _loadProfile();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final result = await ProfileService.getProfile(userId);

      setState(() {
        _isLoading = false;
        if (result['success']) {
          _profile = UserProfile.fromJson(result['profile']);
        } else {
          _error = result['error'] ?? 'Failed to load profile';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading profile: ${e.toString()}';
      });
    }
  }

  Future<void> _navigateToEdit() async {
    if (_profile == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profile: _profile!),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: AppTheme.headingSmall),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Sign out from both services
      await FirebaseAuthService().signOut();
      await BackendAuthService.logout();
      await AuthStateService().clearAuthData();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _error != null
            ? _buildErrorView()
            : _profile == null
            ? _buildEmptyView()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: _buildProfileView(),
              ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text('Error Loading Profile', style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Text(
        'No profile data available',
        style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildProfileView() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 180,
          floating: false,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
              onPressed: _navigateToEdit,
              tooltip: 'Edit Profile',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(color: Colors.white),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const GrowcoinsLogo(
                            width: 40,
                            height: 40,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Profile',
                              style: AppTheme.headingLarge.copyWith(
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Profile Content
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Profile Header Card
              _buildProfileHeaderCard(),

              const SizedBox(height: 24),

              // Personal Information
              _buildSectionCard(
                title: 'Personal Information',
                icon: Icons.person_outline_rounded,
                children: [
                  _buildInfoRow(
                    'Full Name',
                    _profile!.personalInfo.displayName,
                  ),
                  if (_profile!.personalInfo.email != null)
                    _buildInfoRow('Email', _profile!.personalInfo.email!),
                  if (_profile!.personalInfo.phoneNumber != null)
                    _buildInfoRow('Phone', _profile!.personalInfo.phoneNumber!),
                  if (_profile!.personalInfo.dateOfBirth != null)
                    _buildInfoRow(
                      'Date of Birth',
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(_profile!.personalInfo.dateOfBirth!),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Address Information
              _buildSectionCard(
                title: 'Address',
                icon: Icons.location_on_outlined,
                children: [
                  _buildInfoRow('Address', _profile!.address.fullAddress),
                ],
              ),

              const SizedBox(height: 16),

              // Financial Information
              _buildSectionCard(
                title: 'Financial Information',
                icon: Icons.account_balance_wallet_outlined,
                children: [
                  _buildInfoRow(
                    'Account Balance',
                    '₹${_profile!.financialInfo.accountBalance.toStringAsFixed(2)}',
                    valueColor: AppTheme.primaryColor,
                    valueStyle: AppTheme.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_profile!.financialInfo.accountNumber != null)
                    _buildInfoRow(
                      'Account Number',
                      _profile!.financialInfo.accountNumber!,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // KYC Information
              _buildSectionCard(
                title: 'KYC Status',
                icon: Icons.verified_user_outlined,
                children: [
                  _buildInfoRow(
                    'KYC Status',
                    _profile!.kycInfo.kycStatus?.toUpperCase() ??
                        'NOT VERIFIED',
                    valueColor: _profile!.kycInfo.isVerified
                        ? AppTheme.successColor
                        : AppTheme.textSecondary,
                    valueStyle: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_profile!.kycInfo.panNumber != null)
                    _buildInfoRow('PAN Number', _profile!.kycInfo.panNumber!),
                  if (_profile!.kycInfo.aadharNumber != null)
                    _buildInfoRow(
                      'Aadhar Number',
                      _profile!.kycInfo.aadharNumber!,
                    ),
                  // Show KYC options if not verified
                  if (!_profile!.kycInfo.isVerified) ...[
                    const SizedBox(height: 16),
                    _buildKycActionButtons(),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Account Information
              _buildSectionCard(
                title: 'Account Information',
                icon: Icons.info_outline_rounded,
                children: [
                  _buildInfoRow('Username', _profile!.username),
                  _buildInfoRow(
                    'Account Created',
                    DateFormat(
                      'MMM dd, yyyy',
                    ).format(_profile!.timestamps.createdAt),
                  ),
                  if (_profile!.lastLogin != null)
                    _buildInfoRow(
                      'Last Login',
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(_profile!.lastLogin!),
                    ),
                  _buildInfoRow(
                    'Biometric Auth',
                    _profile!.biometricEnabled ? 'Enabled' : 'Disabled',
                    valueColor: _profile!.biometricEnabled
                        ? AppTheme.successColor
                        : AppTheme.textSecondary,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeaderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
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
        child: Row(
          children: [
            // Profile Picture
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: _profile!.personalInfo.profilePictureUrl != null
                  ? ClipOval(
                      child: Image.network(
                        _profile!.personalInfo.profilePictureUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: AppTheme.primaryColor,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile!.personalInfo.displayName,
                    style: AppTheme.headingMedium.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${_profile!.username}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (_profile!.personalInfo.email != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _profile!.personalInfo.email!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTheme.headingSmall.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style:
                  valueStyle ??
                  AppTheme.bodyLarge.copyWith(
                    color: valueColor ?? AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Complete your KYC verification',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingKYCScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadProfile();
                  }
                },
                icon: const Icon(Icons.badge_rounded, size: 18),
                label: const Text('Traditional KYC'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VideoKycIntroScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadProfile();
                  }
                },
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: const Text('Video KYC'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
