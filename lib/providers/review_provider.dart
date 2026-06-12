import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/review_repository.dart';
import '../models/review_model.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) => ReviewRepository());

final venueReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, venueId) =>
    ref.watch(reviewRepositoryProvider).streamReviewsByVenue(venueId));
