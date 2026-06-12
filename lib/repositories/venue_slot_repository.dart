import '../main.dart';
import '../models/venue_slot_model.dart';

class VenueSlotRepository {
  // Ambil semua slot milik venue
  Future<List<VenueSlotModel>> getSlotsByVenue(String venueId) async {
    final data = await supabase
        .from('venue_slots')
        .select()
        .eq('venue_id', venueId)
        .order('day_of_week')
        .order('start_time');

    return data.map((e) => VenueSlotModel.fromJson(e)).toList();
  }

  // Ambil slot aktif berdasarkan venue dan hari
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

  // Toggle aktif/nonaktif slot
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

  // Ambil slot yang sudah dibooking untuk tanggal tertentu
  Future<List<String>> getBookedSlotIds(
      String venueId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final data = await supabase
        .from('bookings')
        .select('slot_id')
        .eq('venue_id', venueId)
        .eq('booking_date', dateStr)
        .inFilter('status', ['pending', 'confirmed']);

    return data
        .map((e) => e['slot_id'] as String)
        .where((id) => id.isNotEmpty)
        .toList();
  }
}
