import 'package:flutter/material.dart';
import '../theme/finora_theme.dart';

class ShieldButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const ShieldButton({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  @override
  State<ShieldButton> createState() => _ShieldButtonState();
}

class _ShieldButtonState extends State<ShieldButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ShieldButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: widget.onToggle,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = active ? _pulseAnimation.value : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FinoraColors.surface,
                  border: Border.all(
                    color: active ? FinoraColors.red : FinoraColors.border,
                    width: 3,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: FinoraColors.red.withValues(alpha: 0.4),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: FinoraColors.redDark.withValues(alpha: 0.2),
                            blurRadius: 60,
                            spreadRadius: 8,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                          ),
                        ],
                ),
                child: Center(
                  child: Container(
                    width: 136,
                    height: 136,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: active
                            ? [
                                FinoraColors.redDark.withValues(alpha: 0.4),
                                FinoraColors.card,
                              ]
                            : [
                                FinoraColors.cardHover,
                                FinoraColors.card,
                              ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        active ? Icons.shield : Icons.shield_outlined,
                        size: 64,
                        color: active ? FinoraColors.red : FinoraColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          // Status Text
          Text(
            active ? 'FBLOCKER KORUMA AKTİF' : 'KORUMA DEVRE DIŞI',
            style: TextStyle(
              color: active ? FinoraColors.white : FinoraColors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            active
                ? 'Tüm reklamlar, izleyiciler ve zararlı bağlantılar engelleniyor'
                : 'Cihazınız korumasız. Başlatmak için kalkana dokunun',
            style: const TextStyle(
              color: FinoraColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
