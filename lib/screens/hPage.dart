import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/hadithAPI.dart';
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
    // Initialize the future once in initState to prevent FutureBuilder rebuilds
    // This ensures the API call is made only once when the screen loads
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

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              'Hadith Books',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontFamily: 'Amiri',
              ),
            ),
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            foregroundColor: theme.colorScheme.onSurface,
          ),
          body: FutureBuilder<HadithFetchResult>(
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
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
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

  @override
  bool get wantKeepAlive => true;
}
