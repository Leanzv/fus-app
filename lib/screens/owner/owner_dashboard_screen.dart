import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/venue_provider.dart';
import '../../providers/booking_provider.dart';
import '../../repositories/venue_repository.dart';
import '../../models/venue_model.dart';
import '../../core/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard Owner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/venue/add'),
            tooltip: 'Tambah Venue',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan'));
          }
          if (!profile.isOwner) {
            return const Center(
                child: Text('Halaman ini hanya untuk Owner'));
          }

          final ownerVenuesAsync =
              ref.watch(ownerVenuesProvider(profile.id));

          return ownerVenuesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (venues) {
              final venueIds = venues.map((v) => v.id).toList();
              final bookingsAsync =
                  ref.watch(ownerBookingsProvider(venueIds));
              final pendingCount = bookingsAsync.asData?.value
                      .where((b) => b.status == 'pending')
                      .length ??
                  0;

              return CustomScrollView(
                slivers: [
                  // Stats
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          _StatCard(
                            icon: '🏟️',
                            label: 'Total Venue',
                            value: '${venues.length}',
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: '📅',
                            label: 'Booking Pending',
                            value: '$pendingCount',
                            color: AppTheme.warningColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Booking shortcut banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: GestureDetector(
                        onTap: () => context.push('/owner/bookings'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.secondaryColor,
                                Color(0xFF0066CC)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Text('📥',
                                  style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lihat Semua Booking',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15),
                                    ),
                                    Text(
                                      pendingCount > 0
                                          ? '$pendingCount booking menunggu konfirmasi'
                                          : 'Tidak ada booking pending',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Venue list header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Venue Saya',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                context.push('/venue/add'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Venue list with slot management
                  venues.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Text('🏟️',
                                    style: TextStyle(fontSize: 60)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum ada venue',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      context.push('/venue/add'),
                                  icon: const Icon(Icons.add,
                                      color: Colors.white),
                                  label: const Text(
                                      'Tambah Venue Pertama'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final venue = venues[index];
                                return _OwnerVenueCard(
                                  venue: venue,
                                  onView: () => context
                                      .push('/venue/${venue.id}'),
                                  onEdit: () => context.push(
                                      '/venue/${venue.id}/edit'),
                                  onManageSlots: () => context.push(
                                    '/venue/${venue.id}/slots',
                                    extra: venue.name,
                                  ),
                                  onDelete: () async {
                                    final confirm =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title:
                                            const Text('Hapus Venue'),
                                        content: Text(
                                            'Yakin hapus "${venue.name}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(
                                                    context, false),
                                            child:
                                                const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(
                                                    context, true),
                                            style: ElevatedButton
                                                .styleFrom(
                                                    backgroundColor:
                                                        AppTheme
                                                            .errorColor),
                                            child:
                                                const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await VenueRepository()
                                          .deleteVenue(venue.id);
                                      ref.invalidate(
                                          ownerVenuesProvider);
                                      ref.invalidate(venueListProvider);
                                    }
                                  },
                                );
                              },
                              childCount: venues.length,
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: 80)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/venue/add'),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Venue',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ─── Owner Venue Card ─────────────────────────────────────────

class _OwnerVenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onManageSlots;
  final VoidCallback onDelete;

  const _OwnerVenueCard({
    required this.venue,
    required this.onView,
    required this.onEdit,
    required this.onManageSlots,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar venue
          Stack(
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: venue.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: venue.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder,
                        errorWidget: (_, __, ___) => _placeholder,
                      )
                    : _placeholder,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    venue.type,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          // Info + tombol
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        venue.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (venue.averageRating != null)
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppTheme.starColor, size: 14),
                          Text(
                            ' ${venue.averageRating!.toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${venue.reviewCount ?? 0} ulasan',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    // Kelola Slot — tombol utama
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onManageSlots,
                        icon: const Icon(Icons.access_time,
                            size: 16, color: Colors.white),
                        label: const Text('Slot Jam'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Lihat
                    _IconBtn(
                        icon: Icons.visibility_outlined,
                        color: AppTheme.secondaryColor,
                        onTap: onView),
                    const SizedBox(width: 6),
                    // Edit
                    _IconBtn(
                        icon: Icons.edit_outlined,
                        color: AppTheme.warningColor,
                        onTap: onEdit),
                    const SizedBox(width: 6),
                    // Hapus
                    _IconBtn(
                        icon: Icons.delete_outline,
                        color: AppTheme.errorColor,
                        onTap: onDelete),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get _placeholder => Container(
        color: AppTheme.primaryColor.withOpacity(0.08),
        child: const Center(
            child: Text('🏟️', style: TextStyle(fontSize: 40))),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
