import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/venue_provider.dart';
import '../../repositories/booking_repository.dart';
import '../../models/booking_model.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';
import 'package:uuid/uuid.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String venueId;
  const BookingScreen({super.key, required this.venueId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _messageCtrl = TextEditingController();
  bool _isLoading = false;
  final _bookingRepo = BookingRepository();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan booking tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId =
          ref.read(authStateProvider).asData?.value.session?.user.id;
      if (userId == null) throw Exception('Sesi tidak ditemukan');

      final booking = BookingModel(
        id: const Uuid().v4(),
        userId: userId,
        venueId: widget.venueId,
        message: _messageCtrl.text.trim(),
        status: 'pending',
      );

      await _bookingRepo.createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil dikirim! 📅'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim booking: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final venueAsync = ref.watch(venueDetailProvider(widget.venueId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Booking Venue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue info card
            venueAsync.when(
              data: (venue) => venue != null
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                  child: Text('🏟️',
                                      style: TextStyle(fontSize: 28))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(venue.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(venue.type,
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 24),

            const Text(
              'Pesan Booking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sampaikan kebutuhan booking Anda kepada pengelola venue',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _messageCtrl,
              label: 'Pesan',
              hint:
                  'Contoh: Ingin booking lapangan futsal tanggal 25 Juni jam 16.00 untuk 10 orang...',
              maxLines: 5,
              prefixIcon: Icons.message_outlined,
            ),
            const SizedBox(height: 12),

            // Info note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.secondaryColor.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.secondaryColor, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pengelola venue akan merespons booking Anda. Tidak ada pembayaran online.',
                      style: TextStyle(
                          color: AppTheme.secondaryColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            LoadingButton(
              isLoading: _isLoading,
              onPressed: _submit,
              label: 'Kirim Booking',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
