import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:darkverse/theme/app_theme.dart';

class InstagramDownloaderPage extends StatefulWidget {
  const InstagramDownloaderPage({super.key});

  @override
  State<InstagramDownloaderPage> createState() => _InstagramDownloaderPageState();
}

class _InstagramDownloaderPageState extends State<InstagramDownloaderPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  List<dynamic>? _mediaData;
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

  Future<void> _downloadInstagram() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "URL Instagram tidak boleh kosong.";
        _mediaData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mediaData = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    final encodedUrl = Uri.encodeComponent(url);
    final apiUrl = Uri.parse("https://api.siputzx.my.id/api/d/igdl?url=$encodedUrl");

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          setState(() {
            _mediaData = json['data'];
          });
          _initializeVideoPlayer();
        } else {
          setState(() {
            _errorMessage = "Gagal mengambil data Instagram.";
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
    if (_mediaData != null && _mediaData!.isNotEmpty) {
      final mediaUrl = _mediaData![0]['url'];
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
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
    if (_mediaData == null || _mediaData!.isEmpty) return;

    try {
      final mediaUrl = _mediaData![0]['url'];
      final response = await http.get(Uri.parse(mediaUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/instagram_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles([XFile(file.path)],
        text: 'Video Instagram',
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

  Widget _buildMediaGrid() {
    if (_mediaData == null) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _mediaData!.length,
      itemBuilder: (context, index) {
        final media = _mediaData![index];
        final isVideo = media['type'] == 'video';

        return GestureDetector(
          onTap: () {
            if (isVideo) {
              _playVideo(media['url']);
            }
          },
          child: Container(
            decoration: AppTheme.accentCardDecor(AppTheme.lavender),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    child: isVideo
                        ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          media['thumbnail'] ?? media['url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.bgInput,
                            child: const Icon(Icons.videocam, color: AppTheme.lavender),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDeep.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow, color: AppTheme.textPrimary, size: 16),
                          ),
                        ),
                      ],
                    )
                        : Image.network(
                      media['url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.bgInput,
                        child: const Icon(Icons.photo, color: AppTheme.lavender),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam : Icons.photo,
                        color: AppTheme.lavender,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVideo ? 'Video' : 'Photo',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _playVideo(String videoUrl) {
    _videoController?.dispose();
    _chewieController?.dispose();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Text('INSTAGRAM DOWNLOADER', style: AppTheme.headingM),
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
                        labelText: 'Masukkan URL Instagram',
                        labelStyle: TextStyle(color: AppTheme.lavender),
                        hintText: 'Contoh: https://www.instagram.com/reel/xxx/',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.borderSubtle),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.lavender, width: 2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        filled: true,
                        fillColor: AppTheme.bgInput,
                        prefixIcon: Icon(Icons.camera_alt, color: AppTheme.lavender),
                        suffixIcon: _isLoading
                            ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppTheme.lavender,
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
                        onPressed: _isLoading ? null : _downloadInstagram,
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
                                color: AppTheme.bgDeep,
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

              if (_chewieController != null)
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
                            const Icon(Icons.play_arrow, color: AppTheme.textPrimary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "VIDEO PLAYER",
                              style: AppTheme.headingS.copyWith(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: Chewie(controller: _chewieController!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _shareVideo,
                          style: AppTheme.primaryButton(AppTheme.teal),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share, size: 20, color: AppTheme.bgDeep),
                              SizedBox(width: 8),
                              Text(
                                'SHARE VIDEO',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.bgDeep,
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

              if (_mediaData != null && _chewieController == null)
                Expanded(
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
                            const Icon(Icons.photo_library, color: AppTheme.textPrimary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "MEDIA GALLERY (${_mediaData!.length})",
                              style: AppTheme.headingS.copyWith(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildMediaGrid(),
                      ),
                    ],
                  ),
                ),

              if (_mediaData == null && !_isLoading && _errorMessage == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 80,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Instagram Downloader',
                          style: AppTheme.headingM.copyWith(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Masukkan URL Instagram Reel, Post, atau Story untuk mendownload media',
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
