import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/models/registration_model.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/status_badge.dart';

class ModernRegTable extends StatefulWidget {
  final List<RegistrationModel> data;
  final String Function(double) formatKip;
  final String? selectedId;
  final Function(String? id) onSelectionChanged;
  final Function(RegistrationModel reg) onRowTap;
  final bool isLoading;
  final bool showRadio;

  const ModernRegTable({
    super.key,
    required this.data,
    required this.formatKip,
    required this.selectedId,
    required this.onSelectionChanged,
    required this.onRowTap,
    this.isLoading = false,
    this.showRadio = true,
  });

  @override
  State<ModernRegTable> createState() => _ModernRegTableState();
}

class _ModernRegTableState extends State<ModernRegTable> {
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
            child: widget.isLoading && widget.data.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : widget.data.isEmpty
                ? _buildEmptyState()
                : _buildTableBody(),
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
          if (widget.showRadio) ...[
            const SizedBox(width: 40),
          ],
          _headerCell('ເລກບິນ', 2),
          _headerCell('ຊື່ນັກຮຽນ', 2),
          _headerCell('ຕ້ອງຈ່າຍ', 2, alignment: Alignment.centerRight),
          _headerCell('ຈ່າຍແລ້ວ', 2, alignment: Alignment.centerRight),
          _headerCell('ຍັງເຫຼືອ', 2, alignment: Alignment.centerRight),
          _headerCell('ສະຖານະ', 2, alignment: Alignment.centerRight),
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
            fontSize: 16,
            fontWeight: FontWeight.w500,
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
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.mutedForeground.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'ບໍ່ມີຂໍ້ມູນ',
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.data.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: AppColors.border,
      ),
      itemBuilder: (context, index) {
        final reg = widget.data[index];
        return _buildDataRow(reg);
      },
    );
  }

  Widget _buildDataRow(RegistrationModel reg) {
    final remaining = reg.remainingAmount;
    final isFullyPaid = remaining <= 0;
    final isSelected = widget.selectedId == reg.registrationId;

    return InkWell(
      onTap: () {
        widget.onSelectionChanged(reg.registrationId);
        widget.onRowTap(reg);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            if (widget.showRadio) ...[
              SizedBox(
                width: 40,
                child: Radio<String>(
                  value: reg.registrationId,
                  groupValue: widget.selectedId,
                  onChanged: (v) {
                    widget.onSelectionChanged(v);
                    widget.onRowTap(reg);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
            Expanded(
              flex: 2,
              child: Text(
                reg.registrationId,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.foreground,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                reg.studentFullName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  widget.formatKip(reg.finalAmount),
                  style: const TextStyle(
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
                  widget.formatKip(reg.paidAmount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: reg.paidAmount > 0
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
                  widget.formatKip(remaining),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isFullyPaid ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildStatusBadge(reg),
              ),
            ),

          ],
        ),
      ),
    );
  }
  Widget _buildStatusBadge(RegistrationModel reg) {
    if (reg.finalAmount <= 0) {
      return const StatusBadge(status: 'ໄດ້ຮັບທຶນ');
    }
    return StatusBadge(status: reg.status);
  }
}
