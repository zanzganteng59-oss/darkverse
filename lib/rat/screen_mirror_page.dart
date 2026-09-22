import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'rat_client.dart';
import '../theme/neo.dart';

class ScreenMirrorPage extends StatefulWidget {
  final RatClient client;
  final String deviceId;

  const ScreenMirrorPage({
    super.key,
    required this.client,
    required this.deviceId,
  });

  @override
  State<ScreenMirrorPage> createState() => _ScreenMirrorPageState();
}

class _ScreenMirrorPageState extends State<ScreenMirrorPage> {
  bool _streaming = false;
  bool _pipMode = false;
  Uint8List? _currentFrame;
  String? _prevRaw;

  int _width = 0;
  int _height = 0;
  int _fps = 0;
  int _fpsCount = 0;
  DateTime _fpsLastCheck = DateTime.now();
  DateTime? _lastFrameAt;

  final GlobalKey _frameKey = GlobalKey();
  double _widgetW = 1;
  double _widgetH = 1;

  void Function(Offset)? _frameTouchCallback;

  static const String _kStartCmd = 'start';
  static const String _kStopCmd = 'stop';

  @override
  void initState() {
    super.initState();
    widget.client.addListener(_onClient);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidget());
  }

  @override
  void dispose() {
    widget.client.removeListener(_onClient);
    if (_streaming) _stopStream();
    super.dispose();
  }

  void _onClient() {
    if (!mounted) return;
    final frame = widget.client.frameFor(widget.deviceId, 'screen');
    final raw = frame?['frame']?.toString();
    if (raw == null || raw == _prevRaw) return;
    _prevRaw = raw;

    _fpsCount++;
    _lastFrameAt = DateTime.now();

    final now = DateTime.now();
    if (now.difference(_fpsLastCheck).inSeconds >= 1) {
      setState(() => _fps = _fpsCount);
      _fpsCount = 0;
      _fpsLastCheck = now;
    }

    try {
      final bytes = base64Decode(raw);
      _decodeResolution(bytes);
      setState(() => _currentFrame = bytes);
    } catch (_) {}
  }

  void _decodeResolution(Uint8List bytes) {
    try {
      final codec = ui.instantiateImageCodec(bytes);
      codec.then((c) async {
        final frame = await c.getNextFrame();
        final img = frame.image;
        if (mounted) {
          setState(() {
            _width = img.width;
            _height = img.height;
          });
        }
        img.dispose();
        c.dispose();
      });
    } catch (_) {}
  }

  void _measureWidget() {
    final box = _frameKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      _widgetW = box.size.width;
      _widgetH = box.size.height;
    }
  }

  void _startStream() {
    widget.client.sendCommand(widget.deviceId, 'screen', _kStartCmd);
    widget.client.patchStatus(widget.deviceId, 'screenActive', true);
    setState(() => _streaming = true);
    _toast('Screen mirroring started');
  }

  void _stopStream() {
    widget.client.sendCommand(widget.deviceId, 'screen', _kStopCmd);
    widget.client.patchStatus(widget.deviceId, 'screenActive', false);
    setState(() {
      _streaming = false;
      _currentFrame = null;
      _prevRaw = null;
      _fps = 0;
      _fpsCount = 0;
      _width = 0;
      _height = 0;
    });
    _toast('Screen mirroring stopped', info: true);
  }

  void _onTapDown(TapDownDetails details) {
    if (!_streaming || _currentFrame == null) return;
    _measureWidget();
    final pos = details.localPosition;
    final xRatio = pos.dx / _widgetW;
    final yRatio = pos.dy / _widgetH;
    final touchX = (xRatio * _width).round().clamp(0, _width);
    final touchY = (yRatio * _height).round().clamp(0, _height);
    widget.client.sendCommand(
      widget.deviceId,
      'screen:touch',
      jsonEncode({'x': touchX, 'y': touchY, 'action': 'tap'}),
    );
    _showTouchIndicator(pos);
  }

  void _onPanStart(DragStartDetails details) {
    if (!_streaming || _currentFrame == null) return;
    _measureWidget();
    final pos = details.localPosition;
    final xRatio = pos.dx / _widgetW;
    final yRatio = pos.dy / _widgetH;
    final touchX = (xRatio * _width).round().clamp(0, _width);
    final touchY = (yRatio * _height).round().clamp(0, _height);
    widget.client.sendCommand(
      widget.deviceId,
      'screen:touch',
      jsonEncode({'x': touchX, 'y': touchY, 'action': 'start'}),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_streaming || _currentFrame == null) return;
    _measureWidget();
    final pos = details.localPosition;
    final xRatio = pos.dx / _widgetW;
    final yRatio = pos.dy / _widgetH;
    final touchX = (xRatio * _width).round().clamp(0, _width);
    final touchY = (yRatio * _height).round().clamp(0, _height);
    widget.client.sendCommand(
      widget.deviceId,
      'screen:touch',
      jsonEncode({'x': touchX, 'y': touchY, 'action': 'move'}),
    );
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_streaming || _currentFrame == null) return;
    _measureWidget();
    final vel = details.velocity.pixelsPerSecond;
    final endX = (_width * 0.5).round();
    final endY = (_height * 0.5).round();
    widget.client.sendCommand(
      widget.deviceId,
      'screen:touch',
      jsonEncode({
        'action': 'end',
        'x2': endX,
        'y2': endY,
      }),
    );
  }

  void _showTouchIndicator(Offset pos) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        left: pos.dx - 14,
        top: pos.dy - 14,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Neo.mint.withValues(alpha: 0.4),
              border: Border.all(color: Neo.mint, width: 1.5),
            ),
          ),
        ),
      );
    });
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 350), () {
      entry.remove();
    });
  }

  void _captureScreenshot() {
    if (_currentFrame == null) {
      _toast('No frame to capture', info: true);
      return;
    }
    _toast('Screenshot captured (${_width}x$_height})', info: true);
  }

  void _togglePip() {
    setState(() => _pipMode = !_pipMode);
    _toast(_pipMode ? 'PIP mode ON' : 'PIP mode OFF', info: true);
  }

  void _toast(String msg, {bool error = false, bool info = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg,
            style: const TextStyle(
                fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark)),
        backgroundColor: error ? Neo.coral : info ? Neo.sky : Neo.mint,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final isPortrait = mq.orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Neo.bg,
      body: AnimatedBuilder(
        animation: widget.client,
        builder: (context, _) {
          return _pipMode
              ? _buildPipMode(screenH, isPortrait)
              : _buildFullScreen(screenH, isPortrait);
        },
      ),
    );
  }

  Widget _buildFullScreen(double screenH, bool isPortrait) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(child: _buildFrameArea(screenH, isPortrait)),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildPipMode(double screenH, bool isPortrait) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 60),
              _buildStatusBarCompact(),
              const SizedBox(height: 16),
              _buildTopBar(),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: screenH * 0.3,
          child: GestureDetector(
            onPanUpdate: (d) {},
            child: Container(
              width: 180,
              height: 320,
              decoration: BoxDecoration(
                color: Neo.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Neo.mint, width: 2.5),
                boxShadow: Neo.shadow(offset: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildFrameContent(),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomBar(),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Neo.white,
        border: Border(bottom: BorderSide(color: Neo.textDark, width: 2.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Neo.cream,
                  border: Border.all(color: Neo.textDark, width: 2),
                ),
                child: const Icon(Icons.arrow_back, size: 16, color: Neo.textDark),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _streaming ? Neo.mint : Neo.coral,
                boxShadow: [
                  BoxShadow(
                    color: (_streaming ? Neo.mint : Neo.coral).withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('SCREEN MIRROR',
                style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Neo.textDark)),
            const Spacer(),
            _InfoChip(
              label: '${_width}x$_height',
              color: Neo.sky,
            ),
            const SizedBox(width: 6),
            _InfoChip(
              label: '$_fps FPS',
              color: _fps >= 20 ? Neo.mint : _fps >= 10 ? Neo.peach : Neo.coral,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBarCompact() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Neo.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Neo.textDark, width: 2),
        boxShadow: Neo.shadow(offset: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _streaming ? Neo.mint : Neo.coral,
            ),
          ),
          const SizedBox(width: 8),
          if (_width > 0)
            Text('${_width}x$_height',
                style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 9,
                    color: Neo.sky)),
          const SizedBox(width: 8),
          Text('$_fps FPS',
              style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 9,
                  color: _fps >= 20 ? Neo.mint : Neo.peach)),
          if (_lastFrameAt != null) ...[
            const SizedBox(width: 8),
            Text(_fmtAgo(_lastFrameAt!),
                style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 8,
                    color: Neo.textMuted)),
          ],
        ],
      ),
    );
  }

  String _fmtAgo(DateTime t) {
    final sec = DateTime.now().difference(t).inSeconds;
    if (sec == 0) return 'now';
    return '${sec}s ago';
  }

  Widget _buildFrameArea(double screenH, bool isPortrait) {
    return Container(
      key: _frameKey,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildFrameContent(),
          if (_streaming)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: _onTapDown,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: _TouchOverlayPainter(),
                ),
              ),
            ),
          if (!_streaming && _currentFrame == null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_android,
                      size: 48,
                      color: Neo.mint.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'TAP START TO BEGIN',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        letterSpacing: 3,
                        color: Neo.mint.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Screen frames will appear here',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 9,
                        color: Neo.textMuted.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          if (_streaming && _currentFrame == null)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Neo.mint),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'CONNECTING STREAM...',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: Neo.mint),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: _buildResolutionBadge(),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _buildFpsBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameContent() {
    if (_currentFrame == null) {
      return const SizedBox.expand();
    }
    return Image.memory(
      _currentFrame!,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildResolutionBadge() {
    if (_width == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Neo.sky.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        '${_width}x$_height',
        style: const TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 9,
            color: Neo.sky),
      ),
    );
  }

  Widget _buildFpsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: (_fps >= 20 ? Neo.mint : Neo.peach).withValues(alpha: 0.5),
            width: 1),
      ),
      child: Text(
        '$_fps FPS',
        style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 9,
            color: _fps >= 20 ? Neo.mint : Neo.peach),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Neo.white,
        border: Border(top: BorderSide(color: Neo.textDark, width: 2.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _streaming ? _stopStream : _startStream,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 44,
                  decoration: BoxDecoration(
                    color: _streaming ? Neo.coral : Neo.mint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Neo.textDark, width: 2.5),
                    boxShadow: Neo.shadow(offset: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _streaming ? Icons.stop : Icons.play_arrow,
                        size: 18,
                        color: Neo.textDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _streaming ? 'STOP' : 'START',
                        style: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Neo.textDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _BottomAction(
              icon: Icons.camera_alt,
              color: Neo.sky,
              onTap: _captureScreenshot,
            ),
            const SizedBox(width: 8),
            _BottomAction(
              icon: _pipMode ? Icons.fullscreen : Icons.picture_in_picture,
              color: Neo.lavender,
              onTap: _togglePip,
            ),
            const SizedBox(width: 8),
            _BottomAction(
              icon: Icons.screen_rotation,
              color: Neo.peach,
              onTap: () {
                HapticFeedback.lightImpact();
                _toast('Orientation locked', info: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 9,
                  color: Neo.textMuted,
                  letterSpacing: 1)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Neo.textDark, width: 2.5),
          boxShadow: Neo.shadow(offset: 2),
        ),
        child: Icon(icon, size: 18, color: Neo.textDark),
      ),
    );
  }
}

class _TouchOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle scanline effect
    final paint = Paint()
      ..color = Neo.mint.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
