import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/booking_repository.dart';
import '../models/booking_model.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) => BookingRepository());

final userBookingsProvider = FutureProvider.family<List<BookingModel>, String>((ref, userId) async =>
    ref.watch(bookingRepositoryProvider).getUserBookings(userId));

final ownerBookingsProvider = FutureProvider.family<List<BookingModel>, List<String>>((ref, venueIds) async =>
    ref.watch(bookingRepositoryProvider).getOwnerAllBookings(venueIds));
