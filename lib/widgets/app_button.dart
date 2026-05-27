import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studentology/core/theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final bool fullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? AppTheme.primaryAccent;
    final minSize = fullWidth
        ? const Size(double.infinity, 50)
        : const Size(0, 50);

    final labelStyle = GoogleFonts.roboto(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? effectiveColor : Colors.white,
              ),
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          foregroundColor: effectiveColor,
          side: BorderSide(color: effectiveColor, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: labelStyle,
        ),
        child: child,
      );
    }

    final cartoonSide = isDark
        ? BorderSide.none
        : const BorderSide(color: AppTheme.cartoonBorder, width: 1.5);

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: minSize,
        backgroundColor: effectiveColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: effectiveColor.withOpacity(0.45),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: cartoonSide,
        ),
        textStyle: labelStyle,
      ),
      child: child,
    );
  }
}
