import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/constants/app_theme.dart';
import 'package:window_manager/window_manager.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await WindowManager.instance.ensureInitialized();
    final options = WindowOptions(minimumSize: Size(1024, 700), center: true);
    await WindowManager.instance.waitUntilReadyToShow(options, () async {
      await WindowManager.instance.show();
      await WindowManager.instance.focus();
    });
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ລະບົບບໍລິຫານຈັດການສູນປາລີບຳລຸງນັກຮຽນເກັ່ງ',
      debugShowCheckedModeBanner: false,
      theme: AppThemeData.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'NotoSans Lao',
            color: AppColors.foreground,
          ),
          child: child!,
        );
      },
    );
  }
}
