import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/enum_localization.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/format_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_year_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/report_provider.dart';
import '../models/academic_year_model.dart';
import '../models/report_models.dart';
import '../widgets/app_card.dart';
import '../widgets/custom_card.dart';
import '../widgets/teacher_subjects_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  bool get _isTeacher => isTeacherRole(ref.read(authProvider).role);

  Future<void> _initializeData() async {
    await ref.read(academicYearProvider.notifier).getAcademicYears();

    final academicYears = ref.read(academicYearProvider).academicYears;
    ref
        .read(dashboardProvider.notifier)
        .setAvailableAcademicYears(academicYears);

    // ອາຈານບໍ່ໂຫຼດ stat ບໍລິຫານ (ລາຍຮັບ/ລາຍຈ່າຍ/ວິຊາຍອດນິຍົມ) —
    // ເຫັນສະເພາະວິຊາທີ່ຕົນສອນ ຜ່ານ TeacherSubjectsCard.
    if (_isTeacher) {
      return;
    }

    final academicId = ref
        .read(dashboardProvider)
        .selectedAcademicYear
        ?.academicId;

    await Future.wait([
      ref
          .read(dashboardProvider.notifier)
          .loadDashboardStats(academicId: academicId),
      ref
          .read(reportProvider.notifier)
          .getPopularSubjectsReport(academicId: academicId),
    ]);
  }

  Future<void> _refreshDashboard() async {
    // ອາຈານບໍ່ມີ stat ບໍລິຫານໃຫ້ refresh — TeacherSubjectsCard ໂຫຼດເອງ.
    if (_isTeacher) {
      return;
    }

    final academicId = ref
        .read(dashboardProvider)
        .selectedAcademicYear
        ?.academicId;

    await Future.wait([
      ref.read(dashboardProvider.notifier).refreshStats(),
      ref
          .read(reportProvider.notifier)
          .getPopularSubjectsReport(academicId: academicId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final padding = context.responsivePadding;
    final isTeacher = ref.watch(
      authProvider.select((state) => isTeacherRole(state.role)),
    );

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: isTeacher
              ? _buildTeacherBody()
              : _buildAdminBody(context),
        ),
      ),
    );
  }

  List<Widget> _buildTeacherBody() {
    return [
      Consumer(
        builder: (context, ref, _) {
          final userName =
              ref.watch(authProvider.select((state) => state.userName)) ??
              'ອາຈານ';
          final selectedYear = ref.watch(
            dashboardProvider.select((state) => state.selectedAcademicYear),
          );
          return _buildWelcomeBanner(
            context,
            userName,
            selectedYear?.academicYear ?? '-',
          );
        },
      ),
      const SizedBox(height: 28),
      Consumer(
        builder: (context, ref, _) {
          final teacherId = ref.watch(
            authProvider.select((state) => state.teacherId),
          );
          if (teacherId == null) {
            return const SizedBox.shrink();
          }
          return TeacherSubjectsCard(teacherId: teacherId);
        },
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildAdminBody(BuildContext context) {
    return [
      Consumer(
        builder: (context, ref, _) {
          final userName =
              ref.watch(authProvider.select((state) => state.userName)) ??
              'ຜູ້ໃຊ້';
          final academicYearText = ref.watch(
            dashboardProvider.select((state) => state.currentAcademicYear),
          );
          return _buildWelcomeBanner(context, userName, academicYearText);
        },
      ),
      const SizedBox(height: 28),
      Consumer(
        builder: (context, ref, _) {
          final academicYears = ref.watch(
            academicYearProvider.select((state) => state.academicYears),
          );
          final selectedAcademicYear = ref.watch(
            dashboardProvider.select((state) => state.selectedAcademicYear),
          );
          return _buildSectionHeaderWithFilter(
            'ພາບລວມ',
            academicYears,
            selectedAcademicYear,
          );
        },
      ),
      const SizedBox(height: 16),
      Consumer(
        builder: (context, ref, _) {
          final dashboard = ref.watch(
            dashboardProvider.select((state) => state),
          );

          if (dashboard.isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (dashboard.error != null) {
            return _buildErrorWidget(dashboard.error!);
          }

          return _buildStatsGrid(context, dashboard);
        },
      ),
      const SizedBox(height: 16),
      Consumer(
        builder: (context, ref, _) {
          final reportState = ref.watch(
            reportProvider.select((state) => state),
          );
          return _buildPopularSubjectsSection(context, reportState);
        },
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              ref.read(dashboardProvider.notifier).refreshStats();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('ລອງໃໝ່'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderWithFilter(
    String title,
    List<AcademicYearModel> academicYears,
    AcademicYearModel? selectedAcademicYear,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF4338CA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (academicYears.isNotEmpty)
          _buildAcademicYearDropdown(academicYears, selectedAcademicYear),
      ],
    );
  }

  Widget _buildAcademicYearDropdown(
    List<AcademicYearModel> academicYears,
    AcademicYearModel? selectedAcademicYear,
  ) {
    final selectedFromList = selectedAcademicYear != null
        ? academicYears.firstWhere(
            (year) => year.academicId == selectedAcademicYear.academicId,
            orElse: () => academicYears.first,
          )
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AcademicYearModel>(
          value: selectedFromList,
          isDense: true,
          hint: const Text('ເລືອກສົກຮຽນ'),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: academicYears.map((year) {
            return DropdownMenuItem<AcademicYearModel>(
              value: year,
              child: Text(
                year.academicYear,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (AcademicYearModel? value) {
            if (value != null) {
              ref.read(dashboardProvider.notifier).selectAcademicYear(value);
              ref
                  .read(reportProvider.notifier)
                  .getPopularSubjectsReport(academicId: value.academicId);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(
    BuildContext context,
    String userName,
    String academicYearText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.30),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 90,
            bottom: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'ສົກຮຽນ $academicYearText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ຍິນດີຕ້ອນຮັບ, $userName',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ລະບົບບໍລິຫານຈັດການສູນປາລີບຳລຸງນັກຮຽນເກັ່ງ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'ວັນທີ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      FormatUtils.getCurrentDateLao(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardState dashboard) {
    final cards = [
      CustomCard(
        icon: Icons.school_rounded,
        label: 'ນັກຮຽນທັງໝົດ',
        value: dashboard.totalStudents.toString(),
        subLabel: 'ລົງທະບຽນແລ້ວ: ${dashboard.activeStudents}',
        badge: 'ຄົນ',
        iconColor: const Color(0xFF2563EB),
        iconBackgroundColor: const Color(0xFFEFF6FF),
        accentColor: const Color(0xFF2563EB),
      ),
      CustomCard(
        icon: Icons.people_rounded,
        label: 'ອາຈານທັງໝົດ',
        value: dashboard.totalTeachers.toString(),
        subLabel: 'ອາຈານສອນປັດຈຸບັນ: ${dashboard.activeTeachers}',
        badge: 'ຄົນ',
        iconColor: const Color(0xFF7C3AED),
        iconBackgroundColor: const Color(0xFFF5F3FF),
        accentColor: const Color(0xFF7C3AED),
      ),
      CustomCard(
        icon: Icons.trending_up_rounded,
        label: 'ລາຍຮັບທັງໝົດ',
        value: FormatUtils.formatKip(dashboard.totalIncome.toInt()),
        subLabel: dashboard.currentAcademicYear,
        badge: 'ກີບ',
        iconColor: const Color(0xFF059669),
        iconBackgroundColor: const Color(0xFFECFDF5),
        accentColor: const Color(0xFF059669),
      ),
      CustomCard(
        icon: Icons.trending_down_rounded,
        label: 'ລາຍຈ່າຍທັງໝົດ',
        value: FormatUtils.formatKip(dashboard.totalExpenses.toInt()),
        subLabel: dashboard.currentAcademicYear,
        badge: 'ກີບ',
        iconColor: const Color(0xFFDC2626),
        iconBackgroundColor: const Color(0xFFFEF2F2),
        accentColor: const Color(0xFFDC2626),
      ),
      CustomCard(
        icon: Icons.account_balance_wallet_rounded,
        label: 'ຍອດເຫຼືອ',
        value: FormatUtils.formatKip(dashboard.balance.toInt()),
        subLabel: dashboard.currentAcademicYear,
        badge: dashboard.balance >= 0 ? 'ກຳໄລ' : 'ຂາດດຸນ',
        iconColor: dashboard.balance >= 0
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626),
        iconBackgroundColor: dashboard.balance >= 0
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFEF2F2),
        accentColor: dashboard.balance >= 0
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width < 600
            ? 1
            : width < 900
            ? 2
            : width < 1200
            ? 3
            : 4;

        const spacing = 16.0;
        final itemWidth =
            (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(width: itemWidth, child: card);
          }).toList(),
        );
      },
    );
  }

  Widget _buildPopularSubjectsSection(
    BuildContext context,
    ReportState reportState,
  ) {
    final data = reportState.popularSubjectsData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reportState.isPopularSubjectsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (reportState.popularSubjectsError != null)
          _buildCompactErrorCard(reportState.popularSubjectsError!)
        else if (data == null || data.subjects.isEmpty)
          SizedBox.shrink()
        else
          Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 1100;

                  if (isCompact) {
                    return Column(
                      children: [
                        _buildSubjectPieChartCard(data),
                        const SizedBox(height: 16),
                        _buildCategoryBarChartCard(data),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSubjectPieChartCard(data)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCategoryBarChartCard(data)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildTopSubjectsCard(data),
            ],
          ),
      ],
    );
  }

  Widget _buildCompactErrorCard(String message) {
    return AppCard(
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.destructive,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.destructive,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPieChartCard(PopularSubjectsReportData data) {
    final subjects = List<PopularSubjectItem>.from(data.subjects)
      ..sort((a, b) => b.studentCount.compareTo(a.studentCount));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ສັດສ່ວນນັກຮຽນຕາມວິຊາ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: subjects.asMap().entries.map((entry) {
                  final item = entry.value;
                  return PieChartSectionData(
                    color: AppColors
                        .chartColors[entry.key % AppColors.chartColors.length],
                    value: item.studentCount.toDouble(),
                    title: '${item.percentage.toStringAsFixed(1)}%',
                    radius: 150,
                    titleStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 1,
                centerSpaceRadius: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: subjects.asMap().entries.map((entry) {
              final item = entry.value;
              final color = AppColors
                  .chartColors[entry.key % AppColors.chartColors.length];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.subjectName} (${item.studentCount} ຄົນ)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChartCard(PopularSubjectsReportData data) {
    final categoryStats = data.categories;
    final sortedEntries = categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxY = categoryStats.values.reduce((a, b) => a > b ? a : b);
    final interval = maxY > 0 ? maxY / 5 : 10.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ສະຖິຕິຕາມໝວດວິຊາ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 0 ? maxY * 1.2 : 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = sortedEntries[groupIndex];
                      return BarTooltipItem(
                        '${item.key}\n',
                        const TextStyle(color: Colors.white, fontSize: 12),
                        children: [
                          TextSpan(
                            text: '${item.value} ຄົນ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()} ຄົນ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        );
                      },
                      interval: interval,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedEntries.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          sortedEntries[index].key,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.foreground,
                            fontWeight: FontWeight.bold,
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
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.border, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: AppColors.primary,
                        width: 36,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTopSubjectsCard(PopularSubjectsReportData data) {
    final sortedSubjects = List<PopularSubjectItem>.from(data.subjects)
      ..sort((a, b) => b.studentCount.compareTo(a.studentCount));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '5 ວິຊານິຍົມອັນດັບສູງສຸດ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedSubjects.take(5).toList().asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final subject = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: rank == sortedSubjects.take(5).length ? 0 : 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? AppColors.primary
                          : AppColors.infoLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: rank <= 3
                              ? Colors.white
                              : AppColors.foreground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              subject.subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                subject.subjectCategory,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: subject.percentage / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.muted,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${subject.studentCount} ຄົນ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${subject.percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
