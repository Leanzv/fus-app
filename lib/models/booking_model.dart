import 'package:flutter/material.dart';

class BookingModel {
  final String id;
  final String userId;
  final String venueId;
  final String message;
  final String status; // 'pending', 'confirmed', 'rejected'
  final DateTime? createdAt;

  // Relasi
  final String? userName;
  final String? userEmail;
  final String? venueName;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.message,
    required this.status,
    this.createdAt,
    this.userName,
    this.userEmail,
    this.venueName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      venueId: json['venue_id'] as String,
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'venue_id': venueId,
      'message': message,
      'status': status,
    };
  }

  BookingModel copyWith({String? status}) {
    return BookingModel(
      id: id,
      userId: userId,
      venueId: venueId,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      userName: userName,
      userEmail: userEmail,
      venueName: venueName,
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
