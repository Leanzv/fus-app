import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/review_repository.dart';
import '../models/review_model.dart';

final reviewRepositoryProvider =
    Provider<ReviewRepository>((ref) => ReviewRepository());

// Provider reviews berdasarkan venue (realtime stream)
final venueReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, venueId) {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.streamReviewsByVenue(venueId);
});
