import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tenis_kulubu/core/router/app_router.dart';
import 'package:tenis_kulubu/core/theme/app_theme.dart';
import 'package:tenis_kulubu/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  // Flutter binding elementlerinin Firebase'den önce hazır olmasını sağlar
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR', null);

  // Firebase başlatma işlemi
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Uygulamanın sadece dikey ekranda çalışmasını zorunlu kılar
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Durum çubuğunu (Status Bar) şeffaf ve ikonları koyu yapar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    // Riverpod provider'larının yaşayabilmesi için ProviderScope şarttır
    const ProviderScope(
      child: TenisApp(),
    ),
  );
}

class TenisApp extends ConsumerWidget {
  const TenisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GoRouter provider'ını dinliyoruz
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Ulaş Tenis Kulübü - Mobil Uygulama',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // GoRouter yapılandırmasını buraya bağlıyoruz
      routerConfig: router,
    );
  }
}