import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/hadithAPI.dart';
import 'package:quran_hadith/layout/adaptive.dart';
// import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import 'package:quran_hadith/widgets/modern_search_dialog.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quran_hadith/widgets/hadith_book_content.dart';
import 'package:get/get.dart';
import 'package:quran_hadith/screens/favorite.dart' as fav_screen;

class HPage extends StatefulWidget {
  const HPage({super.key});

  @override
  _HPageState createState() => _HPageState();
}

class _HPageState extends State<HPage> with AutomaticKeepAliveClientMixin {
  String? _selectedBook;
  // int _currentPage = 1; // handled inside HadithBookContent
  bool _showArabic = true;
  List<HadithBook> _allBooks = [];
  // Hadith list state (infinite scroll)
  final TextEditingController _searchCtrl = TextEditingController();
  // moved to reusable widget
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Auto-load hadith books and select the first one to show data by default
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final hadithAPI = Provider.of<HadithAPI>(context, listen: false);
        final result = await hadithAPI.getHadithBooks();
        if (!mounted) return;
        if (result is HadithFetchSuccess) {
          setState(() {
            _allBooks = result.books;
            _selectedBook = _selectedBook ??
                (result.books.isNotEmpty ? result.books.first.slug : null);
          });
        }
      } catch (e) {
        // Non-fatal: leave UI in selectable state
        debugPrint('Hadith init load error: $e');
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Favorite actions are handled within HadithBookContent

  void _showSearchDialog() async {
    if (_allBooks.isEmpty) {
      // Fetch books if not already loaded
      final hadithAPI = Provider.of<HadithAPI>(context, listen: false);
      final result = await hadithAPI.getHadithBooks();

      if (result is HadithFetchSuccess) {
        _allBooks = result.books;
      } else if (result is HadithFetchError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        return;
      }
    }

    if (_allBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hadith books available'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final searchItems = _allBooks.asMap().entries.map((entry) {
      final index = entry.key;
      final book = entry.value;
      return SearchableItem(
        title: book.name,
        subtitle: '${book.total ?? 0} hadiths',
        description: book.slug,
        badge: '${index + 1}',
        icon: FontAwesomeIcons.bookQuran,
        iconColor: Theme.of(context).colorScheme.primary,
        data: book,
      );
    }).toList();

    await showModernSearchDialog(
      context: context,
      items: searchItems,
      title: 'Search Hadith Books',
      hintText: 'Search by book name...',
      onItemSelected: (item) {
        final book = item.data as HadithBook;
        setState(() {
          _selectedBook = book.slug;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // final size = MediaQuery.of(context).size;
    final isDesktop = isDisplayDesktop(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Content Area
            Expanded(
              flex: 3,
              child: _buildMainContent(theme, isDesktop),
            ),

            // Sidebar
            if (isDesktop)
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: theme.appBarTheme.backgroundColor,
                  border: Border(
                    left: BorderSide(
                      color: theme.dividerColor.withOpacity(0.1),
                    ),
                  ),
                ),
                child: _buildSidebar(theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(theme),

          // Content
          Expanded(
            child: Row(
              children: [
                // Books List
                Container(
                  width: 280,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.onSurface.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildBooksList(theme),
                ),

                // Hadiths List
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _selectedBook == null
                        ? _buildEmptyState()
                        : HadithBookContent(
                            bookSlug: _selectedBook!,
                            showArabic: _showArabic,
                            query: _query,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.bookQuran,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Hadith Collection',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _selectedBook == null
                    ? 'Select a book to browse hadiths'
                    : _selectedBook!,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Book search button
          InkWell(
            onTap: _showSearchDialog,
            child: _pillButton(
              theme: theme,
              width: 260,
              icon: FontAwesomeIcons.magnifyingGlass,
              label: 'Search books...',
            ),
          ),

          const SizedBox(width: 16),

          // In-book search
          Expanded(
            child: _searchField(theme),
          ),

          const SizedBox(width: 16),

          // Arabic Toggle
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.language,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _showArabic,
                  onChanged: (value) {
                    setState(() {
                      _showArabic = value;
                    });
                  },
                  activeThumbColor: theme.colorScheme.primary,
                ),
                Text(
                  'Arabic',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required ThemeData theme,
    required double width,
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: width,
      height: 45,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(ThemeData theme) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.filter,
              size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search in current book (Arabic or translation)...',
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(FontAwesomeIcons.xmark, size: 14),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBooksList(ThemeData theme) {
    final hadithAPI = Provider.of<HadithAPI>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Hadith Books',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<HadithFetchResult>(
            future: hadithAPI.getHadithBooks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildBooksLoadingState(theme);
              }

              if (!snapshot.hasData) {
                return _buildErrorState('No hadith books available');
              }

              final result = snapshot.data!;

              if (result is HadithFetchSuccess) {
                final books = result.books;
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    final isSelected = _selectedBook == book.slug;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          book.name,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${book.total ?? 0} hadiths',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        trailing: Icon(
                          FontAwesomeIcons.chevronRight,
                          size: 14,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedBook = book.slug;
                          });
                        },
                      ),
                    );
                  },
                );
              } else if (result is HadithFetchError) {
                return _buildErrorState(result.message);
              }

              return _buildErrorState('Unexpected error occurred');
            },
          ),
        ),
      ],
    );
  }

  // Pagination controls replaced by infinite scroll & Load more button

  Widget _buildSidebar(ThemeData theme) {
    final user = SpUtil.getUser();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Greeting
          Text(
            'Salam,',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            user,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),

          // Quick Stats
          _buildStatCard(
            title: 'Total Books',
            value: '9',
            icon: FontAwesomeIcons.bookQuran,
            color: theme.colorScheme.primary,
            theme: theme,
          ),
          const SizedBox(height: 16),

          _buildStatCard(
            title: 'Favorites',
            value: '-',
            icon: FontAwesomeIcons.heart,
            color: theme.colorScheme.secondary,
            theme: theme,
            onTap: () {
              // Open the Favorites screen
              Get.to(() => const fav_screen.Favorite());
            },
          ),

          const Spacer(),

          // Hadith of the Day
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FontAwesomeIcons.solidStar,
                        color: theme.colorScheme.onPrimary, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'HADITH OF THE DAY',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withOpacity(0.95),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Messenger of Allāh ﷺ said: "You will see your Lord on the Day of Resurrection, just as you see the sun and the moon clearly."',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          highlightColor: theme.colorScheme.surface,
          child: Container(
            height: 60,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.bookQuran,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'Select a Hadith Book',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a book from the list to browse hadiths',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.exclamationTriangle,
              size: 64,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
