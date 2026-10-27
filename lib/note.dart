import 'dart:convert';

/// A single sticky note with its text and last-edited timestamp.
class Note {
  Note({required this.id, required this.text, required this.updatedAt});

  final String id;
  String text;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        text: json['text'] as String,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      );

  static String encodeList(List<Note> notes) =>
      jsonEncode(notes.map((Note n) => n.toJson()).toList());

  static List<Note> decodeList(String raw) {
    final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((dynamic item) =>
            Note.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
