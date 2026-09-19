import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'login_page.dart';

class CyberSplashPage extends StatefulWidget {
  const CyberSplashPage({super.key});

  @override
  State<CyberSplashPage> createState() => _CyberSplashPageState();
}

class _CyberSplashPageState extends State<CyberSplashPage>
    with TickerProviderStateMixin {
  bool _tapped = false;

  late AnimationController _glitchCtrl;
  late AnimationController _matrixCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _letterCtrl;
  late List<Animation<double>> _letterFade;
  late List<Animation<double>> _letterScale;
  late List<Animation<double>> _letterGlow;

  static const String _megatronText = "MEGATRON";
  bool _lettersDone = false;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  final List<_MatrixColumn> _columns = [];
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Generate matrix rain columns
    for (int i = 0; i < 30; i++) {
      _columns.add(_MatrixColumn(
        x: i * 12.0,
        speed: 0.5 + _rand.nextDouble() * 2.0,
        chars: List.generate(8 + _rand.nextInt(12),
            (_) => String.fromCharCode(0x30A0 + _rand.nextInt(96))),
        startY: -_rand.nextDouble() * 400,
      ));
    }

    _glitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _matrixCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Letter-by-letter bass hit animation
    _letterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _letterFade = List.generate(_megatronText.length, (i) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.3).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _letterCtrl, curve: Interval(start, end, curve: Curves.easeOut));
    });

    _letterScale = List.generate(_megatronText.length, (i) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 0),
        TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.8), weight: 35),
        TweenSequenceItem(tween: Tween<double>(begin: 1.8, end: 1.0), weight: 65),
      ]).animate(CurvedAnimation(parent: _letterCtrl, curve: Interval(start, end, curve: Curves.easeOut)));
    });

    _letterGlow = List.generate(_megatronText.length, (i) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 0),
        TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
        TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.3), weight: 80),
      ]).animate(CurvedAnimation(parent: _letterCtrl, curve: Interval(start, end, curve: Curves.easeOut)));
    });

    _letterCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() { _lettersDone = true; });
      }
    });

    // Auto-start letter animation then logo
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _letterCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _logoCtrl.forward();
    });
  }

  void _onTap() {
    if (_tapped) return;
    setState(() => _tapped = true);
    HapticFeedback.heavyImpact();

    // Glitch effect
    _glitchCtrl.repeat();
    Future.delayed(const Duration(milliseconds: 200), () {
      _glitchCtrl.stop();
      _glitchCtrl.reset();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _glitchCtrl.dispose();
    _matrixCtrl.dispose();
    _scanCtrl.dispose();
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _letterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF020A06),
      body: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Matrix rain background
            AnimatedBuilder(
              animation: _matrixCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _MatrixRainPainter(
                  progress: _matrixCtrl.value,
                  columns: _columns,
                ),
              ),
            ),

            // Scanline overlay
            AnimatedBuilder(
              animation: _scanCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _ScanlinePainter(progress: _scanCtrl.value),
              ),
            ),

            // Vignette
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Color(0xCC020A06),
                  ],
                ),
              ),
            ),

            // Center content
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_logoCtrl, _glowCtrl]),
                builder: (_, __) => Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: _buildLogo(),
                  ),
                ),
              ),
            ),

            // Tap hint
            if (!_tapped) _buildTapHint(size),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Terminal bracket
        Text(
          "[ INITIALIZING ]",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF00FF41).withValues(alpha: 0.4 + _glowCtrl.value * 0.3),
            letterSpacing: 4,
            fontFamily: 'ShareTechMono',
          ),
        ),
        const SizedBox(height: 24),
        // Main logo — letter by letter with bass hit
        AnimatedBuilder(
          animation: _letterCtrl,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_megatronText.length, (i) {
              final fade = _letterFade[i].value;
              final scale = _letterScale[i].value;
              final glow = _letterGlow[i].value;
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: fade.clamp(0.0, 1.0),
                  child: Text(
                    _megatronText[i],
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00FF41),
                      fontFamily: 'Orbitron',
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00FF41).withValues(alpha: glow * 0.9),
                          blurRadius: 16 * glow,
                        ),
                        Shadow(
                          color: const Color(0xFF00FF41).withValues(alpha: glow * 0.5),
                          blurRadius: 32 * glow,
                        ),
                        Shadow(
                          color: const Color(0xFF00FF41).withValues(alpha: 0.1),
                          blurRadius: 60,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        // Subtitle — fades in after letters done
        AnimatedOpacity(
          opacity: _lettersDone ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: Text(
            "CYBER SECURITY ACCESS v7.5",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF00FF41).withValues(alpha: 0.5),
              letterSpacing: 4,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Status line
        AnimatedOpacity(
          opacity: _lettersDone ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: Text(
            "DEFENSE SYSTEM ACTIVE",
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF00FF41).withValues(alpha: 0.3),
              letterSpacing: 3,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
        const SizedBox(height: 28),
        // Loading dots
        AnimatedBuilder(
          animation: _glowCtrl,
          builder: (_, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final delay = (i * 0.2);
              final alpha = ((_glowCtrl.value + delay) % 1.0);
              return Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00FF41).withValues(alpha: alpha * 0.6),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTapHint(Size size) {
    return Positioned(
      bottom: size.height * 0.1,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1A14),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFF00FF41).withValues(alpha: _glowCtrl.value * 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                "> AUTHENTICATE_",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00FF41).withValues(alpha: 0.4 + _glowCtrl.value * 0.4),
                  letterSpacing: 3,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  MATRIX RAIN PAINTER
// ══════════════════════════════════════════

class _MatrixColumn {
  final double x;
  final double speed;
  final List<String> chars;
  final double startY;
  _MatrixColumn({
    required this.x,
    required this.speed,
    required this.chars,
    required this.startY,
  });
}

class _MatrixRainPainter extends CustomPainter {
  final double progress;
  final List<_MatrixColumn> columns;
  _MatrixRainPainter({required this.progress, required this.columns});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final col in columns) {
      final yOffset = (col.startY + progress * col.speed * size.height) % (size.height + 400);

      for (int i = 0; i < col.chars.length; i++) {
        final y = yOffset - i * 18.0;
        if (y < -20 || y > size.height + 20) continue;

        final alpha = (1.0 - i / col.chars.length).clamp(0.0, 1.0);

        if (i == 0) {
          // Head character — bright white-green
          paint.color = const Color(0xFFAAFFCC).withValues(alpha: alpha * 0.8);
        } else {
          // Trail — fading green
          paint.color = const Color(0xFF00FF41).withValues(alpha: alpha * 0.3);
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: col.chars[i],
            style: TextStyle(
              color: paint.color,
              fontSize: 13,
              fontFamily: 'ShareTechMono',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(col.x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter old) => true;
}

// ══════════════════════════════════════════
//  SCANLINE PAINTER
// ══════════════════════════════════════════

class _ScanlinePainter extends CustomPainter {
  final double progress;
  _ScanlinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Horizontal scanlines
    paint.strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 3) {
      paint.color = Colors.black.withValues(alpha: 0.06);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Moving scan beam
    final scanY = progress * size.height;
    final gradient = LinearGradient(
      colors: [
        const Color(0xFF00FF41).withValues(alpha: 0.0),
        const Color(0xFF00FF41).withValues(alpha: 0.08),
        const Color(0xFF00FF41).withValues(alpha: 0.0),
      ],
    );
    paint.shader = gradient.createShader(
      Rect.fromCenter(center: Offset(size.width / 2, scanY), width: size.width, height: 40),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width / 2, scanY), width: size.width, height: 40),
      paint,
    );
    paint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter old) => true;
}
