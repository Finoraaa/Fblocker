import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blocker_stats.dart';
import '../models/block_log.dart';
import '../models/filter_list.dart';

class BlockerService extends ChangeNotifier {
  static const String _keyShieldActive = 'finora_shield_active';
  static const String _keyStats = 'finora_stats';
  static const String _keyWhitelist = 'finora_whitelist';
  static const String _keyBlacklist = 'finora_blacklist';
  static const String _keyDns = 'finora_dns_provider';
  static const String _keyMode = 'finora_protection_mode';
  static const String _keyTrackers = 'finora_block_trackers';
  static const String _keyMalware = 'finora_block_malware';
  static const String _keyPopups = 'finora_block_popups';

  bool _isShieldActive = true;
  String _protectionMode = 'Standart';
  bool _blockTrackers = true;
  bool _blockMalware = true;
  bool _blockPopups = true;
  bool _autoStart = true;
  bool _notifications = false;
  String _dnsProvider = 'Finora Secure DNS (Önerilen)';
  String _customDns = 'https://dns.finora.network/dns-query';

  BlockerStats _stats = const BlockerStats();
  final List<BlockLog> _logs = [];
  final Set<String> _whitelist = {'github.com', 'wikipedia.org', 'flutter.dev'};
  final Set<String> _blacklist = {'bad-ads.net', 'crypto-mining-pool.xyz'};
  List<FilterList> _filterLists = [];

  Timer? _trafficSimulationTimer;
  final Random _random = Random();

  bool get isShieldActive => _isShieldActive;
  String get protectionMode => _protectionMode;
  bool get blockTrackers => _blockTrackers;
  bool get blockMalware => _blockMalware;
  bool get blockPopups => _blockPopups;
  bool get autoStart => _autoStart;
  bool get notifications => _notifications;
  String get dnsProvider => _dnsProvider;
  String get customDns => _customDns;
  BlockerStats get stats => _stats;
  List<BlockLog> get logs => List.unmodifiable(_logs);
  Set<String> get whitelist => Set.unmodifiable(_whitelist);
  Set<String> get blacklist => Set.unmodifiable(_blacklist);
  List<FilterList> get filterLists => List.unmodifiable(_filterLists);

  int get totalActiveRules {
    int total = 0;
    for (final list in _filterLists) {
      if (list.isEnabled) {
        total += list.ruleCount;
      }
    }
    return total;
  }

  BlockerService() {
    _initDefaults();
    _loadFromPreferences();
  }

  void _initDefaults() {
    _filterLists = [
      FilterList(
        id: 'finora-core',
        name: 'Finora Master Core Shield',
        description: 'Finora topluluğu tarafından optimize edilmiş ana reklam kalkanı.',
        url: 'https://filters.finora.network/master-shield.txt',
        ruleCount: 94200,
        isEnabled: true,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
        isBuiltIn: true,
      ),
      FilterList(
        id: 'easylist-ads',
        name: 'EasyList Standart Reklam Koruması',
        description: 'Web sitelerindeki afiş, video ve pop-up reklamları hedefler.',
        url: 'https://easylist.to/easylist/easylist.txt',
        ruleCount: 52100,
        isEnabled: true,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 12)),
        isBuiltIn: true,
      ),
      FilterList(
        id: 'adguard-trackers',
        name: 'AdGuard Gizlilik ve Takip Koruması',
        description: 'Web sitelerindeki çerez ve kullanıcı profil takipçilerini engeller.',
        url: 'https://filters.adtidy.org/extension/chromium/filters/3.txt',
        ruleCount: 38400,
        isEnabled: true,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        isBuiltIn: true,
      ),
      FilterList(
        id: 'finora-malware',
        name: 'Finora Oltalama & Siber Tehdit Kalkanı',
        description: 'Kimlik avı, zararlı yazılım ve fidye sitelerine erişimi durdurur.',
        url: 'https://filters.finora.network/malware-guard.txt',
        ruleCount: 18600,
        isEnabled: true,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 6)),
        isBuiltIn: true,
      ),
      FilterList(
        id: 'peter-lowe',
        name: "Peter Lowe's Reklam & İzleyici Sunucuları",
        description: 'Hafif ve ultra hızlı ad server kara listesi.',
        url: 'https://pgl.yoyo.org/adservers/serverlist.php',
        ruleCount: 4200,
        isEnabled: false,
        lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
        isBuiltIn: true,
      ),
    ];
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isShieldActive = prefs.getBool(_keyShieldActive) ?? true;
      _protectionMode = prefs.getString(_keyMode) ?? 'Standart';
      _blockTrackers = prefs.getBool(_keyTrackers) ?? true;
      _blockMalware = prefs.getBool(_keyMalware) ?? true;
      _blockPopups = prefs.getBool(_keyPopups) ?? true;
      _dnsProvider = prefs.getString(_keyDns) ?? 'Finora Secure DNS (Önerilen)';

      final savedStatsStr = prefs.getString(_keyStats);
      if (savedStatsStr != null) {
        _stats = BlockerStats.fromJson(jsonDecode(savedStatsStr) as Map<String, dynamic>);
      } else {
        _stats = BlockerStats(
          blockedAds: 1420,
          blockedTrackers: 864,
          savedBandwidthMb: 148.6,
          threatsBlocked: 27,
          activeRules: totalActiveRules,
          sessionStarted: DateTime.now().subtract(const Duration(hours: 4)),
        );
      }

      final savedWhitelist = prefs.getStringList(_keyWhitelist);
      if (savedWhitelist != null) {
        _whitelist.clear();
        _whitelist.addAll(savedWhitelist);
      }

      final savedBlacklist = prefs.getStringList(_keyBlacklist);
      if (savedBlacklist != null) {
        _blacklist.clear();
        _blacklist.addAll(savedBlacklist);
      }

      _stats = _stats.copyWith(activeRules: totalActiveRules);
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }

    _startTrafficLoop();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShieldActive, _isShieldActive);
      await prefs.setString(_keyMode, _protectionMode);
      await prefs.setBool(_keyTrackers, _blockTrackers);
      await prefs.setBool(_keyMalware, _blockMalware);
      await prefs.setBool(_keyPopups, _blockPopups);
      await prefs.setString(_keyDns, _dnsProvider);
      await prefs.setString(_keyStats, jsonEncode(_stats.toJson()));
      await prefs.setStringList(_keyWhitelist, _whitelist.toList());
      await prefs.setStringList(_keyBlacklist, _blacklist.toList());
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  void toggleShield() {
    _isShieldActive = !_isShieldActive;
    if (_isShieldActive) {
      _stats = _stats.copyWith(sessionStarted: DateTime.now());
    }
    _savePreferences();
    notifyListeners();
  }

  void setProtectionMode(String mode) {
    _protectionMode = mode;
    _savePreferences();
    notifyListeners();
  }

  void setDnsProvider(String provider, {String? customUrl}) {
    _dnsProvider = provider;
    if (customUrl != null) {
      _customDns = customUrl;
    }
    _savePreferences();
    notifyListeners();
  }

  void toggleBlockTrackers(bool val) {
    _blockTrackers = val;
    _savePreferences();
    notifyListeners();
  }

  void toggleBlockMalware(bool val) {
    _blockMalware = val;
    _savePreferences();
    notifyListeners();
  }

  void toggleBlockPopups(bool val) {
    _blockPopups = val;
    _savePreferences();
    notifyListeners();
  }

  void toggleAutoStart(bool val) {
    _autoStart = val;
    notifyListeners();
  }

  void toggleNotifications(bool val) {
    _notifications = val;
    notifyListeners();
  }

  void toggleFilterList(String id) {
    final index = _filterLists.indexWhere((l) => l.id == id);
    if (index != -1) {
      final item = _filterLists[index];
      _filterLists[index] = item.copyWith(isEnabled: !item.isEnabled);
      _stats = _stats.copyWith(activeRules: totalActiveRules);
      notifyListeners();
    }
  }

  void addCustomFilterList(String name, String url) {
    final newList = FilterList(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: 'Kullanıcı tarafından eklenen özel filtre kuralı.',
      url: url,
      ruleCount: 1200 + _random.nextInt(3500),
      isEnabled: true,
      lastUpdated: DateTime.now(),
      isBuiltIn: false,
    );
    _filterLists.add(newList);
    _stats = _stats.copyWith(activeRules: totalActiveRules);
    notifyListeners();
  }

  void removeFilterList(String id) {
    _filterLists.removeWhere((l) => l.id == id && !l.isBuiltIn);
    _stats = _stats.copyWith(activeRules: totalActiveRules);
    notifyListeners();
  }

  void addWhitelist(String domain) {
    final clean = domain.trim().toLowerCase();
    if (clean.isNotEmpty) {
      _whitelist.add(clean);
      _blacklist.remove(clean);
      _savePreferences();
      notifyListeners();
    }
  }

  void removeWhitelist(String domain) {
    _whitelist.remove(domain);
    _savePreferences();
    notifyListeners();
  }

  void addBlacklist(String domain) {
    final clean = domain.trim().toLowerCase();
    if (clean.isNotEmpty) {
      _blacklist.add(clean);
      _whitelist.remove(clean);
      _savePreferences();
      notifyListeners();
    }
  }

  void removeBlacklist(String domain) {
    _blacklist.remove(domain);
    _savePreferences();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void resetStats() {
    _stats = BlockerStats(
      blockedAds: 0,
      blockedTrackers: 0,
      savedBandwidthMb: 0.0,
      threatsBlocked: 0,
      activeRules: totalActiveRules,
      sessionStarted: DateTime.now(),
    );
    _savePreferences();
    notifyListeners();
  }

  void _startTrafficLoop() {
    _trafficSimulationTimer?.cancel();
    _trafficSimulationTimer = Timer.periodic(const Duration(milliseconds: 2400), (timer) {
      if (!_isShieldActive) return;

      _simulateIncomingTraffic();
    });
  }

  static const List<Map<String, dynamic>> _sampleDomains = [
    {'domain': 'googleads.g.doubleclick.net', 'cat': LogCategory.ad, 'rule': 'EasyList - DoubleClick Ads'},
    {'domain': 'adservice.google.com', 'cat': LogCategory.ad, 'rule': 'Finora Core - Google Ad Service'},
    {'domain': 'analytics.tiktok.com', 'cat': LogCategory.tracker, 'rule': 'AdGuard - TikTok Analytics Tracker'},
    {'domain': 'graph.facebook.com', 'cat': LogCategory.tracker, 'rule': 'Finora Core - Meta Tracker'},
    {'domain': 'telemetry.microsoft.com', 'cat': LogCategory.telemetry, 'rule': 'Finora Shield - MS Telemetry'},
    {'domain': 'c.amazon-adsystem.com', 'cat': LogCategory.ad, 'rule': 'EasyList - Amazon AdSystem'},
    {'domain': 'taboola.com', 'cat': LogCategory.ad, 'rule': 'Finora Core - Native Ad Network'},
    {'domain': 'outbrain.com', 'cat': LogCategory.ad, 'rule': 'Finora Core - Outbrain Click Tracker'},
    {'domain': 'metrics.icloud.com', 'cat': LogCategory.telemetry, 'rule': 'AdGuard - Apple Metrics'},
    {'domain': 'crypto-mining-agent.net', 'cat': LogCategory.malware, 'rule': 'Finora Anti-Malware - Cryptominer'},
    {'domain': 'phishing-login-secure.xyz', 'cat': LogCategory.malware, 'rule': 'Finora Threat Shield - Phishing'},
    {'domain': 'github.com', 'cat': LogCategory.analytics, 'rule': 'Clean Traffic'},
    {'domain': 'wikipedia.org', 'cat': LogCategory.analytics, 'rule': 'Clean Traffic'},
    {'domain': 'flutter.dev', 'cat': LogCategory.analytics, 'rule': 'Clean Traffic'},
  ];

  void _simulateIncomingTraffic() {
    final entry = _sampleDomains[_random.nextInt(_sampleDomains.length)];
    final domain = entry['domain'] as String;
    final cat = entry['cat'] as LogCategory;
    final rule = entry['rule'] as String;

    bool isBlocked = false;

    if (_whitelist.contains(domain)) {
      isBlocked = false;
    } else if (_blacklist.contains(domain)) {
      isBlocked = true;
    } else {
      if (cat == LogCategory.ad) {
        isBlocked = true;
      } else if (cat == LogCategory.tracker && _blockTrackers) {
        isBlocked = true;
      } else if (cat == LogCategory.malware && _blockMalware) {
        isBlocked = true;
      } else if (cat == LogCategory.telemetry) {
        isBlocked = _protectionMode != 'Standart';
      }
    }

    final newLog = BlockLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      domain: domain,
      timestamp: DateTime.now(),
      category: cat,
      action: isBlocked ? LogAction.blocked : LogAction.allowed,
      ruleMatched: isBlocked ? rule : 'İzin Verildi (Temiz)',
    );

    _logs.insert(0, newLog);
    if (_logs.length > 120) {
      _logs.removeLast();
    }

    if (isBlocked) {
      int adsInc = (cat == LogCategory.ad) ? 1 : 0;
      int trackersInc = (cat == LogCategory.tracker || cat == LogCategory.telemetry) ? 1 : 0;
      int malwareInc = (cat == LogCategory.malware) ? 1 : 0;
      double savedInc = (adsInc * 0.12) + (trackersInc * 0.04) + (malwareInc * 0.25);

      _stats = _stats.copyWith(
        blockedAds: _stats.blockedAds + adsInc,
        blockedTrackers: _stats.blockedTrackers + trackersInc,
        threatsBlocked: _stats.threatsBlocked + malwareInc,
        savedBandwidthMb: double.parse((_stats.savedBandwidthMb + savedInc).toStringAsFixed(1)),
      );

      // Periodically persist stats
      if (_stats.blockedAds % 10 == 0) {
        _savePreferences();
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _trafficSimulationTimer?.cancel();
    super.dispose();
  }
}
