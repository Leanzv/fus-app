class VenueSlotModel {
  final String id;
  final String venueId;
  final int dayOfWeek; // 1=Senin, 2=Selasa, ..., 7=Minggu
  final String startTime; // "08:00"
  final String endTime;   // "09:00"
  final int price;
  final bool isActive;
  final DateTime? createdAt;

  const VenueSlotModel({
    required this.id,
    required this.venueId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.price,
    this.isActive = true,
    this.createdAt,
  });

  factory VenueSlotModel.fromJson(Map<String, dynamic> json) {
    return VenueSlotModel(
      id: json['id'] as String,
      venueId: json['venue_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      price: json['price'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'venue_id': venueId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'price': price,
      'is_active': isActive,
    };
  }

  VenueSlotModel copyWith({bool? isActive, int? price}) {
    return VenueSlotModel(
      id: id,
      venueId: venueId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  // Helper: nama hari
  String get dayName {
    const days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[dayOfWeek];
  }

  // Helper: label waktu
  String get timeLabel => '$startTime – $endTime';

  // Helper: format harga
  String get priceLabel {
    if (price == 0) return 'Gratis';
    return 'Rp ${_formatNumber(price)}';
  }

  static String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  // Cek apakah slot ini hari ini
  bool get isToday {
    final now = DateTime.now();
    // DateTime weekday: 1=Senin ... 7=Minggu (sama dengan dayOfWeek kita)
    return now.weekday == dayOfWeek;
  }

  // Cek apakah waktu slot sudah lewat hari ini
  bool isExpiredForDate(DateTime date) {
    final now = DateTime.now();
    if (date.year != now.year ||
        date.month != now.month ||
        date.day != now.day) {
      return false; // Bukan hari ini, belum expired
    }
    // Parse end_time
    final parts = endTime.split(':');
    final endHour = int.parse(parts[0]);
    final endMin = int.parse(parts[1]);
    final endDateTime = DateTime(now.year, now.month, now.day, endHour, endMin);
    return now.isAfter(endDateTime);
  }
}
