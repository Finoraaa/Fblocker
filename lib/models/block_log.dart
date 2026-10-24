enum LogCategory {
  ad,
  tracker,
  malware,
  telemetry,
  analytics,
}

enum LogAction {
  blocked,
  allowed,
}

class BlockLog {
  final String id;
  final String domain;
  final DateTime timestamp;
  final LogCategory category;
  final LogAction action;
  final String ruleMatched;
  final String clientIp;

  const BlockLog({
    required this.id,
    required this.domain,
    required this.timestamp,
    required this.category,
    required this.action,
    required this.ruleMatched,
    this.clientIp = '127.0.0.1',
  });

  String get categoryName {
    switch (category) {
      case LogCategory.ad:
        return 'Reklam';
      case LogCategory.tracker:
        return 'İzleyici';
      case LogCategory.malware:
        return 'Zararlı Yazılım';
      case LogCategory.telemetry:
        return 'Telemetri';
      case LogCategory.analytics:
        return 'Analitik';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'domain': domain,
    'timestamp': timestamp.toIso8601String(),
    'category': category.name,
    'action': action.name,
    'ruleMatched': ruleMatched,
    'clientIp': clientIp,
  };

  factory BlockLog.fromJson(Map<String, dynamic> json) {
    return BlockLog(
      id: json['id'] as String,
      domain: json['domain'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: LogCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => LogCategory.ad,
      ),
      action: LogAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => LogAction.blocked,
      ),
      ruleMatched: json['ruleMatched'] as String? ?? 'Finora Core Shield',
      clientIp: json['clientIp'] as String? ?? '127.0.0.1',
    );
  }
}
