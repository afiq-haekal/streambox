import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/content_model.dart';
import '../app_theme.dart';

/// Compact content card used in horizontal lists and grids.
/// Shows cover image, title, platform badge, and optional rating.
class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const ContentCard({
    super.key,
    required this.item,
    this.onTap,
    this.width = 130,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with platform badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: item.cover ?? '',
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.movie_outlined, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                // Platform badge (top-left)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _platformColor(item.platform),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _platformLabel(item.platform),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Rating badge (top-right)
                if (item.rating != null && item.rating!.isNotEmpty)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            item.rating!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Genre subtitle
            if (item.genre != null && item.genre!.isNotEmpty)
              Text(
                item.genre!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Color _platformColor(String platform) {
    switch (platform) {
      case 'dramabox': return const Color(0xFFE91E63);
      case 'reelshort': return const Color(0xFFFF5722);
      case 'shortmax': return const Color(0xFF9C27B0);
      case 'netshort': return const Color(0xFF2196F3);
      case 'melolo': return const Color(0xFF4CAF50);
      case 'flickreels': return const Color(0xFFFF9800);
      case 'freereels': return const Color(0xFF00BCD4);
      case 'anime': return const Color(0xFFE040FB);
      case 'komik': return const Color(0xFF76FF03).withOpacity(0.85);
      case 'moviebox': return const Color(0xFFFFD600);
      default: return AppTheme.primary;
    }
  }

  static String _platformLabel(String platform) {
    switch (platform) {
      case 'dramabox': return 'DramaBox';
      case 'reelshort': return 'ReelShort';
      case 'shortmax': return 'ShortMax';
      case 'netshort': return 'NetShort';
      case 'melolo': return 'Melolo';
      case 'flickreels': return 'FlickReels';
      case 'freereels': return 'FreeReels';
      case 'anime': return 'Anime';
      case 'komik': return 'Komik';
      case 'moviebox': return 'MovieBox';
      default: return platform;
    }
  }
}
