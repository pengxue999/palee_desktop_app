import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/enum_localization.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({super.key, required this.status, this.padding});

  String _displayStatus() {
    final localizedRegistration = localizeRegistrationStatus(status);
    if (localizedRegistration != status) {
      return localizedRegistration;
    }

    final localizedPayment = localizePaymentMethod(status);
    if (localizedPayment != status) {
      return localizedPayment;
    }

    return status;
  }

  @override
  Widget build(BuildContext context) {
    final displayStatus = _displayStatus();
    final colorTuple =
        AppColors.statusBackgroundColors[displayStatus] ??
        AppColors.statusBackgroundColors[status] ??
        AppColors.statusBackgroundColors[status.toLowerCase()];
    final bgColor = colorTuple?.$1 ?? AppColors.warning;
    final textColor = colorTuple?.$2 ?? AppColors.primaryLight;

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
