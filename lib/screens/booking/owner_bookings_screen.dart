import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/venue_provider.dart';
import '../../repositories/booking_repository.dart';
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
          if (profile == null) return const Center(child: Text('Profil tidak ditemukan'));
          final ownerVenuesAsync = ref.watch(ownerVenuesProvider(profile.id));

          return ownerVenuesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (venues) {
              final venueIds = venues.map((v) => v.id).toList();
              final bookingsAsync = ref.watch(ownerBookingsProvider(venueIds));

              return bookingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📅', style: TextStyle(fontSize: 60)),
                          SizedBox(height: 16),
                          Text('Belum ada permintaan booking',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _BookingCard(booking: booking, ref: ref);
                    },
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
  final dynamic booking;
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
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    booking.userName?.isNotEmpty == true
                        ? booking.userName[0].toUpperCase()
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
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            if (booking.venueName != null)
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    booking.venueName!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Container(
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
            if (booking.createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(booking.createdAt!),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],

            // Action buttons (hanya jika pending)
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
                          side: const BorderSide(color: AppTheme.errorColor)),
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
