import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/goal_service.dart';
import '../../models/goal_models.dart';
import 'goal_configuration_screen.dart';

class GoalCategorySelectionScreen extends StatefulWidget {
  const GoalCategorySelectionScreen({super.key});

  @override
  State<GoalCategorySelectionScreen> createState() =>
      _GoalCategorySelectionScreenState();
}

class _GoalCategorySelectionScreenState
    extends State<GoalCategorySelectionScreen>
    with TickerProviderStateMixin {
  List<GoalCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  GoalCategory? _selectedCategory;

  late AnimationController _headerAnimationController;
  late AnimationController _gridAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late List<Animation<double>> _cardAnimations = [];

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerAnimationController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _loadCategories();
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _gridAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await GoalService.getCategories();

      // Create staggered animations for each card
      _cardAnimations = List.generate(categories.length, (index) {
        // Calculate start and end values, ensuring end never exceeds 1.0
        final animationDuration = 0.3; // Duration of each animation
        final staggerDelay = 0.1; // Delay between each animation start

        // Calculate start time (clamped to 0.0-1.0)
        final start = (index * staggerDelay).clamp(0.0, 1.0);

        // Calculate end time, ensuring it doesn't exceed 1.0
        final calculatedEnd = start + animationDuration;
        final end = calculatedEnd > 1.0 ? 1.0 : calculatedEnd;

        // Ensure start < end
        final finalStart = start < end ? start : 0.0;
        final finalEnd = end > finalStart
            ? end
            : (finalStart + 0.1).clamp(0.0, 1.0);

        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _gridAnimationController,
            curve: Interval(finalStart, finalEnd, curve: Curves.easeOutCubic),
          ),
        );
      });

      setState(() {
        _categories = categories;
        _isLoading = false;
      });

      // Start grid animation after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _gridAnimationController.forward();
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(GoalCategory category) {
    setState(() {
      _selectedCategory = category;
    });

    // Add a subtle delay for visual feedback
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                GoalConfigurationScreen(category: category),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.0, 0.1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    });
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

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'phone':
        return Icons.phone_iphone_rounded;
      case 'camera':
        return Icons.camera_alt_rounded;
      case 'directions_car':
      case 'car':
        return Icons.directions_car_rounded;
      case 'landscape':
      case 'mountain':
        return Icons.landscape_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'celebration':
      case 'party':
        return Icons.celebration_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'cake':
      case 'birthday':
        return Icons.cake_rounded;
      case 'person':
      case 'other':
        return Icons.person_outline_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'New Goal',
            style: AppTheme.headingSmall.copyWith(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading categories...',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Error loading categories',
                      style: AppTheme.headingSmall.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _loadCategories,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated Header
                  SlideTransition(
                    position: _headerSlideAnimation,
                    child: FadeTransition(
                      opacity: _headerFadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Category',
                            style: AppTheme.headingMedium.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose a category for your savings goal',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Animated Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.95,
                        ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory?.id == category.id;
                      final animation = index < _cardAnimations.length
                          ? _cardAnimations[index]
                          : AlwaysStoppedAnimation(1.0);

                      return _buildAnimatedCategoryCard(
                        category,
                        isSelected,
                        animation,
                        index,
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryIcon(GoalCategory category, Color iconColor) {
    // Always try to use asset icon first, regardless of iconType
    final iconAsset =
        _getIconAsset(category.icon) ?? _getIconAsset(category.name);

    if (iconAsset != null) {
      // Try to use asset icon with animation
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Transform.rotate(
              angle: (1 - value) * 0.2,
              child: Image.asset(
                iconAsset,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to material icon if image fails to load
                  return Icon(
                    _getIconData(category.icon),
                    color: iconColor,
                    size: 36,
                  );
                },
              ),
            ),
          );
        },
      );
    }

    // Fallback to material icon if no asset found
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Icon(_getIconData(category.icon), color: iconColor, size: 36),
        );
      },
    );
  }

  Widget _buildAnimatedCategoryCard(
    GoalCategory category,
    bool isSelected,
    Animation<double> animation,
    int index,
  ) {
    final iconColor = _getColorFromString(category.color);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (animation.value * 0.2),
          child: Opacity(
            opacity: animation.value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - animation.value)),
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onCategorySelected(category),
          borderRadius: BorderRadius.circular(20),
          splashColor: iconColor.withOpacity(0.1),
          highlightColor: iconColor.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconColor.withOpacity(0.15),
                        iconColor.withOpacity(0.05),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? iconColor.withOpacity(0.5)
                    : AppTheme.borderColor.withOpacity(0.3),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? iconColor.withOpacity(0.25)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: isSelected ? 20 : 12,
                  offset: Offset(0, isSelected ? 8 : 4),
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconColor.withOpacity(0.15),
                        iconColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildCategoryIcon(category, iconColor),
                ),
                const SizedBox(height: 16),
                Text(
                  category.name,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isSelected ? iconColor : AppTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
