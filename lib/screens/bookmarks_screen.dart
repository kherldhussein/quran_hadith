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
  const BookmarksScreen({super.key});

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

    if (_selectedCategory != null) {
      filtered =
          filtered.where((b) => b.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        return b.title.toLowerCase().contains(query) ||
            (b.notes?.toLowerCase().contains(query) ?? false) ||
            b.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

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
          _buildHeader(theme),
          if (_categories.isNotEmpty) _buildCategoryChips(theme),
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
            color: theme.colorScheme.onSurface.withOpacity(0.05),
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
              FaIcon(FontAwesomeIcons.bookmark,
                  color: theme.colorScheme.primary),
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
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search bookmarks...',
                    prefixIcon:
                        const Icon(FontAwesomeIcons.magnifyingGlass, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon:
                    const FaIcon(FontAwesomeIcons.arrowDownWideShort, size: 18),
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
                          color: _sortBy == 'date'
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('By Date'),
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
                          color: _sortBy == 'surah'
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('By Surah'),
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
                          color: _sortBy == 'name'
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('By Name'),
                      ],
                    ),
                  ),
                ],
              ),
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
          ..._categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(
                        () => _selectedCategory = selected ? category : null);
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
          closedBuilder: (context, action) =>
              _buildBookmarkCard(bookmark, theme),
          openBuilder: (context, action) =>
              _buildBookmarkDetails(bookmark, theme),
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
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
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
                PopupMenuButton(
                  icon:
                      const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 16),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'navigate',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.arrowUpRightFromSquare,
                              size: 16),
                          SizedBox(width: 8),
                          Text('Go to Ayah'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.trash,
                              size: 16, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) =>
                      _handleBookmarkAction(bookmark, value.toString()),
                ),
              ],
            ),
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
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
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
            icon:
                FaIcon(FontAwesomeIcons.trash, color: theme.colorScheme.error),
            onPressed: () => _deleteBookmark(bookmark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailSection(theme, 'Location', [
              Text('Surah ${bookmark.surahNumber}'),
              if (bookmark.ayahNumber != null)
                Text('Ayah ${bookmark.ayahNumber}'),
            ]),
            if (bookmark.notes != null && bookmark.notes!.isNotEmpty)
              _buildDetailSection(theme, 'Notes', [
                Text(bookmark.notes!),
              ]),
            if (bookmark.category != null)
              _buildDetailSection(theme, 'Category', [
                Chip(label: Text(bookmark.category!)),
              ]),
            if (bookmark.tags.isNotEmpty)
              _buildDetailSection(theme, 'Tags', [
                Wrap(
                  spacing: 8,
                  children: bookmark.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
              ]),
            _buildDetailSection(theme, 'Created', [
              Text(_formatDate(bookmark.createdAt)),
            ]),
            _buildDetailSection(theme, 'Last Updated', [
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

  Widget _buildDetailSection(
      ThemeData theme, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
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
      final surah =
          data.surahs!.firstWhere((s) => s.number == bookmark.surahNumber);

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
    Get.snackbar('Info', 'Add bookmark from Ayah page');
  }

  void _showEditBookmarkDialog(BuildContext context, Bookmark bookmark) {
    final titleController = TextEditingController(text: bookmark.title);
    final notesController = TextEditingController(text: bookmark.notes);
    final categoryController = TextEditingController(text: bookmark.category);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Bookmark'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(FontAwesomeIcons.heading),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(FontAwesomeIcons.noteSticky),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(FontAwesomeIcons.folder),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              bookmark.title = titleController.text;
              bookmark.notes =
                  notesController.text.isEmpty ? null : notesController.text;
              bookmark.category = categoryController.text.isEmpty
                  ? null
                  : categoryController.text;
              bookmark.updatedAt = DateTime.now();
              await bookmark.save();
              Get.back();
              await _loadBookmarks();
              Get.snackbar('Success', 'Bookmark updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError),
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
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.fileExport),
              title: const Text('Export Bookmarks'),
              onTap: () {
                Get.back();
                _exportBookmarks();
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.fileImport),
              title: const Text('Import Bookmarks'),
              onTap: () {
                Get.back();
                _importBookmarks();
              },
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.trash,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Clear All Bookmarks',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Get.back();
                _clearAllBookmarks();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBookmarks() async {
    try {
      final bookmarksData = _bookmarks
          .map((b) => {
                'id': b.id,
                'title': b.title,
                'type': b.type,
                'surahNumber': b.surahNumber,
                'ayahNumber': b.ayahNumber,
                'notes': b.notes,
                'tags': b.tags,
                'category': b.category,
                'color': b.color,
                'createdAt': b.createdAt.toIso8601String(),
                'updatedAt': b.updatedAt.toIso8601String(),
              })
          .toList();

      // TODO: Implement file picker to save JSON
      Get.snackbar(
          'Export', 'Bookmarks exported: ${bookmarksData.length} items');
    } catch (e) {
      Get.snackbar('Error', 'Failed to export bookmarks: $e');
    }
  }

  Future<void> _importBookmarks() async {
    // TODO: Implement file picker to load JSON
    Get.snackbar('Import', 'Feature coming soon');
  }

  Future<void> _clearAllBookmarks() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear All Bookmarks?'),
        content: const Text(
            'This will permanently delete all bookmarks. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var bookmark in _bookmarks) {
        await database.removeBookmark(bookmark.id);
      }
      await _loadBookmarks();
      Get.snackbar('Success', 'All bookmarks cleared');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
