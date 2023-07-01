class HadithList {
  final List<HadithBooks>? hadiths;

  HadithList({this.hadiths});

  factory HadithList.fromJson(Map<String, dynamic> json) {
    Iterable hadithlist = json['schema'];
    List<HadithBooks> hadithList =
        hadithlist.map((e) => HadithBooks.fromJson(json)).toList();
    return HadithList(hadiths: hadithList);
  }
}

class HadithChapter {
  final String? collection;
  final String? chapterEnglish;
  final String? chapterNumber;
  final String? chapterArabic;
  final int? chapterId;
  final int? hadithNumber;

// final String page;
  HadithChapter(
      {this.collection,
      this.chapterEnglish,
      this.chapterId,
      this.hadithNumber,
      this.chapterArabic,
      this.chapterNumber});

  factory HadithChapter.fromJson(Map<String, dynamic> json) {
    return HadithChapter(
      collection: json['books'],
      chapterNumber: json['chapterNumber'],
      chapterEnglish: json['chapterEnglish'],
      chapterId: json['id'],
      hadithNumber: json['hadithNumber'],
      chapterArabic: json['chapterArabic'],
    );
  }
}

class HadithBooks {
  final String? bookSlug;
  final String? bookId;
  final String? bookName;
  final String? writerName;
  final int? hadithCount;

  HadithBooks({
    this.bookSlug,
    this.bookId,
    this.hadithCount,
    this.writerName,
    this.bookName,
  });

  factory HadithBooks.fromJson(Map<String, dynamic> json) {
    return HadithBooks(
      bookSlug: json['bookSlug'],
      bookId: json['id'],
      bookName: json['bookName'],
      hadithCount: json['hadiths_count'],
      writerName: json['writerName'],
    );
  }
}
