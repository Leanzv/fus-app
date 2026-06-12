import 'package:flutter/material.dart';

class BookingModel {
  final String id;
  final String userId;
  final String venueId;
  final String message;
  final String status; // 'pending', 'confirmed', 'rejected'
  final String? slotId;
  final DateTime? bookingDate;
  final DateTime? createdAt;

  // Relasi
  final String? userName;
  final String? userEmail;
  final String? venueName;

  // Info slot (dari join)
  final String? slotStartTime;
  final String? slotEndTime;
  final int? slotPrice;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.message,
    required this.status,
    this.slotId,
    this.bookingDate,
    this.createdAt,
    this.userName,
    this.userEmail,
    this.venueName,
    this.slotStartTime,
    this.slotEndTime,
    this.slotPrice,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Parse venue_slots join
    String? startTime;
    String? endTime;
    int? price;
    if (json['venue_slots'] != null) {
      final slot = json['venue_slots'] as Map<String, dynamic>;
      startTime = slot['start_time'] as String?;
      endTime = slot['end_time'] as String?;
      price = slot['price'] as int?;
    }

    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      venueId: json['venue_id'] as String,
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      slotId: json['slot_id'] as String?,
      bookingDate: json['booking_date'] != null
          ? DateTime.parse(json['booking_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      userName: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['name'] as String?
          : null,
      userEmail: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['email'] as String?
          : null,
      venueName: json['venues'] != null
          ? (json['venues'] as Map<String, dynamic>)['name'] as String?
          : null,
      slotStartTime: startTime,
      slotEndTime: endTime,
      slotPrice: price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'venue_id': venueId,
      'message': message,
      'status': status,
      if (slotId != null) 'slot_id': slotId,
      if (bookingDate != null)
        'booking_date':
            '${bookingDate!.year}-${bookingDate!.month.toString().padLeft(2, '0')}-${bookingDate!.day.toString().padLeft(2, '0')}',
    };
  }

  BookingModel copyWith({String? status}) {
    return BookingModel(
      id: id,
      userId: userId,
      venueId: venueId,
      message: message,
      status: status ?? this.status,
      slotId: slotId,
      bookingDate: bookingDate,
      createdAt: createdAt,
      userName: userName,
      userEmail: userEmail,
      venueName: venueName,
      slotStartTime: slotStartTime,
      slotEndTime: slotEndTime,
      slotPrice: slotPrice,
    );
  }

  // Label waktu slot
  String get slotTimeLabel {
    if (slotStartTime != null && slotEndTime != null) {
      return '$slotStartTime – $slotEndTime';
    }
    return '';
  }

  // Format harga slot
  String get slotPriceLabel {
    if (slotPrice == null || slotPrice == 0) return 'Gratis';
    return 'Rp ${_formatNumber(slotPrice!)}';
  }

  static String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Color get statusColor {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF1DB954);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }
}
