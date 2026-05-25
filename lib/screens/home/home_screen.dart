import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/venue_provider.dart';
import '../../core/theme.dart';
import '../../widgets/venue_card.dart';
import '../../widgets/sport_filter_chip.dart';
import '../../models/venue_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  int _currentNavIndex = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(venueFilterProvider.notifier).update(
          (state) => state.copyWith(searchQuery: query.isEmpty ? null : query),
        );
  }

  void _onSportFilter(String? sport) {
    ref.read(venueFilterProvider.notifier).update(
          (state) => state.copyWith(
            sportType: sport,
            clearSport: sport == null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final venuesAsync = ref.watch(venueListProvider);
    final filter = ref.watch(venueFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            profileAsync.when(
                              data: (profile) => Text(
                                'Halo, ${profile?.name.split(' ').first ?? "Sobat"} 👋',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              loading: () => const Text('Halo! 👋'),
                              error: (_, __) => const Text('Halo! 👋'),
                            ),
                            const Text(
                              'Temukan venue olahraga terdekat',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.1),
                            child: profileAsync.when(
                              data: (p) => Text(
                                p?.name.isNotEmpty == true
                                    ? p!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              loading: () => const Icon(Icons.person,
                                  color: AppTheme.primaryColor),
                              error: (_, __) => const Icon(Icons.person,
                                  color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Cari venue olahraga...',
                        prefixIcon: const Icon(Icons.search,
                            color: AppTheme.textSecondary),
                        suffixIcon: filter.searchQuery != null
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearch('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sport type filter
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SportFilterChip(
                        label: 'Semua',
                        isSelected: filter.sportType == null,
                        onTap: () => _onSportFilter(null),
                      ),
                      ...sportTypes.map((sport) => SportFilterChip(
                            label: sport,
                            isSelected: filter.sportType == sport,
                            onTap: () => _onSportFilter(sport),
                          )),
                    ],
                  ),
                ),
              ),
            ),

            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      filter.sportType != null
                          ? filter.sportType!
                          : 'Venue Terdekat',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    venuesAsync.when(
                      data: (list) => Text(
                        '${list.length} venue',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),

            // Venue list
            venuesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: 12),
                      Text('Gagal memuat: $err'),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(venueListProvider),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (venues) {
                if (venues.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🏟️',
                              style: TextStyle(fontSize: 60)),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada venue tersedia',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Coba ubah filter atau tambahkan venue',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VenueCard(
                          venue: venues[index],
                          onTap: () =>
                              context.push('/venue/${venues[index].id}'),
                        ),
                      ),
                      childCount: venues.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      // FAB untuk owner
      floatingActionButton: profileAsync.when(
        data: (profile) {
          if (profile?.isOwner == true) {
            return FloatingActionButton.extended(
              onPressed: () => context.push('/venue/add'),
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Venue',
                  style: TextStyle(color: Colors.white)),
            );
          }
          return null;
        },
        loading: () => null,
        error: (_, __) => null,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          switch (index) {
            case 1:
              profileAsync.when(
                data: (p) => p?.isOwner == true
                    ? context.push('/owner/dashboard')
                    : null,
                loading: () => null,
                error: (_, __) => null,
              );
              break;
            case 2:
              context.push('/profile');
              break;
          }
        },
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda'),
          BottomNavigationBarItem(
            icon: profileAsync.when(
              data: (p) => p?.isOwner == true
                  ? const Icon(Icons.dashboard_outlined)
                  : const Icon(Icons.bookmark_outline),
              loading: () => const Icon(Icons.dashboard_outlined),
              error: (_, __) => const Icon(Icons.dashboard_outlined),
            ),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }
}
