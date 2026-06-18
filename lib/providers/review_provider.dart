import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/review_repository.dart';
import '../models/review_model.dart';

final reviewRepositoryProvider =
    Provider<ReviewRepository>((ref) => ReviewRepository());

// Stream realtime reviews per venue
final venueReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, venueId) {
  return ref.watch(reviewRepositoryProvider).streamReviewsByVenue(venueId);
});

// FutureProvider sebagai fallback jika stream tidak update
final venueReviewsFutureProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, venueId) async {
  return ref.watch(reviewRepositoryProvider).getReviewsByVenue(venueId);
});
