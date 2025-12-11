class ProviderConfig {
  final String id;
  final String name;
  String apiKey;
  String baseUrl;
  List<String> models;

  ProviderConfig({
    required this.id,
    required this.name,
    this.apiKey = '',
    required this.baseUrl,
    required this.models,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'models': models,
    };
  }

  factory ProviderConfig.fromMap(Map<String, dynamic> map) {
    return ProviderConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      apiKey: map['apiKey'] ?? '',
      baseUrl: map['baseUrl'] ?? '',
      models: List<String>.from(map['models'] ?? []),
    );
  }
}
