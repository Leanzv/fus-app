import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/venue_provider.dart';
import '../../providers/booking_provider.dart';
import '../../repositories/venue_repository.dart';
import '../../core/theme.dart';
import '../../widgets/venue_card.dart';

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
              child: Text('Halaman ini hanya untuk Owner'),
            );
          }

          final ownerVenuesAsync =
              ref.watch(ownerVenuesProvider(profile.id));

          return ownerVenuesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
                  // Stats cards
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

                  // Booking shortcut
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
                                  style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 14),
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            onPressed: () => context.push('/venue/add'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Venue list
                  venues.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                  label:
                                      const Text('Tambah Venue Pertama'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final venue = venues[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: VenueCard(
                                    venue: venue,
                                    showOwnerActions: true,
                                    onTap: () => context
                                        .push('/venue/${venue.id}'),
                                    onEdit: () => context
                                        .push('/venue/${venue.id}/edit'),
                                    onDelete: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Hapus Venue'),
                                          content: Text(
                                              'Yakin hapus "${venue.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context, false),
                                              child: const Text('Batal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context, true),
                                              style:
                                                  ElevatedButton.styleFrom(
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
                                  ),
                                );
                              },
                              childCount: venues.length,
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
        label:
            const Text('Tambah Venue', style: TextStyle(color: Colors.white)),
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
            Text(icon, style: const TextStyle(fontSize: 28)),
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
