class MistakeRecord {
  final String id;
  final String imagePath;
  final String solution;
  final DateTime timestamp;
  final String? model;
  final List<Map<String, dynamic>>? chatHistory;
  final String? knowledgePoints;
  final String? note; // User's note for the mistake
  final List<String>? tags;

  MistakeRecord({
    required this.id,
    required this.imagePath,
    required this.solution,
    required this.timestamp,
    this.model,
    this.chatHistory,
    this.knowledgePoints,
    this.note,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'solution': solution,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'chatHistory': chatHistory,
      'knowledgePoints': knowledgePoints,
      'note': note,
      'tags': tags,
    };
  }

  factory MistakeRecord.fromJson(Map<String, dynamic> json) {
    return MistakeRecord(
      id: json['id'],
      imagePath: json['imagePath'],
      solution: json['solution'],
      timestamp: DateTime.parse(json['timestamp']),
      model: json['model'],
      chatHistory: json['chatHistory'] != null 
          ? List<Map<String, dynamic>>.from(json['chatHistory'])
          : null,
      knowledgePoints: json['knowledgePoints'],
      note: json['note'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }
}
