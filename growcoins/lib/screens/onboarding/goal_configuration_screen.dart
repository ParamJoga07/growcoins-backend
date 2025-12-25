import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/goal_service.dart';
import '../../models/goal_models.dart';
import '../../services/api_service.dart' show ApiException;
import 'goal_created_screen.dart';

class GoalConfigurationScreen extends StatefulWidget {
  final GoalCategory category;

  const GoalConfigurationScreen({super.key, required this.category});

  @override
  State<GoalConfigurationScreen> createState() =>
      _GoalConfigurationScreenState();
}

class _GoalConfigurationScreenState extends State<GoalConfigurationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _goalNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  bool _isLoading = false;
  String _selectedTimePeriod = '6M'; // 6M, 9M, 1Y, 1.5Y, 2Y, 2.5Y, 3Y, 4Y, 5Y

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Pre-fill goal name with category name
    _goalNameController.text = '${widget.category.name} Goal';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  DateTime _calculateTargetDate(String timePeriod) {
    final now = DateTime.now();
    switch (timePeriod) {
      case '6M':
        return DateTime(now.year, now.month + 6, now.day);
      case '9M':
        return DateTime(now.year, now.month + 9, now.day);
      case '1Y':
        return DateTime(now.year + 1, now.month, now.day);
      case '1.5Y':
        return DateTime(now.year + 1, now.month + 6, now.day);
      case '2Y':
        return DateTime(now.year + 2, now.month, now.day);
      case '2.5Y':
        return DateTime(now.year + 2, now.month + 6, now.day);
      case '3Y':
        return DateTime(now.year + 3, now.month, now.day);
      case '4Y':
        return DateTime(now.year + 4, now.month, now.day);
      case '5Y':
        return DateTime(now.year + 5, now.month, now.day);
      default:
        return DateTime(now.year, now.month + 6, now.day);
    }
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final targetAmount = double.parse(_targetAmountController.text);
      final targetDate = _calculateTargetDate(_selectedTimePeriod);

      final request = CreateGoalRequest(
        categoryId: widget.category.id,
        goalName: _goalNameController.text.trim(),
        targetAmount: targetAmount,
        targetDate: targetDate,
      );

      final createdGoal = await GoalService.createGoal(request);

      if (mounted) {
        // Navigate to goal created screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GoalCreatedScreen(goal: createdGoal, category: widget.category),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        if (e.errors != null && e.errors!.isNotEmpty) {
          errorMessage = e.errors!.first['msg'] ?? e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating goal: ${e.toString()}',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Widget _buildCategoryIcon(GoalCategory category, Color iconColor) {
    // Always try to use asset icon first, regardless of iconType
    final iconAsset =
        _getIconAsset(category.icon) ?? _getIconAsset(category.name);

    if (iconAsset != null) {
      // Use asset icon without color tinting to preserve original colors
      return Image.asset(
        iconAsset,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        // Don't apply color filter to preserve original image colors
        color: null,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to material icon if image fails to load
          return Icon(_getIconData(category.icon), color: iconColor, size: 28);
        },
      );
    }

    // Fallback to material icon if no asset found
    return Icon(_getIconData(category.icon), color: iconColor, size: 28);
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
    final categoryColor = _getColorFromString(widget.category.color);
    // Use light shades of the category color throughout
    final categoryGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [categoryColor.withOpacity(0.6), categoryColor.withOpacity(0.4)],
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: categoryColor.withOpacity(0.7),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: categoryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'New Goal',
            style: AppTheme.headingSmall.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Header with Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor.withOpacity(0.08),
                          categoryColor.withOpacity(0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                categoryColor.withOpacity(0.2),
                                categoryColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: categoryColor.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _buildCategoryIcon(
                            widget.category,
                            categoryColor.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category.name,
                                style: AppTheme.headingSmall.copyWith(
                                  color: categoryColor.withOpacity(0.9),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Setup your ${widget.category.name.toLowerCase()} goal',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Goal Name
                  Text(
                    'Goal Name',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _goalNameController,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter goal name',
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: categoryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildCategoryIcon(
                          widget.category,
                          categoryColor.withOpacity(0.9),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: categoryColor.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: categoryColor.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: categoryColor.withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter goal name';
                      }
                      if (value.length < 3) {
                        return 'Goal name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Target Amount',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Target Amount
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor.withOpacity(0.15),
                          categoryColor.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Target Amount',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: categoryColor.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹',
                              style: AppTheme.headingMedium.copyWith(
                                color: categoryColor.withOpacity(0.9),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _targetAmountController,
                                keyboardType: TextInputType.number,
                                style: AppTheme.headingMedium.copyWith(
                                  color: categoryColor.withOpacity(0.9),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: categoryColor.withOpacity(0.4),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter target amount';
                                  }
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount < 100) {
                                    return 'Amount must be at least ₹100';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Target Time
                  Text(
                    'Target Time',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor.withOpacity(0.1),
                          categoryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTimeOption(
                            '6M',
                            '6 Months',
                            categoryColor,
                            categoryGradient,
                          ),
                          const SizedBox(width: 6),
                          _buildTimeOption(
                            '9M',
                            '9 Months',
                            categoryColor,
                            categoryGradient,
                          ),
                          const SizedBox(width: 6),
                          _buildTimeOption(
                            '1Y',
                            '1 Year',
                            categoryColor,
                            categoryGradient,
                          ),
                          const SizedBox(width: 6),
                          _buildTimeOption(
                            '1.5Y',
                            '1.5 Years',
                            categoryColor,
                            categoryGradient,
                          ),
                          const SizedBox(width: 6),
                          _buildTimeOption(
                            '2Y',
                            '2 Years',
                            categoryColor,
                            categoryGradient,
                          ),
                          const SizedBox(width: 6),
                          _buildTimeOption(
                            '2.5Y',
                            '2.5 Years',
                            categoryColor,
                            categoryGradient,
                          ),
                          const SizedBox(width: 6),
                          _buildTimeOption(
                            '3Y',
                            '3 Years',
                            categoryColor,
                            categoryGradient,
                          ),
                          const SizedBox(width: 6),
                          _buildTimeOption(
                            '4Y',
                            '4 Years',
                            categoryColor,
                            categoryGradient,
                          ),
                          const SizedBox(width: 6),
                          _buildTimeOption(
                            '5Y',
                            '5 Years',
                            categoryColor,
                            categoryGradient,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Start Goal Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor.withOpacity(0.7),
                          categoryColor.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createGoal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Start Goal',
                                  style: AppTheme.buttonText.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOption(
    String value,
    String label,
    Color categoryColor,
    LinearGradient categoryGradient,
  ) {
    final isSelected = _selectedTimePeriod == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTimePeriod = value;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 95, // Fixed width for horizontal scrolling
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? categoryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTheme.bodyLarge.copyWith(
                  color: isSelected ? Colors.white : categoryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : categoryColor.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
