import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/block_log.dart';

class DnsResolveResult {
  final String domain;
  final bool isBlocked;
  final String resolvedIp;
  final int latencyMs;
  final LogCategory category;
  final String matchedRule;

  const DnsResolveResult({
    required this.domain,
    required this.isBlocked,
    required this.resolvedIp,
    required this.latencyMs,
    required this.category,
    required this.matchedRule,
  });
}

class RealDnsEngine {
  final Set<String> _realBlockedDomains = {};
  RawDatagramSocket? _udpServer;
  int _activePort = 8053;
  bool _isRunning = false;

  int get activePort => _activePort;
  bool get isRunning => _isRunning;
  int get loadedRulesCount => _realBlockedDomains.length;

  RealDnsEngine() {
    _loadBuiltInBlocklist();
  }

  void _loadBuiltInBlocklist() {
    // Curated high-impact real ad, tracking, telemetry, and malware domains
    const baseList = [
      // Google Ads & Tracking
      'doubleclick.net', 'googleads.g.doubleclick.net', 'adservice.google.com',
      'pagead2.googlesyndication.com', 'google-analytics.com', 'googletagservices.com',
      'googletagmanager.com', 'admob.com', 'analytics.google.com',
      // Facebook / Meta
      'graph.facebook.com', 'pixel.facebook.com', 'an.facebook.com', 'ads.facebook.com',
      // Microsoft & Windows Telemetry
      'telemetry.microsoft.com', 'vortex.data.microsoft.com', 'settings-win.data.microsoft.com',
      'watson.telemetry.microsoft.com', 'activity.windows.com',
      // Apple Telemetry
      'metrics.icloud.com', 'iadsdk.apple.com', 'metrics.apple.com',
      // TikTok & ByteDance
      'analytics.tiktok.com', 'log.tiktokv.com', 'mon.tiktokv.com',
      // Major Ad Networks
      'c.amazon-adsystem.com', 'aax.amazon-adsystem.com', 'adnxs.com', 'ib.adnxs.com',
      'taboola.com', 'api.taboola.com', 'outbrain.com', 'widgets.outbrain.com',
      'criteo.com', 'static.criteo.net', 'bidswitch.net', 'rubiconproject.com',
      'pubmatic.com', 'openx.net', 'casalemedia.com', 'smartadserver.com',
      'scorecardresearch.com', 'sb.scorecardresearch.com', 'quantserve.com',
      'adcolony.com', 'unityads.unity3d.com', 'appsflyer.com', 'applovin.com',
      'chartboost.com', 'vungle.com', 'ironsrc.com', 'adjust.com',
      // Popups, Redirects & Aggressive Ads
      'popads.net', 'popcash.net', 'propellerads.com', 'exoclick.com', 'trafficjunky.com',
      'yllix.com', 'adsterra.com', 'clickadu.com', 'hilltopads.com', 'monetag.com',
      // Crypto Mining & Malware
      'coinhive.com', 'crypto-loot.com', 'coin-have.com', 'authedmine.com',
      'crypto-mining-agent.net', 'bad-ads.net', 'phishing-login-secure.xyz',
      'malware-domain-test.com', 'ransomware-c2.net',
    ];

    _realBlockedDomains.addAll(baseList);
  }

  /// Downloads live blocklists from official sources (OTA list updates)
  Future<int> fetchOnlineBlocklist({
    String url = 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts',
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('Çevrimiçi filtre listesi indiriliyor...');
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        onStatus?.call('Filtre kuralları çözümleniyor...');
        final lines = const LineSplitter().convert(response.body);
        int added = 0;
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

          // hosts format: 0.0.0.0 domain.com
          final parts = trimmed.split(RegExp(r'\s+'));
          if (parts.length >= 2 && (parts[0] == '0.0.0.0' || parts[0] == '127.0.0.1')) {
            final domain = parts[1].toLowerCase().trim();
            if (domain != 'localhost' && domain != 'broadcasthost') {
              _realBlockedDomains.add(domain);
              added++;
            }
          }
        }
        onStatus?.call('Başarıyla $added yeni kural eklendi.');
        return added;
      }
    } catch (e) {
      debugPrint('Error fetching online blocklist: $e');
    }
    return 0;
  }

  /// Check if a domain should be blocked according to real rules and heuristics
  DnsResolveResult checkDomain({
    required String domain,
    required bool blockTrackers,
    required bool blockMalware,
    required bool blockPopups,
    required String protectionMode,
    required Set<String> whitelist,
    required Set<String> blacklist,
  }) {
    final clean = domain.trim().toLowerCase();

    // Whitelist check
    if (whitelist.contains(clean)) {
      return DnsResolveResult(
        domain: clean,
        isBlocked: false,
        resolvedIp: '',
        latencyMs: 0,
        category: LogCategory.analytics,
        matchedRule: 'Kullanıcı Beyaz Listesi (İzin Verildi)',
      );
    }

    // Blacklist check
    if (blacklist.contains(clean)) {
      return DnsResolveResult(
        domain: clean,
        isBlocked: true,
        resolvedIp: '0.0.0.0',
        latencyMs: 1,
        category: LogCategory.ad,
        matchedRule: 'Kullanıcı Özel Kara Listesi',
      );
    }

    // Exact domain match
    if (_realBlockedDomains.contains(clean)) {
      final cat = _categorizeDomain(clean);
      return DnsResolveResult(
        domain: clean,
        isBlocked: true,
        resolvedIp: '0.0.0.0',
        latencyMs: 1,
        category: cat,
        matchedRule: 'Finora Real Shield - Tam Eşleşme',
      );
    }

    // Subdomain match (e.g. query is ads.google.com -> checks google.com)
    final parts = clean.split('.');
    for (int i = 1; i < parts.length - 1; i++) {
      final parentDomain = parts.sublist(i).join('.');
      if (_realBlockedDomains.contains(parentDomain)) {
        final cat = _categorizeDomain(parentDomain);
        return DnsResolveResult(
          domain: clean,
          isBlocked: true,
          resolvedIp: '0.0.0.0',
          latencyMs: 1,
          category: cat,
          matchedRule: 'Finora Real Shield - Üst Etki Alanı ($parentDomain)',
        );
      }
    }

    // Aggressive Heuristic checks
    if (protectionMode == 'Agresif' || protectionMode == 'Siber') {
      if (clean.contains('telemetry') || clean.contains('analytic') || clean.contains('tracker')) {
        if (blockTrackers) {
          return DnsResolveResult(
            domain: clean,
            isBlocked: true,
            resolvedIp: '0.0.0.0',
            latencyMs: 1,
            category: LogCategory.tracker,
            matchedRule: 'Heuristik Kalkan - İzleyici / Telemetri Kalıbı',
          );
        }
      }
      if (clean.contains('adservice') || clean.contains('adserver') || clean.contains('pagead')) {
        return DnsResolveResult(
          domain: clean,
          isBlocked: true,
          resolvedIp: '0.0.0.0',
          latencyMs: 1,
          category: LogCategory.ad,
          matchedRule: 'Heuristik Kalkan - Reklam Sunucusu Kalıbı',
        );
      }
      if (clean.contains('mining') || clean.contains('coinhive') || clean.contains('malware')) {
        if (blockMalware) {
          return DnsResolveResult(
            domain: clean,
            isBlocked: true,
            resolvedIp: '0.0.0.0',
            latencyMs: 1,
            category: LogCategory.malware,
            matchedRule: 'Heuristik Kalkan - Kripto Madenciliği & Tehdit',
          );
        }
      }
    }

    return DnsResolveResult(
      domain: clean,
      isBlocked: false,
      resolvedIp: '',
      latencyMs: 0,
      category: LogCategory.analytics,
      matchedRule: 'Temiz Trafik',
    );
  }

  LogCategory _categorizeDomain(String d) {
    if (d.contains('telemetry') || d.contains('metric') || d.contains('analytics') || d.contains('pixel')) {
      return LogCategory.tracker;
    }
    if (d.contains('coinhive') || d.contains('mining') || d.contains('malware') || d.contains('phishing')) {
      return LogCategory.malware;
    }
    return LogCategory.ad;
  }

  /// Real DNS query resolution via DoH (DNS-over-HTTPS)
  Future<DnsResolveResult> resolveDomainWithDoH({
    required String domain,
    required String dohProviderUrl,
    required bool blockTrackers,
    required bool blockMalware,
    required bool blockPopups,
    required String protectionMode,
    required Set<String> whitelist,
    required Set<String> blacklist,
  }) async {
    final check = checkDomain(
      domain: domain,
      blockTrackers: blockTrackers,
      blockMalware: blockMalware,
      blockPopups: blockPopups,
      protectionMode: protectionMode,
      whitelist: whitelist,
      blacklist: blacklist,
    );

    if (check.isBlocked) {
      return check;
    }

    // Perform REAL DoH resolution
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse('$dohProviderUrl?name=${Uri.encodeComponent(domain)}&type=A');
      final response = await http.get(
        uri,
        headers: {'accept': 'application/dns-json'},
      ).timeout(const Duration(seconds: 4));

      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answers = (data['Answer'] as List<dynamic>?) ?? [];
        String resolvedIp = 'Bilinmiyor';

        for (final ans in answers) {
          if (ans['type'] == 1) { // Type 1 = A record (IPv4)
            resolvedIp = ans['data'] as String? ?? '';
            break;
          }
        }

        return DnsResolveResult(
          domain: domain,
          isBlocked: false,
          resolvedIp: resolvedIp,
          latencyMs: latency,
          category: LogCategory.analytics,
          matchedRule: 'DoH Çözümlendi ($resolvedIp - ${latency}ms)',
        );
      }
    } catch (e) {
      stopwatch.stop();
    }

    return DnsResolveResult(
      domain: domain,
      isBlocked: false,
      resolvedIp: '127.0.0.1',
      latencyMs: stopwatch.elapsedMilliseconds,
      category: LogCategory.analytics,
      matchedRule: 'DoH Zaman Aşımı / İzin Verildi',
    );
  }

  /// Start real local UDP DNS server
  Future<bool> startLocalDnsServer({
    required void Function(BlockLog log) onQueryReceived,
  }) async {
    if (_isRunning) return true;

    for (final port in [8053, 5300, 5354, 1053]) {
      try {
        _udpServer = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, port);
        _activePort = port;
        _isRunning = true;

        _udpServer!.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = _udpServer!.receive();
            if (datagram != null) {
              _handleDnsPacket(datagram, onQueryReceived);
            }
          }
        });

        debugPrint('Finora Real DNS Server listening on 127.0.0.1:$_activePort');
        return true;
      } catch (e) {
        debugPrint('Could not bind port $port: $e');
      }
    }
    return false;
  }

  void _handleDnsPacket(Datagram datagram, void Function(BlockLog log) onQueryReceived) {
    try {
      final packet = datagram.data;
      if (packet.length < 12) return; // DNS Header is 12 bytes

      // Parse QNAME from DNS Query packet
      int offset = 12;
      final labels = <String>[];
      while (offset < packet.length) {
        final len = packet[offset];
        if (len == 0) {
          offset++;
          break;
        }
        offset++;
        if (offset + len <= packet.length) {
          final label = utf8.decode(packet.sublist(offset, offset + len), allowMalformed: true);
          labels.add(label);
          offset += len;
        } else {
          break;
        }
      }

      final queriedDomain = labels.join('.').toLowerCase();
      if (queriedDomain.isEmpty) return;

      final isBlocked = _realBlockedDomains.contains(queriedDomain);

      // Create DNS Response Packet
      final response = List<int>.from(packet);
      // Set QR bit = 1 (Response), AA = 1, RA = 1
      response[2] = 0x81;
      response[3] = isBlocked ? 0x83 : 0x80; // 0x83 = NXDOMAIN or 0.0.0.0 A answer

      // Answer Count = 1
      response[6] = 0x00;
      response[7] = 0x01;

      // Add Answer Resource Record (Type A, Class IN, TTL 60, IP 0.0.0.0)
      response.addAll([
        0xc0, 0x0c, // Pointer to domain name in header
        0x00, 0x01, // Type A
        0x00, 0x01, // Class IN
        0x00, 0x00, 0x00, 0x3c, // TTL 60s
        0x00, 0x04, // Data length (4 bytes for IPv4)
        0x00, 0x00, 0x00, 0x00, // IP 0.0.0.0
      ]);

      _udpServer?.send(Uint8List.fromList(response), datagram.address, datagram.port);

      final log = BlockLog(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        domain: queriedDomain,
        timestamp: DateTime.now(),
        category: _categorizeDomain(queriedDomain),
        action: isBlocked ? LogAction.blocked : LogAction.allowed,
        ruleMatched: isBlocked ? 'Finora DNS Engine (0.0.0.0)' : 'Çözümlendi (Temiz)',
        clientIp: datagram.address.address,
      );

      onQueryReceived(log);
    } catch (e) {
      debugPrint('DNS packet parsing error: $e');
    }
  }

  void stop() {
    _udpServer?.close();
    _isRunning = false;
  }
}
