class Level {
  final String levelId;
  final String levelName;

  Level({
    required this.levelId,
    required this.levelName,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      levelId: json['level_id'] ?? '',
      levelName: json['level_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level_id': levelId,
      'level_name': levelName,
    };
  }

  Level copyWith({
    String? levelId,
    String? levelName,
  }) {
    return Level(
      levelId: levelId ?? this.levelId,
      levelName: levelName ?? this.levelName,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'levelId':
      case 'level_id':
        return levelId;
      case 'levelName':
      case 'level_name':
        return levelName;
      default:
        return null;
    }
  }
}
