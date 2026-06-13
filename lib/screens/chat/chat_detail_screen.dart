import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../core/theme.dart';

class ChatDetailScreen extends ConsumerWidget {
  final String bookingId;
  final BookingModel? booking;
  const ChatDetailScreen({super.key, required this.bookingId, this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;
    if (b == null) {
      return const Scaffold(body: Center(child: Text('Data booking tidak ditemukan')));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.venueName ?? 'Venue',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text(b.statusLabel,
              style: TextStyle(fontSize: 12, color: b.statusColor)),
        ]),
      ),
      body: Column(children: [
        // Info booking
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Detail Booking',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            if (b.bookingDate != null)
              _InfoRow(icon: Icons.calendar_today_outlined,
                text: DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(b.bookingDate!)),
            if (b.slotTimeLabel.isNotEmpty)
              _InfoRow(icon: Icons.access_time_rounded,
                text: '${b.slotTimeLabel}  ·  ${b.slotPriceLabel}',
                color: AppTheme.primaryColor),
            _InfoRow(icon: Icons.info_outline,
              text: 'Status: ${b.statusLabel}', color: b.statusColor),
          ]),
        ),

        // Pesan booking
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Bubble pesan dari user
              _ChatBubble(
                message: b.message,
                isMe: true,
                time: b.createdAt,
                label: 'Pesan Booking Anda',
              ),
              if (b.status == 'confirmed')
                const _ChatBubble(
                  message: 'Booking Anda telah dikonfirmasi oleh owner. '
                      'Silakan datang sesuai jadwal yang dipesan.',
                  isMe: false,
                  label: 'Owner',
                ),
              if (b.status == 'rejected')
                const _ChatBubble(
                  message: 'Maaf, booking Anda tidak dapat dikonfirmasi '
                      'oleh owner. Silakan coba waktu lain.',
                  isMe: false,
                  label: 'Owner',
                ),
              if (b.status == 'pending')
                const _ChatBubble(
                  message: 'Pesan Anda sudah diterima. '
                      'Menunggu konfirmasi dari owner...',
                  isMe: false,
                  label: 'Sistem',
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // Info bawah
        Container(
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Row(children: [
            const Icon(Icons.info_outline,
                size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Chat ini menampilkan detail booking Anda dengan owner.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime? time;
  final String? label;
  const _ChatBubble({required this.message, required this.isMe,
      this.time, this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 6, bottom: 6,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                child: Text(label!,
                    style: const TextStyle(fontSize: 11,
                        color: AppTheme.textSecondary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(message,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppTheme.textPrimary,
                    fontSize: 14, height: 1.4)),
            ),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Text(
                  DateFormat('d MMM, HH:mm').format(time!),
                  style: const TextStyle(fontSize: 10,
                      color: AppTheme.textSecondary))),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: color ?? AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(
            fontSize: 13, color: color ?? AppTheme.textSecondary,
            fontWeight: color != null ? FontWeight.w600 : FontWeight.normal))),
      ]),
    );
  }
}
