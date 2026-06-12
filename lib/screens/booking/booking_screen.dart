import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/venue_provider.dart';
import '../../providers/venue_slot_provider.dart';
import '../../repositories/booking_repository.dart';
import '../../models/booking_model.dart';
import '../../models/venue_slot_model.dart';
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
  DateTime _selectedDate = DateTime.now();
  VenueSlotModel? _selectedSlot;
  bool _isLoading = false;
  final _bookingRepo = BookingRepository();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  // Hari dalam seminggu sesuai konvensi kita (1=Senin ... 7=Minggu)
  int get _selectedDayOfWeek {
    // DateTime.weekday sudah 1=Senin ... 7=Minggu
    return _selectedDate.weekday;
  }

  // Generate 14 hari ke depan untuk dipilih
  List<DateTime> get _availableDates {
    return List.generate(14, (i) {
      final d = DateTime.now().add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) return 'Hari ini';
    if (date == tomorrow) return 'Besok';
    return DateFormat('EEE, d MMM', 'id_ID').format(date);
  }

  Future<void> _submit() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih slot waktu terlebih dahulu'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }
    if (_messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tulis pesan untuk owner')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authStateProvider).asData?.value.session?.user.id;
      if (userId == null) throw Exception('Sesi tidak ditemukan');

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final booking = BookingModel(
        id: const Uuid().v4(),
        userId: userId,
        venueId: widget.venueId,
        message: _messageCtrl.text.trim(),
        status: 'pending',
        slotId: _selectedSlot!.id,
        bookingDate: _selectedDate,
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
            content: Text('Gagal: $e'),
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
    final slotParams = SlotQueryParams(
      venueId: widget.venueId,
      dayOfWeek: _selectedDayOfWeek,
      date: _selectedDate,
    );
    final slotsAsync = ref.watch(availableSlotsProvider(slotParams));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Booking Venue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info venue
            venueAsync.when(
              data: (venue) => venue != null
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text(
                                  '🏟️',
                                  style: TextStyle(fontSize: 26),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venue.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    venue.type,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),

            // ─── Pilih Tanggal ───────────────────────────────
            const Text(
              'Pilih Tanggal',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableDates.length,
                itemBuilder: (_, i) {
                  final date = _availableDates[i];
                  final isSelected =
                      date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                        _selectedSlot = null; // reset slot saat ganti tanggal
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.shade200,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE', 'id_ID').format(date),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white70
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            DateFormat('MMM', 'id_ID').format(date),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white70
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ─── Pilih Slot Jam ──────────────────────────────
            Row(
              children: [
                const Text(
                  'Pilih Jam',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_dayName(_selectedDayOfWeek)}, ${DateFormat('d MMM').format(_selectedDate)})',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            slotsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (slots) {
                if (slots.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Text('🕐', style: TextStyle(fontSize: 36)),
                          SizedBox(height: 8),
                          Text(
                            'Tidak ada slot tersedia untuk hari ini',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: slots.map((s) {
                    final isSelected = _selectedSlot?.id == s.slot.id;
                    Color bgColor;
                    Color textColor;
                    String statusLabel = '';

                    if (s.isExpired) {
                      bgColor = Colors.grey.shade100;
                      textColor = Colors.grey.shade400;
                      statusLabel = 'Lewat';
                    } else if (s.isBooked) {
                      bgColor = AppTheme.errorColor.withOpacity(0.08);
                      textColor = AppTheme.errorColor;
                      statusLabel = 'Penuh';
                    } else if (isSelected) {
                      bgColor = AppTheme.primaryColor;
                      textColor = Colors.white;
                    } else {
                      bgColor = Colors.white;
                      textColor = AppTheme.textPrimary;
                    }

                    return GestureDetector(
                      onTap: s.isAvailable
                          ? () => setState(() => _selectedSlot = s.slot)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : s.isBooked
                                ? AppTheme.errorColor.withOpacity(0.2)
                                : Colors.grey.shade200,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.25,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.slot.timeLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusLabel.isNotEmpty
                                  ? statusLabel
                                  : s.slot.priceLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white70
                                    : s.isBooked || s.isExpired
                                    ? textColor
                                    : AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // ─── Legenda ─────────────────────────────────────
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: [
                _LegendItem(color: AppTheme.primaryColor, label: 'Dipilih'),
                _LegendItem(color: AppTheme.errorColor, label: 'Penuh'),
                _LegendItem(color: Colors.grey.shade400, label: 'Sudah Lewat'),
                _LegendItem(color: Colors.grey.shade300, label: 'Tersedia'),
              ],
            ),

            const SizedBox(height: 20),

            // ─── Slot yang dipilih ────────────────────────────
            if (_selectedSlot != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_dayName(_selectedSlot!.dayOfWeek)}, ${DateFormat('d MMM yyyy').format(_selectedDate)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Text(
                            '${_selectedSlot!.timeLabel}  ·  ${_selectedSlot!.priceLabel}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Pesan ───────────────────────────────────────
            CustomTextField(
              controller: _messageCtrl,
              label: 'Pesan untuk Owner',
              hint: 'Contoh: Booking untuk 10 orang, minta perlengkapan...',
              maxLines: 3,
              prefixIcon: Icons.message_outlined,
            ),
            const SizedBox(height: 12),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.secondaryColor,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Booking akan dikonfirmasi oleh owner. Tidak ada pembayaran online.',
                      style: TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim Booking'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _dayName(int dow) {
    const days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[dow];
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
