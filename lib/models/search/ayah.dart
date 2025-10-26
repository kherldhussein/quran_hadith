class Aya {
  final int _num;
  final String _text;
  final String? _surah;

  Aya(this._num, this._text, this._surah);

  String? get surah => _surah;
  String get text => _text;
  int get num => _num;
}
