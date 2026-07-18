import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palee_elite_training_center/screens/report_screen/report_finance.dart';
import 'package:palee_elite_training_center/screens/report_screen/report_salary_payment.dart';
import 'package:palee_elite_training_center/screens/report_screen/report_student_screen.dart';
import 'package:palee_elite_training_center/screens/report_screen/report_teacher_attendance_screen.dart';
import 'package:palee_elite_training_center/screens/report_screen/report_donation.dart';
import 'package:palee_elite_training_center/screens/report_screen/report_popular_subject.dart';
import 'package:palee_elite_training_center/screens/report_screen/report_assessment_screen.dart';
import 'package:palee_elite_training_center/screens/report_screen/report_registration_screen.dart';

class ReportsScreen extends StatefulWidget {
  final String? reportType;

  const ReportsScreen({super.key, this.reportType});

  @override
  State<ReportsScreen> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsScreen> with RouteAware {
  String selectedReport = 'students';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedReportFromUrl();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedReportFromUrl();
  }

  void _updateSelectedReportFromUrl() {
    final location = GoRouterState.of(context).uri;
    final reportType = location.queryParameters['type'];

    if (reportType != null) {
      setState(() {
        selectedReport = reportType;
      });
    } else if (widget.reportType != null) {
      setState(() {
        selectedReport = widget.reportType!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedReport == 'students') {
      return const ReportStudentScreen();
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: _buildReportContent()),
    );
  }

  Widget _buildReportContent() {
    switch (selectedReport) {
      case 'students':
        return ReportStudentScreen();
      case 'registrations':
        return const ReportRegistrationScreen();
      case 'teaching':
        return ReportTeacherAttendanceScreen();
      case 'finance':
        return ReportFinanceScreen();
      case 'salary-payment':
        return const ReportSalaryPaymentScreen();
      case 'assessment':
        return const ReportAssessmentScreen();
      case 'donation':
        return const ReportDonationScreen();
      case 'popular-subjects':
        return const ReportPopularSubjectScreen();
      default:
        return const ReportStudentScreen();
    }
  }
}
