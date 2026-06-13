import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/booking_repository.dart';
import '../models/booking_model.dart';

final bookingRepositoryProvider =
    Provider<BookingRepository>((ref) => BookingRepository());

// Booking milik user
final userBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, userId) async {
  return ref.watch(bookingRepositoryProvider).getUserBookings(userId);
});

// ✅ FIX: gunakan String (comma-joined) sebagai key, bukan List<String>
// Riverpod family tidak support List sebagai key dengan equality yang benar
final ownerBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, venueIdsJoined) async {
  if (venueIdsJoined.isEmpty) return [];
  final venueIds = venueIdsJoined.split(',');
  return ref.watch(bookingRepositoryProvider).getOwnerAllBookings(venueIds);
});
