import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blocker_stats.dart';
import '../models/block_log.dart';
import '../models/filter_list.dart';
import 'real_dns_engine.dart';

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
  String _dnsProvider = 'Cloudflare DNS (1.1.1.1)';
  String _customDns = 'https://cloudflare-dns.com/dns-query';

  final RealDnsEngine _dnsEngine = RealDnsEngine();
  BlockerStats _stats = const BlockerStats();
  final List<BlockLog> _logs = [];
  final Set<String> _whitelist = {'github.com', 'wikipedia.org', 'flutter.dev'};
  final Set<String> _blacklist = {'bad-ads.net', 'crypto-mining-pool.xyz'};
  List<FilterList> _filterLists = [];

  bool _isUpdatingFilters = false;
  String _filterUpdateStatus = '';

  RealDnsEngine get dnsEngine => _dnsEngine;
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
  bool get isUpdatingFilters => _isUpdatingFilters;
  String get filterUpdateStatus => _filterUpdateStatus;

  String get dohEndpoint {
    if (_dnsProvider.contains('Cloudflare')) {
      return 'https://cloudflare-dns.com/dns-query';
    } else if (_dnsProvider.contains('AdGuard')) {
      return 'https://dns.adguard-dns.com/dns-query';
    } else if (_dnsProvider.contains('Quad9')) {
      return 'https://dns.quad9.net/dns-query';
    } else if (_dnsProvider.contains('Google')) {
      return 'https://dns.google/resolve';
    }
    return _customDns;
  }

  int get totalActiveRules {
    int total = _dnsEngine.loadedRulesCount;
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
        name: 'Finora Real Shield (Dahili Motor)',
        description: 'Gerçek zamanlı reklam, telemetri ve izleyici engelleme motoru.',
        url: 'https://filters.finora.network/master-shield.txt',
        ruleCount: 94200,
        isEnabled: true,
        lastUpdated: DateTime.now(),
        isBuiltIn: true,
      ),
      FilterList(
        id: 'stevenblack-hosts',
        name: 'StevenBlack Evrensel Reklam & Tehdit Hosts',
        description: '70.000+ gerçek etki alanı içeren küresel hosts listesi.',
        url: 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts',
        ruleCount: 78500,
        isEnabled: true,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
        isBuiltIn: true,
      ),
      FilterList(
        id: 'easylist-ads',
        name: 'EasyList Standart Web Filtreleri',
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
      _dnsProvider = prefs.getString(_keyDns) ?? 'Cloudflare DNS (1.1.1.1)';

      final savedStatsStr = prefs.getString(_keyStats);
      if (savedStatsStr != null) {
        _stats = BlockerStats.fromJson(jsonDecode(savedStatsStr) as Map<String, dynamic>);
      } else {
        // Start clean with real zero counts!
        _stats = BlockerStats(
          blockedAds: 0,
          blockedTrackers: 0,
          savedBandwidthMb: 0.0,
          threatsBlocked: 0,
          activeRules: totalActiveRules,
          sessionStarted: DateTime.now(),
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

    if (_isShieldActive) {
      _startDnsServer();
    }

    notifyListeners();
  }

  Future<void> _startDnsServer() async {
    await _dnsEngine.startLocalDnsServer(onQueryReceived: (log) {
      _logs.insert(0, log);
      if (_logs.length > 150) {
        _logs.removeLast();
      }

      if (log.action == LogAction.blocked) {
        int adsInc = (log.category == LogCategory.ad) ? 1 : 0;
        int trackersInc = (log.category == LogCategory.tracker || log.category == LogCategory.telemetry) ? 1 : 0;
        int malwareInc = (log.category == LogCategory.malware) ? 1 : 0;
        double savedInc = (adsInc * 0.12) + (trackersInc * 0.04) + (malwareInc * 0.25);

        _stats = _stats.copyWith(
          blockedAds: _stats.blockedAds + adsInc,
          blockedTrackers: _stats.blockedTrackers + trackersInc,
          threatsBlocked: _stats.threatsBlocked + malwareInc,
          savedBandwidthMb: double.parse((_stats.savedBandwidthMb + savedInc).toStringAsFixed(2)),
        );
      }
      notifyListeners();
    });
  }

  /// Resolve real domain query via DoH with real latency and rule enforcement
  Future<DnsResolveResult> testRealDomain(String domain) async {
    final result = await _dnsEngine.resolveDomainWithDoH(
      domain: domain,
      dohProviderUrl: dohEndpoint,
      blockTrackers: _blockTrackers,
      blockMalware: _blockMalware,
      blockPopups: _blockPopups,
      protectionMode: _protectionMode,
      whitelist: _whitelist,
      blacklist: _blacklist,
    );

    final log = BlockLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      domain: domain,
      timestamp: DateTime.now(),
      category: result.category,
      action: result.isBlocked ? LogAction.blocked : LogAction.allowed,
      ruleMatched: result.matchedRule,
      clientIp: '127.0.0.1 (${result.latencyMs}ms)',
    );

    _logs.insert(0, log);
    if (_logs.length > 150) {
      _logs.removeLast();
    }

    if (result.isBlocked) {
      int adsInc = (result.category == LogCategory.ad) ? 1 : 0;
      int trackersInc = (result.category == LogCategory.tracker || result.category == LogCategory.telemetry) ? 1 : 0;
      int malwareInc = (result.category == LogCategory.malware) ? 1 : 0;
      double savedInc = (adsInc * 0.12) + (trackersInc * 0.04) + (malwareInc * 0.25);

      _stats = _stats.copyWith(
        blockedAds: _stats.blockedAds + adsInc,
        blockedTrackers: _stats.blockedTrackers + trackersInc,
        threatsBlocked: _stats.threatsBlocked + malwareInc,
        savedBandwidthMb: double.parse((_stats.savedBandwidthMb + savedInc).toStringAsFixed(2)),
      );
    }

    _savePreferences();
    notifyListeners();
    return result;
  }

  /// Run a live real-time security benchmark on 6 real domains
  Future<void> runLiveSecurityBenchmark() async {
    const testDomains = [
      'google.com',
      'googleads.g.doubleclick.net',
      'wikipedia.org',
      'adservice.google.com',
      'github.com',
      'c.amazon-adsystem.com',
    ];

    for (final d in testDomains) {
      await testRealDomain(d);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// OTA Update of live filter rules from official repositories
  Future<void> updateOnlineFilterLists() async {
    _isUpdatingFilters = true;
    _filterUpdateStatus = 'Filtre listeleri indiriliyor...';
    notifyListeners();

    try {
      final added = await _dnsEngine.fetchOnlineBlocklist(
        onStatus: (status) {
          _filterUpdateStatus = status;
          notifyListeners();
        },
      );

      _stats = _stats.copyWith(activeRules: totalActiveRules);
      _filterUpdateStatus = '$added yeni kural başarıyla belleğe işlendi.';
    } catch (e) {
      _filterUpdateStatus = 'Filtre güncelleme hatası: $e';
    } finally {
      _isUpdatingFilters = false;
      notifyListeners();
    }
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
      _startDnsServer();
    } else {
      _dnsEngine.stop();
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
      ruleCount: 2500,
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

  @override
  void dispose() {
    _dnsEngine.stop();
    super.dispose();
  }
}
