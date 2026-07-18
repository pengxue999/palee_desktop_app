import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';

class ActionCard extends StatelessWidget {
  final int stepNum;
  final bool canSave;
  final VoidCallback onSave;
  final VoidCallback onPrint;
  final VoidCallback onCancel;

  const ActionCard({
    super.key,
    required this.stepNum,
    required this.canSave,
    required this.onSave,
    required this.onPrint,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'ບັນທຶກການລົງທະບຽນ',
            icon: Icons.save_rounded,
            variant: AppButtonVariant.success,
            onPressed: canSave ? onSave : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            label: 'ຍົກເລີກ',
            icon: Icons.close_rounded,
            variant: AppButtonVariant.danger,
            onPressed: onCancel,
          ),
        ),
      ],
    );
  }
}
