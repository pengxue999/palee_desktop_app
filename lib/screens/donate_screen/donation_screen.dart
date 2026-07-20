import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/utils/donation_certificate_printer.dart';
import '../../core/utils/format_utils.dart';
import '../../models/donation_category_model.dart';
import '../../models/donation_model.dart';
import '../../models/donor_model.dart';
import '../../providers/donation_category_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/success_overlay.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_editable_dropdown.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_searchable_dropdown.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_date_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/print_preparation_overlay.dart';

const _donationUnitOptions = ['ແພັກ', 'ຫົວ', 'ກີບ', 'ຖົງ', 'ອັນ', 'ໝ່ວຍ'];

class DonationScreen extends ConsumerStatefulWidget {
  const DonationScreen({super.key});

  @override
  ConsumerState<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends ConsumerState<DonationScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  bool _isPreparingPrint = false;
  DonationModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedDonorId;
  int? _selectedCategoryId;
  bool _autoValidate = false;

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _amountController.text.trim().isNotEmpty &&
        _selectedDonorId != null &&
        _selectedCategoryId != null &&
        _unitController.text.trim().isNotEmpty;
  }

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(donationProvider.notifier).getDonations();
      ref.read(donorProvider.notifier).getDonors();
      ref.read(donationCategoryProvider.notifier).getDonationCategories();
      if (mounted) {
        final error = ref.read(donationProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  List<DonationModel> get _donations => ref.watch(donationProvider).donations;
  List<DonorModel> get _donors => ref.watch(donorProvider).donors;
  List<DonationCategoryModel> get _categories =>
      ref.watch(donationCategoryProvider).donationCategories;

  String _formatDateForApi(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return dateStr;
        }
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  void _resetForm() {
    _nameController.clear();
    _amountController.clear();
    _unitController.clear();
    final now = DateTime.now();
    _dateController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _selectedDonorId = null;
    _selectedCategoryId = null;
    selectedItem = null;
    isEditing = false;
    _autoValidate = false;
    // Use a fresh key for each modal instance so the previous Form element is
    // never reactivated via a stale GlobalKey (which throws the framework
    // "_elements.contains(element)" assertion when reopening after a save/edit).
    _formKey = GlobalKey<FormState>();
  }

  void _openAdd() async {
    _resetForm();
    if (_donors.isEmpty || _categories.isEmpty) {
      await Future.wait([
        ref.read(donorProvider.notifier).getDonors(),
        ref.read(donationCategoryProvider.notifier).getDonationCategories(),
      ]);
    }
    setState(() {
      showAddEditModal = true;
      isEditing = false;
    });
  }

  void _openEdit(DonationModel item) async {
    await Future.wait([
      ref.read(donorProvider.notifier).getDonors(),
      ref.read(donationCategoryProvider.notifier).getDonationCategories(),
    ]);

    await Future.delayed(const Duration(milliseconds: 100));

    final donors = ref.read(donorProvider).donors;

    _nameController.text = item.donationName;
    _amountController.text = FormatUtils.formatNumber(item.amount.toInt());
    _unitController.text = item.unit;
    _dateController.text = _formatDateForApi(item.donationDate);

    final matchingDonor = donors.firstWhere(
      (d) => d.fullName == item.donorFullName,
      orElse: () => donors.first,
    );
    _selectedDonorId = matchingDonor.donorId;

    _selectedCategoryId = item.donationCategoryId;

    // Fresh key per modal instance — see note in _resetForm().
    _formKey = GlobalKey<FormState>();

    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    setState(() {
      _autoValidate = true;
    });

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDonorId == null ||
        _selectedCategoryId == null ||
        _unitController.text.trim().isEmpty) {
      return;
    }

    final amountStr = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountStr);

    if (amount == null || amount <= 0) {
      return;
    }

    bool success;
    if (isEditing && selectedItem != null) {
      final request = DonationUpdateRequest(
        donorId: _selectedDonorId!,
        donationCategoryId: _selectedCategoryId!,
        donationName: _nameController.text.trim(),
        amount: amount,
        unit: _unitController.text.trim(),
        donationDate: _formatDateForApi(_dateController.text),
      );
      success = await ref
          .read(donationProvider.notifier)
          .updateDonation(selectedItem!.donationId, request);
    } else {
      final request = DonationRequest(
        donorId: _selectedDonorId!,
        donationCategoryId: _selectedCategoryId!,
        donationName: _nameController.text.trim(),
        amount: amount,
        unit: _unitController.text.trim(),
        donationDate: _formatDateForApi(_dateController.text),
      );
      success = await ref
          .read(donationProvider.notifier)
          .createDonation(request);
    }

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else {
      final errorMessage = ref.read(donationProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(DonationModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem != null) {
      final success = await ref
          .read(donationProvider.notifier)
          .deleteDonation(selectedItem!.donationId);

      if (mounted) {
        setState(() {
          showDeleteDialog = false;
        });
      }

      if (success && mounted) {
        SuccessOverlay.show(context, message: 'ລຶບການບໍລິຈາກສຳເລັດ');
        setState(() {
          selectedItem = null;
        });
      } else if (mounted) {
        final errorMessage = ref.read(donationProvider).error;
        ApiErrorHandler.handle(
          context,
          errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
        );
      }
    }
  }

  Future<void> _printCertificate(DonationModel item) async {
    if (_isPreparingPrint) {
      return;
    }

    setState(() => _isPreparingPrint = true);

    await showDonationCertificatePrintDialog(
      context: context,
      donationId: item.donationId,
      onPreviewReady: () {
        if (mounted && _isPreparingPrint) {
          setState(() => _isPreparingPrint = false);
        }
      },
    );

    if (mounted && _isPreparingPrint) {
      setState(() => _isPreparingPrint = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = [
      DataColumnDef<DonationModel>(
        key: 'donorFullName',
        label: 'ຜູ້ບໍລິຈາກ',
        flex: 2,
        render: (context, item) => Text(item.donorFullName),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationName',
        label: 'ລາຍການການບໍລິຈາກ',
        flex: 2,
        render: (context, item) => Text(item.donationName),
      ),
      DataColumnDef<DonationModel>(
        key: 'amount',
        label: 'ຈຳນວນ',
        flex: 2,
        render: (context, item) =>
            Text(FormatUtils.formatNumber(item.amount.toInt())),
      ),
      DataColumnDef<DonationModel>(
        key: 'unit',
        label: 'ຫົວໜ່ວຍ',
        flex: 2,
        render: (context, item) => Text(item.unit.isEmpty ? '-' : item.unit),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationCategory',
        label: 'ປະເພດ',
        flex: 2,
        render: (context, item) => Text(item.donationCategory),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationDate',
        label: 'ວັນທີ',
        flex: 2,
        render: (context, item) => Text(item.donationDate),
      ),
    ];

    final donationState = ref.watch(donationProvider);
    final isLoading = donationState.isLoading && _donations.isEmpty;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Skeletonizer(
            enabled: isLoading,
            child: AppDataTable<DonationModel>(
              columns: columns,
              onAdd: _openAdd,
              onPrint: _printCertificate,
              onEdit: _openEdit,
              onDelete: _confirmDelete,
              searchKeys: const [
                'donationName',
                'donorFullName',
                'donationCategory',
                'unit',
              ],
              addLabel: 'ເພີ່ມການບໍລິຈາກ',
              data: _donations,
            ),
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
        if (_isPreparingPrint)
          const PrintPreparationOverlay(
            icon: Icons.workspace_premium_rounded,
            title: 'ກຳລັງໂຫຼດ...',
            message:
                'ລະບົບກຳລັງດຶງຂໍ້ມູນໃບກຽດຕິຄຸນ ແລະ ສ້າງ preview ໃຫ້ພ້ອມສຳລັບການພິມ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
    );
  }

  Widget _buildFormModal() {
    final isSubmitting = ref.watch(donationProvider).isCreating;

    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂການບໍລິຈາກ' : 'ເພີ່ມການບໍລິຈາກໃໝ່',
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
                icon: Icons.save_rounded,
                isLoading: isSubmitting,
                onPressed: (isSubmitting || !_isFormValid) ? null : _save,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: AppSearchableDropdown<String>(
                        label: 'ຜູ້ບໍລິຈາກ',
                        hint: 'ເລືອກຜູ້ບໍລິຈາກ',
                        searchHint: 'ຄົ້ນຫາຊື່ຜູ້ບໍລິຈາກ...',
                        emptyText: 'ບໍ່ພົບຜູ້ບໍລິຈາກ',
                        value: _donors.any((d) => d.donorId == _selectedDonorId)
                            ? _selectedDonorId
                            : null,
                        items: _donors
                            .map(
                              (d) => AppSearchableItem(
                                value: d.donorId,
                                label: d.fullName,
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedDonorId = v;
                        }),
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppDropdown<int>(
                        label: 'ປະເພດການບໍລິຈາກ',
                        hint: 'ເລືອກປະເພດ',
                        value: _selectedCategoryId,
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category.donationCategoryId,
                                child: Text(category.donationCategoryName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedCategoryId = v;
                        }),
                        required: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'ລາຍການການບໍລິຈາກ',
                        hint: 'ກະລຸນາປ້ອນລາຍການ',
                        controller: _nameController,
                        required: true,
                        validator: (v) => v?.isNotEmpty == true
                            ? null
                            : 'ກະລຸນາປ້ອນລາຍການການບໍລິຈາກ',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        label: 'ຈຳນວນ',
                        hint: '0',
                        controller: _amountController,
                        required: true,
                        keyboardType: TextInputType.number,
                        thousandsSeparator: true,
                        digitOnly: DigitOnly.integer,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: AppEditableDropdown(
                        label: 'ຫົວໜ່ວຍ',
                        hint: 'ເລືອກ ຫຼື ພິມຫົວໜ່ວຍ',
                        controller: _unitController,
                        options: _donationUnitOptions,
                        required: true,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'ກະລຸນາລະບຸຫົວໜ່ວຍ';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppDateField(
                        label: 'ວັນທີ່ບໍລິຈາກ',
                        controller: _dateController,
                        required: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    return Material(
      color: Colors.black54,
      child: Center(
        child: ConfirmDialog(
          title: 'ຢືນຢັນການລຶບ',
          message:
              'ທ່ານຕ້ອງການລຶບການບໍລິຈາກ "${selectedItem?.donationName}" ຫຼືບໍ່?',
          onConfirm: _delete,
          onCancel: () => setState(() {
            showDeleteDialog = false;
          }),
          type: ConfirmDialogType.danger,
        ),
      ),
    );
  }
}
