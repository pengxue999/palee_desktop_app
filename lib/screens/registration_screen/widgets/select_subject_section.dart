import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/responsive_utils.dart';
import 'package:palee_elite_training_center/models/fee_model.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/fee_card.dart';
import 'package:palee_elite_training_center/widgets/section_card.dart';

class SelectSubjectSection extends StatefulWidget {
  final List<FeeModel> allFees;
  final Set<String> selectedFeeIds;
  final bool isLoading;
  final bool enabled;
  final ValueChanged<String> onToggleFee;

  const SelectSubjectSection({
    super.key,
    required this.allFees,
    required this.selectedFeeIds,
    required this.isLoading,
    required this.enabled,
    required this.onToggleFee,
  });

  @override
  State<SelectSubjectSection> createState() => SelectSubjectSectionState();
}

class SelectSubjectSectionState extends State<SelectSubjectSection> {
  static const _allCategoriesLabel = 'ທັງໝົດ';
  static const _uncategorizedLabel = 'ບໍ່ລະບຸໝວດ';

  String _selectedCategory = '';
  String _selectedSubject = '';

  Map<String, List<FeeModel>> get _groupedByCategory {
    final map = <String, List<FeeModel>>{};
    for (final fee in widget.allFees) {
      final category = fee.subjectCategory.trim().isEmpty
          ? _uncategorizedLabel
          : fee.subjectCategory.trim();
      map.putIfAbsent(category, () => []).add(fee);
    }
    return map;
  }

  Map<String, List<FeeModel>> get _groupedBySubject {
    final map = <String, List<FeeModel>>{};
    final feesForSelectedCategory = _selectedCategory == _allCategoriesLabel
        ? widget.allFees
        : (_groupedByCategory[_selectedCategory] ?? const <FeeModel>[]);

    for (final fee in feesForSelectedCategory) {
      map.putIfAbsent(fee.subjectName, () => []).add(fee);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.levelName.compareTo(b.levelName));
    }
    return map;
  }

  List<String> get _categoryNames {
    final categories = _groupedByCategory.keys.toList()..sort();
    return [_allCategoriesLabel, ...categories];
  }

  List<String> get _subjectNames => _groupedBySubject.keys.toList()..sort();

  void _ensureSelectionState() {
    final categories = _categoryNames;
    if (categories.isEmpty) {
      _selectedCategory = '';
      _selectedSubject = '';
      return;
    }

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    final subjects = _subjectNames;
    if (subjects.isEmpty) {
      _selectedSubject = '';
      return;
    }

    if (!subjects.contains(_selectedSubject)) {
      _selectedSubject = subjects.first;
    }
  }

  void _selectFeeExclusive(String feeId, String subject) {
    final subjectFees = _groupedBySubject[subject] ?? [];

    if (widget.selectedFeeIds.contains(feeId)) {
      widget.onToggleFee(feeId);
      return;
    }

    for (final fee in subjectFees) {
      if (fee.feeId != feeId && widget.selectedFeeIds.contains(fee.feeId)) {
        widget.onToggleFee(fee.feeId);
      }
    }

    widget.onToggleFee(feeId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_categoryNames.isNotEmpty &&
          (_selectedCategory.isEmpty || _selectedSubject.isEmpty)) {
        setState(_ensureSelectionState);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SelectSubjectSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final categories = _categoryNames;
    final subjects = _subjectNames;
    if (!categories.contains(_selectedCategory) ||
        (subjects.isNotEmpty && !subjects.contains(_selectedSubject))) {
      setState(_ensureSelectionState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSelected = widget.selectedFeeIds.length;
    final grouped = _groupedBySubject;
    final currentSubjectFees = grouped[_selectedSubject] ?? [];

    return SectionCard(
      stepNum: 2,
      stepColor: const Color(0xFF6366F1),
      title: 'ເລືອກວິຊາຮຽນ',
      badge: totalSelected > 0 ? '$totalSelected ວິຊາ' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_categoryNames.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categoryNames.map((category) {
                  final active = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10, bottom: 12),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                            final subjects = _subjectNames;
                            _selectedSubject = subjects.isNotEmpty
                                ? subjects.first
                                : '';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFE0ECFF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFD6DFEA),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: active ? 0.08 : 0.04),
                                blurRadius: active ? 14 : 8,
                                offset: Offset(0, active ? 6 : 3),
                              ),
                            ],
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (_subjectNames.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _subjectNames.map((subject) {
                  final active = subject == _selectedSubject;
                  final selectedInSubject =
                      grouped[subject]
                          ?.where(
                            (f) => widget.selectedFeeIds.contains(f.feeId),
                          )
                          .length ??
                      0;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSubject = subject),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: active ? null : Colors.white,
                            gradient: active
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF4F46E5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: active
                                  ? Colors.transparent
                                  : const Color(0xFFD6DFEA),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: active
                                    ? const Color(
                                        0xFF4F46E5,
                                      ).withValues(alpha: 0.22)
                                    : const Color(
                                        0xFF0F172A,
                                      ).withValues(alpha: 0.06),
                                blurRadius: active ? 18 : 10,
                                offset: Offset(0, active ? 8 : 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                  letterSpacing: 0.1,
                                ),
                              ),
                              if (selectedInSubject > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white.withValues(alpha: 0.22)
                                        : const Color(0xFFE8F0FE),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: active
                                          ? Colors.white.withValues(alpha: 0.18)
                                          : const Color(0xFFD6E4FF),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$selectedInSubject',
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : const Color(0xFF2563EB),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),

          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          if (grouped.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'ບໍ່ມີຂໍ້ມູນວິຊາ',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          else if (currentSubjectFees.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'ບໍ່ມີຂໍ້ມູນສຳລັບວິຊານີ້',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          else
            Stack(
              children: [
                LayoutBuilder(
                  builder: (ctx, box) {
                    int cols = 4;
                    if (box.maxWidth < Breakpoints.tablet) cols = 2;
                    if (box.maxWidth < 400) cols = 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 100,
                      ),
                      itemCount: currentSubjectFees.length,
                      itemBuilder: (_, i) {
                        final fee = currentSubjectFees[i];
                        final sel = widget.selectedFeeIds.contains(fee.feeId);
                        return FeeCard(
                          fee: fee,
                          isSelected: sel,
                          onTap: widget.enabled
                              ? () => _selectFeeExclusive(
                                  fee.feeId,
                                  _selectedSubject,
                                )
                              : () {},
                        );
                      },
                    );
                  },
                ),
                if (!widget.enabled)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 50,
                              color: AppColors.warning,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ກະລຸນາເລືອກນັກຮຽນກ່ອນ',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
