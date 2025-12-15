class HistoryItem {
  final String id;
  final String imagePath;
  final String solution;
  final DateTime timestamp;
  final String? model;
  final List<Map<String, dynamic>>? chatHistory;
  final String? knowledgePoints;

  HistoryItem({
    required this.id,
    required this.imagePath,
    required this.solution,
    required this.timestamp,
    this.model,
    this.chatHistory,
    this.knowledgePoints,
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
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      imagePath: json['imagePath'],
      solution: json['solution'],
      timestamp: DateTime.parse(json['timestamp']),
      model: json['model'],
      chatHistory: json['chatHistory'] != null 
          ? List<Map<String, dynamic>>.from(json['chatHistory'])
          : null,
      knowledgePoints: json['knowledgePoints'],
    );
  }
}
