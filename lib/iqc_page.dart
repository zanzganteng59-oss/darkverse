import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:darkverse/theme/app_theme.dart';

class IQCScreen extends StatefulWidget {
  const IQCScreen({super.key});

  @override
  State<IQCScreen> createState() => _IQCScreenState();
}

class _IQCScreenState extends State<IQCScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _chatTimeController = TextEditingController();
  final TextEditingController _statusBarTimeController = TextEditingController();

  Uint8List? _generatedImage;
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final timeFormat = DateFormat('HH:mm');
    final now = DateTime.now();
    _chatTimeController.text = timeFormat.format(now);
    _statusBarTimeController.text = timeFormat.format(now);
    _textController.text = 'bizz ganteng';
  }

  @override
  void dispose() {
    _textController.dispose();
    _chatTimeController.dispose();
    _statusBarTimeController.dispose();
    super.dispose();
  }

  bool _isValidTime(String time) {
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  Future<void> _generateIQCImage() async {
    if (_textController.text.isEmpty) {
      _showError('Masukkan teks chat terlebih dahulu');
      return;
    }
    if (_chatTimeController.text.isEmpty || _statusBarTimeController.text.isEmpty) {
      _showError('Masukkan waktu chat dan status bar');
      return;
    }
    if (!_isValidTime(_chatTimeController.text)) {
      _showError('Format waktu chat salah (gunakan HH:mm)');
      return;
    }
    if (!_isValidTime(_statusBarTimeController.text)) {
      _showError('Format waktu status bar salah (gunakan HH:mm)');
      return;
    }

    setState(() { _isGenerating = true; _errorMessage = null; _generatedImage = null; });

    try {
      final text = Uri.encodeComponent(_textController.text);
      final chatTime = Uri.encodeComponent(_chatTimeController.text);
      final statusBarTime = Uri.encodeComponent(_statusBarTimeController.text);
      final apiUrl = 'https://api.deline.web.id/maker/iqc?text=$text&chatTime=$chatTime&statusBarTime=$statusBarTime';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'User-Agent': 'IQC-Screenshot-Maker/1.0'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        setState(() { _generatedImage = response.bodyBytes; });
        _showSuccess('Gambar berhasil dihasilkan dari API');
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() { _errorMessage = 'Gagal menghubungi API: $e'; });
      _showError(_errorMessage!);
    } finally {
      setState(() { _isGenerating = false; });
    }
  }

  Future<void> _saveImage() async {
    if (_generatedImage == null) { _showError('Tidak ada gambar untuk disimpan'); return; }
    setState(() { _isSaving = true; });
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) throw Exception('Izin penyimpanan dibutuhkan');
      final directory = await getExternalStorageDirectory();
      final downloadPath = '${directory!.path}/Download';
      final downloadDir = Directory(downloadPath);
      if (!downloadDir.existsSync()) downloadDir.createSync(recursive: true);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'iqc_${_textController.text.replaceAll(' ', '_')}_$timestamp.png';
      final filePath = '$downloadPath/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(_generatedImage!);
      _showSuccess('Gambar disimpan di: Download/$fileName');
      _showSaveSuccessDialog(filePath, fileName);
    } catch (e) {
      _showError('Gagal menyimpan gambar: $e');
    } finally {
      setState(() { _isSaving = false; });
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSuccess('Disalin ke clipboard: $text');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.mint, duration: const Duration(seconds: 2)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.coral, duration: const Duration(seconds: 3)),
    );
  }

  void _showSaveSuccessDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Text('Gambar Disimpan!', style: AppTheme.headingM),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gambar berhasil disimpan di:', style: AppTheme.bodyL),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.bgInput,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Text('Download/$fileName', style: AppTheme.bodyM.copyWith(color: AppTheme.teal, fontFamily: 'monospace')),
            ),
            const SizedBox(height: 16),
            Text('Anda dapat membagikan gambar melalui aplikasi galeri atau file manager.', style: AppTheme.bodyM),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { _copyToClipboard(filePath); Navigator.pop(context); },
            child: const Text('SALIN PATH', style: TextStyle(color: AppTheme.sky)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.sky)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    bool isTime = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyL),
        const SizedBox(height: 8),
        Container(
          decoration: AppTheme.inputDecor(),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.bodyM.copyWith(color: AppTheme.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: isTime
                  ? IconButton(
                      onPressed: () {
                        final timeFormat = DateFormat('HH:mm');
                        final now = DateTime.now();
                        controller.text = timeFormat.format(now);
                      },
                      icon: const Icon(Icons.access_time, color: AppTheme.sky),
                      tooltip: 'Gunakan waktu sekarang',
                    )
                  : null,
            ),
            style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary, fontSize: 16),
            maxLines: isTime ? 1 : 3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('IQC Screenshot Maker', style: AppTheme.headingM),
        centerTitle: true,
        actions: [
          if (_generatedImage != null)
            IconButton(
              onPressed: _isSaving ? null : _saveImage,
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.sky))
                  : const Icon(Icons.download, color: AppTheme.textPrimary),
              tooltip: 'Simpan Gambar',
            ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    side: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                  title: Text('Tentang', style: AppTheme.headingM),
                  content: Text('Screen Shot Whatsapp iPhone\n\nFitur share sementara dinonaktifkan karena masalah kompatibilitas.', style: AppTheme.bodyL),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('TUTUP', style: TextStyle(color: AppTheme.sky)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline, color: AppTheme.textPrimary),
            tooltip: 'Tentang',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecor(),
              child: Column(
                children: [
                  _buildInputField(label: 'Teks Chat', controller: _textController, hint: 'Masukkan teks chat...'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildInputField(label: 'Waktu Chat', controller: _chatTimeController, hint: 'HH:mm', isTime: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField(label: 'Waktu Status Bar', controller: _statusBarTimeController, hint: 'HH:mm', isTime: true)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _copyToClipboard('22:11'),
                    child: Row(
                      children: [
                        const Icon(Icons.info, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text('Format waktu: HH:mm (contoh: 22:11)', style: AppTheme.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateIQCImage,
                      icon: _isGenerating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.generating_tokens),
                      label: Text(
                        _isGenerating ? 'SEDANG MEMBUAT...' : 'BUAT SCREENSHOT',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: AppTheme.primaryButton(AppTheme.lavender),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.accentCardDecor(AppTheme.coral),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.coral),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: AppTheme.bodyL)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                final apiUrl = 'https://api.deline.web.id/maker/iqc?text=${Uri.encodeComponent(_textController.text)}&chatTime=${Uri.encodeComponent(_chatTimeController.text)}&statusBarTime=${Uri.encodeComponent(_statusBarTimeController.text)}';
                _copyToClipboard(apiUrl);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecor(),
                child: Row(
                  children: [
                    const Icon(Icons.api, color: AppTheme.sky),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('API Endpoint', style: AppTheme.headingS),
                          const SizedBox(height: 4),
                          Text('https://api.deline.web.id/maker/iqc', style: AppTheme.bodyM),
                        ],
                      ),
                    ),
                    const Icon(Icons.content_copy, color: AppTheme.textMuted, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecor(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.preview, color: AppTheme.sky),
                      const SizedBox(width: 8),
                      Text('Hasil Screenshot', style: AppTheme.headingM),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_generatedImage != null)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 600),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        child: Image.memory(
                          _generatedImage!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: AppTheme.bgInput,
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.broken_image, size: 64, color: AppTheme.coral),
                                  const SizedBox(height: 16),
                                  Text('Gagal memuat gambar', style: AppTheme.bodyL),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: AppTheme.inputDecor().copyWith(
                        border: Border.all(color: AppTheme.borderMedium, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.screenshot_monitor, size: 80, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 20),
                          Text('Belum ada screenshot', style: AppTheme.bodyL.copyWith(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text('Masukkan teks dan waktu, lalu klik "Buat Screenshot"', textAlign: TextAlign.center, style: AppTheme.bodyM),
                          ),
                        ],
                      ),
                    ),
                  if (_generatedImage != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ukuran: ${(_generatedImage!.lengthInBytes / 1024).toStringAsFixed(1)} KB', style: AppTheme.caption),
                        Text('Dibuat: ${DateFormat('HH:mm:ss').format(DateTime.now())}', style: AppTheme.caption),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecor(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contoh Cepat:', style: AppTheme.headingM),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildExampleChip('Malam minggu yuk', '20:00', '20:05'),
                      _buildExampleChip('Besok ketemuan dimana?', '15:30', '15:45'),
                      _buildExampleChip('Lagi apa?', '21:15', '21:20'),
                      _buildExampleChip('Udah makan belum?', '12:00', '12:10'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String text, String chatTime, String statusBarTime) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _textController.text = text;
          _chatTimeController.text = chatTime;
          _statusBarTimeController.text = statusBarTime;
        });
        _showSuccess('Contoh diterapkan');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgInput,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text.length > 20 ? '${text.substring(0, 20)}...' : text, style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('$chatTime | $statusBarTime', style: AppTheme.caption),
          ],
        ),
      ),
    );
  }
}
