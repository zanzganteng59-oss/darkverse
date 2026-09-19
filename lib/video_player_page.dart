import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerPage({super.key, required this.videoUrl});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  String? _errorMsg;
  bool _hasError = false;
  double _loadProgress = 0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPlayer();
  }

  void _initPlayer() async {
    setState(() { _loadProgress = 0; _hasError = false; _errorMsg = null; });
    
    // Simulate progress while loading
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (mounted && _loadProgress < 0.9) {
        setState(() => _loadProgress += 0.02);
      }
    });

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: const {
          'Connection': 'keep-alive',
        },
      );
      
      // Add timeout
      await _controller.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout - koneksi lambat');
        },
      );
      
      _progressTimer?.cancel();
      if (mounted) {
        setState(() { _initialized = true; _loadProgress = 1.0; });
        _controller.play();
        _controller.addListener(_onVideoProgress);
      }
    } catch (e) {
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = "Gagal memuat video.\nPastikan koneksi stabil.\n\nError: $e";
        });
      }
    }
  }

  void _onVideoProgress() {
    if (_controller.value.position >= _controller.value.duration && _controller.value.duration.inSeconds > 0) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    if (_initialized) {
      _controller.removeListener(_onVideoProgress);
      _controller.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFFF1744), size: 64),
                      const SizedBox(height: 16),
                      Text(_errorMsg ?? "Error", style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() { _hasError = false; _errorMsg = null; });
                          _initPlayer();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF1744)),
                        child: const Text("Retry", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_initialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _loadProgress,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFFFF1744)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadProgress < 0.3 ? "Mengunduh video..." :
                      _loadProgress < 0.7 ? "Buffering..." : "Hampir siap...",
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${(_loadProgress * 100).toInt()}%",
                      style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Orbitron'),
                    ),
                  ],
                ),
              ),

            if (_initialized && _showControls)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 30),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFFFF1744),
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                                });
                              },
                              child: Icon(
                                _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                color: const Color(0xFFFF1744), size: 40,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "${_format(_controller.value.position)} / ${_format(_controller.value.duration)}",
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Orbitron'),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.close, color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_showControls)
              Positioned(
                top: 16, left: 16,
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
