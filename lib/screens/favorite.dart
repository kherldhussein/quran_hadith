import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/favorite.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quran_hadith/screens/qPageView.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/screens/hadith_detail.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  _FavoriteState createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite>
    with AutomaticKeepAliveClientMixin {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDesktop = isDisplayDesktop(context);

    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: theme.brightness == Brightness.dark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kDarkPrimaryColor,
                      kDarkPrimaryColor.withOpacity(0.9),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xffeef2f5),
                      Color(0xffe8f4f8),
                    ],
                  ),
          ),
          child: Column(
            children: [
              _buildHeader(theme),
              _buildCategoryFilter(theme),
              Expanded(
                child: _buildFavoritesList(theme, isDesktop),
              ),
            ],
          ),
        ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.solidHeart,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Favorites',
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
                'Your saved surahs, ayahs, and hadiths',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 300,
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
                  FontAwesomeIcons.magnifyingGlass,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search favorites...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    final categories = ['All', 'Surahs', 'Ayahs', 'Hadiths'];

    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                checkmarkColor: theme.colorScheme.onPrimary,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFavoritesList(ThemeData theme, bool isDesktop) {
    return Consumer<FavoriteManager>(
      builder: (context, favManager, child) {
        return FutureBuilder<List<dynamic>>(
          future: _loadFavorites(favManager),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState(theme, isDesktop);
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(theme);
            }

            var favorites = snapshot.data!;

            if (_selectedCategory != 'All') {
              favorites = favorites.where((fav) {
                final type = fav['type'] as String;
                return type.toLowerCase().contains(_selectedCategory
                    .toLowerCase()
                    .substring(0, _selectedCategory.length - 1));
              }).toList();
            }

            if (_searchQuery.isNotEmpty) {
              favorites = favorites.where((fav) {
                final name = (fav['name'] as String).toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();
            }

            if (favorites.isEmpty) {
              return _buildNoResultsState(theme);
            }

            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                return _buildFavoriteCard(favorites[index], theme, favManager);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteCard(
      Map<String, dynamic> fav, ThemeData theme, FavoriteManager favManager) {
    final type = fav['type'] as String;
    IconData icon;
    Color color;

    switch (type) {
      case 'surah':
        icon = FontAwesomeIcons.book;
        color = theme.colorScheme.primary;
        break;
      case 'ayah':
        icon = FontAwesomeIcons.quoteRight;
        color = theme.colorScheme.secondary;
        break;
      case 'hadith':
        icon = FontAwesomeIcons.bookQuran;
        color = theme.colorScheme.tertiary;
        break;
      default:
        icon = FontAwesomeIcons.solidHeart;
        color = theme.colorScheme.secondary;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openFavoriteTarget(fav),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(icon, color: color, size: 20),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.solidHeart, size: 16),
                    color: theme.colorScheme.secondary,
                    onPressed: () async {
                      await favManager.removeFavorite(fav['id'] as String);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Removed from favorites'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),
              Text(
                fav['name'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFavoriteTarget(Map<String, dynamic> fav) async {
    try {
      final type = (fav['type'] as String?)?.toLowerCase() ?? '';
      final metadata = (fav['metadata'] as Map?)?.cast<String, dynamic>();

      switch (type) {
        case 'hadith':
          final id = fav['id'] as String?; // e.g., bukhari_123
          final number = (id != null && id.contains('_'))
              ? id.split('_').last
              : (metadata?['number']?.toString() ?? '');
          final bookSlug = metadata?['book'] as String? ??
              ((id != null && id.contains('_')) ? id.split('_').first : '');
          if (bookSlug.isEmpty || number.isEmpty) {
            Get.snackbar('Missing info', 'Could not open hadith');
            return;
          }
          Get.to(() => HadithDetailPage(
                bookSlug: bookSlug,
                number: number,
                arabic: metadata?['text'] as String?,
                translation: metadata?['translation'] as String?,
              ));
          break;
        case 'ayah':
          final surahNo =
              (metadata?['surah'] as int?) ?? _parseSurahFromId(fav['id']);
          if (surahNo == null) {
            Get.snackbar('Missing info', 'Could not determine surah');
            return;
          }
          final data = await QuranAPI().getSuratAudio();
          final surah = data.surahs?.firstWhere(
            (s) => s.number == surahNo,
            orElse: () => throw Exception('Surah not found'),
          );
          Get.to(() => QPageView(
                suratName: surah?.name,
                suratNo: surahNo,
                ayahList: surah?.ayahs,
                englishMeaning: surah?.englishNameTranslation,
                suratEnglishName: surah?.englishName,
              ));
          break;
        case 'surah':
        default:
          final idName = fav['id'] as String?;
          final data = await QuranAPI().getSuratAudio();
          final surah = data.surahs?.firstWhere(
            (s) => s.name == idName,
            orElse: () => data.surahs!.first,
          );
          Get.to(() => QPageView(
                suratName: surah?.name,
                suratNo: surah?.number,
                ayahList: surah?.ayahs,
                englishMeaning: surah?.englishNameTranslation,
                suratEnglishName: surah?.englishName,
              ));
      }
    } catch (e) {
      Get.snackbar('Navigation error', e.toString());
    }
  }

  int? _parseSurahFromId(dynamic id) {
    if (id is String && id.contains(':')) {
      final left = id.split(':').first;
      return int.tryParse(left);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _loadFavorites(
      FavoriteManager favManager) async {
    final favorites = await favManager.getFavorites();
    return favorites.map((fav) {
      return {
        'id': fav.id,
        'name': fav.name,
        'type': fav.type,
        'metadata': fav.metadata,
      };
    }).toList();
  }

  Widget _buildLoadingState(ThemeData theme, bool isDesktop) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          highlightColor: theme.colorScheme.surface,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.solidHeart,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No Favorites Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding your favorite surahs, ayahs, and hadiths',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => Get.back(),
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 16),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.magnifyingGlass,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
