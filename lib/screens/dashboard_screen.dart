import 'package:flutter/material.dart';
import '../services/blocker_service.dart';
import '../services/ota_service.dart';
import '../services/real_dns_engine.dart';
import '../theme/finora_theme.dart';
import '../widgets/ota_update_dialog.dart';
import '../widgets/shield_button.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  final BlockerService service;
  final OtaService otaService;
  final VoidCallback onNavigateToLogs;

  const DashboardScreen({
    super.key,
    required this.service,
    required this.otaService,
    required this.onNavigateToLogs,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _testDomainController = TextEditingController(text: 'googleads.g.doubleclick.net');
  bool _isTestingDomain = false;
  DnsResolveResult? _lastTestResult;

  @override
  void dispose() {
    _testDomainController.dispose();
    super.dispose();
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    }
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }

  Future<void> _runSingleTest(String domain) async {
    setState(() {
      _isTestingDomain = true;
      _testDomainController.text = domain;
    });

    final res = await widget.service.testRealDomain(domain);

    setState(() {
      _isTestingDomain = false;
      _lastTestResult = res;
    });
  }

  Future<void> _checkOta() async {
    final info = await widget.otaService.checkForUpdates();
    if (!mounted) return;
    if (info != null) {
      OtaUpdateDialog.show(context, widget.otaService, info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final ota = widget.otaService;
    final stats = service.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // OTA Update Banner / Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: FinoraColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FinoraColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: FinoraColors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cloud_sync, color: FinoraColors.red, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'OTA GÜNCELLEME SİSTEMİ',
                              style: TextStyle(
                                color: FinoraColors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: FinoraColors.card,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: FinoraColors.border),
                            ),
                            child: const Text(
                              'v${OtaService.currentAppVersion}',
                              style: TextStyle(color: FinoraColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ota.statusMessage.isNotEmpty
                            ? ota.statusMessage
                            : 'GitHub Releases sunucusu ile tek tıkla güncelleme.',
                        style: const TextStyle(color: FinoraColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: ota.isChecking ? null : _checkOta,
                  icon: ota.isChecking
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh, size: 14),
                  label: Text(ota.isChecking ? 'Kontrol...' : 'Güncelleme Ara'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Centerpiece Shield
          ShieldButton(
            isActive: service.isShieldActive,
            onToggle: service.toggleShield,
          ),
          const SizedBox(height: 12),

          // Real Local DNS Server Status Pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: FinoraColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FinoraColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    service.isShieldActive ? Icons.dns : Icons.dns_outlined,
                    size: 14,
                    color: service.isShieldActive ? FinoraColors.green : FinoraColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    service.isShieldActive
                        ? 'Yerel DNS Motoru: 127.0.0.1:${service.dnsEngine.activePort} (Aktif)'
                        : 'DNS Motoru Kapalı',
                    style: const TextStyle(
                      color: FinoraColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Live Cyber Stats Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 1.5 : 1.35,
                children: [
                  StatCard(
                    title: 'Engellenen Reklam',
                    value: _formatNumber(stats.blockedAds),
                    subtitle: 'Canlı engelleme',
                    icon: Icons.block,
                    accentColor: FinoraColors.red,
                  ),
                  StatCard(
                    title: 'İzleyici Kalkanı',
                    value: _formatNumber(stats.blockedTrackers),
                    subtitle: 'Durdurulan takipçi',
                    icon: Icons.track_changes,
                    accentColor: FinoraColors.redLight,
                  ),
                  StatCard(
                    title: 'Tasarruf',
                    value: '${stats.savedBandwidthMb.toStringAsFixed(2)} MB',
                    subtitle: 'Bant genişliği',
                    icon: Icons.data_usage,
                    accentColor: FinoraColors.white,
                  ),
                  StatCard(
                    title: 'Aktif Kural',
                    value: _formatNumber(stats.activeRules),
                    subtitle: 'Gerçek kural havuzu',
                    icon: Icons.security,
                    accentColor: FinoraColors.textSecondary,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // REAL-TIME LIVE QUERY & SECURITY BENCHMARK TOOL
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: FinoraColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FinoraColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.radar, color: FinoraColors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CANLI ETKİ ALANI TESTİ & ANALİZ',
                              style: TextStyle(
                                color: FinoraColors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: service.runLiveSecurityBenchmark,
                      icon: const Icon(Icons.flash_on, size: 14),
                      label: const Text('6x Hızlı Test'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FinoraColors.red,
                        side: const BorderSide(color: FinoraColors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Herhangi bir web sitesi veya reklam etki alanını girin; motorumuz DoH üzerinden canlı sorgulayıp engelleme sonucunu dönsün:',
                  style: TextStyle(color: FinoraColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Query Input & Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _testDomainController,
                        decoration: const InputDecoration(
                          hintText: 'Örn: doubleclick.net veya wikipedia.org',
                          prefixIcon: Icon(Icons.search, color: FinoraColors.textMuted, size: 18),
                        ),
                        onSubmitted: (v) => _runSingleTest(v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isTestingDomain ? null : () => _runSingleTest(_testDomainController.text),
                      child: _isTestingDomain
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Canlı Test Et'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick Pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildQuickTestPill('googleads.g.doubleclick.net'),
                    _buildQuickTestPill('adservice.google.com'),
                    _buildQuickTestPill('c.amazon-adsystem.com'),
                    _buildQuickTestPill('wikipedia.org'),
                    _buildQuickTestPill('github.com'),
                  ],
                ),

                // Last Result Card
                if (_lastTestResult != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FinoraColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _lastTestResult!.isBlocked ? FinoraColors.red : FinoraColors.green,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _lastTestResult!.isBlocked ? Icons.block : Icons.check_circle,
                          color: _lastTestResult!.isBlocked ? FinoraColors.red : FinoraColors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lastTestResult!.domain,
                                style: const TextStyle(
                                  color: FinoraColors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _lastTestResult!.matchedRule,
                                style: const TextStyle(color: FinoraColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _lastTestResult!.isBlocked
                                    ? FinoraColors.red.withValues(alpha: 0.15)
                                    : FinoraColors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _lastTestResult!.isBlocked ? 'ENGELLENDİ' : 'GEÇİRİLDİ',
                                style: TextStyle(
                                  color: _lastTestResult!.isBlocked ? FinoraColors.red : FinoraColors.green,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_lastTestResult!.latencyMs} ms',
                              style: const TextStyle(
                                color: FinoraColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Protection Mode Selection
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: FinoraColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FinoraColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: FinoraColors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'KORUMA SEVİYESİ',
                      style: TextStyle(
                        color: FinoraColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildModeButton('Standart', 'Dengeli & Hızlı'),
                    const SizedBox(width: 10),
                    _buildModeButton('Agresif', 'Maksimum Gizlilik'),
                    const SizedBox(width: 10),
                    _buildModeButton('Siber', 'Tehdit Kalkanı'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Security Toggles
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: FinoraColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FinoraColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HIZLI KALKAN AYARLARI',
                  style: TextStyle(
                    color: FinoraColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                _buildToggleRow(
                  title: 'Gizlilik ve İzleyici Engelleme',
                  subtitle: 'Analitik ve profil çıkarma servislerini durdurur',
                  value: service.blockTrackers,
                  onChanged: service.toggleBlockTrackers,
                ),
                const Divider(height: 20),
                _buildToggleRow(
                  title: 'Zararlı Yazılım ve Oltalama Koruması',
                  subtitle: 'Tehlikeli etki alanlarını ve fidye yazılımlarını engeller',
                  value: service.blockMalware,
                  onChanged: service.toggleBlockMalware,
                ),
                const Divider(height: 20),
                _buildToggleRow(
                  title: 'Pop-Up ve Yanıltıcı Reklamlar',
                  subtitle: 'İstenmeyen açılır pencereleri ve yönlendirmeleri keser',
                  value: service.blockPopups,
                  onChanged: service.toggleBlockPopups,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recent Activity Preview
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: FinoraColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FinoraColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SON ENGELLEME AKTİVİTESİ',
                      style: TextStyle(
                        color: FinoraColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onNavigateToLogs,
                      style: TextButton.styleFrom(
                        foregroundColor: FinoraColors.red,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        children: [
                          Text('Tümünü Gör', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 11),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (service.logs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Henüz kaydedilmiş trafik yok. Canlı test yapın veya yerel DNS üzerinden istek gönderin.',
                        style: TextStyle(color: FinoraColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...service.logs.take(3).map((log) {
                    final isBlocked = log.action.name == 'blocked';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: FinoraColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FinoraColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isBlocked ? Icons.block : Icons.check_circle_outline,
                            size: 16,
                            color: isBlocked ? FinoraColors.red : FinoraColors.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              log.domain,
                              style: const TextStyle(
                                color: FinoraColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isBlocked
                                  ? FinoraColors.red.withValues(alpha: 0.15)
                                  : FinoraColors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isBlocked ? 'ENGELLENDİ' : 'GEÇİRİLDİ',
                              style: TextStyle(
                                color: isBlocked ? FinoraColors.red : FinoraColors.green,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTestPill(String domain) {
    return GestureDetector(
      onTap: () => _runSingleTest(domain),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: FinoraColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: FinoraColors.border),
        ),
        child: Text(
          domain,
          style: const TextStyle(color: FinoraColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildModeButton(String mode, String subtitle) {
    final isSelected = widget.service.protectionMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.service.setProtectionMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? FinoraColors.red.withValues(alpha: 0.12) : FinoraColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? FinoraColors.red : FinoraColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                mode,
                style: TextStyle(
                  color: isSelected ? FinoraColors.white : FinoraColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? FinoraColors.redLight : FinoraColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FinoraColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: FinoraColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
