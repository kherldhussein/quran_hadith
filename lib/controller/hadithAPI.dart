import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quran_hadith/database/database_service.dart';

// Define a sealed class for better state management (Success, Error, Loading)
sealed class HadithFetchResult {
  const HadithFetchResult();
}

class HadithFetchSuccess extends HadithFetchResult {
  final List<HadithBook> books;
  const HadithFetchSuccess(this.books);
}

class HadithFetchError extends HadithFetchResult {
  final String message;
  final dynamic error; // Store the actual error object for debugging
  const HadithFetchError(this.message, [this.error]);
}

class HadithFetchLoading extends HadithFetchResult {
  const HadithFetchLoading();
}

// In-memory cache for Hadith books
Map<String, List<HadithBook>> _hadithBooksCache = {};

class HadithAPI {
  static const String base = 'https://api.hadith.gading.dev';
  static const Duration cacheTTL = Duration(hours: 24);

  // Renamed from getBooks to getHadithBooks for clarity and added languageCode
  // Added languageCode for dynamic fetching (simulated for now)
  Future<HadithFetchResult> getHadithBooks({String languageCode = 'en'}) async {
    // 1) Check in-memory cache
    if (_hadithBooksCache.containsKey(languageCode) &&
        _hadithBooksCache[languageCode]!.isNotEmpty) {
      return HadithFetchSuccess(_hadithBooksCache[languageCode]!);
    }

    // 2) Try local database cache (fresh)
    List<Map<String, dynamic>>? cachedRaw;
    DateTime? cachedAt;
    try {
      cachedRaw = database.getCachedHadithBooksRaw(languageCode);
      cachedAt = database.getHadithBooksCachedAt(languageCode);
      if (cachedRaw != null && cachedRaw.isNotEmpty && !_isStale(cachedAt)) {
        final books = cachedRaw.map((m) {
          return HadithBook(
            name: (m['name'] as String?) ?? 'Unknown Book',
            slug: (m['slug'] as String?) ?? '',
            total: _asInt(m['total']),
          );
        }).toList();
        _hadithBooksCache[languageCode] = books;
        return HadithFetchSuccess(books);
      }
    } catch (e) {
      // Non-fatal: fall back to network
      print('Hadith books local cache error: $e');
    }

    try {
      final res = await http.get(Uri.parse(
          '$base/books')); // Current API doesn't support language param, so we simulate.

      if (res.statusCode != 200) {
        throw Exception('Failed to load books: Status code ${res.statusCode}');
      }

      final body = json.decode(res.body);
      final data = body is Map<String, dynamic> ? body['data'] : null;
      final List list = data is List ? data : <dynamic>[];

      List<HadithBook> fetchedBooks = list.map((raw) {
        final e = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        final name = _getLocalizedBookName(e['name'] as String?, languageCode);
        final slug = (e['slug'] as String?) ?? '';
        final total = _asInt(e['total']);
        return HadithBook(name: name, slug: slug, total: total);
      }).toList();

      // Store in memory and DB cache
      _hadithBooksCache[languageCode] = fetchedBooks;
      try {
        await database.cacheHadithBooks(
            languageCode,
            fetchedBooks
                .map((b) => {'name': b.name, 'slug': b.slug, 'total': b.total})
                .toList());
      } catch (e) {
        print('Failed to persist Hadith books cache: $e');
      }

      return HadithFetchSuccess(fetchedBooks);
    } catch (e) {
      print('Error fetching Hadith books: $e');
      // Stale-if-error: return cached books even if stale
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final books = cachedRaw.map((m) {
          return HadithBook(
            name: (m['name'] as String?) ?? 'Unknown Book',
            slug: (m['slug'] as String?) ?? '',
            total: _asInt(m['total']),
          );
        }).toList();
        _hadithBooksCache[languageCode] = books;
        return HadithFetchSuccess(books);
      }
      return HadithFetchError(
          'Failed to load Hadith books. Please check your internet connection or try again.',
          e);
    }
  }

  // Helper to simulate localized book names based on languageCode
  String _getLocalizedBookName(String? originalName, String languageCode) {
    if (originalName == null) return 'Unknown Book';
    switch (languageCode) {
      case 'ar':
        // This is a simplification; in a real app, you'd fetch actual Arabic names
        if (originalName == 'Sahih Bukhari') return 'صحيح البخاري';
        if (originalName == 'Sahih Muslim') return 'صحيح مسلم';
        return '$originalName (AR)';
      case 'id':
        if (originalName == 'Sahih Bukhari') return 'Sahih Bukhari (ID)';
        return '$originalName (ID)';
      default:
        return originalName;
    }
  }

  Future<HadithPage> getHadiths({required String book, int page = 1}) async {
    // 1) Try local database cache first
    Map<String, dynamic>? cached;
    DateTime? cachedAt;
    try {
      cached = database.getCachedHadithPageRaw(book: book, page: page);
      cachedAt = database.getHadithPageCachedAt(book: book, page: page);
      if (cached != null && !_isStale(cachedAt)) {
        final items = (cached['hadiths'] as List? ?? [])
            .map((e) => HadithItem(
                  number: (e['number'] ?? '').toString(),
                  arab: (e['arab'] as String?) ?? '',
                  id: (e['id'] as String?) ?? '',
                ))
            .toList();
        return HadithPage(
          book: (cached['book'] as String?) ?? book,
          hadiths: items,
          available: _asInt(cached['available']) ?? 0,
        );
      }
    } catch (e) {
      print('Hadith page local cache error: $e');
    }

    try {
      // API expects range like "1-10" for page 1, "11-20" for page 2, etc.
      final startRange = ((page - 1) * 10) + 1;
      final endRange = page * 10;
      final res = await http
          .get(Uri.parse('$base/books/$book?range=$startRange-$endRange'));

      if (res.statusCode != 200) {
        throw Exception('Failed to load hadiths: ${res.statusCode}');
      }

      final body = json.decode(res.body);
      final data = body is Map<String, dynamic> ? body['data'] : null;

      List items = const [];
      String? name;
      int available = 0;

      if (data is Map<String, dynamic>) {
        final rawItems = data['hadiths'];
        if (rawItems is List) items = rawItems;
        name = data['name'] as String?;
        available = _asInt(data['available']) ?? 0;
      } else if (data is List) {
        // Some API shapes may return the list directly
        items = data;
      }

      final hadiths = items.map((raw) {
        final e = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        return HadithItem(
          number: (e['number'] ?? '').toString(),
          arab: (e['arab'] as String?) ?? '',
          id: (e['id'] as String?) ?? '',
        );
      }).toList();

      final pageObj = HadithPage(
        book: name ?? book,
        hadiths: hadiths,
        available: available,
      );

      // Persist to DB cache for offline use
      try {
        await database.cacheHadithPage(
          book: book,
          page: page,
          payload: {
            'book': pageObj.book,
            'available': pageObj.available,
            'hadiths': hadiths
                .map((h) => {
                      'number': h.number,
                      'arab': h.arab,
                      'id': h.id,
                    })
                .toList(),
          },
        );
      } catch (e) {
        print('Failed to persist Hadith page cache: $e');
      }

      return pageObj;
    } catch (e) {
      print('Error fetching hadiths: $e');
      // Stale-if-error: return cached page even if stale
      if (cached != null) {
        final items = (cached['hadiths'] as List? ?? [])
            .map((e) => HadithItem(
                  number: (e['number'] ?? '').toString(),
                  arab: (e['arab'] as String?) ?? '',
                  id: (e['id'] as String?) ?? '',
                ))
            .toList();
        return HadithPage(
          book: (cached['book'] as String?) ?? book,
          hadiths: items,
          available: _asInt(cached['available']) ?? items.length,
        );
      }
      // Return safe empty page instead of throwing to avoid UI crash
      return HadithPage(book: book, hadiths: const [], available: 0);
    }
  }

  bool _isStale(DateTime? cachedAt) {
    if (cachedAt == null) return true;
    final age = DateTime.now().difference(cachedAt);
    return age > cacheTTL;
  }
}

class HadithBook {
  final String name; // Made non-nullable
  final String slug; // Made non-nullable
  final int? total;
  HadithBook({required this.name, required this.slug, this.total});
}

class HadithItem {
  final String? id; // Actually the translation text
  final String? number;
  final String? arab;
  HadithItem({this.id, this.number, this.arab});
}

class HadithPage {
  final String? book;
  final List<HadithItem> hadiths;
  final int available;
  HadithPage({this.book, required this.hadiths, this.available = 0});
}

// Helper: safely convert dynamic to int
int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  if (v is double) return v.toInt();
  return null;
}
