import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../services/savings_service.dart';
import '../services/profile_service.dart';
import '../services/backend_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/growcoins_logo.dart';
import '../models/goal_models.dart';
import '../models/savings_models.dart';
import '../models/profile_model.dart';
import 'risk_assessment/risk_assessment_intro_screen.dart';
import 'savings_screen.dart';
import 'onboarding/onboarding_setup_profile_screen.dart';
import 'onboarding/goal_category_selection_screen.dart';
import 'onboarding/auto_save_config_screen.dart';
import 'onboarding/onboarding_kyc_screen.dart';
import 'kyc/video_kyc_intro_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';
import 'all_goals_screen.dart';
import 'goal_details_screen.dart';
import '../widgets/video_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Goal> _goals = [];
  SavingsSummary? _savingsSummary;
  bool _isLoading = true;
  int _unreadNotificationCount = 0;
  bool _isKycPending = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _loadData();
    _checkGoalSetup();
    _loadNotificationCount();
    _loadKycStatus();
    _fadeController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
      _loadKycStatus();
    }
  }

  Future<void> _loadKycStatus() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) return;

      final result = await ProfileService.getProfile(userId);
      if (result['success'] && mounted) {
        final profile = UserProfile.fromJson(result['profile']);
        setState(() {
          _isKycPending = !profile.kycInfo.isVerified;
        });
      }
    } catch (e) {
      debugPrint('Error loading KYC status: $e');
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification count: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load goals
      final goalsResponse = await GoalService.getUserGoals();

      // Load savings summary
      SavingsSummary? savingsSummary;
      try {
        savingsSummary = await SavingsService.getSavingsSummary();
        debugPrint('Savings Summary loaded:');
        debugPrint('  Total Savings: ${savingsSummary.totalSavings}');
        debugPrint('  Transaction Count: ${savingsSummary.transactionCount}');
        debugPrint(
          '  Monthly Projection: ${savingsSummary.projections?.monthly.savings}',
        );
        debugPrint(
          '  Yearly Projection: ${savingsSummary.projections?.yearly.savings}',
        );
        debugPrint(
          '  Daily Projection: ${savingsSummary.projections?.daily.savings}',
        );
      } catch (e) {
        debugPrint('Error loading savings: $e');
        debugPrint('Error stack trace: ${StackTrace.current}');
      }

      setState(() {
        _goals = goalsResponse.goals;
        _savingsSummary = savingsSummary;
        _isLoading = false;
      });

      // Debug: Verify state was updated correctly
      debugPrint('=== State Updated ===');
      debugPrint(
        '_savingsSummary after setState: ${_savingsSummary?.totalSavings}',
      );
      debugPrint('_savingsSummary is null: ${_savingsSummary == null}');
      if (_savingsSummary != null) {
        debugPrint('Total Savings in state: ${_savingsSummary!.totalSavings}');
      }
      debugPrint('====================');
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error to user if it's a critical error
      if (mounted && e.toString().contains('Route not found') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Cannot connect')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  Future<void> _checkGoalSetup() async {
    try {
      final setupStatus = await GoalService.getSetupStatus();

      // If user has no goal, navigate to setup profile screen
      if (!setupStatus.hasGoal && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OnboardingSetupProfileScreen(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking goal setup: $e');
    }
  }

  double _calculateTotalBalance() {
    double savingsWallet = _savingsSummary?.totalSavings ?? 0.0;
    double goalInvestments = _goals.fold(
      0.0,
      (sum, goal) => sum + goal.currentAmount,
    );
    return savingsWallet + goalInvestments;
  }

  double _calculateTotalGoalProgress() {
    if (_goals.isEmpty) return 0.0;
    double totalProgress = _goals.fold(
      0.0,
      (sum, goal) => sum + (goal.progressPercentage.clamp(0.0, 100.0)),
    );
    return (totalProgress / _goals.length).clamp(0.0, 100.0);
  }

  String? _getIconAsset(String iconName) {
    final lowerName = iconName.toLowerCase().trim();

    switch (lowerName) {
      case 'home':
        return 'assets/images/3d-home-realistic-icon-design-illustrations-3d-render-design-concept-vector 2.png';
      case 'camera':
      case 'gadget':
        return 'assets/images/3d-camera-icon-png-transformed 2.png';
      case 'trip':
      case 'international trip':
      case 'domestic trip':
      case 'flight':
      case 'landscape':
        return 'assets/images/3d-world-trip-icon-png-transformed-removebg-preview (1) 3.png';
      case 'birthday':
      case 'cake':
        return 'assets/images/cake-with-confetti-happy-birthday-event-anniversary-surprise-sign-symbol-object-cartoon-3d-background-illustration_56104-2293-removebg-preview 2.png';
      case 'party':
      case 'celebration':
        return 'assets/images/istockphoto-1483188505-612x612-removebg-preview 3.png';
      case 'car':
      case 'directions_car':
        return 'assets/images/isometric-view-cute-vintage-car-made-with-generative-ai_878954-202-transformed-removebg-preview 2.png';
      case 'phone':
        return 'assets/images/Asset 1 2.png';
      case 'other':
      case 'person':
        return 'assets/images/abstract-human-symbol-d-icon-social-avatar-online-communication-work-minimalistic-sign-people-user-business-symbology-230189749-transformed-removebg-preview 3.png';
      default:
        return null;
    }
  }

  Widget _buildGoalIcon(String iconName, Color? color, {double? size}) {
    final iconSize = size ?? 32;
    final iconAsset = _getIconAsset(iconName);

    if (iconAsset != null) {
      return Image.asset(
        iconAsset,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        color: null, // Preserve original colors
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.category_rounded,
            size: iconSize,
            color: color ?? AppTheme.primaryColor,
          );
        },
      );
    }

    return Icon(
      Icons.category_rounded,
      size: iconSize,
      color: color ?? AppTheme.primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _calculateTotalBalance();
    final savingsWallet = _savingsSummary?.totalSavings ?? 0.0;
    final goalInvestments = _goals.fold(
      0.0,
      (sum, goal) => sum + goal.currentAmount,
    );
    final totalProgress = _calculateTotalGoalProgress();

    // Debug: Log the values being used in the UI
    debugPrint('=== Home Screen Build ===');
    debugPrint('_savingsSummary is null: ${_savingsSummary == null}');
    debugPrint('savingsWallet value: $savingsWallet');
    debugPrint('totalBalance value: $totalBalance');
    debugPrint('goalInvestments value: $goalInvestments');
    if (_savingsSummary != null) {
      debugPrint(
        '_savingsSummary.totalSavings: ${_savingsSummary!.totalSavings}',
      );
    }
    debugPrint('========================');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Navigation Bar
                        _buildTopBar(),

                        // KYC Pending Banner
                        if (_isKycPending) ...[
                          const SizedBox(height: 12),
                          _buildKycPendingBanner(),
                          const SizedBox(height: 8),
                        ],

                        const SizedBox(height: 20),

                        // Balance Display
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Your Balance',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '₹${totalBalance.toStringAsFixed(0)}',
                            style: AppTheme.headingLarge.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Goal Progression Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildGoalProgressionCard(totalProgress),
                        ),

                        const SizedBox(height: 16),

                        // Setup Auto Save Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildAutoSaveCard(),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildActionButtons(),
                        ),

                        const SizedBox(height: 24),

                        // Savings Wallet and Goal Investments
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildWalletCard(
                                  'Savings Wallet',
                                  savingsWallet,
                                  Icons.account_balance_wallet_rounded,
                                  AppTheme.successColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildWalletCard(
                                  'Goal Investments',
                                  goalInvestments,
                                  Icons.trending_up_rounded,
                                  AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // User Goals Section
                        if (_goals.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildGoalsSection(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Learning Videos Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildLearningVideosSection(),
                        ),

                        const SizedBox(height: 24),

                        // Additional Options
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildAdditionalOptions(),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),

          // Growcoins Logo
          const GrowcoinsLogo(
            width: 120,
            height: 40,
            color: AppTheme.textPrimary,
          ),

          // Notification Bell
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 20),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadNotificationCount();
                    }
                  },
                ),
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99
                          ? '99+'
                          : '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressionCard(double progress) {
    // Show maximum 3 goals
    final displayGoals = _goals.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: (progress / 100).clamp(0.0, 1.0),
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Goal Icons Grid (2x2) - Symmetric Layout
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // First row: 2 goals - perfectly centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGoalIconButton(
                      displayGoals.isNotEmpty
                          ? displayGoals[0].categoryIcon
                          : null,
                      onTap: displayGoals.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GoalDetailsScreen(
                                    goalId: displayGoals[0].id,
                                  ),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _loadData();
                                }
                              });
                            }
                          : null,
                    ),
                    _buildGoalIconButton(
                      displayGoals.length > 1
                          ? displayGoals[1].categoryIcon
                          : null,
                      onTap: displayGoals.length > 1
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GoalDetailsScreen(
                                    goalId: displayGoals[1].id,
                                  ),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _loadData();
                                }
                              });
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Second row: 1 goal + add button - perfectly centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGoalIconButton(
                      displayGoals.length > 2
                          ? displayGoals[2].categoryIcon
                          : null,
                      onTap: displayGoals.length > 2
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GoalDetailsScreen(
                                    goalId: displayGoals[2].id,
                                  ),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _loadData();
                                }
                              });
                            }
                          : null,
                    ),
                    _buildAddGoalButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalIconButton(String? iconName, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: iconName != null
                ? _buildGoalIcon(iconName, Colors.white, size: 42)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildAddGoalButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GoalCategorySelectionScreen(),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }

  Widget _buildAutoSaveCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Check if user has goals
          if (_goals.isEmpty) {
            // If no goals, navigate to goal category selection
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GoalCategorySelectionScreen(),
              ),
            );
            if (result == true) {
              _loadData();
            }
          } else {
            // If user has goals, navigate to auto-save config with the first goal
            // In the future, you could show a dialog to select which goal
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AutoSaveConfigScreen(goal: _goals.first),
              ),
            );
            // Reload data after returning from auto-save config
            _loadData();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Setup Auto Save',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          icon: Icons.add_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GoalCategorySelectionScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 24),
        _buildActionButton(
          icon: Icons.currency_rupee_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SavingsScreen()),
            );
          },
        ),
        const SizedBox(width: 24),
        _buildActionButton(icon: Icons.refresh_rounded, onTap: _loadData),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildWalletCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningVideosSection() {
    // Real YouTube videos about investing and mutual funds
    final videos = [
      {
        'title': 'Best Mutual Funds 2024',
        'subtitle': 'Top performing funds to invest',
        'videoId': 'JUtes-k-VX4',
        'thumbnail': 'https://img.youtube.com/vi/JUtes-k-VX4/mqdefault.jpg',
      },
      {
        'title': 'Smart Investment Strategies',
        'subtitle': 'Diversify your portfolio wisely',
        'videoId': 'ro3v84swtZ4',
        'thumbnail': 'https://img.youtube.com/vi/ro3v84swtZ4/mqdefault.jpg',
      },
      {
        'title': 'Mutual Funds for Beginners',
        'subtitle': 'Complete guide to start investing',
        'videoId': 'T-nmNeW8AM4',
        'thumbnail': 'https://img.youtube.com/vi/T-nmNeW8AM4/mqdefault.jpg',
      },
      {
        'title': '50/30/20 Budget Rule',
        'subtitle': 'How to manage your money effectively',
        'videoId': 'kz6U0axmPSc',
        'thumbnail': 'https://img.youtube.com/vi/kz6U0axmPSc/mqdefault.jpg',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Learning Videos',
              style: AppTheme.headingSmall.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View More >',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < videos.length - 1 ? 12 : 0,
                ),
                child: _buildVideoCard(
                  video['title']!,
                  video['subtitle']!,
                  video['videoId']!,
                  video['thumbnail']!,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(
    String title,
    String subtitle,
    String videoId,
    String thumbnailUrl,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          VideoOverlay.show(context: context, videoId: videoId, title: title);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.3),
                          AppTheme.primaryColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        height: 70,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.3),
                                  AppTheme.primaryColor.withOpacity(0.1),
                                ],
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.3),
                                  AppTheme.primaryColor.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Goals',
              style: AppTheme.headingSmall.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllGoalsScreen(),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
              child: Text(
                'View All >',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _goals.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'No goals yet. Create your first goal!',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < _goals.length - 1 ? 16 : 0,
                      ),
                      child: _buildGoalCard(goal),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(Goal goal) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalDetailsScreen(goalId: goal.id),
            ),
          ).then((result) {
            if (result == true) {
              _loadData();
            }
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Goal Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _buildGoalIcon(goal.categoryIcon, Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          goal.goalName,
                          style: AppTheme.headingSmall.copyWith(fontSize: 17),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          goal.categoryName,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${goal.progressPercentage.toStringAsFixed(1)}%',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ((goal.progressPercentage.clamp(0.0, 100.0)) / 100)
                          .clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: AppTheme.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Amount Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Saved',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹${goal.currentAmount.toStringAsFixed(0)}',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Target',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹${goal.targetAmount.toStringAsFixed(0)}',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Days Remaining
              if (goal.daysRemaining != null && goal.daysRemaining! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${goal.daysRemaining} days left',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      children: [
        _buildOptionCard(
          'Risk Assessment',
          'Complete your risk profile',
          Icons.assessment_rounded,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RiskAssessmentIntroScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          'Roundoff Savings',
          'Save money automatically',
          Icons.savings_rounded,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SavingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKycPendingBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Show options dialog
            final option = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  'Complete KYC Verification',
                  style: AppTheme.headingSmall.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'Choose your preferred method to complete KYC verification',
                  style: AppTheme.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'traditional'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_rounded, size: 20),
                        const SizedBox(width: 8),
                        const Text('Traditional KYC'),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, 'video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_rounded, size: 20),
                        const SizedBox(width: 8),
                        const Text('Video KYC'),
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (option == 'traditional' && mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OnboardingKYCScreen(),
                ),
              );
              if (result == true) {
                _loadKycStatus();
              }
            } else if (option == 'video' && mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideoKycIntroScreen(),
                ),
              );
              if (result == true) {
                _loadKycStatus();
              }
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentColor,
                  AppTheme.accentColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KYC Verification Pending',
                        style: AppTheme.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to complete your verification',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
