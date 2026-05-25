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

  // Ambil booking user (untuk user)
  Future<List<BookingModel>> getUserBookings(String userId) async {
    final data = await supabase
        .from('bookings')
        .select('*, venues(name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data.map((item) => BookingModel.fromJson(item)).toList();
  }

  // Stream booking owner (realtime)
  Stream<List<BookingModel>> streamOwnerBookings(String ownerId) {
    return supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          // Filter booking yang venue-nya milik owner ini
          return data.map((item) => BookingModel.fromJson(item)).toList();
        });
  }

  // Ambil booking untuk venue tertentu (owner)
  Future<List<BookingModel>> getVenueBookings(String venueId) async {
    final data = await supabase
        .from('bookings')
        .select('*, profiles(name, email)')
        .eq('venue_id', venueId)
        .order('created_at', ascending: false);

    return data.map((item) => BookingModel.fromJson(item)).toList();
  }

  // Ambil semua booking dari venue-venue milik owner
  Future<List<BookingModel>> getOwnerAllBookings(List<String> venueIds) async {
    if (venueIds.isEmpty) return [];

    final data = await supabase
        .from('bookings')
        .select('*, profiles(name, email), venues(name)')
        .inFilter('venue_id', venueIds)
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
