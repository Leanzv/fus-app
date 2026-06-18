import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/venue_slot_repository.dart';
import '../models/venue_slot_model.dart';

final venueSlotRepositoryProvider =
    Provider<VenueSlotRepository>((ref) => VenueSlotRepository());

// Semua slot milik venue (untuk owner manage)
final venueSlotsProvider =
    FutureProvider.family<List<VenueSlotModel>, String>((ref, venueId) async {
  return ref.watch(venueSlotRepositoryProvider).getSlotsByVenue(venueId);
});

// ✅ FIX: Parameter query pakai String gabungan agar equality benar
// Format: "venueId|dayOfWeek|yyyy-MM-dd"
class SlotQueryParams {
  final String venueId;
  final int dayOfWeek;
  final DateTime date;

  const SlotQueryParams({
    required this.venueId,
    required this.dayOfWeek,
    required this.date,
  });

  // ✅ Key unik sebagai String untuk FutureProvider.family
  String get key {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$venueId|$dayOfWeek|$dateStr';
  }

  @override
  bool operator ==(Object other) =>
      other is SlotQueryParams && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

// Model slot + status ketersediaan
class SlotWithStatus {
  final VenueSlotModel slot;
  final bool isBooked;
  final bool isExpired;

  bool get isAvailable => !isBooked && !isExpired;

  const SlotWithStatus({
    required this.slot,
    required this.isBooked,
    required this.isExpired,
  });
}

// ✅ FIX: Provider pakai String key (bukan object) untuk menghindari
// masalah equality yang menyebabkan provider tidak refresh
final availableSlotsProvider =
    FutureProvider.family<List<SlotWithStatus>, String>((ref, paramsKey) async {
  // Parse key: "venueId|dayOfWeek|yyyy-MM-dd"
  final parts     = paramsKey.split('|');
  final venueId   = parts[0];
  final dayOfWeek = int.parse(parts[1]);
  final dateParts = parts[2].split('-');
  final date = DateTime(
    int.parse(dateParts[0]),
    int.parse(dateParts[1]),
    int.parse(dateParts[2]),
  );

  final repo = ref.watch(venueSlotRepositoryProvider);

  // Ambil slot aktif hari itu
  final slots = await repo.getActiveSlotsByDay(venueId, dayOfWeek);

  // Ambil slot yang sudah dibooking untuk tanggal itu
  final bookedIds = await repo.getBookedSlotIds(venueId, date);

  return slots.map((slot) {
    final isBooked  = bookedIds.contains(slot.id);
    final isExpired = slot.isExpiredForDate(date);
    return SlotWithStatus(
      slot:      slot,
      isBooked:  isBooked,
      isExpired: isExpired,
    );
  }).toList();
});
