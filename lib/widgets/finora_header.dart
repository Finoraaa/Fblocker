import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/finora_theme.dart';

class FinoraHeader extends StatelessWidget {
  final bool isShieldActive;

  const FinoraHeader({
    super.key,
    required this.isShieldActive,
  });

  String _getPlatformName() {
    if (kIsWeb) return 'WEB';
    if (Platform.isLinux) return 'LINUX';
    if (Platform.isWindows) return 'WINDOWS';
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    if (Platform.isMacOS) return 'MACOS';
    return 'CROSS-PLATFORM';
  }

  @override
  Widget build(BuildContext context) {
    final platformName = _getPlatformName();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: FinoraColors.surface,
        border: Border(
          bottom: BorderSide(color: FinoraColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Finora Brand Icon & Title
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FinoraColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isShieldActive ? FinoraColors.red : FinoraColors.border,
                width: 1.5,
              ),
              boxShadow: isShieldActive
                  ? [
                      BoxShadow(
                        color: FinoraColors.red.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                'F',
                style: TextStyle(
                  color: isShieldActive ? FinoraColors.red : FinoraColors.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'FINORA',
                    style: TextStyle(
                      color: FinoraColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: FinoraColors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BLOCKER',
                      style: TextStyle(
                        color: FinoraColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Ultra Fast Cyber Shield & Privacy Guard',
                style: TextStyle(
                  color: FinoraColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Platform Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: FinoraColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FinoraColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isShieldActive ? FinoraColors.green : FinoraColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  platformName,
                  style: const TextStyle(
                    color: FinoraColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
