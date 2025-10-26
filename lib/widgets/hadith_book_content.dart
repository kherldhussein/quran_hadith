import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/favorite.dart';
import 'package:quran_hadith/controller/hadithAPI.dart';
import 'package:quran_hadith/widgets/social_share.dart' as share;
import 'package:get/get.dart';
import 'package:quran_hadith/screens/hadith_detail.dart';

// Reusable content widget to display hadiths within a given book
class HadithBookContent extends StatefulWidget {
  final String bookSlug;
  final bool showArabic;
  final String query; // in-book search filter

  const HadithBookContent({
    super.key,
    required this.bookSlug,
    required this.showArabic,
    this.query = '',
  });

  @override
  State<HadithBookContent> createState() => _HadithBookContentState();
}

class _HadithBookContentState extends State<HadithBookContent> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _initialLoading = false;
  bool _loadingMore = false;
  int _available = 0;
  List<HadithItem> _items = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollLoadMore);
    _reloadFromStart();
  }

  @override
  void didUpdateWidget(covariant HadithBookContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookSlug != widget.bookSlug) {
      // Book changed -> reload from page 1
      _reloadFromStart();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reloadFromStart() async {
    setState(() {
      _initialLoading = true;
      _loadingMore = false;
      _currentPage = 1;
      _items = [];
      _available = 0;
    });
    await _loadPage(_currentPage, append: true);
    if (mounted) {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _loadPage(int page, {bool append = true}) async {
    try {
      final api = Provider.of<HadithAPI>(context, listen: false);
      setState(() => _loadingMore = true);
      final res = await api.getHadiths(book: widget.bookSlug, page: page);
      if (!mounted) return;
      setState(() {
        _available = res.available;
        if (append) {
          _items.addAll(res.hadiths);
        } else {
          _items = res.hadiths;
        }
      });
    } catch (e) {
      debugPrint('HadithBookContent _loadPage error: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScrollLoadMore() {
    if (_loadingMore || _initialLoading) return;
    if (_items.length >= _available && _available > 0) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _currentPage += 1;
      _loadPage(_currentPage, append: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // In-book filter
    final filtered = widget.query.isEmpty
        ? _items
        : _items.where((h) {
            final a = (h.arab ?? '').toLowerCase();
            final t = (h.id ?? '').toLowerCase();
            final q = widget.query.toLowerCase();
            return a.contains(q) ||
                t.contains(q) ||
                (h.number ?? '').contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header + Meta
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Text(
                'Hadiths',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              if (_available > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Showing ${filtered.length} of $_available',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              if (_initialLoading)
                const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),

        // List
        Expanded(
          child: _initialLoading
              ? _buildLoadingState(theme)
              : filtered.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: filtered.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_loadingMore && index == filtered.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      theme.colorScheme.primary),
                                ),
                              ),
                            ),
                          );
                        }
                        return _HadithCard(
                          bookSlug: widget.bookSlug,
                          hadith: filtered[index],
                          showArabic: widget.showArabic,
                        );
                      },
                    ),
        ),

        if (_items.length < _available && !_initialLoading)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: OutlinedButton.icon(
              onPressed: _loadingMore
                  ? null
                  : () {
                      _currentPage += 1;
                      _loadPage(_currentPage, append: true);
                    },
              icon: const Icon(FontAwesomeIcons.chevronDown, size: 14),
              label: Text('Load more (${_items.length}/$_available)'),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Text(
        'No hadiths found',
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  final String bookSlug;
  final HadithItem hadith;
  final bool showArabic;

  const _HadithCard({
    required this.bookSlug,
    required this.hadith,
    required this.showArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hadithId = 'hadith_${bookSlug}_${hadith.number}';

    return Consumer<FavoriteManager>(
      builder: (context, favManager, child) {
        return FutureBuilder<List<String>>(
          future: favManager
              .getFavorites()
              .then((list) => list.map((f) => f.id).toList()),
          builder: (context, snapshot) {
            final isFavorite = snapshot.data?.contains(hadithId) ?? false;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.dividerColor.withOpacity(0.2),
                ),
              ),
              child: InkWell(
                onTap: () {
                  // Open hadith detail page
                  Get.to(() => HadithDetailPage(
                        bookSlug: bookSlug,
                        number: hadith.number ?? '-',
                        arabic: hadith.arab,
                        translation: hadith.id,
                      ));
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Hadith ${hadith.number ?? '-'}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isFavorite
                                  ? FontAwesomeIcons.solidHeart
                                  : FontAwesomeIcons.heart,
                              size: 18,
                              color: isFavorite
                                  ? Colors.red
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                            ),
                            onPressed: () async {
                              await Provider.of<FavoriteManager>(context,
                                      listen: false)
                                  .toggleFavorite(
                                id: hadithId,
                                name: 'Hadith - $bookSlug',
                                type: 'hadith',
                                metadata: {
                                  'book': bookSlug,
                                  'text': hadith.arab ?? '',
                                },
                              );
                              // Trigger refresh of favorite state
                              (context as Element).markNeedsBuild();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Arabic Text
                      if (showArabic && (hadith.arab ?? '').isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            hadith.arab!,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.8,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Translation (id field contains translation)
                      if ((hadith.id ?? '').isNotEmpty)
                        Text(
                          hadith.id!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: theme.colorScheme.onSurface.withOpacity(0.9),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _actionButton(
                            context: context,
                            icon: FontAwesomeIcons.copy,
                            label: 'Copy',
                            onPressed: () {
                              final text = hadith.arab ?? '';
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            },
                          ),
                          _actionButton(
                            context: context,
                            icon: FontAwesomeIcons.shareNodes,
                            label: 'Share',
                            onPressed: () {
                              final text = hadith.arab ?? '';
                              share.showShareDialog(
                                context: context,
                                text: text,
                              );
                            },
                          ),
                          _actionButton(
                            context: context,
                            icon: isFavorite
                                ? FontAwesomeIcons.solidBookmark
                                : FontAwesomeIcons.bookmark,
                            label: isFavorite ? 'Saved' : 'Save',
                            onPressed: () async {
                              await Provider.of<FavoriteManager>(context,
                                      listen: false)
                                  .toggleFavorite(
                                id: hadithId,
                                name: 'Hadith - $bookSlug',
                                type: 'hadith',
                                metadata: {
                                  'book': bookSlug,
                                  'text': hadith.arab ?? '',
                                },
                              );
                              (context as Element).markNeedsBuild();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return TextButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
