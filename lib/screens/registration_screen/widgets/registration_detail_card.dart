import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/format_utils.dart';
import 'package:palee_elite_training_center/models/fee_model.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/panel_card.dart';

class RegistrationDetailCard extends StatelessWidget {
  final int stepNum;
  final List<FeeModel> fees;
  final ValueChanged<String> onRemove;
  final Map<String, String> scholarshipStatusByFee;
  final void Function(String feeId, String status) onScholarshipChanged;
  // ການລົງທະບຽນຈ່າຍແລ້ວ → ລັອກການແກ້ໄຂ/ລຶບ ສະເພາະວິຊາທີ່ບັນທຶກໄວ້ແລ້ວ.
  final bool isLocked;
  final bool Function(String feeId) isExistingFee;

  const RegistrationDetailCard({
    super.key,
    required this.stepNum,
    required this.fees,
    required this.onRemove,
    required this.scholarshipStatusByFee,
    required this.onScholarshipChanged,
    this.isLocked = false,
    required this.isExistingFee,
  });

  // ວິຊານີ້ຖືກລັອກບໍ (ຈ່າຍແລ້ວ + ເປັນວິຊາທີ່ບັນທຶກໄວ້ແລ້ວ).
  bool _isRowLocked(String feeId) => isLocked && isExistingFee(feeId);

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      stepNum: stepNum,
      stepColor: AppColors.success,
      title: 'ລາຍລະອຽດການລົງທະບຽນ',
      badge: '${fees.length} ວິຊາ',
      badgeColor: AppColors.infoLight,
      badgeTextColor: AppColors.info,
      child: fees.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'ຍັງບໍ່ໄດ້ເລືອກວິຊາ',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'ວິຊາ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'ຊັ້ນຮຽນ/ລະດັບ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child: Text(
                          'ຄ່າຮຽນ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'ທຶນຮຽນ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 50),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...fees.asMap().entries.map((e) {
                  final i = e.key;
                  final fee = e.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fee.subjectName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  fee.subjectCategory,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            fee.levelName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            FormatUtils.formatKip(
                              scholarshipStatusByFee[fee.feeId] == 'ໄດ້ຮັບທຶນ'
                                  ? 0
                                  : fee.fee.toInt(),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _buildPerSubjectScholarshipDropdown(fee.feeId),
                        ),
                        SizedBox(
                          width: 50,
                          child: _isRowLocked(fee.feeId)
                              ? const Tooltip(
                                  message: 'ຈ່າຍແລ້ວ ບໍ່ສາມາດລຶບໄດ້',
                                  child: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 22,
                                    color: AppColors.mutedForeground,
                                  ),
                                )
                              : IconButton(
                                  onPressed: () => onRemove(fee.feeId),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 26,
                                    color: AppColors.destructive,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildPerSubjectScholarshipDropdown(String feeId) {
    final status = scholarshipStatusByFee[feeId] ?? 'ບໍ່ໄດ້ຮັບທຶນ';
    final locked = _isRowLocked(feeId);
    return AppDropdown<String>(
      value: status,
      items: const [
        DropdownMenuItem(value: 'ໄດ້ຮັບທຶນ', child: Text('ໄດ້ຮັບທຶນ')),
        DropdownMenuItem(value: 'ບໍ່ໄດ້ຮັບທຶນ', child: Text('ບໍ່ໄດ້ຮັບທຶນ')),
      ],
      onChanged: locked
          ? null
          : (v) {
              if (v != null) {
                onScholarshipChanged(feeId, v);
              }
            },
    );
  }
}
