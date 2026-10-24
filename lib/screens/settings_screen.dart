import 'package:flutter/material.dart';
import '../services/blocker_service.dart';
import '../services/ota_service.dart';
import '../theme/finora_theme.dart';
import '../widgets/ota_update_dialog.dart';

class SettingsScreen extends StatelessWidget {
  final BlockerService service;
  final OtaService otaService;

  const SettingsScreen({
    super.key,
    required this.service,
    required this.otaService,
  });

  static const List<String> _dnsProviders = [
    'Cloudflare DNS (1.1.1.1)',
    'AdGuard DNS (Varsayılan Filtreli)',
    'Quad9 DNS (9.9.9.9 Tehdit Korumalı)',
    'Google DNS (8.8.8.8)',
    'Özel DNS Sunucusu',
  ];

  Future<void> _checkOta(BuildContext context) async {
    final info = await otaService.checkForUpdates();
    if (context.mounted && info != null) {
      OtaUpdateDialog.show(context, otaService, info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // OTA In-App Update Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FinoraColors.redDark.withValues(alpha: 0.25),
                  FinoraColors.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FinoraColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.system_update_alt, color: FinoraColors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'TEK TIKLA OTA UYGULAMA GÜNCELLEMESİ',
                          style: TextStyle(
                            color: FinoraColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: FinoraColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: FinoraColors.border),
                      ),
                      child: const Text(
                        'v1.0.0',
                        style: TextStyle(color: FinoraColors.white, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fblocker, GitHub Releases sunucularını denetleyerek işletim sisteminize özel paketi (.AppImage, .deb, .apk, .exe, .dmg) uygulama içinden tek tıkla indirip günceller.',
                  style: TextStyle(color: FinoraColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _checkOta(context),
                  icon: const Icon(Icons.cloud_sync, size: 16),
                  label: const Text('Güncellemeleri Şimdi Kontrol Et'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // DNS Section
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
                    Icon(Icons.dns_outlined, color: FinoraColors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'GÜVENLİ DoH DNS YÖNLENDİRME',
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
                DropdownButtonFormField<String>(
                  initialValue: service.dnsProvider,
                  items: _dnsProviders.map((provider) {
                    return DropdownMenuItem(
                      value: provider,
                      child: Text(
                        provider,
                        style: const TextStyle(
                          color: FinoraColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      service.setDnsProvider(val);
                    }
                  },
                  dropdownColor: FinoraColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'DoH DNS Sağlayıcısı',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Aktif Uç Nokta: ${service.dohEndpoint}',
                  style: const TextStyle(color: FinoraColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // System DNS Integration Help
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
                    Icon(Icons.router, color: FinoraColors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'SİSTEMSEL REKLAM ENGELLEME (DNS ENTEGRASYONU)',
                      style: TextStyle(
                        color: FinoraColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fblocker yerel bir DNS sunucusu çalıştırır. Cihazınızın tüm trafiğini filtrelemek için sistem DNS adresini yerel sokete yönlendirebilirsiniz:',
                  style: TextStyle(color: FinoraColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FinoraColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FinoraColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, color: FinoraColors.textMuted, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '127.0.0.1:${service.dnsEngine.activePort}',
                          style: const TextStyle(
                            color: FinoraColors.white,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FinoraColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('DİNLENİYOR', style: TextStyle(color: FinoraColors.green, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // App Settings Section
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
                  'SİSTEM VE BAŞLANGIÇ AYARLARI',
                  style: TextStyle(
                    color: FinoraColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 14),
                _buildSwitchRow(
                  title: 'Sistem Başlangıcında Otomatik Çalıştır',
                  subtitle: 'Cihaz açıldığında arka planda kalkanı devreye alır',
                  value: service.autoStart,
                  onChanged: service.toggleAutoStart,
                ),
                const Divider(height: 22),
                _buildSwitchRow(
                  title: 'Kritik Tehdit Bildirimleri',
                  subtitle: 'Zararlı yazılım veya kimlik avı engellendiğinde uyarır',
                  value: service.notifications,
                  onChanged: service.toggleNotifications,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Maintenance Section
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
                  'VERİ & BAKIM',
                  style: TextStyle(
                    color: FinoraColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: FinoraColors.surface,
                        title: const Text('İstatistikleri Sıfırla'),
                        content: const Text('Canlı engellenen reklam ve sayaç verileri sıfırlanacaktır. Emin misiniz?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                          ElevatedButton(
                            onPressed: () {
                              service.resetStats();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tüm canlı istatistikler sıfırlandı.')),
                              );
                            },
                            child: const Text('Sıfırla'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tüm Sayaçları ve Canlı Verileri Sıfırla'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FinoraColors.red,
                    side: const BorderSide(color: FinoraColors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About & Finora Identity Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: FinoraColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FinoraColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: FinoraColors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'F',
                          style: TextStyle(color: FinoraColors.white, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finora Fblocker',
                          style: TextStyle(color: FinoraColors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          'Versiyon 1.0.0 (Official Release)',
                          style: TextStyle(color: FinoraColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Finora Fblocker, web sitelerinde ve uygulamalardaki reklamları, izleyicileri ve kötü niyetli betikleri engelleyen yüksek performanslı, açık kaynaklı ve çoklu platform destekli yeni nesil reklam engelleyicidir.',
                  style: TextStyle(color: FinoraColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildInfoBadge('Marka', 'Finora'),
                const SizedBox(height: 6),
                _buildInfoBadge('GitHub Deposu', 'https://github.com/Finoraaa/Fblocker.git'),
                const SizedBox(height: 6),
                _buildInfoBadge('Canlı OTA Kaynağı', 'GitHub Releases API (Otomatik Bağlı)'),
                const SizedBox(height: 6),
                _buildInfoBadge('Hedef Platformlar', 'Windows (.exe), Android (.apk), iOS, Linux (.deb, .AppImage), macOS (.dmg)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
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
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: FinoraColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildInfoBadge(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            key,
            style: const TextStyle(
              color: FinoraColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: FinoraColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
