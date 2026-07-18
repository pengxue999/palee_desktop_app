import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/utils/finance_report_printer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/report_export_action_helper.dart';
import '../../models/report_models.dart';
import '../../providers/report_provider.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/print_preparation_overlay.dart';

class ReportFinanceScreen extends ConsumerStatefulWidget {
  const ReportFinanceScreen({super.key});

  @override
  ConsumerState<ReportFinanceScreen> createState() =>
      _ReportFinanceScreenState();
}

class _ReportFinanceScreenState extends ConsumerState<ReportFinanceScreen> {
  String _activeTab = 'overview';
  int _selectedYear = DateTime.now().year;
  bool _isPreparingPdfPrint = false;

  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await _loadFinanceReport();
  }

  Future<void> _loadFinanceReport() async {
    await ref
        .read(reportProvider.notifier)
        .getFinanceReport(year: _selectedYear);

    final financeData = ref.read(reportProvider).financeData;
    if (financeData != null && financeData.yearlyComparison.isNotEmpty) {
      final years = financeData.yearlyComparison.map((y) => y.year).toList();
      years.sort();
      setState(() {
        _availableYears = years;
        if (!_availableYears.contains(_selectedYear) &&
            _availableYears.isNotEmpty) {
          _selectedYear = _availableYears.last;
        }
      });
    }
  }

  String _formatAmount(double amount) {
    return FormatUtils.formatCurrency(amount);
  }

  String _formatDate(String? date) {
    if (date == null || date == '-') return '-';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return date;
    }
  }

  Future<void> _handleExport() async {
    if (!_canExportExcel) {
      return;
    }

    await ReportExportActionHelper.exportReport(
      context: context,
      reportTitle: _activeTab == 'income' ? 'ລາຍການລາຍຮັບ' : 'ລາຍການລາຍຈ່າຍ',
      requestExport: (format) {
        return ref
            .read(reportProvider.notifier)
            .exportFinanceReport(
              year: _selectedYear,
              tab: _activeTab,
              format: format,
            );
      },
      resolveErrorMessage: () =>
          ref.read(reportProvider).financeError ?? 'ບໍ່ສາມາດ Export ຂໍ້ມູນໄດ້',
    );
  }

  Future<void> _handlePdfPrint(FinanceReportData data) async {
    if (_isPreparingPdfPrint) {
      return;
    }

    final hasPrintableData = switch (_activeTab) {
      'income' => data.incomes.isNotEmpty,
      'expense' => data.expenses.isNotEmpty,
      _ => true,
    };

    if (!hasPrintableData) {
      return;
    }

    setState(() => _isPreparingPdfPrint = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      await showFinanceReportPrintDialog(
        context: context,
        academicId: data.filters.academicId,
        year: _selectedYear,
        tab: _activeTab,
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

  bool get _canExportExcel => true;

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final financeData = reportState.financeData;
    final hasPrintableData =
        financeData != null &&
        (_activeTab == 'overview' ||
            (_activeTab == 'income' && financeData.incomes.isNotEmpty) ||
            (_activeTab == 'expense' && financeData.expenses.isNotEmpty));

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: _loadFinanceReport,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTabs(),
                    Spacer(),
                    SizedBox(
                      width: 120,
                      child: AppDropdown<int>(
                        value: _selectedYear,
                        items: _availableYears.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedYear = value);
                            _loadFinanceReport();
                          }
                        },
                        hint: 'ເລືອກປີ',
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: reportState.isFinanceExporting
                          ? 'ກຳລັງບັນທຶກ...'
                          : 'ສົ່ງອອກເປັນ Excel',
                      icon: Icons.download_rounded,
                      variant: AppButtonVariant.success,
                      onPressed:
                          reportState.isFinanceExporting ||
                              reportState.isFinanceLoading ||
                              _isPreparingPdfPrint ||
                              financeData == null ||
                              !_canExportExcel
                          ? null
                          : _handleExport,
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: _isPreparingPdfPrint ? 'ກຳລັງ ພິມ...' : 'ພິມ PDF',
                      icon: Icons.print_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed:
                          reportState.isFinanceExporting ||
                              reportState.isFinanceLoading ||
                              _isPreparingPdfPrint ||
                              financeData == null ||
                              !hasPrintableData
                          ? null
                          : () => _handlePdfPrint(financeData),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: reportState.isFinanceLoading
                      ? const LoadingWidget(message: 'ກຳລັງໂຫຼດຂໍ້ມູນ...')
                      : financeData == null
                      ? EmptyWidget(
                          title: 'ບໍ່ມີຂໍ້ມູນ',
                          subtitle: 'ກົດດຶງຂໍ້ມູນເພື່ອເບິ່ງລາຍງານ',
                          icon: Icons.insert_chart_outlined,
                          onAction: _loadFinanceReport,
                          actionLabel: 'ດຶງຂໍ້ມູນ',
                        )
                      : _buildContent(financeData),
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
                'ລະບົບກຳລັງສ້າງ PDF ລາຍງານການເງິນ ແລະ ເປີດໜ້າຈໍ preview ສຳລັບການພິມ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = [
      ('overview', 'ພາບລວມ', Icons.dashboard_rounded),
      ('income', 'ລາຍຮັບ', Icons.trending_up_rounded),
      ('expense', 'ລາຍຈ່າຍ', Icons.trending_down_rounded),
    ];

    return Row(
      children: tabs.map((tab) {
        final isActive = _activeTab == tab.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: isActive ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => setState(() => _activeTab = tab.$1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tab.$3,
                      size: 18,
                      color: isActive
                          ? Colors.white
                          : AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab.$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppColors.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContent(FinanceReportData data) {
    switch (_activeTab) {
      case 'overview':
        return _buildOverviewTab(data);
      case 'income':
        return _buildIncomeTab(data);
      case 'expense':
        return _buildExpenseTab(data);
      default:
        return _buildOverviewTab(data);
    }
  }

  Widget _buildOverviewTab(FinanceReportData data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(data.summary),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildIncomePieChart(data.incomeBreakdown)),
              const SizedBox(width: 16),
              Expanded(child: _buildExpensePieChart(data.expenseBreakdown)),
            ],
          ),
          const SizedBox(height: 16),
          _buildYearlyComparisonChart(data.yearlyComparison),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(FinanceSummary summary) {
    final cards = [
      (
        'ລາຍຮັບທັງໝົດ',
        summary.totalIncome,
        AppColors.success,
        Icons.trending_up_rounded,
        AppColors.successLight,
      ),
      (
        'ລາຍຈ່າຍທັງໝົດ',
        summary.totalExpense,
        AppColors.destructive,
        Icons.trending_down_rounded,
        AppColors.destructiveLight,
      ),
      (
        'ຍອດເຫຼືອ',
        summary.balance,
        summary.balance >= 0 ? AppColors.primary : AppColors.warning,
        Icons.account_balance_wallet_rounded,
        summary.balance >= 0 ? AppColors.primaryLight : AppColors.warningLight,
      ),
    ];

    return Row(
      children: cards.map((card) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: card.$5,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(card.$4, color: card.$3, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          card.$1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatAmount(card.$2),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: card.$3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIncomePieChart(List<FinanceBreakdownItem> breakdown) {
    if (breakdown.isEmpty) {
      return AppCard(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                color: AppColors.mutedForeground,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'ບໍ່ມີຂໍ້ມູນລາຍຮັບ',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.secondary,
      AppColors.info,
      AppColors.warning,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ລາຍຮັບແຍກຕາມແຫຼ່ງ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: breakdown.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: item.amount,
                    title: '${item.percentage.toStringAsFixed(1)}%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: breakdown.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.category}: ${_formatAmount(item.amount)}',
                    style: TextStyle(fontSize: 14, color: AppColors.foreground),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensePieChart(List<FinanceBreakdownItem> breakdown) {
    if (breakdown.isEmpty) {
      return AppCard(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                color: AppColors.mutedForeground,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'ບໍ່ມີຂໍ້ມູນລາຍຈ່າຍ',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    final colors = [
      AppColors.destructive,
      AppColors.warning,
      AppColors.info,
      AppColors.secondary,
      AppColors.primary,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ລາຍຈ່າຍແຍກຕາມປະເພດ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: breakdown.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: item.amount,
                    title: '${item.percentage.toStringAsFixed(1)}%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: breakdown.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.category}: ${_formatAmount(item.amount)}',
                    style: TextStyle(fontSize: 14, color: AppColors.foreground),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyComparisonChart(List<YearlyFinanceData> data) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxY = data
        .map((d) => d.income > d.expense ? d.income : d.expense)
        .reduce((a, b) => a > b ? a : b);
    final interval = maxY / 5;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ສົມທຽບລາຍຮັບ-ລາຍຈ່າຍຕາມປີ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 0 ? maxY * 1.2 : 1000000,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final yearData = data[groupIndex];
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        '${yearData.year}\n',
                        const TextStyle(color: Colors.white, fontSize: 12),
                        children: [
                          TextSpan(
                            text:
                                '${isIncome ? "ລາຍຮັບ" : "ລາຍຈ່າຍ"}: ${_formatAmount(rod.toY)}',
                            style: TextStyle(
                              color: isIncome
                                  ? AppColors.success
                                  : AppColors.destructive,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 80,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${(value / 1000000).toStringAsFixed(1)}M',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.mutedForeground,
                          ),
                        );
                      },
                      interval: interval > 0 ? interval : 100000,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${data[index].year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.foreground,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: interval > 0 ? interval : 100000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.border, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final yearData = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: yearData.income,
                        color: AppColors.success,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: yearData.expense,
                        color: AppColors.destructive,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ລາຍຮັບ',
                    style: TextStyle(fontSize: 12, color: AppColors.foreground),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.destructive,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ລາຍຈ່າຍ',
                    style: TextStyle(fontSize: 12, color: AppColors.foreground),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTab(FinanceReportData data) {
    final columns = [
      DataColumnDef<FinanceIncomeItem>(
        key: 'amount',
        label: 'ຈຳນວນເງິນ',
        flex: 2,
        render: (v, row) => Text(
          _formatAmount((v as num).toDouble()),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ),
      DataColumnDef<FinanceIncomeItem>(
        key: 'description',
        label: 'ລາຍລະອຽດ',
        flex: 3,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataColumnDef<FinanceIncomeItem>(
        key: 'source',
        label: 'ແຫຼ່ງທີ່ມາ',
        flex: 2,
        render: (v, row) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            v?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      DataColumnDef<FinanceIncomeItem>(
        key: 'incomeDate',
        label: 'ວັນທີ',
        flex: 2,
        render: (v, row) => Text(
          _formatDate(v?.toString()),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ];

    return AppDataTable<FinanceIncomeItem>(
      title: 'ຂໍ້ມູນລາຍຮັບ',
      subtitle: 'ທັງໝົດ ${data.totalIncomeCount} ລາຍການ',
      data: data.incomes,
      columns: columns,
      searchKeys: const ['description', 'source', 'incomeDate'],
      showActions: false,
    );
  }

  Widget _buildExpenseTab(FinanceReportData data) {
    final columns = [
      DataColumnDef<FinanceExpenseItem>(
        key: 'amount',
        label: 'ຈຳນວນເງິນ',
        flex: 2,
        render: (v, row) => Text(
          _formatAmount((v as num).toDouble()),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.destructive,
          ),
        ),
      ),
      DataColumnDef<FinanceExpenseItem>(
        key: 'description',
        label: 'ລາຍລະອຽດ',
        flex: 3,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataColumnDef<FinanceExpenseItem>(
        key: 'category',
        label: 'ປະເພດ',
        flex: 2,
        render: (v, row) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.destructiveLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            v?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.destructive,
            ),
          ),
        ),
      ),
      DataColumnDef<FinanceExpenseItem>(
        key: 'expenseDate',
        label: 'ວັນທີ',
        flex: 2,
        render: (v, row) => Text(
          _formatDate(v?.toString()),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ];

    return AppDataTable<FinanceExpenseItem>(
      title: 'ຂໍ້ມູນລາຍຈ່າຍ',
      subtitle: 'ທັງໝົດ ${data.totalExpenseCount} ລາຍການ',
      data: data.expenses,
      columns: columns,
      searchKeys: const ['description', 'category', 'expenseDate'],
      showActions: false,
    );
  }
}
