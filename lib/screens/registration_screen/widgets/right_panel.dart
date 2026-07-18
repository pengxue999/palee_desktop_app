import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/models/discount_model.dart';
import 'package:palee_elite_training_center/models/fee_model.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/action_card.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/registration_detail_card.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/summary_section.dart';

class RightPanel extends StatelessWidget {
  final int step3num, step4num, step5num;
  final List<FeeModel> selectedFees;
  final ValueChanged<String> onRemove;
  final String academicYear;
  final String registrationDate;
  final String? studentName;
  final int tuitionFee;
  final int totalFee;
  final int discount;
  final int netFee;
  final List<DiscountModel> discounts;
  final String? selectedDiscountId;
  final ValueChanged<String?> onDiscountChanged;
  final Map<String, String> scholarshipStatusByFee;
  final void Function(String feeId, String status) onScholarshipChanged;
  final bool autoRenew;
  final ValueChanged<bool> onAutoRenewChanged;
  final bool canSave;
  final bool discountEnabled;
  final bool isLocked;
  final bool Function(String feeId) isExistingFee;
  final VoidCallback onSave;
  final VoidCallback onPrint;
  final VoidCallback onCancel;

  const RightPanel({
    super.key,
    required this.step3num,
    required this.step4num,
    required this.step5num,
    required this.selectedFees,
    required this.onRemove,
    required this.academicYear,
    required this.registrationDate,
    required this.studentName,
    required this.tuitionFee,
    required this.totalFee,
    required this.discount,
    required this.netFee,
    required this.discounts,
    required this.selectedDiscountId,
    required this.onDiscountChanged,
    required this.scholarshipStatusByFee,
    required this.onScholarshipChanged,
    required this.autoRenew,
    required this.onAutoRenewChanged,
    required this.canSave,
    this.discountEnabled = true,
    this.isLocked = false,
    required this.isExistingFee,
    required this.onSave,
    required this.onPrint,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RegistrationDetailCard(
          stepNum: step3num,
          fees: selectedFees,
          onRemove: onRemove,
          scholarshipStatusByFee: scholarshipStatusByFee,
          onScholarshipChanged: onScholarshipChanged,
          isLocked: isLocked,
          isExistingFee: isExistingFee,
        ),
        const SizedBox(height: 14),
        SummarySection(
          stepNum: step4num,
          academicYear: academicYear,
          registrationDate: registrationDate,
          studentName: studentName,
          tuitionFee: tuitionFee,
          totalFee: totalFee,
          discount: discount,
          netFee: netFee,
          discounts: discounts,
          selectedDiscountId: selectedDiscountId,
          onDiscountChanged: onDiscountChanged,
          discountEnabled: discountEnabled,
          autoRenew: autoRenew,
          onAutoRenewChanged: onAutoRenewChanged,
          canSave: canSave,
        ),
        const SizedBox(height: 20),
        ActionCard(
          stepNum: step5num,
          canSave: canSave,
          onSave: onSave,
          onPrint: onPrint,
          onCancel: onCancel,
        ),
      ],
    );
  }
}
