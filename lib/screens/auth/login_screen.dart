import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true, _loading = false;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).login(
          email: _email.text.trim(), password: _pass.text);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: $e'), backgroundColor: AppTheme.errorColor));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(key: _form, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Center(child: Column(children: [
              Container(width: 80, height: 80,
                decoration: BoxDecoration(color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(22)),
                child: const Center(child: Text('⚽', style: TextStyle(fontSize: 38)))),
              const SizedBox(height: 16),
              const Text('FuS', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor)),
              const Text('Find ur Sport', style: TextStyle(fontSize: 14,
                  color: AppTheme.textSecondary)),
            ])),
            const SizedBox(height: 48),
            const Text('Masuk', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Selamat datang kembali!', style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 32),
            CustomTextField(controller: _email, label: 'Email', hint: 'contoh@email.com',
              keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined,
              validator: (v) => v?.isEmpty == true ? 'Email wajib diisi'
                  : !v!.contains('@') ? 'Email tidak valid' : null),
            const SizedBox(height: 16),
            CustomTextField(controller: _pass, label: 'Password', hint: 'Minimal 6 karakter',
              obscureText: _obscure, prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure)),
              validator: (v) => v?.isEmpty == true ? 'Password wajib diisi'
                  : v!.length < 6 ? 'Minimal 6 karakter' : null),
            const SizedBox(height: 28),
            LoadingButton(isLoading: _loading, onPressed: _login, label: 'Masuk'),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Belum punya akun? ', style: TextStyle(color: AppTheme.textSecondary)),
              GestureDetector(onTap: () => context.go('/auth/register'),
                child: const Text('Daftar', style: TextStyle(color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 40),
          ],
        )),
      )),
    );
  }
}
