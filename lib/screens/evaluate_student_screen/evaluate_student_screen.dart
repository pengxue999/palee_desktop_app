import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/enum_localization.dart';
import 'package:palee_elite_training_center/core/utils/format_utils.dart';
import 'package:palee_elite_training_center/models/evaluation_model.dart';
import 'package:palee_elite_training_center/providers/assessment_report_provider.dart';
import 'package:palee_elite_training_center/providers/auth_provider.dart';
import 'package:palee_elite_training_center/providers/evaluation_provider.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_card.dart';
import 'package:palee_elite_training_center/widgets/app_data_table.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/app_text_field.dart';
import 'package:palee_elite_training_center/widgets/success_overlay.dart';

class EvaluateStudentScreen extends ConsumerStatefulWidget {
  const EvaluateStudentScreen({super.key});

  @override
  ConsumerState<EvaluateStudentScreen> createState() =>
      _EvaluateStudentScreenState();
}

class _EvaluateStudentScreenState extends ConsumerState<EvaluateStudentScreen> {
  static const _semesters = [
    {'value': 'all', 'label': 'ທັງໝົດ'},
    {'value': 'MIDTERM', 'label': 'ກາງພາກ'},
    {'value': 'FINAL', 'label': 'ທ້າຍພາກ'},
  ];

  final Map<String, TextEditingController> _scoreControllers = {};
  final Set<String> _dirtyItemKeys = <String>{};

  String? _selectedSemester;
  String? _selectedSubjectId;
  String? _selectedLevelId;
  bool _isBulkSaving = false;

  /// teacher_id ປັດຈຸບັນ (null = admin / ບໍ່ແມ່ນອາຈານ → ບໍ່ filter).
  /// ໃຊ້ກັ່ນຕອງວິຊາ/ຄະແນນໃຫ້ອາຈານເຫັນສະເພາະວິຊາທີ່ຕົນສອນ.
  String? get _teacherId {
    final auth = ref.read(authProvider);
    return isTeacherRole(auth.role) ? auth.teacherId : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resetFiltersAndReload();
    });
  }

  @override
  void dispose() {
    _disposeInlineControllers();
    super.dispose();
  }

  String _formatAverage(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  String _semesterLabel(String? value) {
    switch (value) {
      case 'MIDTERM':
      case 'ກາງພາກ':
        return 'ກາງພາກ';
      case 'FINAL':
      case 'ທ້າຍພາກ':
        return 'ທ້າຍພາກ';
      case 'all':
        return 'ທັງໝົດ';
      default:
        return value ?? '-';
    }
  }

  String _toReportSemester(String? value) {
    switch (value) {
      case 'ກາງພາກ':
        return 'MIDTERM';
      case 'ທ້າຍພາກ':
        return 'FINAL';
      default:
        return value ?? 'all';
    }
  }

  String _itemKey(AssessmentReportItem item) {
    return '${item.evaluationId}:${item.regisDetailId}';
  }

  String _groupKey(AssessmentReportItem item) {
    return '${item.semester}|${item.levelId}|${item.subjectDetailId}';
  }

  void _disposeInlineControllers() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    _scoreControllers.clear();
  }

  void _syncInlineEditors(List<AssessmentReportItem> items) {
    _disposeInlineControllers();
    _dirtyItemKeys.clear();

    for (final item in items) {
      final key = _itemKey(item);
      _scoreControllers[key] = TextEditingController(
        text: _formatAverage(item.score),
      );
    }
  }

  double? _readInlineScore(AssessmentReportItem item) {
    final rawScore =
        _scoreControllers[_itemKey(item)]?.text.trim().replaceAll(',', '') ??
        '';
    if (rawScore.isEmpty) {
      return null;
    }
    return double.tryParse(rawScore);
  }

  bool _sameNumber(double? left, double? right) {
    if (left == null && right == null) {
      return true;
    }
    if (left == null || right == null) {
      return false;
    }
    return (left - right).abs() < 0.001;
  }

  void _handleInlineChanged(AssessmentReportItem item) {
    final key = _itemKey(item);
    final isDirty = !_sameNumber(_readInlineScore(item), item.score);

    setState(() {
      if (isDirty) {
        _dirtyItemKeys.add(key);
      } else {
        _dirtyItemKeys.remove(key);
      }
    });
  }

  Future<void> _loadReport() async {
    if (_selectedSemester == null) {
      ref.read(assessmentReportProvider.notifier).clear();
      setState(() {
        _disposeInlineControllers();
        _dirtyItemKeys.clear();
      });
      return;
    }

    await ref
        .read(assessmentReportProvider.notifier)
        .loadReport(semester: _selectedSemester!, teacherId: _teacherId);

    final state = ref.read(assessmentReportProvider);
    if (!mounted) {
      return;
    }
    if (state.error != null) {
      ApiErrorHandler.handle(context, state.error!);
      return;
    }

    setState(() {
      _syncInlineEditors(state.items);
    });
  }

  Future<void> _resetFiltersAndReload() async {
    setState(() {
      _selectedSemester = 'all';
      _selectedSubjectId = null;
      _selectedLevelId = null;
    });
    await _loadReport();
  }

  List<AssessmentReportItem> _filterItems(List<AssessmentReportItem> items) {
    final filtered = items.where((item) {
      if (_selectedSubjectId != null && item.subjectId != _selectedSubjectId) {
        return false;
      }
      if (_selectedLevelId != null && item.levelId != _selectedLevelId) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) => a.ranking.compareTo(b.ranking));
    return filtered;
  }

  Future<void> _saveInlineEdits() async {
    if (_dirtyItemKeys.isEmpty || _isBulkSaving) {
      return;
    }

    final dirtyItems = ref
        .read(assessmentReportProvider)
        .items
        .where((item) => _dirtyItemKeys.contains(_itemKey(item)))
        .toList();

    if (dirtyItems.isEmpty) {
      return;
    }

    setState(() => _isBulkSaving = true);

    try {
      final service = ref.read(evaluationServiceProvider);
      final dirtyGroups = dirtyItems.map(_groupKey).toSet();

      for (final groupKey in dirtyGroups) {
        final groupItems = dirtyItems
            .where((item) => _groupKey(item) == groupKey)
            .toList();
        if (groupItems.isEmpty) {
          continue;
        }

        final firstItem = groupItems.first;
        final request = EvaluationScoreSheetRequest(
          semester: firstItem.semester,
          levelId: firstItem.levelId,
          subjectDetailId: firstItem.subjectDetailId,
          scores: groupItems
              .map(
                (item) => EvaluationScoreUpdateItem(
                  regisDetailId: item.regisDetailId,
                  score: _readInlineScore(item),
                  prize: null,
                ),
              )
              .toList(),
        );

        await service.saveScoreSheet(request);
      }

      if (!mounted) {
        return;
      }

      await SuccessOverlay.show(context, message: 'ອັບເດດຂໍ້ມູນສຳເລັດ');
      await _loadReport();
    } catch (e) {
      if (mounted) {
        ApiErrorHandler.handle(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isBulkSaving = false);
      }
    }
  }

  Future<void> _openScoreEntryDialog({
    String? initialSemester,
    String? initialSubjectId,
    String? initialLevelId,
  }) async {
    final savedSheet = await _EvaluationScoreEntryDialog.show(
      context: context,
      initialSemester: initialSemester,
      initialSubjectId: initialSubjectId,
      initialLevelId: initialLevelId,
      teacherId: _teacherId,
    );
    if (!mounted || savedSheet == null) {
      return;
    }

    setState(() {
      _selectedSemester = _toReportSemester(savedSheet.semester);
      _selectedSubjectId = savedSheet.subjectId;
      _selectedLevelId = savedSheet.levelId;
    });
    await _loadReport();
  }

  List<DataColumnDef<AssessmentReportItem>> _buildResultColumns() {
    return [
      DataColumnDef<AssessmentReportItem>(
        key: 'fullName',
        label: 'ນັກຮຽນ',
        flex: 3,
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'semester',
        label: 'ຮອບປະເມີນ',
        flex: 2,
        render: (_, item) => Text(_semesterLabel(item.semester)),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'subjectName',
        label: 'ວິຊາ',
        flex: 2,
        render: (_, item) => Text(item.subjectName),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'levelName',
        label: 'ຊັ້ນຮຽນ',
        flex: 2,
        render: (_, item) => Text(item.levelName),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'score',
        label: 'ຄະແນນ',
        flex: 2,
        render: (_, item) => AppTextField(
          controller: _scoreControllers[_itemKey(item)],
          hint: '0-10',
          digitOnly: DigitOnly.decimal,
          maxLength: 5,
          maxValue: 10,
          fontWeight: FontWeight.w700,
          onChanged: (_) => _handleInlineChanged(item),
        ),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'ranking',
        label: 'ທີ່',
        flex: 1,
        render: (_, item) => Text(
          item.ranking.toString(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary.withValues(alpha: 0.9),
          ),
        ),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'prize',
        label: 'ລາງວັນ',
        flex: 2,
        render: (_, item) => Text(
          item.prize == null ? '-' : FormatUtils.formatCurrency(item.prize!),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(assessmentReportProvider);
    final filteredItems = _filterItems(reportState.items);
    final canBulkSave =
        _dirtyItemKeys.isNotEmpty && !reportState.isLoading && !_isBulkSaving;
    final availableSubjects = {
      for (final item in reportState.items) item.subjectId: item.subjectName,
    }.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final availableLevels = {
      for (final item in reportState.items)
        if (_selectedSubjectId == null || item.subjectId == _selectedSubjectId)
          item.levelId: item.levelName,
    }.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final selectedSubjectValue =
        availableSubjects.any((item) => item.key == _selectedSubjectId)
        ? _selectedSubjectId
        : null;
    final selectedLevelValue =
        availableLevels.any((item) => item.key == _selectedLevelId)
        ? _selectedLevelId
        : null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            width: double.infinity,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 180,
                  child: AppDropdown<String>(
                    label: 'ຮອບປະເມີນ',
                    value: _selectedSemester,
                    items: _semesters.map((item) {
                      return DropdownMenuItem(
                        value: item['value'],
                        child: Text(item['label'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedSemester = value;
                        _selectedSubjectId = null;
                        _selectedLevelId = null;
                      });
                      await _loadReport();
                    },
                    hint: 'ເລືອກຮອບປະເມີນ',
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: AppDropdown<String>(
                    label: 'ວິຊາ',
                    value: selectedSubjectValue,
                    items: availableSubjects
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.key,
                            child: Text(item.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubjectId = value;
                        _selectedLevelId = null;
                      });
                    },
                    hint: 'ທັງໝົດ',
                    enabled: reportState.items.isNotEmpty,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: AppDropdown<String>(
                    label: 'ຊັ້ນຮຽນ',
                    value: selectedLevelValue,
                    items: availableLevels
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.key,
                            child: Text(item.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedLevelId = value);
                    },
                    hint: 'ທັງໝົດ',
                    enabled: reportState.items.isNotEmpty,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: AppButton(
                      label: 'ລ້າງຟິວເຕີ',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.success,
                      onPressed: _resetFiltersAndReload,
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: AppButton(
                      label: 'ອັບເດດ',
                      icon: Icons.save_as_rounded,
                      onPressed: canBulkSave ? _saveInlineEdits : null,
                      isLoading: _isBulkSaving,
                    ),
                  ),
                ),
                // SizedBox(
                //   width: 160,
                //   child: Padding(
                //     padding: const EdgeInsets.only(top: 30),
                //     child: AppButton(
                //       label: 'ປະເມີນໃໝ່',
                //       icon: Icons.save_as_rounded,
                //       onPressed: ,
                //       isLoading: _isBulkSaving,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AppDataTable<AssessmentReportItem>(
              columns: _buildResultColumns(),
              data: filteredItems,
              isLoading: reportState.isLoading,
              rowHeight: 76,
              showActions: false,
              title: 'ຕາຕະລາງປະເມີນ',
              onAdd: () => _openScoreEntryDialog(),
              addLabel: 'ປະເມີນໃໝ່',
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationScoreEntryDialog extends ConsumerStatefulWidget {
  const _EvaluationScoreEntryDialog({
    this.initialSemester,
    this.initialSubjectId,
    this.initialLevelId,
    this.teacherId,
  });

  final String? initialSemester;
  final String? initialSubjectId;
  final String? initialLevelId;

  /// teacher_id ປັດຈຸບັນ (null = admin → ສະແດງທຸກວິຊາ).
  final String? teacherId;

  static const _semesters = [
    {'value': 'ກາງພາກ', 'label': 'ກາງພາກ'},
    {'value': 'ທ້າຍພາກ', 'label': 'ທ້າຍພາກ'},
  ];

  static Future<EvaluationScoreSheet?> show({
    required BuildContext context,
    String? initialSemester,
    String? initialSubjectId,
    String? initialLevelId,
    String? teacherId,
  }) {
    return showDialog<EvaluationScoreSheet>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EvaluationScoreEntryDialog(
        initialSemester: initialSemester,
        initialSubjectId: initialSubjectId,
        initialLevelId: initialLevelId,
        teacherId: teacherId,
      ),
    );
  }

  @override
  ConsumerState<_EvaluationScoreEntryDialog> createState() =>
      _EvaluationScoreEntryDialogState();
}

class _EvaluationScoreEntryDialogState
    extends ConsumerState<_EvaluationScoreEntryDialog> {
  final Map<int, TextEditingController> _scoreControllers = {};
  final ScrollController _studentsScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<EvaluationScoreEntryStudent> _displayStudents = [];
  String _searchQuery = '';
  bool _hasScoreInput = false;

  String? _selectedSemester;
  String? _selectedSubjectId;
  String? _selectedSubjectDetailId;
  String? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    _selectedSemester = _normalizeEntrySemester(widget.initialSemester);
    _selectedSubjectId = widget.initialSubjectId;
    _selectedLevelId = widget.initialLevelId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(evaluationProvider.notifier).resetScoreEntryForm();
      await _loadSubjects();
      if (_selectedSubjectId != null) {
        await _loadLevelsForSubject();
      }
      if (_selectedLevelId != null) {
        final levels = ref.read(evaluationProvider).availableLevels;
        final selectedLevel = levels
            .where((item) => item.levelId == _selectedLevelId)
            .firstOrNull;
        _selectedSubjectDetailId = selectedLevel?.subjectDetailId;
        await _loadSheet();
      }
    });
  }

  @override
  void dispose() {
    _disposeControllers();
    _studentsScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _normalizeEntrySemester(String? value) {
    switch (value) {
      case 'MIDTERM':
        return 'ກາງພາກ';
      case 'FINAL':
        return 'ທ້າຍພາກ';
      default:
        return value;
    }
  }

  void _disposeControllers() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    _scoreControllers.clear();
  }

  double? _readScore(int regisDetailId) {
    final rawScore =
        _scoreControllers[regisDetailId]?.text.trim().replaceAll(',', '') ?? '';
    if (rawScore.isEmpty) {
      return null;
    }
    return double.tryParse(rawScore);
  }

  String _formatAverage(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  bool get _hasAnyScore => _displayStudents.any(
    (student) => _readScore(student.regisDetailId) != null,
  );

  void _handleScoreChanged() {
    final hasScoreInput = _hasAnyScore;
    if (hasScoreInput != _hasScoreInput) {
      setState(() {
        _hasScoreInput = hasScoreInput;
      });
    }
  }

  bool _hasPersistedScores(EvaluationScoreSheet? sheet) {
    if (sheet == null) {
      return false;
    }
    return sheet.students.any((student) => student.score != null);
  }

  String _semesterLabel(String? value) {
    switch (value) {
      case 'MIDTERM':
      case 'ກາງພາກ':
        return 'ກາງພາກ';
      case 'FINAL':
      case 'ທ້າຍພາກ':
        return 'ທ້າຍພາກ';
      default:
        return value ?? '-';
    }
  }

  Future<void> _loadSubjects() async {
    await ref
        .read(evaluationProvider.notifier)
        .loadScoreSubjects(teacherId: widget.teacherId);
    final state = ref.read(evaluationProvider);
    if (!mounted) {
      return;
    }
    if (state.error != null) {
      ApiErrorHandler.handle(context, state.error!);
    }
  }

  Future<void> _loadLevelsForSubject() async {
    final subjectId = _selectedSubjectId;
    if (subjectId == null) {
      ref.read(evaluationProvider.notifier).clearSheet(clearSubjects: false);
      setState(() {
        _selectedLevelId = null;
        _selectedSubjectDetailId = null;
      });
      _syncControllers(null);
      return;
    }

    await ref
        .read(evaluationProvider.notifier)
        .loadScoreLevels(subjectId: subjectId, teacherId: widget.teacherId);
    final state = ref.read(evaluationProvider);
    if (!mounted) {
      return;
    }
    if (state.error != null) {
      ApiErrorHandler.handle(context, state.error!);
      return;
    }

    final stillExists = state.availableLevels.any(
      (item) => item.subjectDetailId == _selectedSubjectDetailId,
    );
    if (!stillExists) {
      setState(() {
        _selectedLevelId = null;
        _selectedSubjectDetailId = null;
      });
    }
  }

  Future<void> _loadSheet() async {
    if (_selectedSemester == null ||
        _selectedLevelId == null ||
        _selectedSubjectDetailId == null) {
      ref.read(evaluationProvider.notifier).clearSheet(clearLevels: false);
      _syncControllers(null);
      return;
    }

    await ref
        .read(evaluationProvider.notifier)
        .loadScoreSheet(
          semester: _selectedSemester!,
          levelId: _selectedLevelId!,
          subjectDetailId: _selectedSubjectDetailId!,
        );

    final state = ref.read(evaluationProvider);
    if (!mounted) {
      return;
    }

    if (state.error != null) {
      ApiErrorHandler.handle(context, state.error!);
      return;
    }

    _syncControllers(state.sheet);
  }

  void _syncControllers(EvaluationScoreSheet? sheet) {
    _disposeControllers();
    _searchController.clear();
    _searchQuery = '';

    if (sheet == null) {
      setState(() {
        _displayStudents = [];
        _hasScoreInput = false;
      });
      return;
    }

    for (final student in sheet.students) {
      _scoreControllers[student.regisDetailId] = TextEditingController(
        text: student.score == null ? '' : _formatAverage(student.score!),
      );
    }

    setState(() {
      _displayStudents = [...sheet.students];
      _hasScoreInput = _hasAnyScore;
    });
  }

  Future<void> _arrangeAndPersistSheet() async {
    final sheet = ref.read(evaluationProvider).sheet;
    if (sheet == null) {
      ApiErrorHandler.handle(context, 'ກະລຸນາເລືອກຂໍ້ມູນໃຫ້ຄົບກ່ອນ');
      return;
    }

    if (!_hasAnyScore) {
      ApiErrorHandler.handle(context, 'ກະລຸນາປ້ອນຄະແນນຢ່າງນ້ອຍ 1 ຄົນກ່ອນ');
      return;
    }

    final request = EvaluationScoreSheetRequest(
      semester: _selectedSemester ?? _semesterLabel(sheet.semester),
      levelId: sheet.levelId,
      subjectDetailId: sheet.subjectDetailId,
      scores: _displayStudents
          .map(
            (student) => EvaluationScoreUpdateItem(
              regisDetailId: student.regisDetailId,
              score: _readScore(student.regisDetailId),
              prize: null,
            ),
          )
          .toList(),
    );

    final success = await ref
        .read(evaluationProvider.notifier)
        .saveScoreSheet(request);
    final state = ref.read(evaluationProvider);

    if (!mounted) {
      return;
    }

    if (!success) {
      ApiErrorHandler.handle(
        context,
        state.error ?? 'ບັນທຶກການຈັດອັນດັບບໍ່ສຳເລັດ',
      );
      return;
    }

    await SuccessOverlay.show(
      context,
      message: _hasPersistedScores(sheet)
          ? 'ອັບເດດຂໍ້ມູນສຳເລັດ'
          : 'ບັນທຶກຂໍ້ມູນສຳເລັດ',
    );

    if (mounted) {
      Navigator.of(context).pop(state.sheet);
    }
  }

  Widget _buildStudentRow(EvaluationScoreEntryStudent student, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: index.isEven
          ? Colors.transparent
          : AppColors.muted.withValues(alpha: 0.3),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              student.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AppTextField(
              controller: _scoreControllers[student.regisDetailId],
              hint: '0-10',
              digitOnly: DigitOnly.decimal,
              maxLength: 5,
              maxValue: 10,
              onChanged: (_) => _handleScoreChanged(),
            ),
          ),
        ],
      ),
    );
  }

  List<EvaluationScoreEntryStudent> get _visibleStudents {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _displayStudents;
    }
    return _displayStudents
        .where((student) => student.fullName.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildEditableTable(EvaluationState evaluationState) {
    final sheet = evaluationState.sheet;
    final visibleStudents = _visibleStudents;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    'ລຳດັບ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'ນັກຮຽນ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ຄະແນນ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (evaluationState.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_displayStudents.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  sheet == null
                      ? 'ເລືອກຂໍ້ມູນໃຫ້ຄົບເພື່ອສະແດງລາຍຊື່ນັກຮຽນ'
                      : 'ບໍ່ມີນັກຮຽນສຳລັບເງື່ອນໄຂນີ້',
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            )
          else if (visibleStudents.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'ບໍ່ພົບນັກຮຽນທີ່ຄົ້ນຫາ',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            )
          else
            Expanded(
              child: Scrollbar(
                controller: _studentsScrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: _studentsScrollController,
                  padding: EdgeInsets.zero,
                  itemCount: visibleStudents.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) => _buildStudentRow(
                    visibleStudents[index],
                    _displayStudents.indexOf(visibleStudents[index]),
                  ),
                ),
              ),
            ),
          if (sheet != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.35),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text('ວິຊາ: ${sheet.subjectName}'),
                  Text('ລະດັບ: ${sheet.levelName}'),
                  Text('ຮອບ: ${_semesterLabel(sheet.semester)}'),
                  Text('ນັກຮຽນ: ${sheet.summary.totalStudents} ຄົນ'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final evaluationState = ref.watch(evaluationProvider);
    final sheet = evaluationState.sheet;
    final availableSubjects = evaluationState.availableSubjects;
    final availableLevels = evaluationState.availableLevels;
    final selectedSubjectValue =
        availableSubjects.any((item) => item.subjectId == _selectedSubjectId)
        ? _selectedSubjectId
        : null;
    final selectedLevelValue =
        availableLevels.any(
          (item) => item.subjectDetailId == _selectedSubjectDetailId,
        )
        ? _selectedSubjectDetailId
        : null;
    final hasExistingScores = _hasPersistedScores(sheet);
    final canSave =
        sheet != null && !evaluationState.isSaving && _hasScoreInput;
    final primaryActionLabel = hasExistingScores ? 'ອັບເດດ' : 'ບັນທຶກ';
    final primaryActionIcon = hasExistingScores
        ? Icons.edit_note_rounded
        : Icons.save_rounded;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 1180,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialLevelId == null
                              ? 'ປ້ອນຄະແນນປະເມີນ'
                              : 'ແກ້ໄຂຄະແນນປະເມີນ',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ເລືອກຮອບປະເມີນ, ວິຊາ, ແລະ ຊັ້ນຮຽນ/ລະດັບ ແລ້ວປ້ອນຄະແນນຂອງນັກຮຽນ.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: evaluationState.isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 190,
                          child: AppDropdown<String>(
                            label: 'ຮອບປະເມີນ',
                            value: _selectedSemester,
                            items: _EvaluationScoreEntryDialog._semesters
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item['value'],
                                    child: Text(item['label'] ?? ''),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              setState(() => _selectedSemester = value);
                              await _loadSheet();
                            },
                            hint: 'ເລືອກຮອບປະເມີນ',
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: AppDropdown<String>(
                            label: 'ວິຊາ',
                            value: selectedSubjectValue,
                            items: availableSubjects
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.subjectId,
                                    child: Text(item.subjectName),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              setState(() {
                                _selectedSubjectId = value;
                                _selectedSubjectDetailId = null;
                                _selectedLevelId = null;
                              });
                              await _loadLevelsForSubject();
                            },
                            hint: 'ເລືອກວິຊາ',
                            enabled: !evaluationState.isLoadingSubjects,
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: AppDropdown<String>(
                            label: 'ຊັ້ນຮຽນ/ລະດັບ',
                            value: selectedLevelValue,
                            items: availableLevels
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.subjectDetailId,
                                    child: Text(item.levelName),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              final selectedLevel = availableLevels
                                  .where(
                                    (item) => item.subjectDetailId == value,
                                  )
                                  .firstOrNull;
                              setState(() {
                                _selectedSubjectDetailId = value;
                                _selectedLevelId = selectedLevel?.levelId;
                              });
                              await _loadSheet();
                            },
                            hint: 'ເລືອກລະດັບ',
                            enabled: availableLevels.isNotEmpty,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_displayStudents.isNotEmpty) ...[
                      SizedBox(
                        width: 320,
                        child: AppTextField(
                          controller: _searchController,
                          hint: 'ຄົ້ນຫານັກຮຽນ',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(Icons.close_rounded),
                                ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Expanded(child: _buildEditableTable(evaluationState)),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'ຍົກເລີກ',
                    icon: Icons.close_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: evaluationState.isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: primaryActionLabel,
                    icon: primaryActionIcon,
                    onPressed: canSave ? _arrangeAndPersistSheet : null,
                    isLoading: evaluationState.isSaving,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
