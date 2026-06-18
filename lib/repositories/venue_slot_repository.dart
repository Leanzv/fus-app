import '../main.dart';
import '../models/venue_slot_model.dart';

class VenueSlotRepository {
  // Semua slot milik venue (untuk owner manage)
  Future<List<VenueSlotModel>> getSlotsByVenue(String venueId) async {
    final data = await supabase
        .from('venue_slots')
        .select()
        .eq('venue_id', venueId)
        .order('day_of_week')
        .order('start_time');
    return data.map((e) => VenueSlotModel.fromJson(e)).toList();
  }

  // Slot AKTIF berdasarkan venue dan hari — hanya is_active = true
  Future<List<VenueSlotModel>> getActiveSlotsByDay(
      String venueId, int dayOfWeek) async {
    final data = await supabase
        .from('venue_slots')
        .select()
        .eq('venue_id', venueId)
        .eq('day_of_week', dayOfWeek)
        .eq('is_active', true)
        .order('start_time');
    return data.map((e) => VenueSlotModel.fromJson(e)).toList();
  }

  // Tambah slot baru
  Future<VenueSlotModel> addSlot(VenueSlotModel slot) async {
    final data = await supabase
        .from('venue_slots')
        .insert(slot.toJson())
        .select()
        .single();
    return VenueSlotModel.fromJson(data);
  }

  // Toggle aktif/nonaktif
  Future<void> toggleSlot(String slotId, bool isActive) async {
    await supabase
        .from('venue_slots')
        .update({'is_active': isActive})
        .eq('id', slotId);
  }

  // Hapus slot
  Future<void> deleteSlot(String slotId) async {
    await supabase.from('venue_slots').delete().eq('id', slotId);
  }

  // ✅ FIX: Ambil slot_id yang sudah dibooking untuk tanggal tertentu
  // Filter slot_id NOT NULL untuk hindari booking lama tanpa slot
  Future<List<String>> getBookedSlotIds(
      String venueId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final data = await supabase
        .from('bookings')
        .select('slot_id')
        .eq('venue_id', venueId)
        .eq('booking_date', dateStr)
        .inFilter('status', ['pending', 'confirmed'])
        .not('slot_id', 'is', null); // ✅ abaikan booking tanpa slot_id

    return data
        .map((e) => e['slot_id'] as String)
        .where((id) => id.isNotEmpty)
        .toList();
  }
}
