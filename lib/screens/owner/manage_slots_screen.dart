import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/venue_slot_provider.dart';
import '../../repositories/venue_slot_repository.dart';
import '../../models/venue_slot_model.dart';
import '../../core/theme.dart';

class ManageSlotsScreen extends ConsumerStatefulWidget {
  final String venueId;
  final String venueName;

  const ManageSlotsScreen({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  @override
  ConsumerState<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends ConsumerState<ManageSlotsScreen> {
  final _repo = VenueSlotRepository();
  int _selectedDay = 1; // Default Senin

  final List<String> _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  void _showAddSlotDialog() {
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 0);
    final priceCtrl = TextEditingController();
    int selectedDay = _selectedDay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Slot Baru',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),

              // Pilih hari
              const Text('Hari',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  return ChoiceChip(
                    label: Text(_days[i]),
                    selected: selectedDay == day,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: selectedDay == day
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) =>
                        setModalState(() => selectedDay = day),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Jam mulai & selesai
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jam Mulai',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: startTime,
                              builder: (_, child) => MediaQuery(
                                data: MediaQuery.of(ctx).copyWith(
                                    alwaysUse24HourFormat: true),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setModalState(() => startTime = picked);
                            }
                          },
                          child: _TimeBox(
                            time: _formatTime(startTime),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 24, left: 12, right: 12),
                    child: Text('–',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jam Selesai',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: endTime,
                              builder: (_, child) => MediaQuery(
                                data: MediaQuery.of(ctx).copyWith(
                                    alwaysUse24HourFormat: true),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setModalState(() => endTime = picked);
                            }
                          },
                          child: _TimeBox(time: _formatTime(endTime)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Harga
              const Text('Harga per Slot',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0 = Gratis',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Validasi waktu
                    final startMinutes =
                        startTime.hour * 60 + startTime.minute;
                    final endMinutes = endTime.hour * 60 + endTime.minute;
                    if (endMinutes <= startMinutes) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Jam selesai harus lebih dari jam mulai'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      return;
                    }

                    final price = int.tryParse(
                            priceCtrl.text.replaceAll('.', '')) ??
                        0;

                    final slot = VenueSlotModel(
                      id: '',
                      venueId: widget.venueId,
                      dayOfWeek: selectedDay,
                      startTime: _formatTime(startTime),
                      endTime: _formatTime(endTime),
                      price: price,
                    );

                    try {
                      await _repo.addSlot(slot);
                      ref.invalidate(venueSlotsProvider(widget.venueId));
                      if (mounted) Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Slot berhasil ditambahkan ✅'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan Slot'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(venueSlotsProvider(widget.venueId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kelola Slot Booking'),
            Text(
              widget.venueName,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSlotDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Slot',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Filter hari
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final isSelected = _selectedDay == day;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _days[i],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Slot list
          Expanded(
            child: slotsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (slots) {
                final filtered = slots
                    .where((s) => s.dayOfWeek == _selectedDay)
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🕐',
                            style: TextStyle(fontSize: 52)),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada slot untuk ${_days[_selectedDay - 1]}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ketuk tombol + untuk menambahkan',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final slot = filtered[i];
                    return _SlotTile(
                      slot: slot,
                      onToggle: (val) async {
                        await _repo.toggleSlot(slot.id, val);
                        ref.invalidate(
                            venueSlotsProvider(widget.venueId));
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Hapus Slot'),
                            content: Text(
                                'Hapus slot ${slot.timeLabel}?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal')),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.errorColor),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _repo.deleteSlot(slot.id);
                          ref.invalidate(
                              venueSlotsProvider(widget.venueId));
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final VenueSlotModel slot;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _SlotTile({
    required this.slot,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: slot.isActive
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.access_time_rounded,
                color: slot.isActive
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.timeLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: slot.isActive
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slot.priceLabel,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: slot.isActive,
              onChanged: onToggle,
              activeColor: AppTheme.primaryColor,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.errorColor, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String time;
  const _TimeBox({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Icon(Icons.access_time,
              size: 18, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}
