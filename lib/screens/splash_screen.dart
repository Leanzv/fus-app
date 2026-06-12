import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    auth.when(
      data: (s) => context.go(s.session != null ? '/home' : '/auth/login'),
      loading: () => context.go('/auth/login'),
      error: (_, __) => context.go('/auth/login'),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: FadeTransition(opacity: _fade, child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 100, height: 100,
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(28)),
              child: const Center(child: Text('⚽', style: TextStyle(fontSize: 48)))),
            const SizedBox(height: 24),
            const Text('FuS', style: TextStyle(color: Colors.white, fontSize: 42,
                fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text('Find ur Sport', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 60),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        )),
      ),
    );
  }
}
