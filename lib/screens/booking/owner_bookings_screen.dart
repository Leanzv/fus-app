import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/venue_provider.dart';
import '../../repositories/booking_repository.dart';
import '../../models/booking_model.dart';
import '../../core/theme.dart';

class OwnerBookingsScreen extends ConsumerWidget {
  const OwnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Permintaan Booking')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan'));
          }
          final ownerVenuesAsync = ref.watch(ownerVenuesProvider(profile.id));

          return ownerVenuesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (venues) {
              final venueIds = venues.map((v) => v.id).toList();
              final bookingsAsync = ref.watch(ownerBookingsProvider(venueIds));

              return bookingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📅', style: TextStyle(fontSize: 60)),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada permintaan booking',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) => _BookingCard(
                      booking: bookings[index],
                      ref: ref,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final WidgetRef ref;

  const _BookingCard({required this.booking, required this.ref});

  @override
  Widget build(BuildContext context) {
    final bookingRepo = BookingRepository();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: user info + status badge
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    booking.userName?.isNotEmpty == true
                        ? booking.userName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.userName ?? 'Pengguna',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (booking.userEmail != null)
                        Text(
                          booking.userEmail!,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.statusLabel,
                    style: TextStyle(
                        color: booking.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info venue
            if (booking.venueName != null)
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: booking.venueName!,
              ),

            // Info tanggal & slot waktu
            if (booking.bookingDate != null)
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                text: DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                    .format(booking.bookingDate!),
              ),

            if (booking.slotTimeLabel.isNotEmpty)
              _InfoRow(
                icon: Icons.access_time_rounded,
                text:
                    '${booking.slotTimeLabel}  ·  ${booking.slotPriceLabel}',
                color: AppTheme.primaryColor,
              ),

            const SizedBox(height: 8),

            // Pesan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking.message,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.4),
              ),
            ),

            // Waktu booking dikirim
            if (booking.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Dikirim: ${DateFormat('d MMM yyyy, HH:mm').format(booking.createdAt!)}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],

            // Tombol aksi (hanya jika pending)
            if (booking.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await bookingRepo.updateBookingStatus(
                            booking.id, 'rejected');
                        ref.invalidate(ownerBookingsProvider);
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(
                              color: AppTheme.errorColor)),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await bookingRepo.updateBookingStatus(
                            booking.id, 'confirmed');
                        ref.invalidate(ownerBookingsProvider);
                      },
                      child: const Text('Konfirmasi'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: color ?? AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: color != null
                      ? FontWeight.w600
                      : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
