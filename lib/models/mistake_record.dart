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
  
  // Review fields for Ebbinghaus
  final DateTime nextReviewTime;
  final int reviewCount;

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
    DateTime? nextReviewTime,
    this.reviewCount = 0,
  }) : nextReviewTime = nextReviewTime ?? timestamp;

  MistakeRecord copyWith({
    String? id,
    String? imagePath,
    String? solution,
    DateTime? timestamp,
    String? model,
    List<Map<String, dynamic>>? chatHistory,
    String? knowledgePoints,
    String? note,
    List<String>? tags,
    DateTime? nextReviewTime,
    int? reviewCount,
  }) {
    return MistakeRecord(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      solution: solution ?? this.solution,
      timestamp: timestamp ?? this.timestamp,
      model: model ?? this.model,
      chatHistory: chatHistory ?? this.chatHistory,
      knowledgePoints: knowledgePoints ?? this.knowledgePoints,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      nextReviewTime: nextReviewTime ?? this.nextReviewTime,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

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
      'nextReviewTime': nextReviewTime.toIso8601String(),
      'reviewCount': reviewCount,
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
      nextReviewTime: json['nextReviewTime'] != null ? DateTime.parse(json['nextReviewTime']) : null,
      reviewCount: json['reviewCount'] ?? 0,
    );
  }
}
