import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/venue_provider.dart';
import '../../repositories/venue_repository.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../models/venue_model.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import 'package:uuid/uuid.dart';

class AddVenueScreen extends ConsumerStatefulWidget {
  const AddVenueScreen({super.key});

  @override
  ConsumerState<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends ConsumerState<AddVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = sportTypes.first;
  double? _lat;
  double? _lon;
  File? _imageFile;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  final _storageService = StorageService();
  final _locationService = LocationService();
  final _venueRepo = VenueRepository();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final pos = await _locationService.getCurrentLocation();
      if (pos != null) {
        setState(() {
          _lat = pos.latitude;
          _lon = pos.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi berhasil didapat! ✅'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi venue wajib diisi'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authStateProvider).asData?.value.session?.user.id;
      if (userId == null) throw Exception('Sesi tidak ditemukan');

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _storageService.uploadVenueImage(_imageFile!);
      }

      final venue = VenueModel(
        id: const Uuid().v4(),
        ownerId: userId,
        name: _nameCtrl.text.trim(),
        type: _selectedType,
        description: _descCtrl.text.trim(),
        latitude: _lat!,
        longitude: _lon!,
        imageUrl: imageUrl,
      );

      await _venueRepo.addVenue(venue);
      ref.invalidate(venueListProvider);
      ref.invalidate(ownerVenuesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venue berhasil ditambahkan! 🎉'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah venue: $e'),
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
      appBar: AppBar(title: const Text('Tambah Venue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.grey.shade200, width: 2,
                        style: BorderStyle.solid),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_imageFile!, fit: BoxFit.cover,
                              width: double.infinity),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 48, color: AppTheme.textSecondary),
                            SizedBox(height: 8),
                            Text('Tambah Foto Venue',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _nameCtrl,
                label: 'Nama Venue',
                hint: 'Contoh: Lapangan Futsal Maju',
                prefixIcon: Icons.sports_soccer_outlined,
                validator: (val) =>
                    val?.isEmpty == true ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Sport type dropdown
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
                    setState(() => _selectedType = val ?? sportTypes.first),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _descCtrl,
                label: 'Deskripsi',
                hint: 'Jelaskan venue Anda...',
                maxLines: 3,
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 16),

              // Location picker
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _lat != null
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Venue',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                          ),
                          Text(
                            _lat != null
                                ? '${_lat!.toStringAsFixed(5)}, ${_lon!.toStringAsFixed(5)}'
                                : 'Belum ada lokasi',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8)),
                      child: _isGettingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Gunakan GPS', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              LoadingButton(
                isLoading: _isLoading,
                onPressed: _submit,
                label: 'Simpan Venue',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
