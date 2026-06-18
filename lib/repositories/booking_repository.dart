import '../main.dart';
import '../models/booking_model.dart';
import 'message_repository.dart';

class BookingRepository {
  final _msgRepo = MessageRepository();

  Future<BookingModel> createBooking(BookingModel booking) async {
    final data = await supabase
        .from('bookings')
        .insert(booking.toJson())
        .select()
        .single();
    return BookingModel.fromJson(data);
  }

  Future<List<BookingModel>> getUserBookings(String userId) async {
    final data = await supabase
        .from('bookings')
        .select('*, venues(name), venue_slots(start_time, end_time, price)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => BookingModel.fromJson(e)).toList();
  }

  Future<List<BookingModel>> getOwnerAllBookings(List<String> venueIds) async {
    if (venueIds.isEmpty) return [];
    final data = await supabase
        .from('bookings')
        .select('*, profiles(name, email), venues(name), venue_slots(start_time, end_time, price)')
        .inFilter('venue_id', venueIds)
        .order('created_at', ascending: false);
    return data.map((e) => BookingModel.fromJson(e)).toList();
  }

  // Update status + kirim pesan otomatis ke chat
  Future<void> updateBookingStatus(String bookingId, String status) async {
    // 1. Update status di database
    await supabase
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId);

    // 2. Ambil owner_id dari venue untuk kirim pesan sebagai owner
    try {
      final booking = await supabase
          .from('bookings')
          .select('venue_id, venues(owner_id)')
          .eq('id', bookingId)
          .single();

      final ownerId = (booking['venues'] as Map<String, dynamic>)['owner_id'] as String?;
      if (ownerId != null) {
        await _msgRepo.sendStatusMessage(
          bookingId: bookingId,
          senderId:  ownerId,
          status:    status,
        );
      }
    } catch (_) {
      // Jika gagal kirim pesan otomatis, status tetap terupdate
    }
  }
}
