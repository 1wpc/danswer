class HistoryItem {
  final String id;
  final String imagePath;
  final String solution;
  final DateTime timestamp;

  HistoryItem({
    required this.id,
    required this.imagePath,
    required this.solution,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'solution': solution,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      imagePath: json['imagePath'],
      solution: json['solution'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
