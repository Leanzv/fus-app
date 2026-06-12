import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  File? _avatarFile;
  bool _isEditing = false, _isSaving = false;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _pickAvatar() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 80);
    if (p != null) setState(() => _avatarFile = File(p.path));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      String? avatarUrl;
      if (_avatarFile != null) avatarUrl = await StorageService().uploadAvatar(_avatarFile!);
      await AuthService().updateProfile(name: _nameCtrl.text.trim(), avatarUrl: avatarUrl);
      ref.invalidate(currentProfileProvider);
      if (mounted) { setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil berhasil diperbarui ✅'), backgroundColor: AppTheme.primaryColor)); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.errorColor));
    } finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Keluar')),
        ]));
    if (ok == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Profil Saya'),
        actions: [if (!_isEditing) IconButton(icon: const Icon(Icons.edit_outlined),
          onPressed: () { profileAsync.whenData((p) { _nameCtrl.text = p?.name ?? ''; });
            setState(() => _isEditing = true); })]),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profil tidak ditemukan'));
          if (!_isEditing) _nameCtrl.text = profile.name;
          return SingleChildScrollView(padding: const EdgeInsets.all(20),
            child: Column(children: [
              GestureDetector(onTap: _isEditing ? _pickAvatar : null,
                child: Stack(alignment: Alignment.bottomRight, children: [
                  CircleAvatar(radius: 52, backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                    backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) as ImageProvider
                        : profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                    child: _avatarFile == null && profile.avatarUrl == null
                        ? Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 38, color: AppTheme.primaryColor, fontWeight: FontWeight.bold))
                        : null),
                  if (_isEditing) Container(padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16)),
                ])),
              const SizedBox(height: 12),
              if (!_isEditing) ...[
                Text(profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(profile.email, style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(profile.isOwner ? '🏢 Owner' : '🏃 Pengguna',
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600))),
              ],
              const SizedBox(height: 28),
              if (_isEditing) ...[
                CustomTextField(controller: _nameCtrl, label: 'Nama', hint: 'Nama lengkap',
                  prefixIcon: Icons.person_outline),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Batal'))),
                  const SizedBox(width: 12),
                  Expanded(child: LoadingButton(isLoading: _isSaving, onPressed: _save, label: 'Simpan')),
                ]),
                const SizedBox(height: 20),
              ],
              if (!_isEditing) ...[
                if (profile.isOwner) ...[
                  _MenuTile(icon: Icons.dashboard_outlined, label: 'Dashboard Owner',
                    subtitle: 'Kelola venue dan lihat statistik',
                    onTap: () => context.push('/owner/dashboard')),
                  _MenuTile(icon: Icons.calendar_today_outlined, label: 'Permintaan Booking',
                    subtitle: 'Lihat dan kelola booking masuk',
                    onTap: () => context.push('/owner/bookings')),
                ] else
                  _MenuTile(icon: Icons.history_outlined, label: 'Riwayat Booking',
                    subtitle: 'Lihat booking yang telah dikirim',
                    onTap: () => _showBookings(context, ref, profile.id)),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _MenuTile(icon: Icons.logout, label: 'Keluar', subtitle: 'Logout dari akun',
                  iconColor: AppTheme.errorColor, onTap: _logout),
              ],
              const SizedBox(height: 40),
            ]));
        }));
  }

  void _showBookings(BuildContext ctx, WidgetRef ref, String userId) {
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, minChildSize: 0.4,
        maxChildSize: 0.9, expand: false,
        builder: (_, sc) => Column(children: [
          const Padding(padding: EdgeInsets.all(16),
            child: Text('Riwayat Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          Expanded(child: ref.watch(userBookingsProvider(userId)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (bookings) {
              if (bookings.isEmpty) return const Center(child: Text('Belum ada riwayat booking'));
              return ListView.builder(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: bookings.length,
                itemBuilder: (_, i) {
                  final b = bookings[i];
                  return Card(margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: b.statusColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.calendar_today, color: b.statusColor, size: 18)),
                      title: Text(b.venueName ?? 'Venue'),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (b.bookingDate != null) Text(
                          DateFormat('EEE, d MMM yyyy', 'id_ID').format(b.bookingDate!),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        if (b.slotTimeLabel.isNotEmpty) Text(
                          '${b.slotTimeLabel}  ·  ${b.slotPriceLabel}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                        Text(b.message, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ]),
                      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: b.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(b.statusLabel, style: TextStyle(color: b.statusColor,
                            fontSize: 11, fontWeight: FontWeight.w600)))));
                });
            })),
        ])));
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  const _MenuTile({required this.icon, required this.label, required this.subtitle,
    required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Card(margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 22)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary)));
  }
}
