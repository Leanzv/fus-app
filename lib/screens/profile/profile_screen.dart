import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/venue_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/booking_model.dart';
import '../../repositories/booking_repository.dart';

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
    final p = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 400, imageQuality: 80);
    if (p != null) setState(() => _avatarFile = File(p.path));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      String? url;
      if (_avatarFile != null) {
        url = await StorageService().uploadAvatar(_avatarFile!);
      }
      await AuthService().updateProfile(
          name: _nameCtrl.text.trim(), avatarUrl: url);
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profil berhasil diperbarui ✅'),
            backgroundColor: AppTheme.primaryColor));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: AppTheme.errorColor));
    } finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor),
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profil Saya'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                profileAsync.whenData(
                    (p) => _nameCtrl.text = p?.name ?? '');
                setState(() => _isEditing = true);
              }),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Avatar
              GestureDetector(
                onTap: _isEditing ? _pickAvatar : null,
                child: Stack(alignment: Alignment.bottomRight, children: [
                  CircleAvatar(radius: 52,
                    backgroundColor:
                        AppTheme.primaryColor.withOpacity(0.15),
                    backgroundImage: _avatarFile != null
                        ? FileImage(_avatarFile!) as ImageProvider
                        : profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                    child: _avatarFile == null && profile.avatarUrl == null
                        ? Text(
                            profile.name.isNotEmpty
                                ? profile.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 38,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold))
                        : null),
                  if (_isEditing)
                    Container(padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16)),
                ])),
              const SizedBox(height: 12),

              if (!_isEditing) ...[
                Text(profile.name, style: const TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(profile.email, style: const TextStyle(
                    color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    profile.isOwner ? '🏢 Owner' : '🏃 Pengguna',
                    style: const TextStyle(color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600))),
              ],

              const SizedBox(height: 28),

              // Form edit
              if (_isEditing) ...[
                CustomTextField(controller: _nameCtrl, label: 'Nama',
                    hint: 'Nama lengkap',
                    prefixIcon: Icons.person_outline),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Batal'))),
                  const SizedBox(width: 12),
                  Expanded(child: LoadingButton(isLoading: _isSaving,
                      onPressed: _save, label: 'Simpan')),
                ]),
                const SizedBox(height: 20),
              ],

              // Menu owner
              if (!_isEditing && profile.isOwner) ...[
                _MenuTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Permintaan Booking',
                  subtitle: 'Lihat dan kelola semua booking masuk',
                  onTap: () => _showOwnerBookings(context, ref, profile.id),
                ),
                _MenuTile(
                  icon: Icons.chat_bubble_outline,
                  label: 'Pesan dari Pengguna',
                  subtitle: 'Lihat pesan booking dari pengguna',
                  onTap: () => _showOwnerMessages(context, ref, profile.id),
                ),
              ],

              // Menu logout
              if (!_isEditing) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _MenuTile(
                  icon: Icons.logout,
                  label: 'Keluar',
                  subtitle: 'Logout dari akun',
                  iconColor: AppTheme.errorColor,
                  onTap: _logout,
                ),
              ],

              const SizedBox(height: 40),
            ]),
          );
        },
      ),
    );
  }

  // ─── Owner: Permintaan Booking ────────────────────────────

  void _showOwnerBookings(
      BuildContext ctx, WidgetRef ref, String ownerId) {
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OwnerBookingsSheet(ownerId: ownerId));
  }

  void _showOwnerMessages(
      BuildContext ctx, WidgetRef ref, String ownerId) {
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OwnerMessagesSheet(ownerId: ownerId));
  }
}

// ─── Bottom Sheet: Permintaan Booking (Owner) ─────────────────
class _OwnerBookingsSheet extends ConsumerWidget {
  final String ownerId;
  const _OwnerBookingsSheet({required this.ownerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(ownerVenuesProvider(ownerId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75, minChildSize: 0.5,
      maxChildSize: 0.95, expand: false,
      builder: (_, sc) => Column(children: [
        // Handle
        Center(child: Container(margin: const EdgeInsets.only(top: 10),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)))),
        const Padding(padding: EdgeInsets.all(16),
          child: Text('Permintaan Booking', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700))),
        Expanded(child: venuesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('Error: $e')),
          data: (venues) {
            if (venues.isEmpty) {
              return const Center(
                  child: Text('Belum ada venue. Tambahkan venue dulu.'));
            }
            final venueIds = venues.map((v) => v.id).toList();
            return _BookingsList(venueIds: venueIds, scrollCtrl: sc);
          },
        )),
      ]),
    );
  }
}

class _BookingsList extends ConsumerWidget {
  final List<String> venueIds;
  final ScrollController scrollCtrl;
  const _BookingsList(
      {required this.venueIds, required this.scrollCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(ownerBookingsProvider(venueIds.join(",")));

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error memuat booking: $e')),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📭', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Belum ada permintaan booking',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ]));
        }
        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: bookings.length,
          itemBuilder: (_, i) =>
              _BookingCard(booking: bookings[i], ref: ref),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final WidgetRef ref;
  const _BookingCard({required this.booking, required this.ref});

  @override
  Widget build(BuildContext context) {
    final repo = BookingRepository();
    return Card(margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(radius: 18,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  booking.userName?.isNotEmpty == true
                      ? booking.userName![0].toUpperCase() : '?',
                  style: const TextStyle(color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.userName ?? 'Pengguna',
                      style: const TextStyle(fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (booking.userEmail != null)
                    Text(booking.userEmail!, style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
                ])),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(booking.statusLabel, style: TextStyle(
                    color: booking.statusColor, fontSize: 12,
                    fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 10),
            if (booking.venueName != null)
              _Row(icon: Icons.location_on_outlined,
                  text: booking.venueName!),
            if (booking.bookingDate != null)
              _Row(icon: Icons.calendar_today_outlined,
                text: DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                    .format(booking.bookingDate!)),
            if (booking.slotTimeLabel.isNotEmpty)
              _Row(icon: Icons.access_time_rounded,
                text: '${booking.slotTimeLabel}  ·  ${booking.slotPriceLabel}',
                color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Container(width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(booking.message,
                  style: const TextStyle(fontSize: 13, height: 1.4))),
            if (booking.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () async {
                    await repo.updateBookingStatus(
                        booking.id, 'rejected');
                    ref.invalidate(ownerBookingsProvider);
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(
                          color: AppTheme.errorColor)),
                  child: const Text('Tolak'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    await repo.updateBookingStatus(
                        booking.id, 'confirmed');
                    ref.invalidate(ownerBookingsProvider);
                  },
                  child: const Text('Konfirmasi'))),
              ]),
            ],
          ])));
  }
}

// ─── Bottom Sheet: Pesan dari Pengguna (Owner) ────────────────
class _OwnerMessagesSheet extends ConsumerWidget {
  final String ownerId;
  const _OwnerMessagesSheet({required this.ownerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(ownerVenuesProvider(ownerId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75, minChildSize: 0.5,
      maxChildSize: 0.95, expand: false,
      builder: (_, sc) => Column(children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 10),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)))),
        const Padding(padding: EdgeInsets.all(16),
          child: Text('Pesan dari Pengguna', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700))),
        Expanded(child: venuesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('Error: $e')),
          data: (venues) {
            if (venues.isEmpty) {
              return const Center(
                  child: Text('Belum ada venue'));
            }
            final venueIds = venues.map((v) => v.id).toList();
            final bookingsAsync =
                ref.watch(ownerBookingsProvider(venueIds.join(",")));
            return bookingsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('💬', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Belum ada pesan dari pengguna',
                          style: TextStyle(
                              color: AppTheme.textSecondary)),
                    ]));
                }
                return ListView.builder(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bookings.length,
                  itemBuilder: (_, i) {
                    final b = bookings[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            b.userName?.isNotEmpty == true
                                ? b.userName![0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold))),
                        title: Text(b.userName ?? 'Pengguna',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.venueName ?? '',
                                style: const TextStyle(fontSize: 12,
                                    color: AppTheme.textSecondary)),
                            if (b.bookingDate != null)
                              Text(
                                DateFormat('d MMM · ', 'id_ID')
                                        .format(b.bookingDate!) +
                                    b.slotTimeLabel,
                                style: const TextStyle(fontSize: 12,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600)),
                            Text(b.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: b.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text(b.statusLabel,
                              style: TextStyle(
                                  color: b.statusColor, fontSize: 11,
                                  fontWeight: FontWeight.w600))),
                        isThreeLine: true,
                      ));
                  });
              });
          })),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon; final String text; final Color? color;
  const _Row({required this.icon, required this.text, this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Icon(icon, size: 14, color: color ?? AppTheme.textSecondary),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12,
          color: color ?? AppTheme.textSecondary,
          fontWeight: color != null
              ? FontWeight.w600 : FontWeight.normal))),
    ]));
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  const _MenuTile({required this.icon, required this.label,
      required this.subtitle, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryColor,
            size: 22)),
      title: Text(label, style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(
          color: AppTheme.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right,
          color: AppTheme.textSecondary)));
}
