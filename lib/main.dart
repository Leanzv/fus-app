import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia untuk format tanggal
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: 'https://jpvvhtvdmjykwdxgnjxu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpwdnZodHZkbWp5a3dkeGduanh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwMTY5NDQsImV4cCI6MjA5NTU5Mjk0NH0.sSmhQAUAtVSuPD4jpoT-oVRtwHyPH4N2g3pa_TvLY-o',
  );

  runApp(
    const ProviderScope(
      child: FuSApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class FuSApp extends ConsumerWidget {
  const FuSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FuS - Find ur Sport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,

      // Localization
      locale: const Locale('id', 'ID'),

      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}