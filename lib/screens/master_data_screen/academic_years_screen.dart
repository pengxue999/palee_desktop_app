import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/enum_localization.dart';
import '../../models/academic_year_model.dart';
import '../../providers/academic_year_provider.dart';
import '../../widgets/app_alerts.dart';

import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_date_field.dart';
import '../../widgets/app_button.dart';

class _AcademicYearInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;

    final formatted = limitedDigits.length <= 4
        ? limitedDigits
        : '${limitedDigits.substring(0, 4)}-${limitedDigits.substring(4)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AcademicYearsScreen extends ConsumerStatefulWidget {
  const AcademicYearsScreen({super.key});

  @override
  ConsumerState<AcademicYearsScreen> createState() =>
      _AcademicYearsScreenState();
}

class _AcademicYearsScreenState extends ConsumerState<AcademicYearsScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  AcademicYearModel? selectedItem;
  bool isEditing = false;

  /// ສົກຮຽນທີ່ກຳລັງປ່ຽນສະຖານະຢູ່ (ໃຊ້ປິດ toggle ທັງໝົດໃນລະຫວ່າງບັນທຶກ)
  String? statusUpdatingId;
  AcademicYearModel? pendingStatusItem;
  bool pendingStatusValue = false;

  final _yearController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  String _selectedStatus = 'ດໍາເນີນການ';
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(academicYearProvider.notifier).getAcademicYears();
      if (mounted) {
        final error = ref.read(academicYearProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _yearController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _selectedStatus = 'ດໍາເນີນການ';
    _showValidationErrors = false;
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

  String _toIsoDate(String ddMmYyyy) {
    final parts = ddMmYyyy.split('-');
    if (parts.length == 3 && parts[0].length == 2) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return ddMmYyyy;
  }

  void _openEdit(AcademicYearModel item) {
    _yearController.text = item.academicYear;
    _startDateController.text = _toIsoDate(item.startDate);
    _endDateController.text = _toIsoDate(item.endDate);
    _selectedStatus = item.academicStatus;
    setState(() {
      _showValidationErrors = false;
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  DateTime? _parseIsoDateStrict(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }

    final normalized =
        '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    return normalized == value ? parsed : null;
  }

  bool _isValidAcademicYear(String value) {
    if (!RegExp(r'^\d{4}-\d{4}$').hasMatch(value)) {
      return false;
    }

    final parts = value.split('-');
    final startYear = int.tryParse(parts[0]);
    final endYear = int.tryParse(parts[1]);
    if (startYear == null || endYear == null) {
      return false;
    }

    return endYear == startYear + 1;
  }

  String? get _academicYearErrorText {
    final value = _yearController.text.trim();
    if (value.isEmpty) {
      return 'ກະລຸນາປ້ອນສົກຮຽນ';
    }
    if (!_isValidAcademicYear(value)) {
      return 'ຈົ່ງຂຽນຮູບແບບ: 2024-2025, 2025-2026';
    }
    return null;
  }

  String? get _startDateErrorText {
    final value = _startDateController.text;
    if (value.isEmpty) {
      return 'ກະລຸນາເລືອກວັນທີເລີ່ມຮຽນ';
    }
    if (_parseIsoDateStrict(value) == null) {
      return 'ກະລຸນາປ້ອນວັນທີໃຫ້ຖືກຕ້ອງ';
    }
    return null;
  }

  String? get _endDateErrorText {
    final endValue = _endDateController.text;
    if (endValue.isEmpty) {
      return 'ກະລຸນາເລືອກວັນທີສິ້ນສຸດຮຽນ';
    }

    final endDate = _parseIsoDateStrict(endValue);
    if (endDate == null) {
      return 'ກະລຸນາປ້ອນວັນທີໃຫ້ຖືກຕ້ອງ';
    }

    final startDate = _parseIsoDateStrict(_startDateController.text);
    if (startDate != null && !endDate.isAfter(startDate)) {
      return 'ວັນທີສິ້ນສຸດຕ້ອງຫຼາຍກວ່າວັນທີເລີ່ມ';
    }

    return null;
  }

  DateTime? get _minimumEndDate {
    final startDate = _parseIsoDateStrict(_startDateController.text);
    if (startDate == null) {
      return null;
    }
    return startDate.add(const Duration(days: 1));
  }

  void _handleAcademicYearChanged(String _) {
    setState(() {});
  }

  void _handleStartDateChanged(String _) {
    final startDate = _parseIsoDateStrict(_startDateController.text);
    final endDate = _parseIsoDateStrict(_endDateController.text);

    if (startDate != null && endDate != null && !endDate.isAfter(startDate)) {
      _endDateController.clear();
    }

    setState(() {});
  }

  void _handleEndDateChanged(String _) {
    setState(() {});
  }

  Future<void> _save() async {
    setState(() {
      _showValidationErrors = true;
    });

    if (!_isFormValid) {
      return;
    }

    final request = AcademicYearRequest(
      academicYear: _yearController.text.trim(),
      startDate: _startDateController.text,
      endDate: _endDateController.text,
      academicStatus: _selectedStatus,
    );

    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(academicYearProvider.notifier)
          .updateAcademicYear(selectedItem!.academicId!, request);
    } else {
      success = await ref
          .read(academicYearProvider.notifier)
          .createAcademicYear(request);
    }

    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(academicYearProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmStatusChange(AcademicYearModel item, bool makeActive) {
    if (item.academicId == null) return;
    setState(() {
      pendingStatusItem = item;
      pendingStatusValue = makeActive;
    });
  }

  Future<void> _applyStatusChange() async {
    final item = pendingStatusItem;
    if (item?.academicId == null) return;

    final academicId = item!.academicId!;
    setState(() {
      statusUpdatingId = academicId;
      pendingStatusItem = null;
    });

    final success = await ref
        .read(academicYearProvider.notifier)
        .updateAcademicYearStatus(
          academicId,
          pendingStatusValue ? 'ACTIVE' : 'ENDED',
        );

    if (!mounted) return;
    setState(() {
      statusUpdatingId = null;
    });

    if (!success) {
      ApiErrorHandler.handle(
        context,
        ref.read(academicYearProvider).error ??
            'ເກີດຂໍ້ຜິດພາດໃນການປ່ຽນສະຖານະສົກຮຽນ',
      );
    }
  }

  void _confirmDelete(AcademicYearModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem != null) {
      final success = await ref
          .read(academicYearProvider.notifier)
          .deleteAcademicYear(selectedItem!.academicId!);

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
        final errorMessage = ref.read(academicYearProvider).error;
        ApiErrorHandler.handle(
          context,
          errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
        );
      }
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) => isActiveAcademicStatus(status)
      ? AppColors.success
      : AppColors.mutedForeground;

  @override
  Widget build(BuildContext context) {
    final academicYearState = ref.watch(academicYearProvider);
    final items = academicYearState.academicYears.isNotEmpty
        ? academicYearState.academicYears
        : <AcademicYearModel>[];
    final isLoading = academicYearState.isLoading && items.isEmpty;

    final columns = [
      DataColumnDef<AcademicYearModel>(
        key: 'academicId',
        label: 'ລະຫັດ',
        flex: 1,
      ),
      DataColumnDef<AcademicYearModel>(
        key: 'academicYear',
        label: 'ສົກຮຽນ',
        flex: 2,
      ),
      DataColumnDef<AcademicYearModel>(
        key: 'startDate',
        label: 'ເລີ່ມຮຽນ',
        flex: 2,
      ),
      DataColumnDef<AcademicYearModel>(
        key: 'endDate',
        label: 'ສິ້ນສຸດຮຽນ',
        flex: 2,
      ),
      DataColumnDef<AcademicYearModel>(
        key: 'academicStatus',
        label: 'ສະຖານະ',
        flex: 2,
        render: (value, row) {
          final isActive = isActiveAcademicStatus(value);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ໃຊ້ WidgetStateProperty ເພື່ອຄວບຄຸມສີເອງ ລວມທັງຕອນ disabled
              // ໃນລະຫວ່າງກຳລັງບັນທຶກສະຖານະ.
              Switch(
                value: isActive,
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : AppColors.mutedForeground,
                ),
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.muted,
                ),
                trackOutlineColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.border,
                ),
                onChanged: statusUpdatingId != null
                    ? null
                    : (v) => _confirmStatusChange(row, v),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: _statusColor(value),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: AppDataTable<AcademicYearModel>(
                  data: items,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const ['academicYear', 'academicStatus'],
                  addLabel: 'ເພີ່ມສົກຮຽນ',
                  isLoading: isLoading,
                  isRowMuted: (row) =>
                      !isActiveAcademicStatus(row.academicStatus),
                ),
              ),
            ],
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
        if (pendingStatusItem != null) _buildStatusDialog(),
      ],
    );
  }

  bool get _isFormValid {
    return _academicYearErrorText == null &&
        _startDateErrorText == null &&
        _endDateErrorText == null;
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(academicYearProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂສົກຮຽນ' : 'ເພີ່ມສົກຮຽນໃໝ່',
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
                icon: Icons.save,
                isLoading: isLoading,
                onPressed: (isLoading || !_isFormValid) ? null : _save,
              ),
            ],
          ),
          child: Column(
            children: [
              AppTextField(
                label: 'ສົກຮຽນ',
                hint: '2024-2025',
                controller: _yearController,
                required: true,
                maxLength: 9,
                keyboardType: TextInputType.number,
                inputFormatters: [_AcademicYearInputFormatter()],
                onChanged: _handleAcademicYearChanged,
                errorText: _showValidationErrors
                    ? _academicYearErrorText
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppDateField(
                      label: 'ວັນທີເລີ່ມຮຽນ',
                      controller: _startDateController,
                      required: true,
                      onChanged: _handleStartDateChanged,
                      errorText: _showValidationErrors
                          ? _startDateErrorText
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppDateField(
                      label: 'ວັນທີສິ້ນສຸດຮຽນ',
                      controller: _endDateController,
                      required: true,
                      firstDate: _minimumEndDate,
                      onChanged: _handleEndDateChanged,
                      errorText: _showValidationErrors
                          ? _endDateErrorText
                          : null,
                    ),
                  ),
                ],
              ),
              if (!isEditing) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ສົກຮຽນໃໝ່ຈະຖືກຕັ້ງເປັນ "ດໍາເນີນການ" ແລະ ສົກຮຽນເກົ່າຈະຖືກປ່ຽນເປັນ "ສິ້ນສຸດ"',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDialog() {
    final item = pendingStatusItem;
    if (item == null) return const SizedBox.shrink();

    final currentActive = ref
        .watch(academicYearProvider)
        .academicYears
        .where(
          (ay) =>
              isActiveAcademicStatus(ay.academicStatus) &&
              ay.academicId != item.academicId,
        )
        .firstOrNull;

    final makeActive = pendingStatusValue;
    final message = makeActive
        ? (currentActive != null
              ? 'ຕັ້ງ "${item.academicYear}" ເປັນສົກຮຽນດໍາເນີນການ ແລະ ປ່ຽນ "${currentActive.academicYear}" ເປັນສິ້ນສຸດ?'
              : 'ຕັ້ງ "${item.academicYear}" ເປັນສົກຮຽນດໍາເນີນການ?')
        : 'ປ່ຽນ "${item.academicYear}" ເປັນສົກຮຽນສິ້ນສຸດ?\n'
              'ຈະບໍ່ມີສົກຮຽນດໍາເນີນການຈົນກວ່າຈະຕັ້ງສົກຮຽນອື່ນ';

    void close() => setState(() => pendingStatusItem = null);

    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: 'ຢືນຢັນການປ່ຽນສະຖານະ',
          size: AppDialogSize.small,
          onClose: close,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: close,
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'ຢືນຢັນ',
                icon: Icons.check,
                onPressed: _applyStatusChange,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                message,
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

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(academicYearProvider).isLoading;
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
                icon: Icons.delete,
                variant: AppButtonVariant.danger,
                isLoading: isLoading,
                onPressed: isLoading ? null : _delete,
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
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.academicYear}"?',
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
