import '../main.dart';
import '../models/review_model.dart';

class ReviewRepository {
  // Ambil review berdasarkan venue
  Future<List<ReviewModel>> getReviewsByVenue(String venueId) async {
    final data = await supabase
        .from('reviews')
        .select('*, profiles(name, avatar_url)')
        .eq('venue_id', venueId)
        .order('created_at', ascending: false);

    return data.map((item) => ReviewModel.fromJson(item)).toList();
  }

  // Stream review realtime berdasarkan venue
  Stream<List<ReviewModel>> streamReviewsByVenue(String venueId) {
    return supabase
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('venue_id', venueId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => ReviewModel.fromJson(item)).toList());
  }

  // Tambah review
  Future<ReviewModel> addReview(ReviewModel review) async {
    final data = await supabase
        .from('reviews')
        .insert(review.toJson())
        .select()
        .single();

    return ReviewModel.fromJson(data);
  }

  // Hapus review (hanya milik sendiri)
  Future<void> deleteReview(String reviewId) async {
    await supabase.from('reviews').delete().eq('id', reviewId);
  }

  // Cek apakah user sudah mereview venue ini
  Future<bool> hasUserReviewed(String venueId, String userId) async {
    final data = await supabase
        .from('reviews')
        .select('id')
        .eq('venue_id', venueId)
        .eq('user_id', userId);

    return data.isNotEmpty;
  }
}
