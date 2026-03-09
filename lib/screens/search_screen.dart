import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../app_router.dart';
import '../models/content_model.dart';
import '../providers/content_provider.dart';
import '../widgets/content_card.dart';

/// Cross-platform search screen.
/// Searches ALL 10 platforms simultaneously and shows unified results.
/// Features: debounced input, category filter chips, grid results.
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  ContentType? _filterType;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ContentProvider>().search(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ContentProvider>().search(query);
    });
  }

  List<ContentItem> _applyFilter(List<ContentItem> items) {
    if (_filterType == null) return items;
    return items.where((item) => item.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        toolbarHeight: 64,
      ),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          final filtered = _applyFilter(provider.searchResults);

          return Column(
            children: [
              // Filter chips
              _buildFilterChips(provider.searchResults),

              // Results area
              Expanded(
                child: provider.isSearching
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppTheme.primary),
                            SizedBox(height: 16),
                            Text(
                              'Searching across all platforms...',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : provider.searchQuery.isEmpty
                        ? _buildEmptyState()
                        : filtered.isEmpty
                            ? _buildNoResults()
                            : _buildResults(filtered),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search dramas, anime, komik, movies...',
          hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 18),
                  onPressed: () {
                    _controller.clear();
                    context.read<ContentProvider>().clearSearch();
                    setState(() => _filterType = null);
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<ContentItem> allResults) {
    if (allResults.isEmpty) return const SizedBox.shrink();

    // Count results per type
    final counts = <ContentType, int>{};
    for (final item in allResults) {
      counts[item.type] = (counts[item.type] ?? 0) + 1;
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'All (${allResults.length})',
            selected: _filterType == null,
            onTap: () => setState(() => _filterType = null),
          ),
          const SizedBox(width: 8),
          ...counts.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: '${_typeLabel(entry.key)} (${entry.value})',
              selected: _filterType == entry.key,
              onTap: () => setState(() {
                _filterType = _filterType == entry.key ? null : entry.key;
              }),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildResults(List<ContentItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.52,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ContentCard(
          item: item,
          width: double.infinity,
          height: 160,
          onTap: () {
            Navigator.pushNamed(
              context,
              Routes.detail,
              arguments: DetailArgs(item: item),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Search across all platforms',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'DramaBox, ReelShort, ShortMax, Anime,\nKomik, MovieBox & more',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No results for "${_controller.text}"',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different keyword',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _typeLabel(ContentType type) {
    switch (type) {
      case ContentType.drama: return 'Drama';
      case ContentType.anime: return 'Anime';
      case ContentType.komik: return 'Komik';
      case ContentType.movie: return 'Movie';
    }
  }
}

/// Filter chip for content type filtering
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
