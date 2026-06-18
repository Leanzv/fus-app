import '../main.dart';
import '../models/message_model.dart';

class MessageRepository {
  // Stream pesan realtime berdasarkan booking
  Stream<List<MessageModel>> streamMessages(String bookingId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('created_at')
        .map((data) => data.map((e) => MessageModel.fromJson(e)).toList());
  }

  // Kirim pesan baru
  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String content,
  }) async {
    await supabase.from('messages').insert({
      'booking_id': bookingId,
      'sender_id':  senderId,
      'content':    content,
    });
  }

  // Kirim pesan otomatis saat status booking berubah
  Future<void> sendStatusMessage({
    required String bookingId,
    required String senderId,
    required String status,
  }) async {
    final content = status == 'confirmed'
        ? '✅ Booking telah dikonfirmasi. Silakan datang sesuai jadwal yang dipesan.'
        : '❌ Mohon maaf, booking tidak dapat dikonfirmasi. Silakan coba waktu lain.';

    await supabase.from('messages').insert({
      'booking_id': bookingId,
      'sender_id':  senderId,
      'content':    content,
    });
  }
}
