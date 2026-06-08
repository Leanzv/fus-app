import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/venue_provider.dart';
import '../../repositories/venue_repository.dart';
import '../../services/storage_service.dart';
import '../../models/venue_model.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class EditVenueScreen extends ConsumerStatefulWidget {
  final String venueId;
  const EditVenueScreen({super.key, required this.venueId});

  @override
  ConsumerState<EditVenueScreen> createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends ConsumerState<EditVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = sportTypes.first;
  File? _newImageFile;
  bool _isLoading = false;
  VenueModel? _venue;

  final _storageService = StorageService();
  final _venueRepo = VenueRepository();

  @override
  void initState() {
    super.initState();
    _loadVenue();
  }

  Future<void> _loadVenue() async {
    final venue = await _venueRepo.getVenueById(widget.venueId);
    if (venue != null && mounted) {
      setState(() {
        _venue = venue;
        _nameCtrl.text = venue.name;
        _descCtrl.text = venue.description;
        _selectedType = venue.type;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked != null) {
      setState(() => _newImageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl = _venue?.imageUrl;
      if (_newImageFile != null) {
        imageUrl = await _storageService.uploadVenueImage(_newImageFile!);
      }

      await _venueRepo.updateVenue(widget.venueId, {
        'name': _nameCtrl.text.trim(),
        'type': _selectedType,
        'description': _descCtrl.text.trim(),
        'image_url': ?imageUrl,
      });

      ref.invalidate(venueListProvider);
      ref.invalidate(venueDetailProvider(widget.venueId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venue berhasil diperbarui! ✅'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui: $e'),
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
    if (_venue == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Edit Venue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _newImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_newImageFile!, fit: BoxFit.cover,
                              width: double.infinity),
                        )
                      : _venue!.imageUrl != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: CachedNetworkImage(
                                    imageUrl: _venue!.imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Ganti Foto',
                                            style: TextStyle(
                                                color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 48, color: AppTheme.textSecondary),
                                SizedBox(height: 8),
                                Text('Tambah Foto',
                                    style: TextStyle(color: AppTheme.textSecondary)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _nameCtrl,
                label: 'Nama Venue',
                hint: 'Nama venue',
                prefixIcon: Icons.sports_soccer_outlined,
                validator: (val) =>
                    val?.isEmpty == true ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Jenis Olahraga',
                  prefixIcon: const Icon(Icons.sports),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: sportTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedType = val ?? _selectedType),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descCtrl,
                label: 'Deskripsi',
                hint: 'Deskripsi venue...',
                maxLines: 3,
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 32),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _submit,
                label: 'Simpan Perubahan',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
