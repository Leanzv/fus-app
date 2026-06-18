class MessageModel {
  final String id;
  final String bookingId;
  final String senderId;
  final String content;
  final DateTime? createdAt;

  // Relasi
  final String? senderName;

  const MessageModel({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.content,
    this.createdAt,
    this.senderName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id:        json['id'] as String,
      bookingId: json['booking_id'] as String,
      senderId:  json['sender_id'] as String,
      content:   json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      senderName: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId,
    'sender_id':  senderId,
    'content':    content,
  };
}
