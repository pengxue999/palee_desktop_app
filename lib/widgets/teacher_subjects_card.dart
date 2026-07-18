import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/models/evaluation_model.dart';
import 'package:palee_elite_training_center/providers/evaluation_provider.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_card.dart';
import 'package:palee_elite_training_center/widgets/app_data_table.dart';

/// Card ສະແດງວິຊາ/ລະດັບທີ່ອາຈານສອນ ພ້ອມຈຳນວນນັກຮຽນທີ່ລົງທະບຽນ (ສົກຮຽນ ACTIVE).
/// ກົດແຕ່ລະ chip ເພື່ອສະແດງຕາຕະລາງລາຍຊື່ນັກຮຽນຢູ່ດ້ານລຸ່ມ. ໂຫຼດຂໍ້ມູນເອງຈາກ [teacherId].
class TeacherSubjectsCard extends ConsumerStatefulWidget {
  const TeacherSubjectsCard({super.key, required this.teacherId});

  final String teacherId;

  @override
  ConsumerState<TeacherSubjectsCard> createState() =>
      _TeacherSubjectsCardState();
}

class _TeacherSubjectsCardState extends ConsumerState<TeacherSubjectsCard> {
  bool _isLoading = false;
  List<TeacherSubjectRegistration> _subjects = [];
  TeacherSubjectRegistration? _selectedSubject;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await ref
          .read(evaluationServiceProvider)
          .getTeacherSubjectRegistrations(teacherId: widget.teacherId);
      if (!mounted) {
        return;
      }
      setState(() {
        _subjects = response.data;
        _isLoading = false;
        _selectedSubject = _subjects
            .where((item) => item.registeredStudents > 0)
            .firstOrNull;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ApiErrorHandler.handle(context, e.toString());
    }
  }

  bool _isSelected(TeacherSubjectRegistration subject) {
    final selected = _selectedSubject;
    return selected != null &&
        selected.subjectDetailId == subject.subjectDetailId &&
        selected.levelId == subject.levelId;
  }

  void _selectSubject(TeacherSubjectRegistration subject) {
    setState(() => _selectedSubject = subject);
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = _subjects.fold<int>(
      0,
      (sum, item) => sum + item.registeredStudents,
    );
    final selected = _selectedSubject;

    return AppCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'ວິຊາທີ່ຂ້ອຍສອນ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_subjects.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ນັກຮຽນລົງທະບຽນລວມ: $totalStudents ຄົນ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isLoading && _subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'ຍັງບໍ່ມີວິຊາທີ່ມອບໝາຍໃຫ້ສອນໃນສົກຮຽນນີ້',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _subjects.map(_buildChip).toList(),
            ),
          if (selected != null) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            _SubjectStudentsTable(
              key: ValueKey(
                '${selected.subjectDetailId}-${selected.levelId}',
              ),
              subject: selected,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(TeacherSubjectRegistration subject) {
    final hasStudents = subject.registeredStudents > 0;
    final isSelected = _isSelected(subject);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: hasStudents ? () => _selectSubject(subject) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.muted.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subject.subjectName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subject.levelName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 16,
                    color: hasStudents
                        ? AppColors.success
                        : AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${subject.registeredStudents} ຄົນ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hasStudents
                          ? AppColors.success
                          : AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'ລົງທະບຽນ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ຕາຕະລາງລາຍຊື່ນັກຮຽນທີ່ລົງທະບຽນ ໃນວິຊາ/ລະດັບທີ່ອາຈານເລືອກ.
class _SubjectStudentsTable extends ConsumerStatefulWidget {
  const _SubjectStudentsTable({super.key, required this.subject});

  final TeacherSubjectRegistration subject;

  @override
  ConsumerState<_SubjectStudentsTable> createState() =>
      _SubjectStudentsTableState();
}

class _SubjectStudentsTableState extends ConsumerState<_SubjectStudentsTable> {
  bool _isLoading = true;
  String? _error;
  List<EvaluationScoreEntryStudent> _students = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents());
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // ລາຍຊື່ນັກຮຽນ filter ຕາມ subject_detail_id + level_id ເທົ່ານັ້ນ —
      // ບໍ່ຂຶ້ນກັບຮອບປະເມີນ, ສະນັ້ນໃຊ້ 'ກາງພາກ' ດຶງ roster ມາສະແດງ.
      final response = await ref
          .read(evaluationServiceProvider)
          .getScoreSheet(
            semester: 'ກາງພາກ',
            levelId: widget.subject.levelId,
            subjectDetailId: widget.subject.subjectDetailId,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _students = response.data.students;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ນັກຮຽນທີ່ລົງທະບຽນ — ${subject.subjectName}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ຊັ້ນຮຽນ: ${subject.levelName}  •  ລວມ ${subject.registeredStudents} ຄົນ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 12),
        _buildBody(),
      ],
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.destructive,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.destructive),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'ລອງໃໝ່',
              variant: AppButtonVariant.outline,
              onPressed: _loadStudents,
            ),
          ],
        ),
      );
    }

    if (!_isLoading && _students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'ບໍ່ມີນັກຮຽນທີ່ລົງທະບຽນໃນວິຊານີ້',
            style: TextStyle(color: AppColors.mutedForeground),
          ),
        ),
      );
    }

    // AppDataTable ໃຊ້ Expanded ພາຍໃນ — ຕ້ອງກຳນົດຄວາມສູງ ເພາະ card ນີ້ຢູ່ໃນ
    // SingleChildScrollView ຂອງໜ້າຫຼັກ.
    return SizedBox(
      height: 480,
      child: AppDataTable<EvaluationScoreEntryStudent>(
        data: _students,
        isLoading: _isLoading,
        showActions: false,
        searchKeys: const [
          'studentId',
          'studentName',
          'studentLastname',
          'studentContact',
          'school',
          'districtName',
          'provinceName',
        ],
        columns: [
          DataColumnDef<EvaluationScoreEntryStudent>(
            key: 'studentId',
            label: 'ລະຫັດ',
            flex: 2,
          ),
          DataColumnDef<EvaluationScoreEntryStudent>(
            key: 'fullName',
            label: 'ຊື່ ແລະ ນາມສະກຸນ',
            flex: 3,
          ),
          DataColumnDef<EvaluationScoreEntryStudent>(
            key: 'gender',
            label: 'ເພດ',
            flex: 1,
          ),
          DataColumnDef<EvaluationScoreEntryStudent>(
            key: 'studentContact',
            label: 'ເບີໂທ',
            flex: 2,
          ),
          DataColumnDef<EvaluationScoreEntryStudent>(
            key: 'parentsContact',
            label: 'ເບີຜູ້ປົກຄອງ',
            flex: 2,
          ),
          DataColumnDef<EvaluationScoreEntryStudent>(
            key: 'school',
            label: 'ໂຮງຮຽນ',
            flex: 3,
          ),
          DataColumnDef<EvaluationScoreEntryStudent>(
            key: 'districtName',
            label: 'ເມືອງ',
            flex: 2,
          ),
          DataColumnDef<EvaluationScoreEntryStudent>(
            key: 'provinceName',
            label: 'ແຂວງ',
            flex: 2,
          ),
        ],
      ),
    );
  }
}
