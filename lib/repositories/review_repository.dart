import '../main.dart';
import '../models/review_model.dart';

class ReviewRepository {
  // Fetch biasa (fallback jika realtime belum aktif)
  Future<List<ReviewModel>> getReviewsByVenue(String venueId) async {
    final data = await supabase
        .from('reviews')
        .select('*, profiles(name, avatar_url)')
        .eq('venue_id', venueId)
        .order('created_at', ascending: false);
    return data.map((e) => ReviewModel.fromJson(e)).toList();
  }

  // Stream realtime — jika realtime aktif di Supabase, pakai ini
  // Jika belum aktif, gunakan getReviewsByVenue + manual refresh
  Stream<List<ReviewModel>> streamReviewsByVenue(String venueId) {
    return supabase
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('venue_id', venueId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => ReviewModel.fromJson(e)).toList());
  }

  Future<ReviewModel> addReview(ReviewModel review) async {
    final data = await supabase
        .from('reviews')
        .insert(review.toJson())
        .select()
        .single();
    return ReviewModel.fromJson(data);
  }

  // Fix: hapus review dengan pengecekan eksplisit user_id
  Future<void> deleteReview(String reviewId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Sesi tidak ditemukan');
    await supabase
        .from('reviews')
        .delete()
        .eq('id', reviewId)
        .eq('user_id', userId); // pastikan hanya bisa hapus milik sendiri
  }

  Future<bool> hasUserReviewed(String venueId, String userId) async {
    final data = await supabase
        .from('reviews')
        .select('id')
        .eq('venue_id', venueId)
        .eq('user_id', userId);
    return data.isNotEmpty;
  }
}
