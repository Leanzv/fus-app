import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/message_repository.dart';
import '../models/message_model.dart';

final messageRepositoryProvider =
    Provider<MessageRepository>((ref) => MessageRepository());

final messagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, bookingId) {
  return ref.watch(messageRepositoryProvider).streamMessages(bookingId);
});
