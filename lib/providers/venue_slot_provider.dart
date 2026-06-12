import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/venue_slot_repository.dart';
import '../models/venue_slot_model.dart';

final venueSlotRepositoryProvider =
    Provider<VenueSlotRepository>((ref) => VenueSlotRepository());

// Semua slot milik venue (untuk owner manage)
final venueSlotsProvider =
    FutureProvider.family<List<VenueSlotModel>, String>((ref, venueId) async {
  final repo = ref.watch(venueSlotRepositoryProvider);
  return repo.getSlotsByVenue(venueId);
});

// Parameter query untuk slot tersedia
class SlotQueryParams {
  final String venueId;
  final int dayOfWeek;
  final DateTime date;

  const SlotQueryParams({
    required this.venueId,
    required this.dayOfWeek,
    required this.date,
  });

  @override
  bool operator ==(Object other) =>
      other is SlotQueryParams &&
      other.venueId == venueId &&
      other.dayOfWeek == dayOfWeek &&
      other.date.year == date.year &&
      other.date.month == date.month &&
      other.date.day == date.day;

  @override
  int get hashCode =>
      venueId.hashCode ^ dayOfWeek.hashCode ^ date.hashCode;
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

// Slot aktif berdasarkan venue + hari + tanggal (untuk user pilih)
final availableSlotsProvider =
    FutureProvider.family<List<SlotWithStatus>, SlotQueryParams>(
        (ref, params) async {
  final repo = ref.watch(venueSlotRepositoryProvider);

  // Ambil slot aktif hari itu
  final slots =
      await repo.getActiveSlotsByDay(params.venueId, params.dayOfWeek);

  // Ambil slot yang sudah dibooking untuk tanggal itu
  final bookedIds =
      await repo.getBookedSlotIds(params.venueId, params.date);

  // Gabungkan status
  return slots.map((slot) {
    final isBooked = bookedIds.contains(slot.id);
    final isExpired = slot.isExpiredForDate(params.date);
    return SlotWithStatus(
      slot: slot,
      isBooked: isBooked,
      isExpired: isExpired,
    );
  }).toList();
});
