import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:darkverse/theme/app_theme.dart';

class TiktokDownloaderPage extends StatefulWidget {
  const TiktokDownloaderPage({super.key});

  @override
  State<TiktokDownloaderPage> createState() => _TiktokDownloaderPageState();
}

class _TiktokDownloaderPageState extends State<TiktokDownloaderPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _videoData;
  String? _errorMessage;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void dispose() {
    _urlController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _downloadTiktok() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "URL TikTok tidak boleh kosong.";
        _videoData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoData = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    final apiUrl = Uri.parse("https://api.siputzx.my.id/api/d/tiktok?url=$url");

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          setState(() {
            _videoData = json['data'];
          });
          _initializeVideoPlayer();
        } else {
          setState(() {
            _errorMessage = "Gagal mengambil data TikTok.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal terhubung ke server.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeVideoPlayer() {
    if (_videoData?['urls'] != null && _videoData!['urls'].isNotEmpty) {
      final videoUrl = _videoData!['urls'][0];
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: true,
              looping: false,
              showControls: true,
              materialProgressColors: ChewieProgressColors(
                playedColor: AppTheme.lavender,
                handleColor: AppTheme.teal,
                backgroundColor: AppTheme.textMuted.withValues(alpha: 0.3),
                bufferedColor: AppTheme.textMuted.withValues(alpha: 0.2),
              ),
            );
          });
        });
    }
  }

  Future<void> _shareVideo() async {
    if (_videoData?['urls'] == null || _videoData!['urls'].isEmpty) return;

    try {
      final videoUrl = _videoData!['urls'][0];
      final response = await http.get(Uri.parse(videoUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tiktok_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles([XFile(file.path)],
        text: 'Video TikTok dari: ${_videoData!['metadata']?['creator'] ?? 'Unknown'}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e', style: const TextStyle(color: AppTheme.textPrimary)),
          backgroundColor: AppTheme.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Text('TIKTOK DOWNLOADER', style: AppTheme.headingM),
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecor(),
                child: Column(
                  children: [
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Masukkan URL TikTok',
                        labelStyle: TextStyle(color: AppTheme.teal),
                        hintText: 'Contoh: https://vt.tiktok.com/xxx/',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.borderSubtle),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.teal, width: 2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        filled: true,
                        fillColor: AppTheme.bgInput,
                        prefixIcon: Icon(Icons.link, color: AppTheme.teal),
                        suffixIcon: _isLoading
                            ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppTheme.teal,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _downloadTiktok,
                        style: AppTheme.primaryButton(AppTheme.lavender),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isLoading ? Icons.hourglass_top : Icons.download, size: 20, color: AppTheme.bgDeep),
                            const SizedBox(width: 8),
                            Text(
                              _isLoading ? 'PROSES...' : 'DOWNLOAD',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.bgDeep
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.accentCardDecor(AppTheme.coral),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.coral),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.coral, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              if (_videoData != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecor(),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient(AppTheme.lavender),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.videocam, color: AppTheme.textPrimary, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      "VIDEO PREVIEW",
                                      style: AppTheme.headingS.copyWith(color: AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (_chewieController != null)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    border: Border.all(color: AppTheme.borderSubtle),
                                    boxShadow: AppTheme.softGlow(AppTheme.lavender),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    child: AspectRatio(
                                      aspectRatio: _videoController!.value.aspectRatio,
                                      child: Chewie(controller: _chewieController!),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgInput,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    border: Border.all(color: AppTheme.borderSubtle),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const CircularProgressIndicator(color: AppTheme.teal),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Loading video...',
                                          style: TextStyle(color: AppTheme.teal, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 16),

                              if (_videoData?['metadata'] != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgInput,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    border: Border.all(color: AppTheme.borderSubtle),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _videoData!['metadata']['title'] ?? 'No Title',
                                        style: AppTheme.headingM.copyWith(fontSize: 16),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, color: AppTheme.teal, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Creator: ${_videoData!['metadata']['creator'] ?? 'Unknown'}',
                                              style: AppTheme.bodyL,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _shareVideo,
                                  style: AppTheme.primaryButton(AppTheme.teal),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.share, size: 20, color: AppTheme.bgDeep),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'SHARE VIDEO',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.bgDeep
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_videoData == null && !_isLoading && _errorMessage == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library,
                          size: 80,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'TikTok Downloader',
                          style: AppTheme.headingM.copyWith(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Masukkan URL TikTok untuk mendownload video',
                            style: AppTheme.bodyL,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
