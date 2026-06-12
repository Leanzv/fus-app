import '../main.dart';
import '../models/venue_model.dart';
import '../services/location_service.dart';

class VenueRepository {
  final _loc = LocationService();

  Future<List<VenueModel>> getVenues({String? searchQuery, String? sportType,
      double? minRating, double? userLat, double? userLon}) async {
    var query = supabase.from('venues').select('*, reviews(rating)');
    if (searchQuery != null && searchQuery.isNotEmpty)
      query = query.ilike('name', '%$searchQuery%');
    if (sportType != null && sportType.isNotEmpty)
      query = query.eq('type', sportType);

    final data = await query.order('created_at', ascending: false);
    List<VenueModel> venues = [];
    for (final item in data) {
      final reviews = (item['reviews'] as List?) ?? [];
      double? avg;
      if (reviews.isNotEmpty) {
        avg = reviews.map((r) => (r['rating'] as num).toDouble()).reduce((a, b) => a + b) / reviews.length;
      }
      final v = VenueModel(
        id: item['id'], ownerId: item['owner_id'], name: item['name'],
        type: item['type'], description: item['description'] ?? '',
        latitude: (item['latitude'] as num).toDouble(),
        longitude: (item['longitude'] as num).toDouble(),
        imageUrl: item['image_url'], averageRating: avg,
        reviewCount: reviews.length,
        createdAt: item['created_at'] != null ? DateTime.parse(item['created_at']) : null,
      );
      if (userLat != null && userLon != null) {
        v.distanceKm = _loc.calculateDistance(
          startLat: userLat, startLon: userLon, endLat: v.latitude, endLon: v.longitude);
      }
      venues.add(v);
    }
    if (minRating != null) venues = venues.where((v) => (v.averageRating ?? 0) >= minRating).toList();
    if (userLat != null) venues.sort((a, b) => (a.distanceKm ?? 99999).compareTo(b.distanceKm ?? 99999));
    return venues;
  }

  Future<VenueModel?> getVenueById(String id) async {
    final d = await supabase.from('venues').select('*, reviews(rating)').eq('id', id).single();
    final reviews = (d['reviews'] as List?) ?? [];
    double? avg;
    if (reviews.isNotEmpty)
      avg = reviews.map((r) => (r['rating'] as num).toDouble()).reduce((a, b) => a + b) / reviews.length;
    return VenueModel(
      id: d['id'], ownerId: d['owner_id'], name: d['name'], type: d['type'],
      description: d['description'] ?? '',
      latitude: (d['latitude'] as num).toDouble(), longitude: (d['longitude'] as num).toDouble(),
      imageUrl: d['image_url'], averageRating: avg, reviewCount: reviews.length,
      createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : null,
    );
  }

  Future<List<VenueModel>> getOwnerVenues(String ownerId) async {
    final data = await supabase.from('venues').select('*, reviews(rating)')
        .eq('owner_id', ownerId).order('created_at', ascending: false);
    return data.map((item) {
      final reviews = (item['reviews'] as List?) ?? [];
      double? avg;
      if (reviews.isNotEmpty)
        avg = reviews.map((r) => (r['rating'] as num).toDouble()).reduce((a, b) => a + b) / reviews.length;
      return VenueModel(
        id: item['id'], ownerId: item['owner_id'], name: item['name'], type: item['type'],
        description: item['description'] ?? '',
        latitude: (item['latitude'] as num).toDouble(), longitude: (item['longitude'] as num).toDouble(),
        imageUrl: item['image_url'], averageRating: avg, reviewCount: reviews.length,
        createdAt: item['created_at'] != null ? DateTime.parse(item['created_at']) : null,
      );
    }).toList();
  }

  Future<VenueModel> addVenue(VenueModel venue) async {
    final d = await supabase.from('venues').insert(venue.toJson()).select().single();
    return VenueModel.fromJson(d);
  }

  Future<void> updateVenue(String id, Map<String, dynamic> updates) async =>
      await supabase.from('venues').update(updates).eq('id', id);

  Future<void> deleteVenue(String id) async =>
      await supabase.from('venues').delete().eq('id', id);
}
