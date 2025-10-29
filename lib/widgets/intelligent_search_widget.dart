import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/services/intelligent_search_service.dart';

/// Enhanced search widget with intelligent features
class IntelligentSearchWidget extends StatefulWidget {
  final Function(List<SearchResult>)? onResults;

  const IntelligentSearchWidget({
    super.key,
    this.onResults,
  });

  @override
  State<IntelligentSearchWidget> createState() =>
      _IntelligentSearchWidgetState();
}

class _IntelligentSearchWidgetState extends State<IntelligentSearchWidget> {
  final IntelligentSearchService _searchService = IntelligentSearchService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  SearchMode _selectedMode = SearchMode.text;
  bool _isSearching = false;
  List<SearchResult> _results = [];
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _initializeService();
    _searchController.addListener(_onSearchTextChanged);
  }

  Future<void> _initializeService() async {
    await _searchService.initialize();
    if (mounted) {
      setState(() {
        _suggestions = _searchService.searchHistory;
      });
    }
  }

  void _onSearchTextChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _suggestions = _searchService.searchHistory;
      });
    } else {
      setState(() {
        _suggestions = _searchService.getSuggestions(query);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),
        _buildModeSelector(context),
        if (_searchController.text.isEmpty && _suggestions.isNotEmpty)
          _buildSuggestions(context)
        else if (_isSearching)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_results.isNotEmpty)
          _buildResults(context)
        else if (_searchController.text.isNotEmpty && _results.isEmpty)
          _buildNoResults(context),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        decoration: InputDecoration(
          hintText: 'Search Quran...',
          prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 18),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(FontAwesomeIcons.xmark, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _results.clear();
                    });
                  },
                ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.sliders, size: 16),
                onPressed: () => _showAdvancedOptions(context),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        onSubmitted: (_) => _performSearch(),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildModeChip(
              SearchMode.text, 'Text', FontAwesomeIcons.magnifyingGlass),
          _buildModeChip(
              SearchMode.fuzzy, 'Fuzzy', FontAwesomeIcons.wandMagicSparkles),
          _buildModeChip(SearchMode.root, 'Root', FontAwesomeIcons.seedling),
          _buildModeChip(SearchMode.topic, 'Topic', FontAwesomeIcons.tags),
          _buildModeChip(
              SearchMode.characteristics, 'Type', FontAwesomeIcons.listCheck),
        ],
      ),
    );
  }

  Widget _buildModeChip(SearchMode mode, String label, IconData icon) {
    final isSelected = _selectedMode == mode;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 12),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedMode = mode);
            if (_searchController.text.isNotEmpty) {
              _performSearch();
            }
          }
        },
        selectedColor: theme.colorScheme.primaryContainer,
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: ListView(
        children: [
          if (_searchService.savedSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Saved Searches',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ..._searchService.savedSearches.map((query) => ListTile(
                  leading: const FaIcon(FontAwesomeIcons.star, size: 16),
                  title: Text(query),
                  trailing: IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                    onPressed: () async {
                      await _searchService.removeSavedSearch(query);
                      setState(() {});
                    },
                  ),
                  onTap: () {
                    _searchController.text = query;
                    _performSearch();
                  },
                )),
          ],
          if (_suggestions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _searchService.clearHistory();
                      setState(() {
                        _suggestions = [];
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            ..._suggestions.map((query) => ListTile(
                  leading:
                      const FaIcon(FontAwesomeIcons.clockRotateLeft, size: 16),
                  title: Text(query),
                  trailing: IconButton(
                    icon: const FaIcon(FontAwesomeIcons.star, size: 14),
                    onPressed: () async {
                      await _searchService.saveSearch(query);
                      setState(() {});
                    },
                  ),
                  onTap: () {
                    _searchController.text = query;
                    _performSearch();
                  },
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_results.length} Results',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final query = _searchController.text;
                    _searchService.saveSearch(query);
                  },
                  icon: const FaIcon(FontAwesomeIcons.star, size: 14),
                  label: const Text('Save Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return _buildResultCard(result, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(SearchResult result, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          result.ayah.text,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            height: 1.8,
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    result.ayah.surah!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  avatar: const FaIcon(FontAwesomeIcons.bookQuran, size: 12),
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    'Ayah ${result.ayah.num}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  avatar: const FaIcon(FontAwesomeIcons.hashtag, size: 12),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    result.matchType.toUpperCase(),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: _getMatchTypeColor(result.matchType, theme),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getMatchTypeColor(String matchType, ThemeData theme) {
    switch (matchType) {
      case 'exact':
        return Colors.green.withOpacity(0.3);
      case 'fuzzy':
        return Colors.orange.withOpacity(0.3);
      case 'root':
        return Colors.blue.withOpacity(0.3);
      case 'topic':
        return Colors.purple.withOpacity(0.3);
      default:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  Widget _buildNoResults(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term or mode',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvancedOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Search Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.bookQuran),
              title: const Text('Search in Specific Surah'),
              onTap: () {
                // TODO: Implement surah-specific search
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.language),
              title: const Text('Search Translations'),
              onTap: () {
                // TODO: Implement translation search
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.rightLeft),
              title: const Text('Cross-Reference with Hadith'),
              onTap: () async {
                Navigator.pop(context);
                await _searchService
                    .crossReferenceWithHadith(_searchController.text);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _results.clear();
    });

    try {
      final results = await _searchService.search(
        query,
        mode: _selectedMode,
      );

      setState(() {
        _results = results;
        _isSearching = false;
      });

      widget.onResults?.call(results);
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }
}
