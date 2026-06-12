import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia untuk intl (format tanggal)
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',          // Ganti dengan URL Supabase Anda
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // Ganti dengan Anon Key Supabase Anda
  );

  runApp(
    const ProviderScope(
      child: FuSApp(),
    ),
  );
}

// Shortcut global untuk Supabase client
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
      // Support locale Indonesia
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
    );
  }
}
