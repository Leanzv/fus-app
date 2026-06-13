import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme.dart';
import '../../models/booking_model.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Chat Booking')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan'));
          }
          final bookingsAsync =
              ref.watch(userBookingsProvider(profile.id));

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
                      Text('💬', style: TextStyle(fontSize: 60)),
                      SizedBox(height: 16),
                      Text('Belum ada booking',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      SizedBox(height: 8),
                      Text('Booking venue untuk mulai chat dengan owner',
                          style: TextStyle(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (_, i) => _BookingChatTile(
                  booking: bookings[i],
                  onTap: () => context.push(
                    '/chat/${bookings[i].id}',
                    extra: bookings[i],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingChatTile extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  const _BookingChatTile({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14)),
          child: const Center(
              child: Text('🏟️', style: TextStyle(fontSize: 22)))),
        title: Text(booking.venueName ?? 'Venue',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (booking.bookingDate != null && booking.slotTimeLabel.isNotEmpty)
              Text(
                '${DateFormat('EEE, d MMM', 'id_ID').format(booking.bookingDate!)}  ·  ${booking.slotTimeLabel}',
                style: const TextStyle(fontSize: 12,
                    color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
            Text(booking.message,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: booking.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
              child: Text(booking.statusLabel,
                  style: TextStyle(color: booking.statusColor,
                      fontSize: 11, fontWeight: FontWeight.w600))),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
