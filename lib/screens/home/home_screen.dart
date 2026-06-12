import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/venue_provider.dart';
import '../../core/theme.dart';
import '../../widgets/venue_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/venue_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  int _navIndex = 0;

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final venuesAsync = ref.watch(venueListProvider);
    final filter = ref.watch(venueFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                profileAsync.when(
                  data: (p) => Text('Halo, ${p?.name.split(' ').first ?? "Sobat"} 👋',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                  loading: () => const Text('Halo! 👋'),
                  error: (_, __) => const Text('Halo! 👋')),
                const Text('Temukan venue olahraga terdekat',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ]),
              GestureDetector(onTap: () => context.push('/profile'),
                child: CircleAvatar(radius: 22,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: profileAsync.when(
                    data: (p) => Text(p?.name.isNotEmpty == true ? p!.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    loading: () => const Icon(Icons.person, color: AppTheme.primaryColor),
                    error: (_, __) => const Icon(Icons.person, color: AppTheme.primaryColor)))),
            ]),
            const SizedBox(height: 16),
            TextField(controller: _search,
              onChanged: (q) => ref.read(venueFilterProvider.notifier).update(
                (s) => s.copyWith(searchQuery: q.isEmpty ? null : q)),
              decoration: InputDecoration(hintText: 'Cari venue olahraga...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: filter.searchQuery != null ? IconButton(icon: const Icon(Icons.close),
                  onPressed: () { _search.clear();
                    ref.read(venueFilterProvider.notifier).update((s) => s.copyWith(clearSearch: true)); }) : null,
                filled: true, fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none))),
          ]))),
        SliverToBoxAdapter(child: Container(color: Colors.white, padding: const EdgeInsets.only(bottom: 12),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              SportFilterChip(label: 'Semua', isSelected: filter.sportType == null,
                onTap: () => ref.read(venueFilterProvider.notifier).update((s) => s.copyWith(clearSport: true))),
              ...sportTypes.map((t) => SportFilterChip(label: t, isSelected: filter.sportType == t,
                onTap: () => ref.read(venueFilterProvider.notifier).update((s) => s.copyWith(sportType: t)))),
            ])))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(filter.sportType ?? 'Venue Terdekat',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            venuesAsync.when(
              data: (l) => Text('${l.length} venue', style: const TextStyle(color: AppTheme.textSecondary)),
              loading: () => const SizedBox(), error: (_, __) => const SizedBox()),
          ]))),
        venuesAsync.when(
          loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverFillRemaining(child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12), Text('Gagal memuat: $e'),
              TextButton(onPressed: () => ref.invalidate(venueListProvider), child: const Text('Coba lagi'))]))),
          data: (venues) {
            if (venues.isEmpty) return const SliverFillRemaining(child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text('🏟️', style: TextStyle(fontSize: 60)), SizedBox(height: 16),
                Text('Belum ada venue tersedia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))])));
            return SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: VenueCard(venue: venues[i], onTap: () => context.push('/venue/${venues[i].id}'))),
                childCount: venues.length)));
          }),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ])),
      floatingActionButton: profileAsync.when(
        data: (p) => p?.isOwner == true ? FloatingActionButton.extended(
          onPressed: () => context.push('/venue/add'),
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Tambah Venue', style: TextStyle(color: Colors.white))) : null,
        loading: () => null, error: (_, __) => null),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 1) profileAsync.whenData((p) {
            if (p?.isOwner == true) context.push('/owner/dashboard');
          });
          if (i == 2) context.push('/profile');
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(profileAsync.asData?.value?.isOwner == true
              ? Icons.dashboard_outlined : Icons.bookmark_outline), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person), label: 'Profil'),
        ]),
    );
  }
}
