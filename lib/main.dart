import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jpvvhtvdmjykwdxgnjxu.supabase.co',         // Ganti dengan URL Supabase Anda
    anonKey: 'sb_publishable_H9Z8Ds59_MPaihr6pKySug_NwWAGB5k', // Ganti dengan Anon Key Supabase Anda
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
