import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart'; // ← 1. EKLENDİ

import 'package:tenis_kulubu/core/router/app_router.dart';
import 'package:tenis_kulubu/core/theme/app_theme.dart';
import 'package:tenis_kulubu/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized(); // ← 2. EKLENDİ

  await initializeDateFormatting('tr_TR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    EasyLocalization( // ← 3. EKLENDİ — ProviderScope'u sarmalıyor
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
        Locale('ru'),
        Locale('uk'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr'),
      child: const ProviderScope(
        child: TenisApp(),
      ),
    ),
  );
}

class TenisApp extends ConsumerWidget {
  const TenisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ulaş Tenis Kulübü - Mobil Uygulama',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ↓ Bu 3 satır EasyLocalization için EKLENDİ
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      routerConfig: router,
    );
  }
}