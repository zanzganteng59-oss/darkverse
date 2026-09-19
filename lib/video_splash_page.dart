import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

class VideoSplashPage extends StatefulWidget {
  final Map<String, dynamic> dashboardArgs;

  const VideoSplashPage({super.key, required this.dashboardArgs});

  @override
  State<VideoSplashPage> createState() => _VideoSplashPageState();
}

class _VideoSplashPageState extends State<VideoSplashPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _navigated = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Palet warna Neobrutalism
  static const Color kNeoYellow = Color(0xFFFFE74C);
  static const Color kNeoBlack = Color(0xFF1A1A1A);
  static const Color kNeoWhite = Color(0xFFFFFFFF);
  static const Color kNeoRed = Color(0xFFFF3B30);
  static const Color kNeoBlue = Color(0xFF007AFF);
  static const Color kNeoOrange = Color(0xFFFF9F0A);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _initVideo();
  }

  void _initVideo() async {
    _controller = VideoPlayerController.asset('assets/videos/login.mp4');

    try {
      await _controller.initialize();
      await _controller.setVolume(1.0);
      await _controller.setLooping(false);

      _controller.addListener(_onVideoEnd);
      await _controller.play();

      if (mounted) {
        setState(() => _isInitialized = true);
        _fadeController.forward();
      }
    } catch (e) {
      _goToDashboard();
    }
  }

  void _onVideoEnd() {
    if (!_navigated &&
        _controller.value.position >= _controller.value.duration &&
        _controller.value.duration > Duration.zero) {
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    if (_navigated) return;
    _navigated = true;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            username: widget.dashboardArgs['username'],
            password: widget.dashboardArgs['password'],
            role: widget.dashboardArgs['role'],
            sessionKey: widget.dashboardArgs['key'],
            expiredDate: widget.dashboardArgs['expiredDate'],
            listBug: List<Map<String, dynamic>>.from(
              widget.dashboardArgs['listBug'] ?? [],
            ),
            listDoos: List<Map<String, dynamic>>.from(
              widget.dashboardArgs['listDoos'] ?? [],
            ),
            news: List<Map<String, dynamic>>.from(
              widget.dashboardArgs['news'] ?? [],
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoEnd);
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNeoBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ============================================================
          // LAPISAN 0 — Background dengan pola grid neobrutalism
          // ============================================================
          Container(
            color: kNeoBlack,
            child: CustomPaint(painter: NeoGridPainter()),
          ),

          // ============================================================
          // LAPISAN 1 — Video full layar dengan border neobrutalism
          // ============================================================
          if (_isInitialized)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kNeoYellow, width: 6),
                  boxShadow: const [
                    BoxShadow(
                      color: kNeoYellow,
                      offset: Offset(8, 8),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ),
            )
          else
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: kNeoBlack,
                  border: Border.all(color: kNeoYellow, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: kNeoYellow,
                      offset: Offset(6, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(kNeoYellow),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'LOADING...',
                      style: TextStyle(
                        color: kNeoWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        fontFamily: 'Courier',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'DON\'T PANIC',
                      style: TextStyle(
                        color: kNeoYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ============================================================
          // LAPISAN 2 — Overlay diagonal stripes (gaya brutalism)
          // ============================================================
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                backgroundBlendMode: BlendMode.overlay,
              ),
              child: CustomPaint(
                painter: NeoDiagonalPainter(),
                size: MediaQuery.of(context).size,
              ),
            ),
          ),

          // ============================================================
          // LAPISAN 3 — Brand "ORBITION" gaya neobrutalism
          // ============================================================
          Positioned(
            left: 24,
            right: 24,
            bottom: 120,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blok warna aksen neobrutalism
                    Container(
                      width: 60,
                      height: 8,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: kNeoYellow,
                    ),
                    // Teks utama dengan efek shadow khas neobrutalism
                    Stack(
                      children: [
                        Text(
                          'MEGATRON',
                          style: TextStyle(
                            color: kNeoBlack,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            height: 1.0,
                            fontFamily: 'Courier',
                          ),
                        ),
                        Text(
                          'MEGATRON',
                          style: TextStyle(
                            color: kNeoWhite,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            height: 1.0,
                            fontFamily: 'Courier',
                            shadows: const [
                              Shadow(
                                color: kNeoYellow,
                                offset: Offset(6, 6),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tagline dengan gaya brutal
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: kNeoRed,
                      child: Text(
                        'SISTEM TERINTEGRASI • v2.0',
                        style: TextStyle(
                          color: kNeoWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Label versi / status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      color: kNeoBlue,
                      child: Text(
                        '● ACTIVE SESSION',
                        style: TextStyle(
                          color: kNeoWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // LAPISAN 4 — Tombol "SKIP" gaya neobrutalism
          // ============================================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _goToDashboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kNeoYellow,
                    border: Border.all(color: kNeoBlack, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: kNeoBlack,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SKIP',
                        style: TextStyle(
                          color: kNeoBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontFamily: 'Courier',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: kNeoBlack,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // LAPISAN 5 — Progress bar gaya neobrutalism
          // ============================================================
          if (_isInitialized)
            Positioned(
              left: 24,
              right: 24,
              bottom: 80,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    final duration = value.duration.inMilliseconds;
                    final position = value.position.inMilliseconds;
                    final progress = duration > 0
                        ? (position / duration).clamp(0.0, 1.0)
                        : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PROGRESS',
                              style: TextStyle(
                                color: kNeoWhite.withOpacity(0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                fontFamily: 'Courier',
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                color: kNeoYellow,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Progress bar dengan style neobrutalism
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: kNeoWhite,
                            border: Border.all(color: kNeoBlack, width: 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width:
                                    progress *
                                    (MediaQuery.of(context).size.width - 48),
                                height: 12,
                                color: kNeoYellow,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // ============================================================
          // LAPISAN 6 — Dekorasi sudut neobrutalism
          // ============================================================
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: kNeoYellow, width: 4),
                  left: BorderSide(color: kNeoYellow, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: kNeoYellow, width: 4),
                  right: BorderSide(color: kNeoYellow, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: kNeoYellow, width: 4),
                  right: BorderSide(color: kNeoYellow, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: kNeoYellow, width: 4),
                  left: BorderSide(color: kNeoYellow, width: 4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CUSTOM PAINTER — Grid background gaya neobrutalism
// ============================================================
class NeoGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Tambahan blok warna acak
    final blockPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(50, 50, 80, 80), blockPaint);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 130, size.height - 130, 80, 80),
      blockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// CUSTOM PAINTER — Diagonal stripes overlay
// ============================================================
class NeoDiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0x0AFFFFFF) // Transparan tipis
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const spacing = 60.0;
    final double diagonalLength = size.width + size.height;

    for (
      double offset = -diagonalLength;
      offset < diagonalLength;
      offset += spacing
    ) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
