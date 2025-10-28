import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/hadithAPI.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/screens/hadith_book_page.dart';
import 'package:quran_hadith/theme/theme_state.dart';
import 'package:quran_hadith/widgets/hadith_book_tile.dart';

class HPage extends StatefulWidget {
  const HPage({super.key});

  @override
  _HPageState createState() => _HPageState();
}

class _HPageState extends State<HPage> with AutomaticKeepAliveClientMixin {
  /// Stores the future for fetching hadith books to prevent rebuilds from creating new futures
  late final Future<HadithFetchResult> _hadithBooksFuture;

  @override
  void initState() {
    super.initState();
    final hadithAPI = Provider.of<HadithAPI>(context, listen: false);
    _hadithBooksFuture = hadithAPI.getHadithBooks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ThemeState>(
      builder: (context, themeState, _) {
        final theme = Theme.of(context);
        final size = MediaQuery.of(context).size;
        final isDesktop = size.width >= 768;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: FutureBuilder<HadithFetchResult>(
                  future: _hadithBooksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading Hadith Books...',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              size: 64,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Hadith Books Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final result = snapshot.data!;

                    if (result is HadithFetchSuccess) {
                      final books = result.books;
                      final colors = _getGradientColors(theme);

                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildEnhancedDashboard(theme),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _getCrossAxisCount(
                                    MediaQuery.of(context).size.width),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.95,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final book = books[index];
                                  final colorIndex = index % colors.length;

                                  return HadithBookTile(
                                    bookIndex: index + 1,
                                    name: book.name,
                                    slug: book.slug,
                                    total: book.total,
                                    colorI: colors[colorIndex],
                                    radius: 16,
                                  );
                                },
                                childCount: books.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    } else if (result is HadithFetchError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.exclamationTriangle,
                                size: 64,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Error Loading Data',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                result.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Center(
                      child: Text(
                        'Unexpected error occurred',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isDesktop)
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                      color: theme.appBarTheme.backgroundColor,
                      border: Border(
                        left: BorderSide(
                          color: theme.dividerColor.withOpacity(0.1),
                        ),
                      )),
                  child: _buildSidebar(theme),
                )
            ],
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) {
      return 2; // Mobile
    } else if (width < 1000) {
      return 3; // Tablet
    } else {
      return 4; // Desktop
    }
  }

  List<Color> _getGradientColors(ThemeData theme) {
    return [
      const Color(0xFF667EEA),
      const Color(0xFF764BA2),
      const Color(0xFFF093FB),
      const Color(0xFF4158D0),
      const Color(0xFF43E97B),
      const Color(0xFF38F9D7),
      const Color(0xFFFA709A),
      const Color(0xFFFECE00),
      const Color(0xFF30CFD0),
      const Color(0xFF330867),
      const Color(0xFFFF6B9D),
      const Color(0xFFC471ED),
    ];
  }

  /// Enhanced dashboard with Continue Reading, Last Read Hadith, and Hadith of the Day
  Widget _buildEnhancedDashboard(ThemeData theme) {
    final lastReading = database.getLastHadithReading();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.bookOpen,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Hadith Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Continue Reading Section
          if (lastReading != null) ...[
            _buildDashboardCard(
              theme: theme,
              title: 'Continue Reading',
              icon: FontAwesomeIcons.bookmark,
              iconColor: Colors.blue,
              onTap: () {
                Get.to(() => HadithBookPage(
                      bookSlug: lastReading['bookSlug'] as String,
                      bookName: lastReading['bookName'] as String,
                    ));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lastReading['bookName'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.book,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Page ${lastReading['page']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (lastReading['time'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      lastReading['time'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Last Read Hadith Section
          _buildDashboardCard(
            theme: theme,
            title: 'Last Read Hadith',
            icon: FontAwesomeIcons.history,
            iconColor: Colors.orange,
            onTap: () {
              if (lastReading != null) {
                Get.to(() => HadithBookPage(
                      bookSlug: lastReading['bookSlug'] as String,
                      bookName: lastReading['bookName'] as String,
                    ));
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastReading != null) ...[
                  Text(
                    lastReading['bookName'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Page ${lastReading['page']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Start exploring hadith books',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Hadith of the Day Section
          _buildDashboardCard(
            theme: theme,
            title: 'Hadith of the Day',
            icon: FontAwesomeIcons.lightbulb,
            iconColor: Colors.purple,
            onTap: () {
              // Can add navigation to featured hadith later
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"The best of you are those who have the best manners and character."',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '- Sahih Al-Bukhari 3331',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Reflection',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    FaIcon(
                      FontAwesomeIcons.share,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Reusable dashboard card widget
  Widget _buildDashboardCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FaIcon(
                      icon,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 14,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    final lastReading = database.getLastHadithReading();
    final hasLastRead = lastReading != null;

    final bookSlug = lastReading?['bookSlug'] as String?;
    final bookName = lastReading?['bookName'] as String?;
    final page = lastReading?['page'] as int?;
    final timeStr = lastReading?['time'] as String?;

    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Salam,',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            color: theme.dividerColor.withValues(alpha: 0.3),
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
          ),
          if (hasLastRead &&
              bookSlug != null &&
              bookName != null &&
              page != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.clock,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last Read',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Get.to(() => HadithBookPage(
                              bookSlug: bookSlug,
                              bookName: bookName,
                            ));
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Page: $page',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (timeStr != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Continue Reading →',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    thickness: 0.5,
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  FaIcon(
                    FontAwesomeIcons.bookOpen,
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recent hadith\nreading yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    thickness: 0.5,
                    indent: 16,
                    endIndent: 16,
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Tips',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.lightbulb,
                            size: 14,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap on any hadith book to explore',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.bookmark,
                            size: 14,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your reading progress is saved automatically',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
