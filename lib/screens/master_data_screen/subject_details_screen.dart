import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../models/subject_detail_model.dart';
import '../../providers/subject_detail_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/level_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_button.dart';

class SubjectDetailsScreen extends ConsumerStatefulWidget {
  const SubjectDetailsScreen({super.key});

  @override
  ConsumerState<SubjectDetailsScreen> createState() =>
      _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends ConsumerState<SubjectDetailsScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  SubjectDetailModel? selectedItem;
  bool isEditing = false;

  String? _selectedSubjectId;
  String? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(subjectDetailProvider.notifier).getSubjectDetails();
      ref.read(subjectProvider.notifier).getSubjects();
      ref.read(levelProvider.notifier).getLevels();
      if (mounted) {
        final error = ref.read(subjectDetailProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _selectedSubjectId = null;
    _selectedLevelId = null;
    selectedItem = null;
    isEditing = false;
  }

  void _openAdd() {
    _resetForm();
    setState(() {
      showAddEditModal = true;
      isEditing = false;
    });
  }

  void _openEdit(SubjectDetailModel item) {
    setState(() {
      selectedItem = item;
      _selectedSubjectId = item.subjectId;
      _selectedLevelId = item.levelId;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (_selectedSubjectId == null || _selectedLevelId == null) return;

    final request = SubjectDetailRequest(
      subjectId: _selectedSubjectId!,
      levelId: _selectedLevelId!,
    );

    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(subjectDetailProvider.notifier)
          .updateSubjectDetail(selectedItem!.subjectDetailId, request);
    } else {
      success = await ref
          .read(subjectDetailProvider.notifier)
          .createSubjectDetail(request);
    }

    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(subjectDetailProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(SubjectDetailModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) return;
    final success = await ref
        .read(subjectDetailProvider.notifier)
        .deleteSubjectDetail(selectedItem!.subjectDetailId);

    if (mounted) {
      setState(() {
        showDeleteDialog = false;
      });
    }

    if (success && mounted) {
      setState(() {
        selectedItem = null;
      });
    } else if (mounted) {
      final errorMessage = ref.read(subjectDetailProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subjectDetailProvider);
    final subjectState = ref.watch(subjectProvider);
    final levelState = ref.watch(levelProvider);
    final isLoading = state.isLoading && state.subjectDetails.isEmpty;

    final subjectMap = {
      for (final s in subjectState.subjects) s.subjectId: s.subjectName,
    };
    final levelMap = {
      for (final l in levelState.levels) l.levelId: l.levelName,
    };

    final displayItems = state.subjectDetails
        .map(
          (sd) => _SubjectDetailDisplay(
            model: sd,
            subjectName: subjectMap[sd.subjectId] ?? sd.subjectId,
            levelName: levelMap[sd.levelId] ?? sd.levelId,
          ),
        )
        .toList();

    final columns = [
      DataColumnDef<_SubjectDetailDisplay>(
        key: 'subjectDetailId',
        label: 'ລະຫັດ',
        flex: 2,
        render: (v, row) => Text(
          v.toString(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      DataColumnDef<_SubjectDetailDisplay>(
        key: 'subjectName',
        label: 'ຊື່ວິຊາ',
        flex: 3,
      ),
      DataColumnDef<_SubjectDetailDisplay>(
        key: 'levelName',
        label: 'ຊັ້ນ/ລະດັບ',
        flex: 2,
        render: (v, row) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            v.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ),
      ),
    ];

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppDataTable<_SubjectDetailDisplay>(
                  data: isLoading ? _getMockSubjectDetails() : displayItems,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: (display) => _openEdit(display.model),
                  onDelete: (display) => _confirmDelete(display.model),
                  searchKeys: const [
                    'subjectDetailId',
                    'subjectName',
                    'levelName',
                  ],
                  addLabel: 'ເພີ່ມລາຍລະອຽດ',
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        ),
        if (showAddEditModal)
          _buildFormModal(subjectState, levelState, subjectMap, levelMap),
        if (showDeleteDialog) _buildDeleteDialog(subjectMap, levelMap),
      ],
    );
  }

  List<_SubjectDetailDisplay> _getMockSubjectDetails() {
    return List.generate(
      5,
      (index) => _SubjectDetailDisplay(
        model: SubjectDetailModel(
          subjectDetailId: 'SD00${index + 1}',
          subjectId: 'SUBJ${index + 1}',
          levelId: 'LEV${index + 1}',
          subjectName: '',
          levelName: '',
        ),
        subjectName: 'ວິຊາ ${index + 1}',
        levelName: 'ຊັ້ນ ${index + 1}',
      ),
    );
  }

  bool get _isFormValid {
    return _selectedSubjectId != null && _selectedLevelId != null;
  }

  Widget _buildFormModal(
    SubjectState subjectState,
    LevelState levelState,
    Map<String, String> subjectMap,
    Map<String, String> levelMap,
  ) {
    final sdState = ref.watch(subjectDetailProvider);
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂລາຍລະອຽດວິຊາ' : 'ເພີ່ມລາຍລະອຽດວິຊາໃໝ່',
          size: AppDialogSize.medium,
          onClose: () => setState(() {
            showAddEditModal = false;
            _resetForm();
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showAddEditModal = false;
                  _resetForm();
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: isEditing ? 'ຢືນຢັນ' : 'ບັນທຶກ',
                icon: Icons.save_rounded,
                isLoading: sdState.isLoading,
                onPressed: (sdState.isLoading || !_isFormValid) ? null : _save,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDropdown<String>(
                label: 'ວິຊາ',
                hint: 'ເລືອກວິຊາ',
                value: _selectedSubjectId,
                required: true,
                items: subjectState.subjects
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.subjectId,
                        child: Text(s.subjectName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedSubjectId = v),
              ),
              const SizedBox(height: 16),
              AppDropdown<String>(
                label: 'ຊັ້ນ/ລະດັບ',
                hint: 'ເລືອກຊັ້ນ/ລະດັບ',
                value: _selectedLevelId,
                required: true,
                items: levelState.levels
                    .map(
                      (l) => DropdownMenuItem(
                        value: l.levelId,
                        child: Text(l.levelName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedLevelId = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog(
    Map<String, String> subjectMap,
    Map<String, String> levelMap,
  ) {
    if (selectedItem == null) return const SizedBox.shrink();
    final sdState = ref.watch(subjectDetailProvider);
    final subjectName =
        subjectMap[selectedItem!.subjectId] ?? selectedItem!.subjectId;
    final levelName = levelMap[selectedItem!.levelId] ?? selectedItem!.levelId;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: 'ຢືນຢັນການລຶບ',
          size: AppDialogSize.small,
          onClose: () => setState(() {
            showDeleteDialog = false;
            selectedItem = null;
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showDeleteDialog = false;
                  selectedItem = null;
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'ລຶບ',
                icon: Icons.delete_rounded,
                variant: AppButtonVariant.danger,
                isLoading: sdState.isLoading,
                onPressed: _delete,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              Text(
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "$subjectName - $levelName"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectDetailDisplay {
  final SubjectDetailModel model;
  final String subjectName;
  final String levelName;

  _SubjectDetailDisplay({
    required this.model,
    required this.subjectName,
    required this.levelName,
  });

  dynamic operator [](String key) {
    switch (key) {
      case 'subjectDetailId':
        return model.subjectDetailId;
      case 'subjectName':
        return subjectName;
      case 'levelName':
        return levelName;
      default:
        return null;
    }
  }
}
