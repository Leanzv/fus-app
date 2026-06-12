import '../main.dart';
import '../models/booking_model.dart';

class BookingRepository {
  // Kirim booking dari user
  Future<BookingModel> createBooking(BookingModel booking) async {
    final data = await supabase
        .from('bookings')
        .insert(booking.toJson())
        .select()
        .single();

    return BookingModel.fromJson(data);
  }

  // Ambil booking milik user (dengan info slot)
  Future<List<BookingModel>> getUserBookings(String userId) async {
    final data = await supabase
        .from('bookings')
        .select('*, venues(name), venue_slots(start_time, end_time, price)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data.map((item) => BookingModel.fromJson(item)).toList();
  }

  // Ambil booking untuk semua venue owner (dengan info user dan slot)
  Future<List<BookingModel>> getOwnerAllBookings(List<String> venueIds) async {
    if (venueIds.isEmpty) return [];

    final data = await supabase
        .from('bookings')
        .select('*, profiles(name, email), venues(name), venue_slots(start_time, end_time, price)')
        .inFilter('venue_id', venueIds)
        .order('created_at', ascending: false);

    return data.map((item) => BookingModel.fromJson(item)).toList();
  }

  // Ambil booking untuk venue tertentu
  Future<List<BookingModel>> getVenueBookings(String venueId) async {
    final data = await supabase
        .from('bookings')
        .select('*, profiles(name, email), venue_slots(start_time, end_time, price)')
        .eq('venue_id', venueId)
        .order('created_at', ascending: false);

    return data.map((item) => BookingModel.fromJson(item)).toList();
  }

  // Update status booking (oleh owner)
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await supabase
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId);
  }
}
