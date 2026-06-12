import '../main.dart';
import '../models/review_model.dart';

class ReviewRepository {
  Future<List<ReviewModel>> getReviewsByVenue(String venueId) async {
    final data = await supabase.from('reviews')
        .select('*, profiles(name, avatar_url)').eq('venue_id', venueId)
        .order('created_at', ascending: false);
    return data.map((e) => ReviewModel.fromJson(e)).toList();
  }

  Stream<List<ReviewModel>> streamReviewsByVenue(String venueId) {
    return supabase.from('reviews').stream(primaryKey: ['id'])
        .eq('venue_id', venueId).order('created_at', ascending: false)
        .map((data) => data.map((e) => ReviewModel.fromJson(e)).toList());
  }

  Future<ReviewModel> addReview(ReviewModel review) async {
    final d = await supabase.from('reviews').insert(review.toJson()).select().single();
    return ReviewModel.fromJson(d);
  }

  Future<void> deleteReview(String id) async =>
      await supabase.from('reviews').delete().eq('id', id);

  Future<bool> hasUserReviewed(String venueId, String userId) async {
    final d = await supabase.from('reviews').select('id')
        .eq('venue_id', venueId).eq('user_id', userId);
    return d.isNotEmpty;
  }
}
