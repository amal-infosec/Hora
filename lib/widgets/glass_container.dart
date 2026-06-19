import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_themes.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blur = 25,
    this.padding,
    this.opacity = 0.4, // Increased for light mode
  });

  @override
  Widget build(BuildContext context) {
    final isGlass = Provider.of<ThemeProvider>(context).themeMode == ThemeModeType.liquidGlass;

    if (!isGlass) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.black.withAlpha(13)), // 0.05 * 255 approx 13
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5), // 0.02 * 255 approx 5
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((opacity * 255).toInt()),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withAlpha(153)), // 0.6 * 255 = 153 for crisp light borders
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withAlpha(15), // Blue tint soft shadow
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
