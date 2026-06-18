import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../repositories/message_repository.dart';
import '../../core/theme.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final BookingModel? booking;
  const ChatDetailScreen({super.key, required this.bookingId, this.booking});
  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _repo       = MessageRepository();
  bool _sending     = false;

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final uid = ref.read(authStateProvider).asData?.value.session?.user.id;
    if (uid == null) return;
    setState(() => _sending = true);
    try {
      _msgCtrl.clear();
      await _repo.sendMessage(bookingId: widget.bookingId, senderId: uid, content: text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal kirim: $e'), backgroundColor: AppTheme.errorColor));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    final b   = widget.booking;
    final uid = ref.watch(authStateProvider).asData?.value.session?.user.id;
    final messagesAsync = ref.watch(messagesProvider(widget.bookingId));

    messagesAsync.whenData((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(radius: 18,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
            child: const Text('🏟️', style: TextStyle(fontSize: 16))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b?.venueName ?? 'Chat Booking', style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (b != null) Text(b.statusLabel, style: TextStyle(
                fontSize: 11, color: b.statusColor, fontWeight: FontWeight.w600)),
          ])),
        ]),
      ),
      body: Column(children: [
        // Banner info booking
        if (b != null) _BookingBanner(booking: b),

        // List pesan
        Expanded(child: messagesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('Gagal memuat: $e')),
          data: (messages) {
            if (messages.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('💬', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Belum ada pesan.\nMulai percakapan sekarang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary)),
                ])));
            }
            return ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg      = messages[i];
                final isMe     = msg.senderId == uid;
                final showDate = i == 0 || !_isSameDay(messages[i-1].createdAt, msg.createdAt);
                return Column(children: [
                  if (showDate) _DateDivider(date: msg.createdAt),
                  _MessageBubble(message: msg, isMe: isMe),
                ]);
              });
          })),

        // Input bar
        _ChatInput(controller: _msgCtrl, sending: _sending, onSend: _send),
      ]),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ─── Banner ──────────────────────────────────────────────────
class _BookingBanner extends StatefulWidget {
  final BookingModel booking;
  const _BookingBanner({required this.booking});
  @override
  State<_BookingBanner> createState() => _BookingBannerState();
}
class _BookingBannerState extends State<_BookingBanner> {
  bool _exp = false;
  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return GestureDetector(
      onTap: () => setState(() => _exp = !_exp),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppTheme.primaryColor.withOpacity(0.07),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.info_outline, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            const Expanded(child: Text('Detail Booking', style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primaryColor))),
            Icon(_exp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16, color: AppTheme.primaryColor),
          ]),
          if (_exp) ...[
            const SizedBox(height: 8),
            if (b.bookingDate != null) _BRow(icon: Icons.calendar_today_outlined,
              text: DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(b.bookingDate!)),
            if (b.slotTimeLabel.isNotEmpty) _BRow(icon: Icons.access_time_rounded,
              text: '${b.slotTimeLabel}  ·  ${b.slotPriceLabel}', color: AppTheme.primaryColor),
            _BRow(icon: Icons.circle, text: 'Status: ${b.statusLabel}', color: b.statusColor),
          ],
        ])),
    );
  }
}
class _BRow extends StatelessWidget {
  final IconData icon; final String text; final Color? color;
  const _BRow({required this.icon, required this.text, this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Icon(icon, size: 12, color: color ?? AppTheme.textSecondary),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12,
          color: color ?? AppTheme.textSecondary,
          fontWeight: color != null ? FontWeight.w600 : FontWeight.normal))),
    ]));
}

// ─── Bubble ──────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: 3, bottom: 3,
            left: isMe ? 64 : 0, right: isMe ? 0 : 64),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && message.senderName != null)
              Padding(padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(message.senderName!, style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4  : 18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                    blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text(message.content, style: TextStyle(
                  color: isMe ? Colors.white : AppTheme.textPrimary,
                  fontSize: 14, height: 1.4))),
            if (message.createdAt != null)
              Padding(padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Text(DateFormat('HH:mm').format(message.createdAt!),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))),
          ])));
  }
}

// ─── Date divider ────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime? date;
  const _DateDivider({this.date});
  String get _label {
    if (date == null) return '';
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date!.year, date!.month, date!.day);
    if (d == today) return 'Hari ini';
    if (d == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return DateFormat('d MMMM yyyy', 'id_ID').format(date!);
  }
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      const Expanded(child: Divider()),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(_label, style: const TextStyle(
            fontSize: 11, color: AppTheme.textSecondary))),
      const Expanded(child: Divider()),
    ]));
}

// ─── Input bar ───────────────────────────────────────────────
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _ChatInput({required this.controller, required this.sending, required this.onSend});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(left: 12, right: 12, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8),
    decoration: BoxDecoration(color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, -2))]),
    child: Row(children: [
      Expanded(child: TextField(controller: controller,
        maxLines: 4, minLines: 1,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(hintText: 'Ketik pesan...',
          filled: true, fillColor: AppTheme.backgroundColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none)))),
      const SizedBox(width: 8),
      GestureDetector(onTap: sending ? null : onSend,
        child: AnimatedContainer(duration: const Duration(milliseconds: 180),
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: sending ? AppTheme.primaryColor.withOpacity(0.5) : AppTheme.primaryColor,
            shape: BoxShape.circle),
          child: sending
              ? const Padding(padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
    ]));
}
