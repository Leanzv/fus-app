import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/venue_model.dart';
import '../services/location_service.dart';
import '../core/theme.dart';

class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onTap;
  final bool showOwnerActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VenueCard({
    super.key,
    required this.venue,
    required this.onTap,
    this.showOwnerActions = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final locationService = LocationService();

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue image
            Stack(
              children: [
                SizedBox(
                  height: 160,
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
                // Sport type badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
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
                // Rating badge
                if (venue.averageRating != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: AppTheme.starColor, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            venue.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Owner actions overlay
                if (showOwnerActions)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (onEdit != null)
                          _ActionIconButton(
                            icon: Icons.edit_outlined,
                            onTap: onEdit!,
                            color: AppTheme.secondaryColor,
                          ),
                        const SizedBox(width: 6),
                        if (onDelete != null)
                          _ActionIconButton(
                            icon: Icons.delete_outline,
                            onTap: onDelete!,
                            color: AppTheme.errorColor,
                          ),
                      ],
                    ),
                  ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppTheme.starColor, size: 14),
                      Text(
                        ' ${venue.averageRating?.toStringAsFixed(1) ?? "Belum ada rating"}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                      ),
                      Text(
                        ' · ${venue.reviewCount ?? 0} ulasan',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      if (venue.distanceKm != null)
                        Row(
                          children: [
                            const Icon(Icons.near_me,
                                color: AppTheme.secondaryColor, size: 14),
                            Text(
                              ' ${locationService.formatDistance(venue.distanceKm)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (venue.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      venue.description,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _placeholder => Container(
        color: AppTheme.primaryColor.withOpacity(0.08),
        child: Center(
          child: Text(
            _sportEmoji,
            style: const TextStyle(fontSize: 52),
          ),
        ),
      );

  String get _sportEmoji {
    switch (venue.type.toLowerCase()) {
      case 'futsal': return '⚽';
      case 'badminton': return '🏸';
      case 'basket': return '🏀';
      case 'renang': return '🏊';
      case 'tenis': return '🎾';
      case 'voli': return '🏐';
      case 'gym / fitness': return '🏋️';
      default: return '🏟️';
    }
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
            )
          ],
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
