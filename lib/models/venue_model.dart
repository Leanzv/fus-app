class VenueModel {
  final String id;
  final String ownerId;
  final String name;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final double? averageRating;
  final int? reviewCount;
  final DateTime? createdAt;

  // Calculated field
  double? distanceKm;

  VenueModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.averageRating,
    this.reviewCount,
    this.createdAt,
    this.distanceKm,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
      reviewCount: json['review_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'name': name,
      'type': type,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
    };
  }

  VenueModel copyWith({
    String? name,
    String? type,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    double? averageRating,
    int? reviewCount,
    double? distanceKm,
  }) {
    return VenueModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

// Daftar jenis olahraga
const List<String> sportTypes = [
  'Futsal',
  'Badminton',
  'Basket',
  'Renang',
  'Tenis',
  'Voli',
  'Gym / Fitness',
  'Skate Park',
  'Climbing',
  'Golf',
  'Lainnya',
];
