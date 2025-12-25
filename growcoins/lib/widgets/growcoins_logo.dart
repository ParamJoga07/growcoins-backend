import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GrowcoinsLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const GrowcoinsLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo-growcoins.png',
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image fails to load
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            size: width != null ? width! * 0.6 : 40,
            color: color ?? AppTheme.primaryColor,
          ),
        );
      },
    );
  }
}

// Logo with text variant (if needed)
class GrowcoinsLogoWithText extends StatelessWidget {
  final double? logoSize;
  final double? textSize;
  final Color? color;
  final MainAxisAlignment alignment;

  const GrowcoinsLogoWithText({
    super.key,
    this.logoSize = 60,
    this.textSize = 24,
    this.color,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        GrowcoinsLogo(width: logoSize, height: logoSize, color: color),
        const SizedBox(width: 12),
        Text(
          'Growcoins',
          style: AppTheme.headingMedium.copyWith(
            fontSize: textSize,
            color: color,
          ),
        ),
      ],
    );
  }
}
