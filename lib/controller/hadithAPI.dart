import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/services/error_service.dart';

sealed class HadithFetchResult {
  const HadithFetchResult();
}

class HadithFetchSuccess extends HadithFetchResult {
  final List<HadithBook> books;
  const HadithFetchSuccess(this.books);
}

class HadithFetchError extends HadithFetchResult {
  final String message;
  final dynamic error;
  const HadithFetchError(this.message, [this.error]);
}

class HadithFetchLoading extends HadithFetchResult {
  const HadithFetchLoading();
}

Map<String, List<HadithBook>> _hadithBooksCache = {};

class HadithAPI {
  static const String base = 'https://api.hadith.gading.dev';
  static const Duration cacheTTL = Duration(hours: 24);

  Future<HadithFetchResult> getHadithBooks({String languageCode = 'en'}) async {
    if (_hadithBooksCache.containsKey(languageCode) &&
        _hadithBooksCache[languageCode]!.isNotEmpty) {
      return HadithFetchSuccess(_hadithBooksCache[languageCode]!);
    }

    List<Map<String, dynamic>>? cachedRaw;
    DateTime? cachedAt;
    try {
      cachedRaw = database.getCachedHadithBooksRaw(languageCode);
      cachedAt = database.getHadithBooksCachedAt(languageCode);
      if (cachedRaw?.isNotEmpty == true && !_isStale(cachedAt)) {
        final books = cachedRaw?.map((m) {
              final bookId = (m['id'] as String?) ?? '';
              return HadithBook(
                name: (m['name'] as String?) ?? 'Unknown Book',
                slug: bookId,
                total: _asInt(m['available']) ?? _asInt(m['total']),
              );
            }).toList() ??
            [];
        _hadithBooksCache[languageCode] = books;
        return HadithFetchSuccess(books);
      }
    } catch (e, s) {
      errorService.reportError('Hadith books local cache error: $e', s);
    }

    try {
      final res = await http.get(Uri.parse('$base/books'));

      if (res.statusCode != 200) {
        throw Exception('Failed to load books: Status code ${res.statusCode}');
      }

      final body = json.decode(res.body);
      final data = body is Map<String, dynamic> ? body['data'] : null;
      final List list = data is List ? data : <dynamic>[];

      List<HadithBook> fetchedBooks = list.map((raw) {
        final e = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        final name = _getLocalizedBookName(e['name'] as String?, languageCode);
        final bookId = (e['id'] as String?) ?? '';
        final available = _asInt(e['available']) ?? _asInt(e['total']);
        return HadithBook(name: name, slug: bookId, total: available);
      }).toList();

      _hadithBooksCache[languageCode] = fetchedBooks;
      try {
        await database.cacheHadithBooks(
            languageCode,
            fetchedBooks
                .map(
                    (b) => {'name': b.name, 'id': b.slug, 'available': b.total})
                .toList());
      } catch (e, s) {
        errorService.reportError('Failed to persist Hadith books cache: $e', s);
      }

      return HadithFetchSuccess(fetchedBooks);
    } catch (e, s) {
      errorService.reportError('Error fetching Hadith books: $e', s);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final books = cachedRaw.map((m) {
          final bookId = (m['id'] as String?) ?? '';
          return HadithBook(
            name: (m['name'] as String?) ?? 'Unknown Book',
            slug: bookId,
            total: _asInt(m['available']) ?? _asInt(m['total']),
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

  String _getLocalizedBookName(String? originalName, String languageCode) {
    if (originalName == null) return 'Unknown Book';
    switch (languageCode) {
      case 'ar':
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
    Map<String, dynamic>? cached;
    DateTime? cachedAt;
    try {
      cached = database.getCachedHadithPageRaw(book: book, page: page);
      cachedAt = database.getHadithPageCachedAt(book: book, page: page);
      if (!_isStale(cachedAt) && cached != null) {
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
    } catch (e, s) {
      errorService.reportError('Hadith page local cache error: $e', s);
    }

    try {
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
        available = _asInt(data['available']) ??
            _asInt(data['total']) ??
            _asInt(data['hadithCount']) ??
            items.length;
      } else if (data is List) {
        items = data;
        available = items.length;
      } else if (body is Map<String, dynamic> && body.containsKey('hadiths')) {
        items = body['hadiths'] is List ? body['hadiths'] : [];
        available =
            _asInt(body['available']) ?? _asInt(body['total']) ?? items.length;
      }

      if (available == 0 && items.isNotEmpty) {
        available = items.length;
      }

      final hadiths = items.map((raw) {
        final e = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        String? arabic = e['arab'] as String?;
        String? translation = e['id'] as String?;

        if ((arabic == null || arabic.isEmpty) && e['arabic'] != null) {
          arabic = (e['arabic'] as String?);
        }
        if ((arabic == null || arabic.isEmpty) && e['text_arab'] != null) {
          arabic = (e['text_arab'] as String?);
        }
        if ((translation == null || translation.isEmpty) &&
            e['translation'] != null) {
          translation = (e['translation'] as String?);
        }
        if ((translation == null || translation.isEmpty) &&
            e['text_id'] != null) {
          translation = (e['text_id'] as String?);
        }

        return HadithItem(
          number: (e['number'] ?? '').toString(),
          arab: arabic ?? '',
          id: translation ?? '',
        );
      }).toList();

      final pageObj = HadithPage(
        book: name ?? book,
        hadiths: hadiths,
        available: available,
      );

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
      } catch (e, s) {
        errorService.reportError('Failed to persist Hadith page cache: $e', s);
      }

      return pageObj;
    } catch (e, s) {
      errorService.reportError('Error fetching hadiths: $e', s);
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
      return HadithPage(book: book, hadiths: const [], available: 0);
    }
  }

  bool _isStale(DateTime? cachedAt) {
    if (cachedAt == null) return true;
    final age = DateTime.now().difference(cachedAt);
    return age > cacheTTL;
  }

  Future<HadithItem?> getRandomHadith() async {
    try {
      final res = await http.get(Uri.parse('$base/random'));
      if (res.statusCode != 200) {
        throw Exception('Failed to load random hadith: ${res.statusCode}');
      }

      final body = json.decode(res.body);
      final data = body is Map<String, dynamic> ? body['data'] : null;

      if (data is Map<String, dynamic>) {
        return HadithItem(
          id: data['id'] as String?,
          number: data['number'] as String?,
          arab: data['arab'] as String?,
        );
      }
    } catch (e, s) {
      errorService.reportError('Error fetching random hadith: $e', s);
    }
    return null;
  }
}

class HadithBook {
  final String name;
  final String slug;
  final int? total;
  HadithBook({required this.name, required this.slug, this.total});
}

class HadithItem {
  final String? id;
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

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  if (v is double) return v.toInt();
  return null;
}
