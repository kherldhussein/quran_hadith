class Reciter {
  final String id;
  final String name;
  final String? arabicName;
  final String? translatedName;
  final String? language;
  final String? style;
  final String? description;
  final String? avatarUrl;
  final String? audioUrlPrefix;

  const Reciter({
    required this.id,
    required this.name,
    this.arabicName,
    this.translatedName,
    this.language,
    this.style,
    this.description,
    this.avatarUrl,
    this.audioUrlPrefix,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    final translated = json['translated_name'];
    String? translatedName;
    String? translatedLanguage;
    if (translated is Map<String, dynamic>) {
      translatedName = translated['name'] as String?;
      translatedLanguage = translated['language_name'] as String?;
    } else if (translated is String) {
      translatedName = translated;
    }

    // Safely extract audio prefix, handling both String and potential Map types
    String? audioPrefix;
    final audioUrlPrefix = json['audio_url_prefix'];
    final audioUrl = json['audio_url'];
    final relativePath = json['relative_path'];

    if (audioUrlPrefix is String) {
      audioPrefix = audioUrlPrefix;
    } else if (audioUrl is String) {
      audioPrefix = audioUrl;
    } else if (relativePath is String) {
      audioPrefix = relativePath;
    }

    // Safely extract identifier
    String identifier = '';
    final jsonId = json['identifier'] ?? json['slug'] ?? json['id'];
    if (jsonId is String) {
      identifier = jsonId;
    } else if (jsonId != null) {
      identifier = jsonId.toString();
    }

    if (identifier.isEmpty && audioPrefix != null) {
      final segments = audioPrefix.split('/');
      final candidate = segments.isNotEmpty ? segments.last : '';
      if (candidate.isNotEmpty) identifier = candidate;
    }

    // Safely extract name
    String name = 'Unknown Reciter';
    final jsonName = json['name'];
    if (jsonName is String) {
      name = jsonName;
    } else if (translatedName != null) {
      name = translatedName;
    }

    // Safely extract other string fields
    String? safeExtract(dynamic value) {
      if (value is String) return value;
      if (value is Map) return null;
      return value?.toString();
    }

    return Reciter(
      id: identifier.isEmpty ? 'unknown_reciter' : identifier,
      name: name,
      arabicName: safeExtract(json['arabic_name']) ??
          (translatedLanguage == 'Arabic' ? translatedName : null),
      translatedName: translatedName,
      language: safeExtract(json['language']) ?? translatedLanguage,
      style: safeExtract(json['style']) ??
          safeExtract(json['recitation_style']) ??
          safeExtract(json['type']),
      description: safeExtract(json['description']) ??
          safeExtract(json['bio']) ??
          safeExtract(json['about']),
      avatarUrl:
          safeExtract(json['profile_picture']) ?? safeExtract(json['image']),
      audioUrlPrefix: audioPrefix,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arabic_name': arabicName,
      'translated_name': translatedName,
      'language': language,
      'style': style,
      'description': description,
      'profile_picture': avatarUrl,
      'audio_url_prefix': audioUrlPrefix,
    };
  }

  Reciter copyWith({
    String? id,
    String? name,
    String? arabicName,
    String? translatedName,
    String? language,
    String? style,
    String? description,
    String? avatarUrl,
    String? audioUrlPrefix,
  }) {
    return Reciter(
      id: id ?? this.id,
      name: name ?? this.name,
      arabicName: arabicName ?? this.arabicName,
      translatedName: translatedName ?? this.translatedName,
      language: language ?? this.language,
      style: style ?? this.style,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      audioUrlPrefix: audioUrlPrefix ?? this.audioUrlPrefix,
    );
  }

  String get displayName =>
      translatedName?.isNotEmpty == true ? translatedName! : name;

  String get styleLabel => style?.isNotEmpty == true ? style! : 'Murattal';

  static List<Reciter> fallback = const [
    Reciter(
      id: 'ar.alafasy',
      name: 'Mishary Rashid Alafasy',
      arabicName: 'مشاري بن راشد العفاسي',
      language: 'Arabic',
      style: 'Mujawwad',
      description:
          'One of the most popular reciters worldwide, known for his beautiful and emotional recitation.',
    ),
    Reciter(
      id: 'ar.abdulbasit',
      name: 'Abdul Basit Abdul Samad',
      arabicName: 'عبد الباسط عبد الصمد',
      language: 'Arabic',
      style: 'Mujawwad',
      description:
          'Legendary Egyptian reciter, considered one of the greatest Quran reciters of all time.',
    ),
    Reciter(
      id: 'ar.abdullahbasfar',
      name: 'Abdullah Basfar',
      arabicName: 'عبدالله بصفر',
      language: 'Arabic',
      style: 'Murattal',
      description:
          'Saudi Arabian reciter known for his clear and melodious voice.',
    ),
    Reciter(
      id: 'ar.abdurrahmaansudais',
      name: 'Abdur-Rahman As-Sudais',
      arabicName: 'عبد الرحمن السديس',
      language: 'Arabic',
      style: 'Mujawwad',
      description:
          'Imam of the Grand Mosque in Mecca, famous for his emotional and powerful recitation.',
    ),
    Reciter(
      id: 'ar.shaatree',
      name: 'Abu Bakr Ash-Shaatree',
      arabicName: 'أبو بكر الشاطري',
      language: 'Arabic',
      style: 'Murattal',
      description:
          'Saudi reciter known for his beautiful tajweed and clear pronunciation.',
    ),
    Reciter(
      id: 'ar.husary',
      name: 'Mahmoud Khalil Al-Hussary',
      arabicName: 'محمود خليل الحصري',
      language: 'Arabic',
      style: 'Muallim',
      description:
          'Egyptian reciter famous for his educational recitation, perfect for learning tajweed.',
    ),
    Reciter(
      id: 'ar.minshawi',
      name: 'Mohamed Siddiq El-Minshawi',
      arabicName: 'محمد صديق المنشاوي',
      language: 'Arabic',
      style: 'Mujawwad',
      description:
          'Egyptian reciter renowned for his mujawwad style with beautiful melody.',
    ),
    Reciter(
      id: 'ar.muhammadayyoub',
      name: 'Muhammad Ayyub',
      arabicName: 'محمد أيوب',
      language: 'Arabic',
      style: 'Murattal',
      description:
          'Former Imam of the Prophet\'s Mosque in Medina, known for his calm and soothing voice.',
    ),
    Reciter(
      id: 'ar.hanirifai',
      name: 'Hani Ar-Rifai',
      arabicName: 'هاني الرفاعي',
      language: 'Arabic',
      style: 'Murattal',
      description: 'Well-known reciter with a distinctive and melodious voice.',
    ),
    Reciter(
      id: 'ar.hudhaify',
      name: 'Ali Al-Hudhaify',
      arabicName: 'علي الحذيفي',
      language: 'Arabic',
      style: 'Murattal',
      description:
          'Imam of the Prophet\'s Mosque, known for his powerful and clear recitation.',
    ),
    Reciter(
      id: 'ar.mahermuaiqly',
      name: 'Maher Al-Muaiqly',
      arabicName: 'ماهر المعيقلي',
      language: 'Arabic',
      style: 'Mujawwad',
      description:
          'Imam of the Grand Mosque in Mecca, beloved for his beautiful voice.',
    ),
    Reciter(
      id: 'ar.saudalshuraim',
      name: 'Saud Ash-Shuraim',
      arabicName: 'سعود الشريم',
      language: 'Arabic',
      style: 'Mujawwad',
      description:
          'Imam of the Grand Mosque in Mecca, known for his emotional recitation.',
    ),
  ];

  static Reciter resolveById(String id) {
    return fallback.firstWhere(
      (reciter) => reciter.id == id,
      orElse: () => fallback.first,
    );
  }
}
