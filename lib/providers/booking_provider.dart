import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/booking_repository.dart';
import '../models/booking_model.dart';

final bookingRepositoryProvider =
    Provider<BookingRepository>((ref) => BookingRepository());

// Provider booking user
final userBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, userId) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getUserBookings(userId);
});

// Provider booking untuk semua venue owner
final ownerBookingsProvider =
    FutureProvider.family<List<BookingModel>, List<String>>((ref, venueIds) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getOwnerAllBookings(venueIds);
});
