import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/venue_repository.dart';
import '../models/venue_model.dart';
import '../services/location_service.dart';

final venueRepositoryProvider = Provider<VenueRepository>((ref) => VenueRepository());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

// Provider lokasi user saat ini
final userLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  try {
    return await locationService.getCurrentLocation();
  } catch (_) {
    return null;
  }
});

// Filter state
class VenueFilter {
  final String? searchQuery;
  final String? sportType;
  final double? minRating;

  const VenueFilter({this.searchQuery, this.sportType, this.minRating});

  VenueFilter copyWith({
    String? searchQuery,
    String? sportType,
    double? minRating,
    bool clearSearch = false,
    bool clearSport = false,
    bool clearRating = false,
  }) {
    return VenueFilter(
      searchQuery: clearSearch ? null : searchQuery ?? this.searchQuery,
      sportType: clearSport ? null : sportType ?? this.sportType,
      minRating: clearRating ? null : minRating ?? this.minRating,
    );
  }
}

final venueFilterProvider = StateProvider<VenueFilter>((ref) => const VenueFilter());

// Provider list venue dengan filter dan lokasi
final venueListProvider = FutureProvider<List<VenueModel>>((ref) async {
  final repo = ref.watch(venueRepositoryProvider);
  final filter = ref.watch(venueFilterProvider);
  final location = await ref.watch(userLocationProvider.future);

  return repo.getVenues(
    searchQuery: filter.searchQuery,
    sportType: filter.sportType,
    minRating: filter.minRating,
    userLat: location?.latitude,
    userLon: location?.longitude,
  );
});

// Provider detail venue
final venueDetailProvider =
    FutureProvider.family<VenueModel?, String>((ref, id) async {
  final repo = ref.watch(venueRepositoryProvider);
  return repo.getVenueById(id);
});

// Provider venue milik owner
final ownerVenuesProvider =
    FutureProvider.family<List<VenueModel>, String>((ref, ownerId) async {
  final repo = ref.watch(venueRepositoryProvider);
  return repo.getOwnerVenues(ownerId);
});
