class BlockerStats {
  final int blockedAds;
  final int blockedTrackers;
  final double savedBandwidthMb;
  final int threatsBlocked;
  final int activeRules;
  final DateTime? sessionStarted;

  const BlockerStats({
    this.blockedAds = 0,
    this.blockedTrackers = 0,
    this.savedBandwidthMb = 0.0,
    this.threatsBlocked = 0,
    this.activeRules = 184520,
    this.sessionStarted,
  });

  BlockerStats copyWith({
    int? blockedAds,
    int? blockedTrackers,
    double? savedBandwidthMb,
    int? threatsBlocked,
    int? activeRules,
    DateTime? sessionStarted,
  }) {
    return BlockerStats(
      blockedAds: blockedAds ?? this.blockedAds,
      blockedTrackers: blockedTrackers ?? this.blockedTrackers,
      savedBandwidthMb: savedBandwidthMb ?? this.savedBandwidthMb,
      threatsBlocked: threatsBlocked ?? this.threatsBlocked,
      activeRules: activeRules ?? this.activeRules,
      sessionStarted: sessionStarted ?? this.sessionStarted,
    );
  }

  Map<String, dynamic> toJson() => {
    'blockedAds': blockedAds,
    'blockedTrackers': blockedTrackers,
    'savedBandwidthMb': savedBandwidthMb,
    'threatsBlocked': threatsBlocked,
    'activeRules': activeRules,
    'sessionStarted': sessionStarted?.toIso8601String(),
  };

  factory BlockerStats.fromJson(Map<String, dynamic> json) {
    return BlockerStats(
      blockedAds: json['blockedAds'] as int? ?? 0,
      blockedTrackers: json['blockedTrackers'] as int? ?? 0,
      savedBandwidthMb: (json['savedBandwidthMb'] as num?)?.toDouble() ?? 0.0,
      threatsBlocked: json['threatsBlocked'] as int? ?? 0,
      activeRules: json['activeRules'] as int? ?? 184520,
      sessionStarted: json['sessionStarted'] != null
          ? DateTime.tryParse(json['sessionStarted'] as String)
          : null,
    );
  }
}
