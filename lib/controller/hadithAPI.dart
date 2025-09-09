import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // Renamed from getBooks to getHadithBooks for clarity and added languageCode
  // Added languageCode for dynamic fetching (simulated for now)
  Future<HadithFetchResult> getHadithBooks({String languageCode = 'en'}) async {
    // Check cache first
    if (_hadithBooksCache.containsKey(languageCode) && _hadithBooksCache[languageCode]!.isNotEmpty) {
      print('Serving Hadith books from cache for language: $languageCode');
      return HadithFetchSuccess(_hadithBooksCache[languageCode]!);
    }

    try {
      final res = await http.get(Uri.parse('$base/books')); // Current API doesn't support language param, so we simulate.

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

      // Store in cache
      _hadithBooksCache[languageCode] = fetchedBooks;
      print('Fetched and cached Hadith books for language: $languageCode');
      return HadithFetchSuccess(fetchedBooks);
    } catch (e) {
      print('Error fetching Hadith books: $e');
      return HadithFetchError('Failed to load Hadith books. Please check your internet connection or try again.', e);
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
    try {
      // API expects range like "1-10" for page 1, "11-20" for page 2, etc.
      final startRange = ((page - 1) * 10) + 1;
      final endRange = page * 10;
      final res = await http.get(Uri.parse('$base/books/$book?range=$startRange-$endRange'));

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

      return HadithPage(
        book: name ?? book,
        hadiths: hadiths,
        available: available,
      );
    } catch (e) {
      print('Error fetching hadiths: $e');
      // Return safe empty page instead of throwing to avoid UI crash
      return HadithPage(book: book, hadiths: const [], available: 0);
    }
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
