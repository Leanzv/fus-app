import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../providers/venue_provider.dart';
import '../../repositories/venue_repository.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../models/venue_model.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';

class AddVenueScreen extends ConsumerStatefulWidget {
  const AddVenueScreen({super.key});
  @override
  ConsumerState<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends ConsumerState<AddVenueScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _type = sportTypes.first;
  double? _lat, _lon;
  File? _img;
  bool _loading = false, _gpsLoading = false;

  @override
  void dispose() { _name.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (p != null) setState(() => _img = File(p.path));
  }

  Future<void> _getLocation() async {
    setState(() => _gpsLoading = true);
    try {
      final pos = await LocationService().getCurrentLocation();
      if (pos != null) {
        setState(() { _lat = pos.latitude; _lon = pos.longitude; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lokasi berhasil didapat! ✅'), backgroundColor: AppTheme.primaryColor));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor));
    } finally { setState(() => _gpsLoading = false); }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_lat == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lokasi venue wajib diisi'), backgroundColor: AppTheme.errorColor));
      return;
    }
    setState(() => _loading = true);
    try {
      final uid = ref.read(authStateProvider).asData?.value.session?.user.id;
      if (uid == null) throw Exception('Sesi tidak ditemukan');
      String? imgUrl;
      if (_img != null) imgUrl = await StorageService().uploadVenueImage(_img!);
      await VenueRepository().addVenue(VenueModel(
        id: const Uuid().v4(), ownerId: uid, name: _name.text.trim(),
        type: _type, description: _desc.text.trim(),
        latitude: _lat!, longitude: _lon!, imageUrl: imgUrl));
      ref.invalidate(venueListProvider);
      if (mounted) { context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Venue berhasil ditambahkan! 🎉'), backgroundColor: AppTheme.primaryColor)); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.errorColor));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Tambah Venue')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: _pickImage,
            child: Container(height: 180, decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 2)),
              child: _img != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(14),
                      child: Image.file(_img!, fit: BoxFit.cover, width: double.infinity))
                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppTheme.textSecondary),
                      SizedBox(height: 8),
                      Text('Tambah Foto Venue', style: TextStyle(color: AppTheme.textSecondary))]))),
          const SizedBox(height: 20),
          CustomTextField(controller: _name, label: 'Nama Venue', hint: 'Contoh: Lapangan Futsal Maju',
            prefixIcon: Icons.sports_soccer_outlined,
            validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: _type,
            decoration: InputDecoration(labelText: 'Jenis Olahraga', prefixIcon: const Icon(Icons.sports),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: sportTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v ?? _type)),
          const SizedBox(height: 16),
          CustomTextField(controller: _desc, label: 'Deskripsi', hint: 'Jelaskan venue Anda...',
            maxLines: 3, prefixIcon: Icons.description_outlined),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              Icon(Icons.location_on, color: _lat != null ? AppTheme.primaryColor : AppTheme.textSecondary),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Lokasi Venue', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(_lat != null ? '${_lat!.toStringAsFixed(5)}, ${_lon!.toStringAsFixed(5)}' : 'Belum ada lokasi',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))])),
              ElevatedButton(onPressed: _gpsLoading ? null : _getLocation,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: _gpsLoading ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('GPS', style: TextStyle(fontSize: 12))),
            ])),
          const SizedBox(height: 32),
          LoadingButton(isLoading: _loading, onPressed: _submit, label: 'Simpan Venue'),
          const SizedBox(height: 40),
        ]))));
  }
}
