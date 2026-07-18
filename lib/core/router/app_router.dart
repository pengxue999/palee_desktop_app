import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/utils/enum_localization.dart';
import 'package:palee_elite_training_center/screens/auth/login_screen.dart';
import 'package:palee_elite_training_center/screens/dashboard_screen.dart';
import 'package:palee_elite_training_center/screens/donate_screen/donation_screen.dart';
import 'package:palee_elite_training_center/screens/finance_screen/finance_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/students_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/teachers_screen.dart';
import 'package:palee_elite_training_center/screens/tuition_payment_screen/tuition_payment_screen.dart';
import 'package:palee_elite_training_center/screens/registration_screen/registration_screen.dart';
import 'package:palee_elite_training_center/screens/registration_screen/new_registration_screen.dart';
import 'package:palee_elite_training_center/screens/report_screen/reports_screen.dart';
import 'package:palee_elite_training_center/screens/report_screen/report_student_screen.dart';
import 'package:palee_elite_training_center/screens/evaluate_student_screen/evaluate_student_screen.dart';
import 'package:palee_elite_training_center/screens/salary_payment_screen/salary_payment_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/subject_details_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/subjects_screen.dart'
    as subjects;
import 'package:palee_elite_training_center/screens/master_data_screen/level_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/discounts_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/districts_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/fees_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/expense_types_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/donation_category_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/donors_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/provinces_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/users_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/academic_years_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/subject_categories_screen.dart';
import 'package:palee_elite_training_center/screens/master_data_screen/teacher_assigment_screen.dart';
import 'package:palee_elite_training_center/screens/teaching_tracking_screen/teaching_tracking_screen.dart';
import 'package:palee_elite_training_center/widgets/app_layout.dart';
import '../../widgets/app_toast.dart' show toastNavigatorKey;
import '../../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(
    authProvider.select(
      (state) => (state.isInitializing, state.isAuthenticated, state.role),
    ),
  );

  return GoRouter(
    navigatorKey: toastNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      if (authState.$1) return null;

      final isLoggedIn = authState.$2;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) {
        return '/';
      }

      if (isLoggedIn && isTeacherRole(authState.$3)) {
        final allowedRoutes = [
          '/',
          '/teaching-tracking',
          '/evaluate-student',
          '/assessment',
        ];
        if (!allowedRoutes.contains(state.matchedLocation)) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            const MaterialPage(child: LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (context, state) =>
                const MaterialPage(child: DashboardScreen()),
          ),

          GoRoute(
            path: '/students',
            name: 'students',
            pageBuilder: (context, state) =>
                const MaterialPage(child: StudentsScreen()),
          ),

          GoRoute(
            path: '/teachers',
            name: 'teachers',
            pageBuilder: (context, state) =>
                const MaterialPage(child: TeachersScreen()),
          ),

          GoRoute(
            path: '/subject-details',
            name: 'subject-details',
            pageBuilder: (context, state) =>
                const MaterialPage(child: SubjectDetailsScreen()),
          ),

          GoRoute(
            path: '/registration',
            name: 'registration',
            pageBuilder: (context, state) =>
                const MaterialPage(child: RegistrationScreen()),
          ),

          GoRoute(
            path: '/registration/new',
            name: 'registration-new',
            pageBuilder: (context, state) =>
                const MaterialPage(child: NewRegistrationScreen()),
          ),

          GoRoute(
            path: '/payment',
            name: 'payment',
            pageBuilder: (context, state) =>
                const MaterialPage(child: TuitionPaymentScreen()),
          ),

          GoRoute(
            path: '/teaching-tracking',
            name: 'teaching-tracking',
            pageBuilder: (context, state) =>
                const MaterialPage(child: TeachingTrackingScreen()),
          ),

          GoRoute(
            path: '/evaluate-student',
            name: 'evaluate-student',
            pageBuilder: (context, state) =>
                const MaterialPage(child: EvaluateStudentScreen()),
          ),

          GoRoute(
            path: '/assessment',
            redirect: (context, state) => '/evaluate-student',
          ),

          GoRoute(
            path: '/salary',
            name: 'salary',
            pageBuilder: (context, state) =>
                const MaterialPage(child: SalaryPaymentScreen()),
          ),

          GoRoute(
            path: '/finance',
            name: 'finance',
            pageBuilder: (context, state) =>
                const MaterialPage(child: FinanceScreen()),
          ),

          GoRoute(
            path: '/donation',
            name: 'donation',
            pageBuilder: (context, state) =>
                const MaterialPage(child: DonationScreen()),
          ),

          GoRoute(
            path: '/reports',
            name: 'reports',
            pageBuilder: (context, state) {
              final type = state.uri.queryParameters['type'];
              return MaterialPage(child: ReportsScreen(reportType: type));
            },
          ),

          GoRoute(
            path: '/reports/students',
            name: 'reports-students',
            pageBuilder: (context, state) =>
                const MaterialPage(child: ReportStudentScreen()),
          ),

          GoRoute(
            path: '/teaching-info',
            name: 'teaching-info',
            pageBuilder: (context, state) =>
                const MaterialPage(child: TeacherAssigmentScreen()),
          ),
          GoRoute(
            path: '/academic-years',
            name: 'academic-years',
            pageBuilder: (context, state) =>
                const MaterialPage(child: AcademicYearsScreen()),
          ),
          GoRoute(
            path: '/subject-categories',
            name: 'subject-categories',
            pageBuilder: (context, state) =>
                const MaterialPage(child: SubjectCategoriesScreen()),
          ),
          GoRoute(
            path: '/subjects',
            name: 'subjects',
            pageBuilder: (context, state) =>
                const MaterialPage(child: subjects.SubjectsScreen()),
          ),
          GoRoute(
            path: '/levels',
            name: 'levels',
            pageBuilder: (context, state) =>
                const MaterialPage(child: LevelScreen()),
          ),
          GoRoute(
            path: '/provinces',
            name: 'provinces',
            pageBuilder: (context, state) =>
                const MaterialPage(child: ProvincesScreen()),
          ),
          GoRoute(
            path: '/districts',
            name: 'districts',
            pageBuilder: (context, state) =>
                const MaterialPage(child: DistrictsScreen()),
          ),
          GoRoute(
            path: '/discounts',
            name: 'discounts',
            pageBuilder: (context, state) =>
                const MaterialPage(child: DiscountsScreen()),
          ),
          GoRoute(
            path: '/fees',
            name: 'fees',
            pageBuilder: (context, state) =>
                const MaterialPage(child: FeesScreen()),
          ),
          GoRoute(
            path: '/expense-types',
            name: 'expense-types',
            pageBuilder: (context, state) =>
                const MaterialPage(child: ExpenseTypesScreen()),
          ),
          GoRoute(
            path: '/donors',
            name: 'donors',
            pageBuilder: (context, state) =>
                const MaterialPage(child: DonorsScreen()),
          ),
          GoRoute(
            path: '/donation-categories',
            name: 'donation-categories',
            pageBuilder: (context, state) =>
                const MaterialPage(child: DonationCategoryScreen()),
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            pageBuilder: (context, state) =>
                const MaterialPage(child: UsersScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri.path}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
