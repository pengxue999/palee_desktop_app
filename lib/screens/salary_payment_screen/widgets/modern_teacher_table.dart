import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/salary_payment_model.dart';

class ModernTeacherTable extends StatelessWidget {
  final List<TeacherMonthlySummary> data;
  final String Function(double) formatKip;
  final String? selectedId;
  final Function(String? id) onSelectionChanged;
  final Function(TeacherMonthlySummary teacher) onRowTap;
  final bool isLoading;

  const ModernTeacherTable({
    super.key,
    required this.data,
    required this.formatKip,
    required this.selectedId,
    required this.onSelectionChanged,
    required this.onRowTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: Stack(
              children: [
                if (data.isEmpty && !isLoading)
                  _buildEmptyState()
                else if (data.isNotEmpty)
                  _buildTableBody(),
                if (isLoading)
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.card.withValues(alpha: 0.6),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40),
          _headerCell('ຊື່ ແລະ ນາມສະກຸນ', 3),
          _headerCell('ຈຳນວນຊົ່ວໂມງ', 2, alignment: Alignment.center),
          _headerCell('ເງິນສອນ', 2, alignment: Alignment.centerRight),
          _headerCell('ຈ່າຍແລ້ວ', 2, alignment: Alignment.centerRight),
          _headerCell('ຍັງເຫຼືອ', 2, alignment: Alignment.centerRight),
        ],
      ),
    );
  }

  Widget _headerCell(
    String label,
    double flex, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Expanded(
      flex: flex.toInt(),
      child: Align(
        alignment: alignment,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.accentForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off,
            size: 48,
            color: AppColors.mutedForeground.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'ບໍ່ມີຂໍ້ມູນອາຈານ',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableBody() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: data.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: AppColors.border,
      ),
      itemBuilder: (context, index) {
        final teacher = data[index];
        return _buildDataRow(teacher);
      },
    );
  }

  Widget _buildDataRow(TeacherMonthlySummary teacher) {
    final isSelected = selectedId == teacher.teacherId;
    final remaining = teacher.remainingBalance;

    return InkWell(
      onTap: () {
        onSelectionChanged(teacher.teacherId);
        onRowTap(teacher);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Radio<String>(
                value: teacher.teacherId,
                groupValue: selectedId,
                onChanged: (v) {
                  onSelectionChanged(v);
                  onRowTap(teacher);
                },
                activeColor: AppColors.primary,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                teacher.teacherFullName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  '${teacher.totalHours.toStringAsFixed(1)} ຊມ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatKip(teacher.totalAmount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatKip(teacher.totalPaid),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: teacher.totalPaid > 0
                        ? AppColors.success
                        : AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatKip(remaining),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: remaining <= 0
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
