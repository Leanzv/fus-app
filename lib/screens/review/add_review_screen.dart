import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/review_repository.dart';
import '../../services/storage_service.dart';
import '../../models/review_model.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  final String venueId;
  const AddReviewScreen({super.key, required this.venueId});
  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final _comment = TextEditingController();
  double _rating = 3;
  File? _img;
  bool _loading = false;

  @override
  void dispose() { _comment.dispose(); super.dispose(); }

  String get _label { switch (_rating.toInt()) {
    case 1: return 'Sangat Buruk 😞'; case 2: return 'Buruk 😕';
    case 3: return 'Biasa Saja 😐'; case 4: return 'Bagus 😊';
    case 5: return 'Luar Biasa! 🤩'; default: return ''; } }

  Future<void> _submit() async {
    if (_comment.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tulis komentar dulu')));
      return;
    }
    setState(() => _loading = true);
    try {
      final uid = ref.read(authStateProvider).asData?.value.session?.user.id;
      if (uid == null) throw Exception('Sesi tidak ditemukan');
      final hasReviewed = await ReviewRepository().hasUserReviewed(widget.venueId, uid);
      if (hasReviewed) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Anda sudah pernah mereview venue ini'), backgroundColor: AppTheme.warningColor));
        return;
      }
      String? imgUrl;
      if (_img != null) imgUrl = await StorageService().uploadReviewImage(_img!);
      await ReviewRepository().addReview(ReviewModel(
        id: const Uuid().v4(), userId: uid, venueId: widget.venueId,
        rating: _rating, comment: _comment.text.trim(), imageUrl: imgUrl));
      if (mounted) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ulasan berhasil dikirim! 🌟'), backgroundColor: AppTheme.primaryColor)); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.errorColor));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Tulis Ulasan')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            const Text('Beri Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            RatingBar.builder(initialRating: _rating, minRating: 1, itemCount: 5, itemSize: 48,
              itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppTheme.starColor),
              onRatingUpdate: (r) => setState(() => _rating = r)),
            const SizedBox(height: 8),
            Text(_label, style: const TextStyle(color: AppTheme.textSecondary)),
          ]))),
          const SizedBox(height: 16),
          CustomTextField(controller: _comment, label: 'Komentar', hint: 'Ceritakan pengalamanmu...',
            maxLines: 4, prefixIcon: Icons.comment_outlined),
          const SizedBox(height: 16),
          const Text('Foto (opsional)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _ImgBtn(icon: Icons.camera_alt_outlined, label: 'Kamera',
              onTap: () async { final p = await ImagePicker().pickImage(
                source: ImageSource.camera, maxWidth: 1000, imageQuality: 80);
                if (p != null) setState(() => _img = File(p.path)); })),
            const SizedBox(width: 10),
            Expanded(child: _ImgBtn(icon: Icons.photo_library_outlined, label: 'Galeri',
              onTap: () async { final p = await ImagePicker().pickImage(
                source: ImageSource.gallery, maxWidth: 1000, imageQuality: 80);
                if (p != null) setState(() => _img = File(p.path)); })),
          ]),
          if (_img != null) ...[
            const SizedBox(height: 12),
            Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: Image.file(_img!, height: 180, width: double.infinity, fit: BoxFit.cover)),
              Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => setState(() => _img = null),
                child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 16)))),
            ])],
          const SizedBox(height: 32),
          LoadingButton(isLoading: _loading, onPressed: _submit, label: 'Kirim Ulasan'),
          const SizedBox(height: 40),
        ])));
  }
}

class _ImgBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _ImgBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Column(children: [
          Icon(icon, color: AppTheme.primaryColor, size: 28), const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))])));
  }
}
