import 'package:flutter/material.dart';
import '../services/blocker_service.dart';
import '../theme/finora_theme.dart';
import '../widgets/shield_button.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  final BlockerService service;
  final VoidCallback onNavigateToLogs;

  const DashboardScreen({
    super.key,
    required this.service,
    required this.onNavigateToLogs,
  });

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    }
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    final stats = service.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centerpiece Shield
          ShieldButton(
            isActive: service.isShieldActive,
            onToggle: service.toggleShield,
          ),
          const SizedBox(height: 32),

          // Cyber Stats Grid (Responsive 2 columns)
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
                    title: 'Reklamlar',
                    value: _formatNumber(stats.blockedAds),
                    subtitle: 'Engellenen reklam',
                    icon: Icons.block,
                    accentColor: FinoraColors.red,
                  ),
                  StatCard(
                    title: 'İzleyiciler',
                    value: _formatNumber(stats.blockedTrackers),
                    subtitle: 'Durdurulan takipçi',
                    icon: Icons.track_changes,
                    accentColor: FinoraColors.redLight,
                  ),
                  StatCard(
                    title: 'Tasarruf',
                    value: '${stats.savedBandwidthMb.toStringAsFixed(1)} MB',
                    subtitle: 'Bant genişliği',
                    icon: Icons.data_usage,
                    accentColor: FinoraColors.white,
                  ),
                  StatCard(
                    title: 'Aktif Kural',
                    value: _formatNumber(stats.activeRules),
                    subtitle: 'Filtre veritabanı',
                    icon: Icons.security,
                    accentColor: FinoraColors.textSecondary,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

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
                      onPressed: onNavigateToLogs,
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
                        'Henüz kaydedilmiş trafik yok. Kalkan aktifken görünür.',
                        style: TextStyle(color: FinoraColors.textMuted, fontSize: 13),
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

  Widget _buildModeButton(String mode, String subtitle) {
    final isSelected = service.protectionMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => service.setProtectionMode(mode),
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
