import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../app_router.dart';
import 'content_card.dart';
import 'section_header.dart';
import 'shimmer_loading.dart';

/// A horizontal scrolling list of content cards with section header.
/// Used for "For You", "Trending", "Latest" sections on home screen.
class ContentHorizontalList extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<ContentItem> items;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final double cardWidth;
  final double cardHeight;

  const ContentHorizontalList({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.items,
    this.isLoading = false,
    this.onSeeAll,
    this.cardWidth = 130,
    this.cardHeight = 190,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          icon: icon,
          onSeeAll: onSeeAll,
        ),
        SizedBox(
          height: cardHeight + 50, // card + title + genre text
          child: isLoading
              ? _buildShimmer()
              : items.isEmpty
                  ? const Center(
                      child: Text('No content available',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < items.length - 1 ? 12 : 0,
                          ),
                          child: ContentCard(
                            item: item,
                            width: cardWidth,
                            height: cardHeight,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.detail,
                                arguments: DetailArgs(item: item),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (_, index) => Padding(
        padding: EdgeInsets.only(right: index < 4 ? 12 : 0),
        child: ShimmerCard(width: cardWidth, height: cardHeight),
      ),
    );
  }
}
