import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/donation_report_printer.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/report_export_action_helper.dart';
import '../../models/donation_category_model.dart';
import '../../models/donation_model.dart';
import '../../models/donor_model.dart';
import '../../providers/donation_category_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/donor_provider.dart';
import '../../services/report_service.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_searchable_dropdown.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/print_preparation_overlay.dart';
const cashDonationCategory = 'ເງິນສົດ';
class ReportDonationScreen extends ConsumerStatefulWidget {
  const ReportDonationScreen({super.key});

  @override
  ConsumerState<ReportDonationScreen> createState() =>
      _ReportDonationScreenState();
}

class _ReportDonationScreenState extends ConsumerState<ReportDonationScreen> {
  String? _selectedDonorId;
  String? _selectedCategory;
  String? _selectedYear;
  final List<String> _availableYears = [];
  final ReportService _reportService = ReportService();
  bool _isExporting = false;
  bool _isPreparingPdfPrint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      ref.read(donationProvider.notifier).getDonations(),
      ref.read(donorProvider.notifier).getDonors(),
      ref.read(donationCategoryProvider.notifier).getDonationCategories(),
    ]);
    _generateAvailableYears();
  }

  void _generateAvailableYears() {
    final donations = ref.read(donationProvider).donations;
    final years = donations
        .map((d) {
          try {
            final parts = d.donationDate.split('-');
            if (parts.length == 3) {
              return parts[2].length == 4 ? parts[2] : parts[0];
            }
            return DateTime.now().year.toString();
          } catch (_) {
            return null;
          }
        })
        .whereType<String>()
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));

    setState(() {
      _availableYears.clear();
      _availableYears.addAll(years);
      if (_availableYears.isNotEmpty && _selectedYear == null) {
        _selectedYear = _availableYears.first;
      }
    });
  }

  List<DonationModel> _getFilteredDonations() {
    final donations = ref.watch(donationProvider).donations;
    return donations.where((d) {
      if (_selectedDonorId != null && d.donorId != _selectedDonorId) {
        return false;
      }
      if (_selectedCategory != null &&
          d.donationCategory != _selectedCategory) {
        return false;
      }
      if (_selectedYear != null) {
        try {
          final parts = d.donationDate.split('-');
          if (parts.length == 3) {
            final year = parts[2].length == 4 ? parts[2] : parts[0];
            if (year != _selectedYear) return false;
          }
        } catch (_) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _handleExport() async {
    final filteredDonations = _getFilteredDonations();
    if (filteredDonations.isEmpty) {
      AppToast.error(context, 'ບໍ່ມີຂໍ້ມູນສຳລັບ Export');
      return;
    }

    setState(() => _isExporting = true);

    try {
      await ReportExportActionHelper.exportReport(
        context: context,
        reportTitle: 'ລາຍງານການບໍລິຈາກ',
        requestExport: (format) async {
          final exportResponse = await _reportService.exportDonationReport(
            donorId: _selectedDonorId,
            donationCategory: _selectedCategory,
            year: int.tryParse(_selectedYear ?? ''),
            format: format,
          );
          return exportResponse.data;
        },
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Export ບໍ່ສຳເລັດ: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handlePdfPrint() async {
    final filteredDonations = _getFilteredDonations();
    if (_isPreparingPdfPrint || filteredDonations.isEmpty) {
      return;
    }

    setState(() => _isPreparingPdfPrint = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      await showDonationReportPrintDialog(
        context: context,
        donorId: _selectedDonorId,
        donationCategory: _selectedCategory,
        year: int.tryParse(_selectedYear ?? ''),
        onPreviewReady: () {
          if (mounted && _isPreparingPdfPrint) {
            setState(() => _isPreparingPdfPrint = false);
          }
        },
      );
    } finally {
      if (mounted && _isPreparingPdfPrint) {
        setState(() => _isPreparingPdfPrint = false);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDonorId = null;
      _selectedCategory = null;
      _selectedYear = _availableYears.isNotEmpty ? _availableYears.first : null;
    });
  }

  String _formatAmount(double amount) {
    return FormatUtils.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    final donationState = ref.watch(donationProvider);
    final donors = ref.watch(donorProvider).donors;
    final donationCategories = ref
        .watch(donationCategoryProvider)
        .donationCategories;
    final filteredDonations = _getFilteredDonations();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: _loadInitialData,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilters(
                  donors,
                  donationCategories,
                  hasData: filteredDonations.isNotEmpty,
                ),
                Expanded(
                  child: donationState.isLoading
                      ? const LoadingWidget(message: 'ກຳລັງໂຫຼດຂໍ້ມູນ...')
                      : filteredDonations.isEmpty
                      ? EmptyWidget(
                          title: 'ບໍ່ມີຂໍ້ມູນ',
                          subtitle: 'ບໍ່ພົບຂໍ້ມູນການບໍລິຈາກຕາມທີ່ກຳນົດ',
                          icon: Icons.volunteer_activism_outlined,
                          onAction: _clearFilters,
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _buildListTab(filteredDonations),
                        ),
                ),
              ],
            ),
          ),
        ),
        if (_isPreparingPdfPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງໂຫຼດ...',
            message:
                'ລະບົບກຳລັງສ້າງ PDF ລາຍງານການບໍລິຈາກ ແລະ ເປີດໜ້າຈໍ preview ສຳລັບການພິມ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
    );
  }

  Widget _buildFilters(
    List<DonorModel> donors,
    List<DonationCategoryModel> donationCategories, {
    required bool hasData,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'ກອງຂໍ້ມູນ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
                label: Text(
                  'Refresh',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: AppDropdown<String>(
                  value: _selectedYear,
                  items: _availableYears.map((year) {
                    return DropdownMenuItem(value: year, child: Text(year));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedYear = value);
                  },
                  hint: 'ສົກຮຽນ',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200,
                child: AppSearchableDropdown<String?>(
                  value: donors.any((d) => d.donorId == _selectedDonorId)
                      ? _selectedDonorId
                      : null,
                  searchHint: 'ຄົ້ນຫາຊື່ຜູ້ບໍລິຈາກ...',
                  emptyText: 'ບໍ່ພົບຜູ້ບໍລິຈາກ',
                  items: [
                    AppSearchableItem<String?>(
                      value: null,
                      label: 'ທັງໝົດຜູ້ບໍລິຈາກ',
                    ),
                    ...donors.map(
                      (donor) => AppSearchableItem<String?>(
                        value: donor.donorId,
                        label: donor.fullName,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDonorId = value);
                  },
                  hint: 'ຜູ້ບໍລິຈາກ',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: AppDropdown<String>(
                  value: _selectedCategory,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('ທັງໝົດປະເພດ'),
                    ),
                    ...donationCategories.map((category) {
                      return DropdownMenuItem(
                        value: category.donationCategoryName,
                        child: Text(
                          category.donationCategoryName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  hint: 'ປະເພດການບໍລິຈາກ',
                ),
              ),
              const Spacer(),
              AppButton(
                label: _isExporting ? 'ກຳລັງບັນທຶກ...' : 'ສົ່ງອອກເປັນ Excel',
                icon: Icons.download_rounded,
                variant: AppButtonVariant.success,
                onPressed: _isExporting || _isPreparingPdfPrint || !hasData
                    ? null
                    : _handleExport,
              ),
              const SizedBox(width: 12),
              AppButton(
                label: _isPreparingPdfPrint ? 'ກຳລັງ ພິມ...' : 'ພິມ PDF',
                icon: Icons.print_rounded,
                variant: AppButtonVariant.primary,
                onPressed: _isExporting || _isPreparingPdfPrint || !hasData
                    ? null
                    : _handlePdfPrint,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTab(List<DonationModel> donations) {
    final columns = [
      DataColumnDef<DonationModel>(
        key: 'donorFullName',
        label: 'ຜູ້ບໍລິຈາກ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationCategory',
        label: 'ປະເພດ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationName',
        label: 'ລາຍການການບໍລິຈາກ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataColumnDef<DonationModel>(
        key: 'amount',
        label: 'ຈຳນວນ',
        flex: 2,
        render: (v, row) {
          final amount = (v as num).toDouble();
          final isCashDonation = row.donationCategory == cashDonationCategory;
          final displayText = isCashDonation
              ? _formatAmount(amount)
              : amount.toString();

          return Text(
            displayText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          );
        },
      ),
      DataColumnDef<DonationModel>(
        key: 'unit',
        label: 'ຫົວໜ່ວຍ',
        flex: 1,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationDate',
        label: 'ວັນທີ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    ];

    return AppDataTable<DonationModel>(
      data: donations,
      columns: columns,
      showActions: false,
    );
  }
}
