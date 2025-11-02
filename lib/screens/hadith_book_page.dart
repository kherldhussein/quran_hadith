import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/widgets/hadith_book_content.dart';
import 'package:quran_hadith/widgets/split_view_pane.dart';
import 'package:quran_hadith/theme/theme_state.dart';
import 'package:quran_hadith/layout/adaptive.dart';

/// Full page screen for viewing a specific Hadith book
class HadithBookPage extends StatefulWidget {
  final String bookSlug;
  final String? bookName;

  const HadithBookPage({
    super.key,
    required this.bookSlug,
    this.bookName,
  });

  @override
  State<HadithBookPage> createState() => _HadithBookPageState();
}

class _HadithBookPageState extends State<HadithBookPage> {
  bool _showArabic = true;
  bool _showTranslation = true;
  bool _isSplitViewEnabled = false;
  String _query = '';
  final int _currentPage = 1;
  final TextEditingController _searchCtrl = TextEditingController();
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    // Track reading on page load
    _trackReading();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = isDisplayDesktop(context);

    return Consumer<ThemeState>(
      builder: (context, themeState, _) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            centerTitle: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bookName ?? 'Hadith Book',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Amiri',
                  ),
                ),
                Text(
                  widget.bookSlug,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            elevation: 0,
            backgroundColor: theme.appBarTheme.backgroundColor,
            surfaceTintColor: Colors.transparent,
            foregroundColor: theme.colorScheme.onSurface,
            actions: [
              if (isDesktop)
                IconButton(
                  icon: Icon(
                    _isSplitViewEnabled
                        ? FontAwesomeIcons.rectangleXmark
                        : FontAwesomeIcons.tableColumns,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() => _isSplitViewEnabled = !_isSplitViewEnabled);
                    if (_isSplitViewEnabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Split view enabled'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  tooltip: _isSplitViewEnabled
                      ? 'Exit Split View'
                      : 'Enable Split View',
                  splashRadius: 20,
                ),
              PopupMenuButton<String>(
                icon: Icon(FontAwesomeIcons.gear,
                    color: theme.colorScheme.primary),
                onSelected: (value) => _handleSettingsSelection(value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'show_arabic',
                    child: Row(
                      children: [
                        Icon(
                          _showArabic ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Show Arabic'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'show_translation',
                    child: Row(
                      children: [
                        Icon(
                          _showTranslation
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Show Translation'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'font_small',
                    child: Text('Small Font'),
                  ),
                  const PopupMenuItem(
                    value: 'font_medium',
                    child: Text('Medium Font'),
                  ),
                  const PopupMenuItem(
                    value: 'font_large',
                    child: Text('Large Font'),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search hadiths...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              FontAwesomeIcons.xmark,
                              size: 16,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),

              // Content area
              Expanded(
                child: HadithBookContent(
                  bookSlug: widget.bookSlug,
                  showArabic: _showArabic && !_isSplitViewEnabled,
                  query: _query,
                  fontSize: _fontSize,
                  isSplitView: _isSplitViewEnabled,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSettingsSelection(String value) {
    switch (value) {
      case 'show_arabic':
        setState(() => _showArabic = !_showArabic);
        break;
      case 'show_translation':
        setState(() => _showTranslation = !_showTranslation);
        break;
      case 'font_small':
        setState(() => _fontSize = 16.0);
        break;
      case 'font_medium':
        setState(() => _fontSize = 18.0);
        break;
      case 'font_large':
        setState(() => _fontSize = 22.0);
        break;
    }
  }

  /// Track hadith reading
  void _trackReading() {
    database.trackHadithReading(
      bookSlug: widget.bookSlug,
      bookName: widget.bookName ?? widget.bookSlug,
      page: _currentPage,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
