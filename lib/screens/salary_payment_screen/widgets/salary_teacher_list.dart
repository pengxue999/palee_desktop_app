import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/salary_payment_model.dart';
import '../../../providers/salary_payment_provider.dart';
import '../../../widgets/app_text_field.dart';
import 'modern_teacher_table.dart';
import 'payment_dialog.dart';

class SalaryTeacherList extends ConsumerStatefulWidget {
  final void Function(String teacherId) onSelectTeacher;
  final Future<void> Function(String paymentId)? onPrintPayment;

  const SalaryTeacherList({
    super.key,
    required this.onSelectTeacher,
    this.onPrintPayment,
  });

  @override
  ConsumerState<SalaryTeacherList> createState() => _SalaryTeacherListState();
}

class _SalaryTeacherListState extends ConsumerState<SalaryTeacherList> {
  String _searchText = '';
  final _searchController = TextEditingController();
  static const List<String> _monthNames = [
    'ມັງກອນ',
    'ກຸມພາ',
    'ມີນາ',
    'ເມສາ',
    'ພຶດສະພາ',
    'ມິຖຸນາ',
    'ກໍລະກົດ',
    'ສິງຫາ',
    'ກັນຍາ',
    'ຕຸລາ',
    'ພະຈິກ',
    'ທັນວາ',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final currentMonth = TeachingMonth(
        year: now.year,
        month: now.month,
        label: _monthNames[now.month - 1],
        count: 0,
      );
      ref.read(salaryPaymentProvider.notifier).selectMonth(currentMonth);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(
      salaryPaymentProvider.select((s) => s.selectedMonth),
    );
    final teachers = ref.watch(
      salaryPaymentProvider.select((s) => s.monthlyTeachers),
    );
    final selectedTeacherId = ref.watch(
      salaryPaymentProvider.select((s) => s.selectedTeacherId),
    );
    final isLoadingTeachers = ref.watch(
      salaryPaymentProvider.select((s) => s.isLoadingTeachers),
    );

    final filteredTeachers = _searchText.isEmpty
        ? teachers
        : teachers
              .where(
                (t) =>
                    t.teacherFullName.toLowerCase().contains(
                      _searchText.toLowerCase(),
                    ) ||
                    t.teacherId.toLowerCase().contains(
                      _searchText.toLowerCase(),
                    ),
              )
              .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLayout =
            constraints.maxHeight < 470 || constraints.maxWidth < 720;
        final outerPadding = compactLayout ? 10.0 : 16.0;
        final sectionPadding = compactLayout ? 12.0 : 16.0;
        final headerHeight = compactLayout ? 52.0 : 60.0;
        final headerFontSize = compactLayout ? 15.0 : 18.0;
        final monthSpacing = compactLayout ? 6.0 : 8.0;
        final monthCrossSpacing = compactLayout ? 8.0 : 10.0;
        final monthAspectRatio = compactLayout ? 2.7 : 2.2;
        final tablePadding = compactLayout ? 12.0 : 16.0;

        return Padding(
          padding: EdgeInsets.all(outerPadding),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: headerHeight,
                  padding: EdgeInsets.fromLTRB(
                    sectionPadding,
                    compactLayout ? 12 : 16,
                    sectionPadding,
                    compactLayout ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Center(
                    child: Text(
                      'ເລືອກງວດເດືອນທີ່ຕ້ອງການຈ່າຍເງິນ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: headerFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    sectionPadding,
                    sectionPadding,
                    sectionPadding,
                    sectionPadding,
                  ),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: monthSpacing,
                    crossAxisSpacing: monthCrossSpacing,
                    childAspectRatio: monthAspectRatio,
                    children: List.generate(12, (i) {
                      final monthNum = i + 1;
                      final isSelected = selectedMonth?.month == monthNum;
                      return _MonthCard(
                        monthName: _monthNames[i],
                        monthNum: monthNum,
                        isSelected: isSelected,
                        compact: compactLayout,
                        onTap: () {
                          final m = TeachingMonth(
                            year: DateTime.now().year,
                            month: monthNum,
                            label: _monthNames[i],
                            count: 0,
                          );
                          ref
                              .read(salaryPaymentProvider.notifier)
                              .selectMonth(m);
                        },
                      );
                    }),
                  ),
                ),
                const Divider(height: 1),
                if (selectedMonth != null) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sectionPadding,
                      compactLayout ? 8 : 12,
                      sectionPadding,
                      0,
                    ),
                    child: AppTextField(
                      controller: _searchController,
                      label: '',
                      hint: 'ຄົ້ນຫາອາຈານ...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      onChanged: (v) => setState(() => _searchText = v),
                      fontSize: compactLayout ? 14 : 16,
                      suffixIcon: _searchText.isNotEmpty
                          ? MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchText = '');
                                },
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
                Expanded(
                  child: selectedMonth == null
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: EdgeInsets.all(tablePadding),
                          child: ModernTeacherTable(
                            data: filteredTeachers,
                            formatKip: (value) =>
                                FormatUtils.formatKip(value.toInt()),
                            selectedId: selectedTeacherId,
                            onSelectionChanged: (id) {
                              if (id != null) {
                                widget.onSelectTeacher(id);
                              }
                            },
                            onRowTap: (teacher) async {
                              widget.onSelectTeacher(teacher.teacherId);
                              final month = ref
                                  .read(salaryPaymentProvider)
                                  .selectedMonth;
                              if (month != null) {
                                await ref
                                    .read(salaryPaymentProvider.notifier)
                                    .calculateTeacherSalary(
                                      teacher.teacherId,
                                      month.month,
                                      month.year,
                                    );
                                if (context.mounted) {
                                  await PaymentDialog.show(
                                    context: context,
                                    teacherId: teacher.teacherId,
                                    month: month,
                                    onPrintPayment: widget.onPrintPayment,
                                  );
                                }
                              }
                            },
                            isLoading: isLoadingTeachers,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthCard extends StatefulWidget {
  final String monthName;
  final int monthNum;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _MonthCard({
    required this.monthName,
    required this.monthNum,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.primary
        : _isHovered
        ? AppColors.primary.withValues(alpha: 0.1)
        : Colors.white;

    final textColor = widget.isSelected
        ? Colors.white
        : _isHovered
        ? AppColors.primary
        : AppColors.foreground;

    final borderColor = widget.isSelected
        ? AppColors.primary
        : _isHovered
        ? AppColors.primary.withValues(alpha: 0.4)
        : AppColors.border;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 6 : 8,
            vertical: widget.compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.monthName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: widget.compact ? 13 : 15,
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: textColor,
                letterSpacing: widget.compact ? 0 : 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
