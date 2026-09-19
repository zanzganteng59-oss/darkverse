import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:darkverse/theme/app_theme.dart';

class AttackCountdownOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final String targetName;

  const AttackCountdownOverlay({
    super.key,
    required this.onComplete,
    this.targetName = "",
  });

  static Future<void> show(BuildContext context, {required VoidCallback onComplete, String targetName = ""}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.bgDeep.withValues(alpha: 0.85),
      builder: (_) => AttackCountdownOverlay(onComplete: onComplete, targetName: targetName),
    );
  }

  @override
  State<AttackCountdownOverlay> createState() => _AttackCountdownOverlayState();
}

class _AttackCountdownOverlayState extends State<AttackCountdownOverlay>
    with TickerProviderStateMixin {
  int _count = 5;
  late AnimationController _cardController;
  late AnimationController _numberController;
  late AnimationController _glowController;
  late AnimationController _shockwaveController;
  late AnimationController _shakeController;
  late Animation<double> _cardEntry;
  late Animation<double> _numberScale;
  late Animation<double> _numberGlow;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _cardEntry = CurvedAnimation(parent: _cardController, curve: Curves.elasticOut);
    _cardController.forward();

    _numberController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _numberScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _numberController, curve: Curves.elasticOut),
    );
    _numberGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _numberController, curve: Curves.easeOut),
    );

    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

    _shockwaveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 50));

    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = 5; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _count = i);
      _numberController.forward(from: 0);
      _shockwaveController.forward(from: 0);
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    for (int i = 0; i < 5; i++) {
      _shakeController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 60));
    }
    if (mounted) {
      Navigator.pop(context);
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _numberController.dispose();
    _glowController.dispose();
    _shockwaveController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shakeX = sin(_shakeController.value * pi * 6) * 10;
        final shakeY = cos(_shakeController.value * pi * 4) * 5;
        return Transform.translate(
          offset: Offset(shakeX, shakeY),
          child: Center(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.targetName.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.coral.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: AppTheme.coral.withValues(alpha: 0.6), width: 1),
                      ),
                      child: Text(
                        widget.targetName.toUpperCase(),
                        style: const TextStyle(color: AppTheme.coral, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                    ),

                  AnimatedBuilder(
                    animation: _shockwaveController,
                    builder: (_, __) {
                      final sw = _shockwaveController.value;
                      return Container(
                        width: 200 + sw * 80,
                        height: 200 + sw * 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.coral.withValues(alpha: (1 - sw) * 0.6),
                            width: 2 - sw * 1.5,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  AnimatedBuilder(
                    animation: Listenable.merge([_numberScale, _glowController, _numberGlow]),
                    builder: (_, __) {
                      final pulse = 1.0 + _glowController.value * 0.08;
                      final glow = _numberGlow.value;
                      return Transform.scale(
                        scale: _numberScale.value * pulse,
                        child: Text(
                          "$_count",
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 96,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: AppTheme.coral.withValues(alpha: glow * 0.8), blurRadius: 30),
                              Shadow(color: AppTheme.peach.withValues(alpha: glow * 0.5), blurRadius: 60),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (_, __) {
                      return Text(
                        "LAUNCHING ATTACK",
                        style: TextStyle(
                          color: AppTheme.coral.withValues(alpha: 0.7 + _glowController.value * 0.3),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                          shadows: [
                            Shadow(color: AppTheme.coral.withValues(alpha: _glowController.value * 0.5), blurRadius: 10),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: 200,
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (_, __) {
                        final progress = (5 - _count) / 5.0;
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: AppTheme.borderSubtle,
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.coral.withValues(alpha: 0.7 + _glowController.value * 0.3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${(progress * 100).toInt()}%",
                              style: AppTheme.caption,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (_, __) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (i) {
                          final active = i < (5 - _count);
                          final dotPulse = (i + _glowController.value * 3) % 1.0;
                          return Container(
                            width: active ? 10 : 6,
                            height: active ? 10 : 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppTheme.coral.withValues(alpha: 0.8 + dotPulse * 0.2)
                                  : AppTheme.textMuted,
                              shape: BoxShape.circle,
                              boxShadow: active
                                  ? [BoxShadow(color: AppTheme.coral.withValues(alpha: 0.4 + dotPulse * 0.3), blurRadius: 8)]
                                  : null,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
  }
}
