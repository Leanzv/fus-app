import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/venue_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../core/theme.dart';
import '../../widgets/rating_badge.dart';

class VenueDetailScreen extends ConsumerWidget {
  final String venueId;
  const VenueDetailScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueAsync = ref.watch(venueDetailProvider(venueId));
    final reviewsAsync = ref.watch(venueReviewsProvider(venueId));
    final profileAsync = ref.watch(currentProfileProvider);
    final locationService = LocationService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: venueAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (venue) {
          if (venue == null) {
            return const Center(child: Text('Venue tidak ditemukan'));
          }
          return CustomScrollView(
            slivers: [
              // App bar dengan foto venue
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.white,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: venue.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: venue.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, __, ___) =>
                              _VenuePlaceholder(type: venue.type),
                        )
                      : _VenuePlaceholder(type: venue.type),
                ),
              ),

              // Info venue
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              venue.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (venue.averageRating != null)
                            RatingBadge(rating: venue.averageRating!),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              venue.type,
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.star,
                              color: AppTheme.starColor, size: 16),
                          Text(
                            ' ${venue.averageRating?.toStringAsFixed(1) ?? "0.0"}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(' (${venue.reviewCount ?? 0} review)',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                          const Spacer(),
                          if (venue.distanceKm != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    color: AppTheme.secondaryColor, size: 16),
                                Text(
                                  ' ${locationService.formatDistance(venue.distanceKm)}',
                                  style: const TextStyle(
                                      color: AppTheme.secondaryColor,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (venue.description.isNotEmpty) ...[
                        const Text(
                          'Deskripsi',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          venue.description,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/venue/$venueId/booking'),
                          icon: const Icon(Icons.calendar_today_outlined,
                              size: 18),
                          label: const Text('Booking'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/venue/$venueId/review'),
                          icon: const Icon(Icons.rate_review_outlined,
                              size: 18, color: Colors.white),
                          label: const Text('Review'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Reviews header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ulasan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      reviewsAsync.when(
                        data: (reviews) => Text(
                          '${reviews.length} ulasan',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),

              // Reviews list (realtime)
              reviewsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Gagal memuat review: $e')),
                ),
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Belum ada ulasan. Jadilah yang pertama!',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final review = reviews[index];
                          final userId =
                              ref.read(authStateProvider).asData?.value.session?.user.id;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        child: Text(
                                          review.userName?.isNotEmpty == true
                                              ? review.userName![0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review.userName ?? 'Pengguna',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13),
                                            ),
                                            Text(
                                              review.createdAt != null
                                                  ? timeago.format(
                                                      review.createdAt!,
                                                      locale: 'id')
                                                  : '',
                                              style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      RatingBarIndicator(
                                        rating: review.rating,
                                        itemCount: 5,
                                        itemSize: 14,
                                        itemBuilder: (_, __) => const Icon(
                                            Icons.star,
                                            color: AppTheme.starColor),
                                      ),
                                      if (userId == review.userId)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 18,
                                              color: AppTheme.errorColor),
                                          onPressed: () async {
                                            await ref
                                                .read(reviewRepositoryProvider)
                                                .deleteReview(review.id);
                                          },
                                        ),
                                    ],
                                  ),
                                  if (review.comment.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      review.comment,
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 13,
                                          height: 1.4),
                                    ),
                                  ],
                                  if (review.imageUrl != null) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: review.imageUrl!,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: reviews.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

class _VenuePlaceholder extends StatelessWidget {
  final String type;
  const _VenuePlaceholder({required this.type});

  String get _emoji {
    switch (type.toLowerCase()) {
      case 'futsal':
        return '⚽';
      case 'badminton':
        return '🏸';
      case 'basket':
        return '🏀';
      case 'renang':
        return '🏊';
      case 'tenis':
        return '🎾';
      case 'voli':
        return '🏐';
      case 'gym / fitness':
        return '🏋️';
      default:
        return '🏟️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Center(
        child: Text(_emoji, style: const TextStyle(fontSize: 72)),
      ),
    );
  }
}
