class PracticalNote {
  final String topic;
  final String title;
  final String shortText;
  final String longerText;
  final String lastVerified;

  PracticalNote({
    required this.topic,
    required this.title,
    required this.shortText,
    required this.longerText,
    required this.lastVerified,
  });

  factory PracticalNote.fromJson(Map<String, dynamic> json) {
    return PracticalNote(
      topic: json['topic'] as String,
      title: json['title'] as String? ?? json['topic'] as String,
      shortText: json['short_text'] as String,
      longerText: json['longer_text'] as String,
      lastVerified: json['last_verified'] as String? ?? '',
    );
  }
}

