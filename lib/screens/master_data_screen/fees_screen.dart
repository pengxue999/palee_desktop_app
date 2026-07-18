import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/utils/format_utils.dart';
import 'package:palee_elite_training_center/core/utils/responsive_utils.dart';
import 'package:palee_elite_training_center/models/subject_detail_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/enum_localization.dart';
import '../../models/fee_model.dart';
import '../../providers/fee_provider.dart';
import '../../providers/subject_detail_provider.dart';
import '../../providers/academic_year_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_dropdown.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  static const double _minFee = 500000;

  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  FeeModel? selectedItem;
  bool isEditing = false;

  String? selectedSubjectDetailId;
  String? selectedAcademicId;
  String? _selectedSubjectFilter;
  String? _academicYearFilter;
  bool _submitted = false;
  final _feeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(feeProvider.notifier).getFees();
      ref.read(subjectDetailProvider.notifier).getSubjectDetails();
      ref.read(academicYearProvider.notifier).getAcademicYears();
      if (mounted) {
        final error = ref.read(feeProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    selectedSubjectDetailId = null;
    selectedAcademicId = null;
    _selectedSubjectFilter = null;
    _submitted = false;
    _feeController.clear();
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

  void _openEdit(FeeModel item) {
    final subjectDetails = ref.read(subjectDetailProvider).subjectDetails;
    final academicYears = ref.read(academicYearProvider).academicYears;

    final subjectDetail = _firstWhereOrNull<SubjectDetailModel>(
      subjectDetails,
      (sd) =>
          sd.subjectName == item.subjectName && sd.levelName == item.levelName,
    );
    final academic = _firstWhereOrNull(
      academicYears,
      (a) => a.academicYear == item.academicYear,
    );

    selectedSubjectDetailId = subjectDetail?.subjectDetailId;
    selectedAcademicId = academic?.academicId;
    _feeController.text = item.fee.toStringAsFixed(0);

    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  double get _feeValue =>
      double.tryParse(_feeController.text.replaceAll(',', '')) ?? 0;

  Future<void> _save() async {
    setState(() => _submitted = true);

    if (!_isFormValid) {
      return;
    }

    final feeValue = _feeValue;
    final request = FeeRequest(
      subjectDetailId: selectedSubjectDetailId!,
      academicId: selectedAcademicId!,
      fee: feeValue,
    );

    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(feeProvider.notifier)
          .updateFee(selectedItem!.feeId, request);
    } else {
      success = await ref.read(feeProvider.notifier).createFee(request);
    }

    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(feeProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(FeeModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem != null) {
      final success = await ref
          .read(feeProvider.notifier)
          .deleteFee(selectedItem!.feeId);

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
        final errorMessage = ref.read(feeProvider).error;
        ApiErrorHandler.handle(
          context,
          errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
        );
      }
    }
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feeState = ref.watch(feeProvider);
    final isLoading = feeState.isLoading && feeState.fees.isEmpty;
    final academicYearsList = ref.watch(academicYearProvider).academicYears;
    final endedAcademicYears = <String>{
      for (final a in academicYearsList)
        if (!isActiveAcademicStatus(a.academicStatus)) a.academicYear,
    };

    final columns = [
      DataColumnDef<FeeModel>(key: 'feeId', label: 'ລະຫັດ', flex: 1),
      DataColumnDef<FeeModel>(key: 'subjectName', label: 'ວິຊາ', flex: 2),
      DataColumnDef<FeeModel>(key: 'levelName', label: 'ລະດັບ', flex: 2),
      DataColumnDef<FeeModel>(key: 'academicYear', label: 'ສົກຮຽນ', flex: 2),
      DataColumnDef<FeeModel>(
        key: 'fee',
        label: 'ຄ່າຮຽນ',
        flex: 2,
        render: (value, item) => Text(FormatUtils.formatKip(item.fee.toInt())),
      ),
    ];

    final tableData = isLoading ? _getMockFees() : feeState.fees;

    final academicYears = <String>{
      for (final fee in tableData)
        if (fee.academicYear.isNotEmpty) fee.academicYear,
    }.toList()..sort((a, b) => b.compareTo(a));

    // Drop a stale filter that no longer matches any available year.
    if (_academicYearFilter != null &&
        !academicYears.contains(_academicYearFilter)) {
      _academicYearFilter = null;
    }

    final filteredData = _academicYearFilter == null
        ? tableData
        : tableData
              .where((fee) => fee.academicYear == _academicYearFilter)
              .toList();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: AppDataTable<FeeModel>(
            key: ValueKey(
              'fees_table_${filteredData.length}_${_academicYearFilter ?? 'all'}_$isLoading',
            ),
            data: filteredData,
            columns: columns,
            onAdd: _openAdd,
            onEdit: _openEdit,
            onDelete: _confirmDelete,
            searchKeys: const ['subjectName', 'levelName', 'academicYear'],
            addLabel: 'ເພີ່ມຄ່າຮຽນ',
            isLoading: isLoading,
            headerTrailing: _buildAcademicYearFilter(academicYears),
            isRowMuted: (row) => endedAcademicYears.contains(row.academicYear),
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  Widget _buildAcademicYearFilter(List<String> academicYears) {
    return SizedBox(
      width: 200,
      child: AppDropdown<String?>(
        hint: 'ສົກຮຽນທັງໝົດ',
        value: _academicYearFilter,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('ສົກຮຽນທັງໝົດ'),
          ),
          ...academicYears.map(
            (year) => DropdownMenuItem<String?>(value: year, child: Text(year)),
          ),
        ],
        onChanged: (value) => setState(() => _academicYearFilter = value),
      ),
    );
  }

  List<FeeModel> _getMockFees() {
    return List.generate(
      5,
      (index) => FeeModel(
        feeId: 'FEE00${index + 1}',
        subjectName: 'ວິຊາ ${index + 1}',
        levelName: 'ຊັ້ນ ${index + 1}',
        academicYear: '2024-2025',
        fee: 500000 + (index * 100000),
        subjectCategory: '',
      ),
    );
  }

  bool get _isFormValid {
    return selectedSubjectDetailId != null &&
        selectedAcademicId != null &&
        _feeController.text.isNotEmpty &&
        _feeValue >= _minFee;
  }

  String? get _academicError {
    if (!_submitted) return null;
    if (selectedAcademicId == null) {
      return 'ກະລຸນາເລືອກສົກຮຽນ';
    }
    return null;
  }

  String? get _feeError {
    if (!_submitted) return null;
    if (_feeController.text.isEmpty) {
      return 'ກະລຸນາປ້ອນຄ່າຮຽນ';
    }
    if (_feeValue < _minFee) {
      return 'ຄ່າຮຽນຕ້ອງບໍ່ຕ່ຳກວ່າ ${FormatUtils.formatKip(_minFee.toInt())}';
    }
    return null;
  }

  Widget _buildFormModal() {
    final subjectDetails = ref.watch(subjectDetailProvider).subjectDetails;
    final academicYears = ref.watch(academicYearProvider).academicYears;
    final isLoading = ref.watch(feeProvider).isLoading;

    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຄ່າຮຽນ' : 'ເພີ່ມຄ່າຮຽນໃໝ່',
          size: AppDialogSize.large,
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
                onPressed: isLoading ? null : _save,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                AppDropdown<String>(
                  label: 'ສົກຮຽນ',
                  hint: 'ເລືອກສົກຮຽນ',
                  value:
                      academicYears.any(
                        (a) => a.academicId == selectedAcademicId,
                      )
                      ? selectedAcademicId
                      : null,
                  required: true,
                  errorText: _academicError,
                  items: academicYears
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.academicId,
                          child: Text(a.academicYear),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedAcademicId = v),
                ),
                const SizedBox(height: 16),
                _buildSubjectGrid(subjectDetails),

                const SizedBox(height: 16),
                AppTextField(
                  label: 'ຄ່າຮຽນ',
                  hint: 'ເຊັ່ນ: 500000',
                  controller: _feeController,
                  onChanged: (_) => setState(() {}),
                  required: true,
                  keyboardType: TextInputType.number,
                  digitOnly: DigitOnly.integer,
                  thousandsSeparator: true,
                  inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^0'))],
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  errorText: _feeError,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
    for (final item in items) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }

  Widget _buildSubjectGrid(List<SubjectDetailModel> subjectDetails) {
    final subjects = subjectDetails.map((sd) => sd.subjectName).toSet().toList()
      ..sort();

    final filteredDetails = _selectedSubjectFilter == null
        ? subjectDetails
        : subjectDetails
              .where((sd) => sd.subjectName == _selectedSubjectFilter)
              .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < Breakpoints.desktop;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildSectionTitle()],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildSectionTitle()),
                      const SizedBox(width: 16),
                    ],
                  ),
            const SizedBox(height: 16),
            if (subjects.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildSubjectFilterChip(
                    label: 'ທັງໝົດ',
                    isSelected: _selectedSubjectFilter == null,
                    onTap: () => setState(() => _selectedSubjectFilter = null),
                    showCheck: false,
                  ),
                  ...subjects.map((subject) {
                    return _buildSubjectFilterChip(
                      label: subject,
                      isSelected: _selectedSubjectFilter == subject,
                      onTap: () =>
                          setState(() => _selectedSubjectFilter = subject),
                    );
                  }),
                ],
              ),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 380,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF8FBFF),
                            AppColors.primaryLight.withOpacity(0.28),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: subjectDetails.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(
                                            0.08,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.menu_book_outlined,
                                      size: 28,
                                      color: AppColors.primary.withOpacity(
                                        0.75,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'ບໍ່ມີຂໍ້ມູນວິຊາ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.foreground,
                                      fontFamily: 'NotoSansLao',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ເພີ່ມຂໍ້ມູນວິຊາແລະລະດັບກ່ອນຈຶ່ງຈະສາມາດກຳນົດຄ່າຮຽນໄດ້',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.mutedForeground,
                                      fontFamily: 'NotoSansLao',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : filteredDetails.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.filter_list_off,
                                    size: 28,
                                    color: AppColors.mutedForeground,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'ບໍ່ພົບລາຍການສຳລັບວິຊານີ້',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.mutedForeground,
                                      fontFamily: 'NotoSansLao',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, gridConstraints) {
                                final width = gridConstraints.maxWidth;
                                int crossAxisCount = 4;
                                if (width < 620) {
                                  crossAxisCount = 1;
                                } else if (width < Breakpoints.desktop) {
                                  crossAxisCount = 4;
                                } else if (width < 1240) {
                                  crossAxisCount = 6;
                                }

                                return GridView.builder(
                                  padding: const EdgeInsets.all(12),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        mainAxisExtent: 112,
                                      ),
                                  itemCount: filteredDetails.length,
                                  itemBuilder: (context, index) {
                                    final sd = filteredDetails[index];
                                    final isSelected =
                                        sd.subjectDetailId ==
                                        selectedSubjectDetailId;

                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => setState(
                                          () => selectedSubjectDetailId =
                                              sd.subjectDetailId,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFFEAF3FF),
                                                      Color(0xFFDDEBFF),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : const LinearGradient(
                                                    colors: [
                                                      Colors.white,
                                                      Color(0xFFF8FAFC),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.border,
                                              width: isSelected ? 1.8 : 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isSelected
                                                    ? AppColors.primary
                                                          .withOpacity(0.16)
                                                    : const Color(
                                                        0xFF0F172A,
                                                      ).withOpacity(0.05),
                                                blurRadius: isSelected
                                                    ? 18
                                                    : 10,
                                                offset: Offset(
                                                  0,
                                                  isSelected ? 10 : 4,
                                                ),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? AppColors.primary
                                                                  .withOpacity(
                                                                    0.12,
                                                                  )
                                                            : AppColors
                                                                  .background,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        sd.subjectName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: isSelected
                                                              ? AppColors
                                                                    .primaryDark
                                                              : AppColors
                                                                    .mutedForeground,
                                                          fontFamily:
                                                              'NotoSansLao',
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 220,
                                                    ),
                                                    width: 28,
                                                    height: 28,
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? AppColors.primary
                                                          : Colors.white,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? AppColors.primary
                                                            : AppColors.border,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      isSelected
                                                          ? Icons.check_rounded
                                                          : Icons
                                                                .arrow_forward_rounded,
                                                      size: 16,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : AppColors
                                                                .mutedForeground,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              Text(
                                                sd.levelName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
                                                  color: isSelected
                                                      ? AppColors.primaryDark
                                                      : AppColors.foreground,
                                                  letterSpacing: 0.1,
                                                  fontFamily: 'NotoSansLao',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isSelected
                                                    ? 'ກຳລັງເລືອກຢູ່'
                                                    : 'ກົດເພື່ອເລືອກຊລະດັບນີ້',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : AppColors
                                                            .mutedForeground,
                                                  fontFamily: 'NotoSansLao',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ເລືອກວິຊາ ແລະ ຊັ້ນຮຽນ/ລະດັບ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: AppColors.foreground,
                fontFamily: 'NotoSansLao',
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.destructive,
                fontFamily: 'NotoSansLao',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool showCheck = true,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? null : Colors.white,
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.18)
                    : const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: isSelected ? 14 : 8,
                offset: Offset(0, isSelected ? 8 : 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheck && isSelected) ...[
                const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.foreground,
                  fontFamily: 'NotoSansLao',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(feeProvider).isLoading;
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
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.subjectName} - ${selectedItem!.levelName}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
