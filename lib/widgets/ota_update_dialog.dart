import 'package:flutter/material.dart';
import '../models/update_info.dart';
import '../services/ota_service.dart';
import '../theme/finora_theme.dart';

class OtaUpdateDialog extends StatefulWidget {
  final OtaService otaService;
  final UpdateInfo updateInfo;

  const OtaUpdateDialog({
    super.key,
    required this.otaService,
    required this.updateInfo,
  });

  static Future<void> show(BuildContext context, OtaService otaService, UpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: !otaService.isDownloading,
      builder: (ctx) => OtaUpdateDialog(otaService: otaService, updateInfo: info),
    );
  }

  @override
  State<OtaUpdateDialog> createState() => _OtaUpdateDialogState();
}

class _OtaUpdateDialogState extends State<OtaUpdateDialog> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.otaService,
      builder: (context, _) {
        final info = widget.updateInfo;
        final ota = widget.otaService;
        final hasUpdate = info.hasUpdate;

        return AlertDialog(
          backgroundColor: FinoraColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: FinoraColors.border),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasUpdate
                      ? FinoraColors.red.withValues(alpha: 0.15)
                      : FinoraColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasUpdate ? Icons.system_update_alt : Icons.verified,
                  color: hasUpdate ? FinoraColors.red : FinoraColors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasUpdate ? 'YENİ SÜRÜM MEVCUT' : 'UYGULAMA GÜNCEL',
                      style: const TextStyle(
                        color: FinoraColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'v${info.latestVersion} (Mevcut: v${OtaService.currentAppVersion})',
                      style: const TextStyle(
                        color: FinoraColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (info.fileName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FinoraColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FinoraColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.download_for_offline, size: 18, color: FinoraColors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  info.fileName,
                                  style: const TextStyle(
                                    color: FinoraColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (info.formattedSize.isNotEmpty)
                          Text(
                            info.formattedSize,
                            style: const TextStyle(
                              color: FinoraColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),

                // Release Notes
                const Text(
                  'Sürüm Notları & Yenilikler:',
                  style: TextStyle(
                    color: FinoraColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FinoraColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FinoraColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      info.releaseNotes.isNotEmpty
                          ? info.releaseNotes
                          : 'Finora Fblocker performans ve güvenlik güncellemesi.',
                      style: const TextStyle(
                        color: FinoraColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Download Progress
                if (ota.isDownloading) ...[
                  LinearProgressIndicator(
                    value: ota.downloadProgress > 0 ? ota.downloadProgress : null,
                    backgroundColor: FinoraColors.card,
                    valueColor: const AlwaysStoppedAnimation<Color>(FinoraColors.red),
                    borderRadius: BorderRadius.circular(6),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(ota.downloadProgress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: FinoraColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        ota.statusMessage,
                        style: const TextStyle(
                          color: FinoraColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: ota.isDownloading ? null : () => Navigator.pop(context),
              child: const Text('Kapat', style: TextStyle(color: FinoraColors.textMuted)),
            ),
            if (info.downloadUrl.isNotEmpty && !ota.isDownloading)
              ElevatedButton.icon(
                onPressed: () async {
                  await ota.downloadAndInstallUpdate();
                },
                icon: const Icon(Icons.download, size: 16),
                label: Text(hasUpdate ? 'Tek Tıkla İndir & Güncelle' : 'Paketi Yeniden İndir'),
              ),
          ],
        );
      },
    );
  }
}
