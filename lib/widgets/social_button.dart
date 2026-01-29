import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final String? assetIcon;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const SocialButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.assetIcon,
    this.icon,
    this.backgroundColor,
    this.textColor,
  }) : assert(assetIcon != null || icon != null, 'Either assetIcon or icon must be provided');

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.white,
        foregroundColor: textColor ?? Colors.black87,
        elevation: 1,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (assetIcon != null)
             Image.asset(assetIcon!, height: 24, width: 24)
          else
            Icon(icon, size: 24, color: textColor ?? Colors.black87),
            
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
