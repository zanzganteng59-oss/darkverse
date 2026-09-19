import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'api.dart';

class BuildApkPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  const BuildApkPage({super.key, required this.sessionKey, required this.username});

  @override
  State<BuildApkPage> createState() => _BuildApkPageState();
}

class _BuildApkPageState extends State<BuildApkPage> {
  bool _building = false;
  bool _downloading = false;
  String _status = "IDLE";
  String _apkSize = "";
  final String _packageName = "com.sync.xxx";
  final String _appName = "PRX Panel";
  final List<String> _logs = [];

  File? _apkFile;
  String _customName = "PRX_Panel";

  static const String _githubRepo = "zanzganteng59-oss/darkverse";
  static const String _releaseTag = "v7.5.0";
  String get _githubApkUrl => "https://github.com/$_githubRepo/releases/download/$_releaseTag/app-release.apk";

  @override
  void initState() {
    super.initState();
    _addLog("[INFO] Build APK Panel", const Color(0xFFFFE74C));
    _addLog("[INFO] Project: $_appName ($_packageName)", const Color(0xFF888888));
    _checkExistingApk();
  }

  void _addLog(String log, [Color? color]) {
    if (!mounted) return;
    setState(() { _logs.add(log); });
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        status = await Permission.storage.status;
        if (!status.isGranted) status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        _addLog("[!] Storage permission denied", const Color(0xFFFF6B6B));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Izin storage diperlukan untuk download/share APK"), backgroundColor: Color(0xFFFF6B6B)),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<void> _checkExistingApk() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/PRX_Panel.apk');
      if (await file.exists()) {
        final size = await file.length();
        if (size > 1000) {
          setState(() {
            _apkFile = file;
            _apkSize = '${(size / 1024 / 1024).toStringAsFixed(1)}MB';
            _status = "SUCCESS";
          });
          _addLog("[INFO] APK ditemukan: $_apkSize", const Color(0xFF39FF14));
          _addLog("[INFO] Tap RENAME atau SHARE", const Color(0xFF888888));
        }
      }
    } catch (_) {}
  }

  Future<void> _triggerBuild() async {
    if (_building || _downloading) return;
    final url = Uri.parse("https://github.com/$_githubRepo/actions");
    _addLog("[...] Membuka halaman build...", const Color(0xFFFFE74C));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      _addLog("[OK] Buka browser untuk download APK", const Color(0xFF39FF14));
      _addLog("[INFO] Setelah download, tap PICK APK", const Color(0xFF00D4FF));
    } else {
      _addLog("[!] Tidak bisa buka browser", const Color(0xFFFF6B6B));
    }
  }

  Future<void> _pickApkFile() async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final size = await file.length();
        final sizeMB = (size / 1024 / 1024).toStringAsFixed(1);
        setState(() {
          _apkFile = file;
          _apkSize = '${sizeMB}MB';
          _status = "SUCCESS";
        });
        _addLog("[OK] APK dipilih: ${result.files.first.name} (${sizeMB}MB)", const Color(0xFF39FF14));
        _addLog("[INFO] Tap RENAME lalu SHARE", const Color(0xFF00D4FF));
      }
    } catch (e) {
      _addLog("[ERROR] Gagal pick file: $e", const Color(0xFFFF6B6B));
    }
  }

  void _showRenameDialog() {
    final ctrl = TextEditingController(text: _customName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFFE74C), width: 2)),
        title: const Text("RENAME APK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Masukkan nama baru:", style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12, fontFamily: 'Inter')),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono', fontSize: 14),
              decoration: InputDecoration(
                hintText: "PRX_UID_nama",
                hintStyle: const TextStyle(color: Color(0xFF555555)),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF333333))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFFE74C), width: 2)),
              ),
            ),
            const SizedBox(height: 8),
            Text("File: ${ctrl.text}.apk", style: const TextStyle(color: Color(0xFF666666), fontSize: 10, fontFamily: 'ShareTechMono')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL", style: TextStyle(color: Color(0xFF666666)))),
          TextButton(
            onPressed: () {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() { _customName = newName; });
                _addLog("[OK] Nama: ${newName}.apk", const Color(0xFF39FF14));
              }
              Navigator.pop(ctx);
            },
            child: const Text("SIMPAN", style: TextStyle(color: Color(0xFFFFE74C), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareApk() async {
    if (_apkFile == null || _downloading) return;
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return;
    try {
      if (!await _apkFile!.exists()) {
        _addLog("[ERROR] File APK tidak ada", const Color(0xFFFF6B6B));
        return;
      }
      _addLog("[...] Sharing ${_customName}.apk...", const Color(0xFFFFE74C));
      await Share.shareXFiles(
        [XFile(_apkFile!.path, mimeType: 'application/vnd.android.package-archive', name: '${_customName}.apk')],
        text: '$_appName - $_customName',
      );
      _addLog("[OK] Share opened!", const Color(0xFF39FF14));
    } catch (e) {
      _addLog("[ERROR] Share gagal: $e", const Color(0xFFFF6B6B));
    }
  }

  Color _statusColor() {
    switch (_status) {
      case "SUCCESS": return const Color(0xFF39FF14);
      case "ERROR": return const Color(0xFFFF6B6B);
      default: return const Color(0xFF666666);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text("BUILD APK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'Inter')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF181C28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2F3E), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFFFE74C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.android_rounded, color: Color(0xFFFFE74C), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_appName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Inter')),
                            Text(_packageName, style: const TextStyle(color: Color(0xFF666666), fontSize: 12, fontFamily: 'Inter')),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _statusColor().withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(_status, style: TextStyle(color: _statusColor(), fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_building || _downloading) ...[
                    const SizedBox(height: 12),
                  ],
                  if (_status == "SUCCESS" && _apkFile != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF39FF14).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.3), width: 1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("APK SIAP", style: TextStyle(color: Color(0xFF39FF14), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF39FF14), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text("${_customName}.apk", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'ShareTechMono')),
                              ),
                              Text(_apkSize, style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontFamily: 'ShareTechMono')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFFE74C).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFFFFE74C), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Tap BUILD untuk buka halaman build, download APK, lalu tap PICK APK. Atau PICK APK langsung dari storage.",
                            style: TextStyle(color: Color(0xFFFFE74C), fontSize: 11, fontFamily: 'Inter', height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: (_building || _downloading) ? null : _triggerBuild,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: (_building || _downloading) ? const Color(0xFF333333) : const Color(0xFFFFE74C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(child: Text("BUILD APK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Inter', letterSpacing: 1))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: (_building || _downloading) ? null : _pickApkFile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: (_building || _downloading) ? const Color(0xFF333333) : const Color(0xFF00D4FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(child: Text("PICK APK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Inter', letterSpacing: 1))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_apkFile != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _showRenameDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: const Color(0xFFFF6B6B), borderRadius: BorderRadius.circular(10)),
                              child: const Center(child: Text("RENAME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'Inter', letterSpacing: 1))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _shareApk,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: const Color(0xFF39FF14), borderRadius: BorderRadius.circular(10)),
                              child: const Center(child: Text("SHARE APK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'Inter', letterSpacing: 1))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222222), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terminal_rounded, color: Color(0xFF00D4FF), size: 16),
                      SizedBox(width: 8),
                      Text("BUILD LOG", style: TextStyle(color: Color(0xFF00D4FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 80, maxHeight: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF050505), borderRadius: BorderRadius.circular(8)),
                    child: _logs.isEmpty
                        ? const Text("Tap BUILD APK untuk mulai", style: TextStyle(color: Color(0xFF444444), fontSize: 11, fontFamily: 'ShareTechMono'))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _logs.map((log) {
                                Color c = const Color(0xFF888888);
                                if (log.contains('[DONE]') || log.contains('[OK]')) c = const Color(0xFF39FF14);
                                else if (log.contains('[ERROR]') || log.contains('[!]')) c = const Color(0xFFFF6B6B);
                                else if (log.contains('[INFO]')) c = const Color(0xFF00D4FF);
                                else if (log.contains('[URL]')) c = const Color(0xFFAAAAAA);
                                else if (log.contains('=== ')) c = const Color(0xFFFFE74C);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1),
                                  child: Text(log, style: TextStyle(color: c, fontSize: 11, fontFamily: 'ShareTechMono', height: 1.4)),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
