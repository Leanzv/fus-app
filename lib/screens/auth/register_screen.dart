import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _role = 'user';
  bool _obscure = true, _loading = false;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).register(
        email: _email.text.trim(), password: _pass.text,
        name: _name.text.trim(), role: _role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Registrasi berhasil! Silakan masuk.'),
          backgroundColor: AppTheme.primaryColor));
        context.go('/auth/login');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.errorColor));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Buat Akun'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/auth/login'))),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(key: _form, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text('Daftar Akun', style: TextStyle(fontSize: 26,
                fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Isi data untuk membuat akun baru',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 32),
            CustomTextField(controller: _name, label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap', prefixIcon: Icons.person_outline,
              validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null),
            const SizedBox(height: 16),
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
            const SizedBox(height: 20),
            const Text('Daftar sebagai', style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            Row(children: [
              _RoleCard(icon: '🏃', label: 'Pengguna', subtitle: 'Cari & review venue',
                isSelected: _role == 'user', onTap: () => setState(() => _role = 'user')),
              const SizedBox(width: 12),
              _RoleCard(icon: '🏢', label: 'Owner', subtitle: 'Kelola venue olahraga',
                isSelected: _role == 'owner', onTap: () => setState(() => _role = 'owner')),
            ]),
            const SizedBox(height: 32),
            LoadingButton(isLoading: _loading, onPressed: _register, label: 'Daftar'),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Sudah punya akun? ', style: TextStyle(color: AppTheme.textSecondary)),
              GestureDetector(onTap: () => context.go('/auth/login'),
                child: const Text('Masuk', style: TextStyle(color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 40),
          ],
        )),
      )),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String icon, label, subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.label, required this.subtitle,
    required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1)),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ),
    ));
  }
}
