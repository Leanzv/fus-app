import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/review_repository.dart';
import '../../services/storage_service.dart';
import '../../models/review_model.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import 'package:uuid/uuid.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  final String venueId;
  const AddReviewScreen({super.key, required this.venueId});

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final _commentCtrl = TextEditingController();
  double _rating = 3;
  File? _imageFile;
  bool _isLoading = false;

  final _reviewRepo = ReviewRepository();
  final _storageService = StorageService();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis komentar terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId =
          ref.read(authStateProvider).asData?.value.session?.user.id;
      if (userId == null) throw Exception('Sesi tidak ditemukan');

      // Cek apakah sudah pernah review
      final hasReviewed =
          await _reviewRepo.hasUserReviewed(widget.venueId, userId);
      if (hasReviewed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda sudah memberikan ulasan untuk venue ini'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
        return;
      }

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _storageService.uploadReviewImage(_imageFile!);
      }

      final review = ReviewModel(
        id: const Uuid().v4(),
        userId: userId,
        venueId: widget.venueId,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
        imageUrl: imageUrl,
      );

      await _reviewRepo.addReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ulasan berhasil dikirim! 🌟'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim ulasan: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Tulis Ulasan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Beri Rating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      itemCount: 5,
                      itemSize: 48,
                      itemBuilder: (_, __) => const Icon(
                        Icons.star_rounded,
                        color: AppTheme.starColor,
                      ),
                      onRatingUpdate: (r) => setState(() => _rating = r),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ratingLabel,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Comment
            CustomTextField(
              controller: _commentCtrl,
              label: 'Komentar',
              hint: 'Ceritakan pengalamanmu...',
              maxLines: 4,
              prefixIcon: Icons.comment_outlined,
            ),
            const SizedBox(height: 16),

            // Image picker
            const Text(
              'Foto (opsional)',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ImagePickerButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Kamera',
                  onTap: () => _pickImage(fromCamera: true),
                ),
                const SizedBox(width: 10),
                _ImagePickerButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Galeri',
                  onTap: () => _pickImage(fromCamera: false),
                ),
              ],
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _imageFile!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _imageFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _submit,
              label: 'Kirim Ulasan',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String get _ratingLabel {
    switch (_rating.toInt()) {
      case 1: return 'Sangat Buruk 😞';
      case 2: return 'Buruk 😕';
      case 3: return 'Biasa Saja 😐';
      case 4: return 'Bagus 😊';
      case 5: return 'Luar Biasa! 🤩';
      default: return '';
    }
  }
}

class _ImagePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 28),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
