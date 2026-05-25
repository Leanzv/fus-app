import '../main.dart';
import '../models/venue_model.dart';
import '../services/location_service.dart';

class VenueRepository {
  final LocationService _locationService = LocationService();

  // Ambil semua venue dengan filter opsional
  Future<List<VenueModel>> getVenues({
    String? searchQuery,
    String? sportType,
    double? minRating,
    double? userLat,
    double? userLon,
  }) async {
    var query = supabase.from('venues').select('''
      *,
      reviews(rating)
    ''');

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    if (sportType != null && sportType.isNotEmpty) {
      query = query.eq('type', sportType);
    }

    final data = await query.order('created_at', ascending: false);

    List<VenueModel> venues = [];

    for (final item in data) {
      final reviews = (item['reviews'] as List<dynamic>?) ?? [];
      double? avgRating;
      if (reviews.isNotEmpty) {
        final total = reviews
            .map((r) => (r['rating'] as num).toDouble())
            .reduce((a, b) => a + b);
        avgRating = total / reviews.length;
      }

      final venue = VenueModel(
        id: item['id'],
        ownerId: item['owner_id'],
        name: item['name'],
        type: item['type'],
        description: item['description'] ?? '',
        latitude: (item['latitude'] as num).toDouble(),
        longitude: (item['longitude'] as num).toDouble(),
        imageUrl: item['image_url'],
        averageRating: avgRating,
        reviewCount: reviews.length,
        createdAt: item['created_at'] != null
            ? DateTime.parse(item['created_at'])
            : null,
      );

      // Hitung jarak jika ada koordinat user
      if (userLat != null && userLon != null) {
        venue.distanceKm = _locationService.calculateDistance(
          startLat: userLat,
          startLon: userLon,
          endLat: venue.latitude,
          endLon: venue.longitude,
        );
      }

      venues.add(venue);
    }

    // Filter berdasarkan rating minimum
    if (minRating != null) {
      venues =
          venues.where((v) => (v.averageRating ?? 0) >= minRating).toList();
    }

    // Urutkan berdasarkan jarak jika ada
    if (userLat != null && userLon != null) {
      venues.sort((a, b) {
        final da = a.distanceKm ?? double.infinity;
        final db = b.distanceKm ?? double.infinity;
        return da.compareTo(db);
      });
    }

    return venues;
  }

  // Ambil venue berdasarkan ID
  Future<VenueModel?> getVenueById(String id) async {
    final data = await supabase
        .from('venues')
        .select('*, reviews(rating)')
        .eq('id', id)
        .single();

    final reviews = (data['reviews'] as List<dynamic>?) ?? [];
    double? avgRating;
    if (reviews.isNotEmpty) {
      final total = reviews
          .map((r) => (r['rating'] as num).toDouble())
          .reduce((a, b) => a + b);
      avgRating = total / reviews.length;
    }

    return VenueModel(
      id: data['id'],
      ownerId: data['owner_id'],
      name: data['name'],
      type: data['type'],
      description: data['description'] ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      imageUrl: data['image_url'],
      averageRating: avgRating,
      reviewCount: reviews.length,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
    );
  }

  // Ambil venue milik owner
  Future<List<VenueModel>> getOwnerVenues(String ownerId) async {
    final data = await supabase
        .from('venues')
        .select('*, reviews(rating)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);

    return data.map((item) {
      final reviews = (item['reviews'] as List<dynamic>?) ?? [];
      double? avgRating;
      if (reviews.isNotEmpty) {
        final total = reviews
            .map((r) => (r['rating'] as num).toDouble())
            .reduce((a, b) => a + b);
        avgRating = total / reviews.length;
      }

      return VenueModel(
        id: item['id'],
        ownerId: item['owner_id'],
        name: item['name'],
        type: item['type'],
        description: item['description'] ?? '',
        latitude: (item['latitude'] as num).toDouble(),
        longitude: (item['longitude'] as num).toDouble(),
        imageUrl: item['image_url'],
        averageRating: avgRating,
        reviewCount: reviews.length,
        createdAt: item['created_at'] != null
            ? DateTime.parse(item['created_at'])
            : null,
      );
    }).toList();
  }

  // Tambah venue baru
  Future<VenueModel> addVenue(VenueModel venue) async {
    final data = await supabase
        .from('venues')
        .insert(venue.toJson())
        .select()
        .single();

    return VenueModel.fromJson(data);
  }

  // Update venue
  Future<void> updateVenue(String id, Map<String, dynamic> updates) async {
    await supabase.from('venues').update(updates).eq('id', id);
  }

  // Hapus venue
  Future<void> deleteVenue(String id) async {
    await supabase.from('venues').delete().eq('id', id);
  }
}
