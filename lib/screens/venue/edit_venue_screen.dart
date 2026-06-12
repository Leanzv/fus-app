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

class EditVenueScreen extends ConsumerStatefulWidget {
  final String venueId;
  const EditVenueScreen({super.key, required this.venueId});
  @override
  ConsumerState<EditVenueScreen> createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends ConsumerState<EditVenueScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _type = sportTypes.first;
  File? _newImg;
  bool _loading = false;
  VenueModel? _venue;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final v = await VenueRepository().getVenueById(widget.venueId);
    if (v != null && mounted) setState(() {
      _venue = v; _name.text = v.name; _desc.text = v.description; _type = v.type;
    });
  }

  @override
  void dispose() { _name.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? imgUrl = _venue?.imageUrl;
      if (_newImg != null) imgUrl = await StorageService().uploadVenueImage(_newImg!);
      await VenueRepository().updateVenue(widget.venueId, {
        'name': _name.text.trim(), 'type': _type, 'description': _desc.text.trim(),
        if (imgUrl != null) 'image_url': imgUrl,
      });
      ref.invalidate(venueListProvider);
      ref.invalidate(venueDetailProvider(widget.venueId));
      if (mounted) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Venue berhasil diperbarui ✅'), backgroundColor: AppTheme.primaryColor)); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.errorColor));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_venue == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Edit Venue')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: () async {
            final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
            if (p != null) setState(() => _newImg = File(p.path));
          }, child: Container(height: 180, decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: _newImg != null
                ? ClipRRect(borderRadius: BorderRadius.circular(14),
                    child: Image.file(_newImg!, fit: BoxFit.cover, width: double.infinity))
                : _venue!.imageUrl != null
                    ? Stack(fit: StackFit.expand, children: [
                        ClipRRect(borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(imageUrl: _venue!.imageUrl!, fit: BoxFit.cover)),
                        Positioned(bottom: 8, right: 8, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: const Row(children: [
                            Icon(Icons.edit, color: Colors.white, size: 14), SizedBox(width: 4),
                            Text('Ganti Foto', style: TextStyle(color: Colors.white, fontSize: 12))])))])
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 8), Text('Tambah Foto', style: TextStyle(color: AppTheme.textSecondary))]))),
          const SizedBox(height: 20),
          CustomTextField(controller: _name, label: 'Nama Venue', hint: 'Nama venue',
            prefixIcon: Icons.sports_soccer_outlined,
            validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: _type,
            decoration: InputDecoration(labelText: 'Jenis Olahraga', prefixIcon: const Icon(Icons.sports),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: sportTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v ?? _type)),
          const SizedBox(height: 16),
          CustomTextField(controller: _desc, label: 'Deskripsi', hint: 'Deskripsi venue...', maxLines: 3,
            prefixIcon: Icons.description_outlined),
          const SizedBox(height: 32),
          LoadingButton(isLoading: _loading, onPressed: _submit, label: 'Simpan Perubahan'),
          const SizedBox(height: 40),
        ]))));
  }
}
