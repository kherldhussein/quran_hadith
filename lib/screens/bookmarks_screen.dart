import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';
import 'package:quran_hadith/screens/qPageView.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:animations/animations.dart';

/// Advanced bookmarks screen with categories, search, and organization
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Bookmark> _bookmarks = [];
  List<Bookmark> _filteredBookmarks = [];
  Set<String> _categories = {};
  String? _selectedCategory;
  String _searchQuery = '';
  String _sortBy = 'date'; // date, surah, name
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);

    try {
      _bookmarks = database.getAllBookmarks();
      _categories = _bookmarks
          .where((b) => b.category != null)
          .map((b) => b.category!)
          .toSet();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }

    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    var filtered = List<Bookmark>.from(_bookmarks);

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((b) => b.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        return b.title.toLowerCase().contains(query) ||
            (b.notes?.toLowerCase().contains(query) ?? false) ||
            b.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'date':
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'surah':
        filtered.sort((a, b) {
          final surahCompare = a.surahNumber.compareTo(b.surahNumber);
          if (surahCompare != 0) return surahCompare;
          return (a.ayahNumber ?? 0).compareTo(b.ayahNumber ?? 0);
        });
        break;
      case 'name':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    setState(() => _filteredBookmarks = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor,
      body: Column(
        children: [
          // Header with search and filters
          _buildHeader(theme),

          // Category chips
          if (_categories.isNotEmpty) _buildCategoryChips(theme),

          // Bookmarks list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBookmarks.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildBookmarksList(theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBookmarkDialog(context),
        icon: const FaIcon(FontAwesomeIcons.plus),
        label: const Text('Add Bookmark'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.bookmark, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Bookmarks',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${_filteredBookmarks.length} items',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Search bar
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search bookmarks...',
                    prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Sort dropdown
              PopupMenuButton<String>(
                icon: const FaIcon(FontAwesomeIcons.arrowDownWideShort, size: 18),
                tooltip: 'Sort by',
                onSelected: (value) {
                  setState(() => _sortBy = value);
                  _applyFilters();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'date',
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.clock,
                          size: 16,
                          color: _sortBy == 'date' ? theme.colorScheme.primary : null,
                        ),
                        const SizedBox(width: 8),
                        Text('By Date'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'surah',
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.bookQuran,
                          size: 16,
                          color: _sortBy == 'surah' ? theme.colorScheme.primary : null,
                        ),
                        const SizedBox(width: 8),
                        Text('By Surah'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.font,
                          size: 16,
                          color: _sortBy == 'name' ? theme.colorScheme.primary : null,
                        ),
                        const SizedBox(width: 8),
                        Text('By Name'),
                      ],
                    ),
                  ),
                ],
              ),

              // View options
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 18),
                onPressed: () => _showOptionsMenu(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                setState(() => _selectedCategory = null);
                _applyFilters();
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),

          // Category chips
          ..._categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = selected ? category : null);
                    _applyFilters();
                  },
                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = _filteredBookmarks[index];
        return OpenContainer(
          closedElevation: 0,
          openElevation: 0,
          closedColor: Colors.transparent,
          openColor: Colors.transparent,
          closedBuilder: (context, action) => _buildBookmarkCard(bookmark, theme),
          openBuilder: (context, action) => _buildBookmarkDetails(bookmark, theme),
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }

  Widget _buildBookmarkCard(Bookmark bookmark, ThemeData theme) {
    final color = bookmark.color != null
        ? Color(int.parse(bookmark.color!.replaceFirst('#', '0xFF')))
        : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Color indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookmark.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Surah ${bookmark.surahNumber}${bookmark.ayahNumber != null ? ', Ayah ${bookmark.ayahNumber}' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton(
                  icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 16),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'navigate',
                      child: Row(
                        children: const [
                          FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 16),
                          SizedBox(width: 8),
                          Text('Go to Ayah'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          FaIcon(FontAwesomeIcons.trash, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleBookmarkAction(bookmark, value.toString()),
                ),
              ],
            ),

            // Notes preview
            if (bookmark.notes != null && bookmark.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                bookmark.notes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Tags and category
            if (bookmark.tags.isNotEmpty || bookmark.category != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (bookmark.category != null)
                    Chip(
                      label: Text(bookmark.category!),
                      avatar: const FaIcon(FontAwesomeIcons.folder, size: 12),
                      backgroundColor: color.withOpacity(0.1),
                      labelStyle: TextStyle(fontSize: 12, color: color),
                    ),
                  ...bookmark.tags.map((tag) => Chip(
                        label: Text(tag),
                        avatar: const FaIcon(FontAwesomeIcons.tag, size: 12),
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        labelStyle: const TextStyle(fontSize: 12),
                      )),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkDetails(Bookmark bookmark, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bookmark.title),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.penToSquare),
            onPressed: () => _showEditBookmarkDialog(context, bookmark),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
            onPressed: () => _deleteBookmark(bookmark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailSection('Location', [
              Text('Surah ${bookmark.surahNumber}'),
              if (bookmark.ayahNumber != null) Text('Ayah ${bookmark.ayahNumber}'),
            ]),
            if (bookmark.notes != null && bookmark.notes!.isNotEmpty)
              _buildDetailSection('Notes', [
                Text(bookmark.notes!),
              ]),
            if (bookmark.category != null)
              _buildDetailSection('Category', [
                Chip(label: Text(bookmark.category!)),
              ]),
            if (bookmark.tags.isNotEmpty)
              _buildDetailSection('Tags', [
                Wrap(
                  spacing: 8,
                  children: bookmark.tags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
              ]),
            _buildDetailSection('Created', [
              Text(_formatDate(bookmark.createdAt)),
            ]),
            _buildDetailSection('Last Updated', [
              Text(_formatDate(bookmark.updatedAt)),
            ]),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAyah(bookmark),
              icon: const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare),
              label: const Text('Go to Ayah'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.bookmark,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding bookmarks to remember important verses',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleBookmarkAction(Bookmark bookmark, String action) {
    switch (action) {
      case 'navigate':
        _navigateToAyah(bookmark);
        break;
      case 'edit':
        _showEditBookmarkDialog(context, bookmark);
        break;
      case 'delete':
        _deleteBookmark(bookmark);
        break;
    }
  }

  Future<void> _navigateToAyah(Bookmark bookmark) async {
    try {
      final data = await QuranAPI().getSuratAudio();
      final surah = data.surahs!.firstWhere((s) => s.number == bookmark.surahNumber);

      Get.to(() => QPageView(
            suratName: surah.name,
            suratNo: bookmark.surahNumber,
            ayahList: surah.ayahs,
            englishMeaning: surah.englishNameTranslation,
            suratEnglishName: surah.englishName,
          ));
    } catch (e) {
      Get.snackbar('Error', 'Failed to load Surah: $e');
    }
  }

  void _showAddBookmarkDialog(BuildContext context) {
    // Implementation for add bookmark dialog
    Get.snackbar('Info', 'Add bookmark from Ayah page');
  }

  void _showEditBookmarkDialog(BuildContext context, Bookmark bookmark) {
    // Implementation for edit bookmark dialog
    // Similar to add but pre-filled with bookmark data
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Bookmark?'),
        content: Text('Are you sure you want to delete "${bookmark.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await database.removeBookmark(bookmark.id);
      await _loadBookmarks();
      Get.snackbar('Success', 'Bookmark deleted');
    }
  }

  void _showOptionsMenu(BuildContext context) {
    // Show additional options
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
