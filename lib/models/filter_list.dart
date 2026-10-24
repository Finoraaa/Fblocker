class FilterList {
  final String id;
  final String name;
  final String description;
  final String url;
  final int ruleCount;
  final bool isEnabled;
  final DateTime lastUpdated;
  final bool isBuiltIn;

  const FilterList({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.ruleCount,
    this.isEnabled = true,
    required this.lastUpdated,
    this.isBuiltIn = false,
  });

  FilterList copyWith({
    String? id,
    String? name,
    String? description,
    String? url,
    int? ruleCount,
    bool? isEnabled,
    DateTime? lastUpdated,
    bool? isBuiltIn,
  }) {
    return FilterList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      ruleCount: ruleCount ?? this.ruleCount,
      isEnabled: isEnabled ?? this.isEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'url': url,
    'ruleCount': ruleCount,
    'isEnabled': isEnabled,
    'lastUpdated': lastUpdated.toIso8601String(),
    'isBuiltIn': isBuiltIn,
  };

  factory FilterList.fromJson(Map<String, dynamic> json) {
    return FilterList(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      url: json['url'] as String,
      ruleCount: json['ruleCount'] as int,
      isEnabled: json['isEnabled'] as bool? ?? true,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }
}
