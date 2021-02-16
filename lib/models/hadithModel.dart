
class HadithList {
  final List<Hadith> hadiths;

  HadithList({this.hadiths});

  factory HadithList.fromJson(Map<String, dynamic> json) {
    Iterable hadithlist = json['schema'];
    List<Hadith> hadithList =
    hadithlist.map((e) => Hadith.fromJson(json)).toList();
    return HadithList(hadiths: hadithList);
  }
}

class Hadith {
  final String collection;
  final String bookNumber;
  final int chapterId;
  final int hadithNumber;

// final String page;
  Hadith({this.collection, this.bookNumber, this.chapterId, this.hadithNumber});

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      collection: json['collection'],
      bookNumber: json['bookNumber'],
      chapterId: json['chapterId'],
      hadithNumber: json['hadithNumber'],
    );
  }
}
