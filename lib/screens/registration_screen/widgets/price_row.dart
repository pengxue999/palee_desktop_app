import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isNegative;
  final bool isBold;

  const PriceRow({
    super.key,
    required this.label,
    required this.value,
    this.isNegative = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isBold ? AppColors.foreground : AppColors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isNegative
                ? AppColors.destructive
                : (isBold ? AppColors.primary : AppColors.foreground),
          ),
        ),
      ],
    );
  }
}
