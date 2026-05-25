import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'core/theme.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sqjnzxrssejtzpsjfgxv.supabase.co/rest/v1/',         // Ganti dengan URL Supabase Anda
    anonKey: 'sb_publishable_Nb-p0Ln9bZT14N9S1VAmZg_ThcqrhYp', // Ganti dengan Anon Key Supabase Anda
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
    );
  }
}
