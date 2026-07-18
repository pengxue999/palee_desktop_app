import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';

class CustomDataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const CustomDataRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 16, color: AppColors.mutedForeground),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: bold ? 20 : 16,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color: AppColors.foreground,
        ),
      ),
    ],
  );
}
