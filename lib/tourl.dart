import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:darkverse/theme/app_theme.dart';

class CatboxUploaderPage extends StatefulWidget {
  final String username;
  final String role;
  final int totalTools;

  const CatboxUploaderPage({
    super.key,
    required this.username,
    required this.role,
    this.totalTools = 11,
  });

  @override
  State<CatboxUploaderPage> createState() => _CatboxUploaderPageState();
}

class _CatboxUploaderPageState extends State<CatboxUploaderPage> {
  File? _selectedFile;
  String? _fileName;
  String? _fileSize;
  String? _fileType;
  String? _uploadedUrl;
  bool _isUploading = false;
  String _uploadStatus = "";
  double _uploadProgress = 0.0;

  final TextEditingController _urlController = TextEditingController();

  static const int maxFileSizeMB = 50;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.photos.request();
      await Permission.videos.request();
      await Permission.audio.request();
    }
  }

  Future<void> _pickMedia() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? result = await showDialog<XFile>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          title: Text("Pilih Media", style: AppTheme.headingM),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.sky),
                title: Text("Gallery", style: AppTheme.bodyL),
                onTap: () async { final XFile? picked = await picker.pickImage(source: ImageSource.gallery); Navigator.pop(context, picked); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppTheme.mint),
                title: Text("Camera", style: AppTheme.bodyL),
                onTap: () async { final XFile? picked = await picker.pickImage(source: ImageSource.camera); Navigator.pop(context, picked); },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: AppTheme.peach),
                title: Text("Video", style: AppTheme.bodyL),
                onTap: () async { final XFile? picked = await picker.pickVideo(source: ImageSource.gallery); Navigator.pop(context, picked); },
              ),
            ],
          ),
        ),
      );

      if (result != null) {
        final file = File(result.path);
        final sizeInBytes = await file.length();
        final sizeInMB = sizeInBytes / (1024 * 1024);
        if (sizeInMB > maxFileSizeMB) {
          _showSnackbar("File terlalu besar! Maksimal $maxFileSizeMB MB", isError: true);
          return;
        }
        setState(() {
          _selectedFile = file;
          _fileName = result.name;
          _fileSize = "${sizeInMB.toStringAsFixed(2)} MB";
          _fileType = result.path.split('.').last.toUpperCase();
          _uploadedUrl = null;
          _uploadStatus = "";
          _uploadProgress = 0.0;
        });
      }
    } catch (e) {
      _showSnackbar("Gagal memilih file: $e", isError: true);
    }
  }

  Future<void> _uploadToCatbox() async {
    if (_selectedFile == null) { _showSnackbar("Pilih media terlebih dahulu!", isError: true); return; }
    setState(() { _isUploading = true; _uploadStatus = "Mengupload file..."; _uploadProgress = 0.2; });
    try {
      final uri = Uri.parse("https://catbox.moe/user/api.php");
      final request = http.MultipartRequest("POST", uri);
      request.fields['reqtype'] = 'fileupload';
      request.fields['userhash'] = '';
      final fileStream = http.ByteStream(_selectedFile!.openRead());
      final fileLength = await _selectedFile!.length();
      final multipartFile = http.MultipartFile('fileToUpload', fileStream, fileLength, filename: _fileName);
      request.files.add(multipartFile);
      setState(() => _uploadProgress = 0.5);
      final response = await request.send().timeout(const Duration(minutes: 5), onTimeout: () { throw Exception("Upload timeout (maksimal 5 menit)"); });
      setState(() => _uploadProgress = 0.8);
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200 && responseBody.isNotEmpty) {
        final url = responseBody.trim();
        if (url.startsWith("http")) {
          setState(() { _uploadedUrl = url; _urlController.text = url; _uploadStatus = "Upload berhasil!"; _uploadProgress = 1.0; _isUploading = false; });
          _showSnackbar("Upload berhasil! URL siap digunakan", isError: false);
        } else {
          throw Exception("API Error: $responseBody");
        }
      } else {
        throw Exception("Gagal upload: ${response.statusCode}");
      }
    } catch (e) {
      setState(() { _uploadStatus = "Error: ${e.toString()}"; _isUploading = false; _uploadProgress = 0.0; });
      _showSnackbar("Upload gagal: ${e.toString()}", isError: true);
    }
  }

  void _copyToClipboard() {
    if (_uploadedUrl == null || _uploadedUrl!.isEmpty) { _showSnackbar("Tidak ada URL untuk disalin", isError: true); return; }
    Clipboard.setData(ClipboardData(text: _uploadedUrl!));
    _showSnackbar("URL berhasil disalin!", isError: false);
  }

  void _shareUrl() {
    if (_uploadedUrl == null || _uploadedUrl!.isEmpty) { _showSnackbar("Tidak ada URL untuk dibagikan", isError: true); return; }
    Share.share("Upload Media ke URI\n\nURI: $_uploadedUrl\n\nUpload by: ${widget.username}\nRole: ${widget.role}\nTools: ${widget.totalTools} Modules\n\nUpload via Prime Vision", subject: "Upload Media URI");
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null; _fileName = null; _fileSize = null; _fileType = null;
      _uploadedUrl = null; _urlController.clear(); _uploadStatus = ""; _uploadProgress = 0.0;
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: isError ? AppTheme.coral : AppTheme.sky, duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
    );
  }

  String _getFileIcon() {
    if (_fileType == null) return '📁';
    final type = _fileType!.toLowerCase();
    if (type.contains('jpg') || type.contains('jpeg') || type.contains('png') || type.contains('gif')) return '🖼️';
    if (type.contains('mp4') || type.contains('mov') || type.contains('avi')) return '🎬';
    if (type.contains('mp3') || type.contains('wav') || type.contains('flac')) return '🎵';
    if (type.contains('pdf')) return '📄';
    if (type.contains('zip') || type.contains('rar') || type.contains('7z')) return '🗜️';
    if (type.contains('apk') || type.contains('exe')) return '📦';
    return '📎';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("UPLOAD MEDIA KE URI", style: AppTheme.headingM),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 16),
            _buildCategorySection(),
            const SizedBox(height: 16),
            _buildFilePreviewSection(),
            const SizedBox(height: 16),
            _buildResultSection(),
            const SizedBox(height: 16),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.accentCardDecor(AppTheme.sky).copyWith(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Column(
        children: [
          Text("Upload Media ke URI", style: AppTheme.headingL),
          const SizedBox(height: 8),
          Text("${_fileSize ?? '311.17 KB'}", style: AppTheme.bodyL),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("KATEGORI MENU", style: AppTheme.label.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text("Pilih kategori menu yang Anda butuhkan.", style: AppTheme.bodyL),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.sky.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text("${widget.totalTools} Modules", style: AppTheme.headingS.copyWith(color: AppTheme.sky)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreviewSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.sky.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image_rounded, color: AppTheme.sky, size: 20),
              ),
              const SizedBox(width: 12),
              Text("Pratinjau Media", style: AppTheme.headingM),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            width: double.infinity,
            decoration: AppTheme.inputDecor(),
            child: _selectedFile != null
                ? _buildMediaPreview()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_rounded, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 8),
                      Text("Belum ada file dipilih", style: AppTheme.bodyM),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          if (_selectedFile != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgInput,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Row(
                children: [
                  Text(_getFileIcon(), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fileName ?? "Unknown", style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("$_fileSize • $_fileType", style: AppTheme.caption),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearSelection,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.coral.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, color: AppTheme.coral, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickMedia,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: AppTheme.accentCardDecor(AppTheme.sky),
              child: Center(child: Text("Pilih Media", style: AppTheme.headingS)),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedFile != null)
            GestureDetector(
              onTap: _isUploading ? null : _uploadToCatbox,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: AppTheme.cardDecor(),
                child: Center(
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.sky)),
                            const SizedBox(width: 8),
                            Text("${(_uploadProgress * 100).toInt()}%", style: AppTheme.headingS.copyWith(color: AppTheme.sky)),
                          ],
                        )
                      : Text("UPLOAD KE CATBOX", style: AppTheme.headingS.copyWith(color: AppTheme.sky)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    final ext = _fileType?.toLowerCase() ?? '';
    final isImage = ext.contains('jpg') || ext.contains('jpeg') || ext.contains('png') || ext.contains('gif') || ext.contains('webp');
    final isVideo = ext.contains('mp4') || ext.contains('mov') || ext.contains('avi') || ext.contains('mkv');
    final isAudio = ext.contains('mp3') || ext.contains('wav') || ext.contains('flac') || ext.contains('ogg');

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        child: Image.file(_selectedFile!, width: double.infinity, height: 150, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.broken_image_rounded, size: 48, color: AppTheme.textMuted),
            const Text("Tidak bisa preview", style: TextStyle(color: AppTheme.textMuted)),
          ])),
        ),
      );
    } else if (isVideo) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.video_file_rounded, size: 48, color: AppTheme.sky),
        const SizedBox(height: 8),
        Text("Video file ready", style: AppTheme.bodyM),
      ]));
    } else if (isAudio) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.audiotrack_rounded, size: 48, color: AppTheme.sky),
        const SizedBox(height: 8),
        Text("Audio file ready", style: AppTheme.bodyM),
      ]));
    } else {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.insert_drive_file_rounded, size: 48, color: AppTheme.sky),
        const SizedBox(height: 8),
        Text(_fileType ?? "Document", style: AppTheme.bodyM),
      ]));
    }
  }

  Widget _buildResultSection() {
    if (_uploadedUrl == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("URI Hasil Upload", style: AppTheme.label.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.inputDecor(),
            child: SelectableText(_uploadedUrl!, style: AppTheme.bodyM.copyWith(color: AppTheme.sky, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: GestureDetector(
                onTap: _copyToClipboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: AppTheme.accentCardDecor(AppTheme.sky),
                  child: Center(child: Text("COPY", style: AppTheme.headingS)),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: _shareUrl,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: AppTheme.cardDecor(),
                  child: Center(child: Text("BAGIKAN", style: AppTheme.headingS)),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.sky, size: 18),
              const SizedBox(width: 8),
              Text("Informasi", style: AppTheme.headingM),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoBullet("Upload media ke Catbox.moe dan dapatkan URI langsung."),
          _buildInfoBullet("Batas file per upload: 50 MB (jika lebih akan di-zip)."),
          _buildInfoBullet("Format file apa pun didukung."),
          _buildInfoBullet("URI akan langsung bisa digunakan."),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: AppTheme.bodyM.copyWith(color: AppTheme.sky)),
          Expanded(child: Text(text, style: AppTheme.bodyM)),
        ],
      ),
    );
  }
}
