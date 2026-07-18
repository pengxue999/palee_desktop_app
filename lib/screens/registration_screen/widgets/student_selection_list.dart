import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/widgets/app_text_field.dart';
import '../../../core/constants/app_colors.dart';

class StudentSelectionItem {
  final String id;
  final String fullName;
  final String school;

  const StudentSelectionItem({
    required this.id,
    required this.fullName,
    required this.school,
  });
}

class StudentSelectionList extends StatelessWidget {
  final List<StudentSelectionItem> students;
  final String? selectedStudentId;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<StudentSelectionItem> onSelect;
  final VoidCallback? onClearSearch;
  final Widget? action;

  const StudentSelectionList({
    super.key,
    required this.students,
    this.selectedStudentId,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSelect,
    this.onClearSearch,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final displayStudents = students.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: searchController,
                hint: 'ຄົ້ນຫາດ້ວຍລະຫັດ, ຊື່, ໂຮງຮຽນ...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: onClearSearch,
                      )
                    : null,
                onChanged: onSearchChanged,
              ),
            ),
            if (action != null) ...[const SizedBox(width: 12), action!],
          ],
        ),
        const SizedBox(height: 14),

        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.border.withValues(alpha: 0.85),
                      AppColors.border,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 44),
                    _TableHeader(label: 'ລະຫັດ', flex: 2),
                    _TableHeader(label: 'ຊື່ ແລະ ນາມສະກຸນ', flex: 4),
                    _TableHeader(label: 'ມາຈາກໂຮງຮຽນ', flex: 3),
                  ],
                ),
              ),

              if (displayStudents.isEmpty)
                _buildEmptyState()
              else
                ...List.generate(displayStudents.length, (index) {
                  return _buildStudentRow(
                    displayStudents[index],
                    index,
                    isLast: index == displayStudents.length - 1,
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.muted,
                    AppColors.muted.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 28,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'ບໍ່ພົບຂໍ້ມູນນັກຮຽນ',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ລອງຄົ້ນຫາດ້ວຍຄຳອື່ນ',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentRow(
    StudentSelectionItem student,
    int index, {
    bool isLast = false,
  }) {
    final isActive = selectedStudentId == student.id;
    final isEven = index.isEven;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(student),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryLight.withValues(alpha: 0.6)
                : isEven
                ? AppColors.card
                : const Color(0xFFF8FAFC),
            border: isActive
                ? Border(left: BorderSide(color: AppColors.primary, width: 3))
                : !isLast
                ? Border(
                    bottom: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isActive
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),

              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.muted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    student.id,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.mutedForeground,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                flex: 4,
                child: Text(
                  student.fullName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.primary : AppColors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 15,
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.6)
                          : AppColors.mutedForeground.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        student.school,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.8)
                              : AppColors.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;

  const _TableHeader({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
