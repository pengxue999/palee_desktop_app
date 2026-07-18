import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class LeftPanel extends StatelessWidget {
  final Widget child;
  const LeftPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
        width: 520,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 520,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.info,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'ແບບຟອມບັນທຶກການສອນ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
