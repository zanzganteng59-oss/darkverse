import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  String _status = "IDLE";
  String _apkUrl = "";
  String _apkSize = "";
  final String _packageName = "com.sync.xxx";
  final String _appName = "PRX Panel";
  final List<String> _logs = [];
  double _progress = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _addLog("[INFO] Build APK Panel", const Color(0xFFFFE74C));
    _addLog("[INFO] Project: $_appName ($_packageName)", const Color(0xFF888888));
    _addLog("[INFO] Tap BUILD untuk trigger build via server", const Color(0xFF888888));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _addLog(String log, [Color? color]) {
    if (!mounted) return;
    setState(() {
      _logs.add(log);
    });
  }

  Future<void> _triggerBuild() async {
    if (_building) return;
    setState(() {
      _building = true;
      _status = "SENDING";
      _logs.clear();
      _apkUrl = "";
      _progress = 0;
    });
    _addLog("[...] Mengirim request build ke server...", const Color(0xFFFFE74C));
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/build-apk'),
        body: jsonEncode({
          'key': widget.sessionKey,
          'username': widget.username,
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        setState(() {
          _status = "BUILDING";
        });
        _addLog("[OK] Build request dikirim ke server!", const Color(0xFF39FF14));
        _addLog("[INFO] ${data['message'] ?? 'Menunggu build...'}", const Color(0xFF00D4FF));
        if (data['apkUrl'] != null) {
          setState(() {
            _status = "SUCCESS";
            _apkUrl = data['apkUrl'] ?? '';
            _apkSize = data['apkSize'] ?? '';
          });
          _addLog("[DONE] Build selesai!", const Color(0xFF39FF14));
          _addLog("[APK] $_apkUrl ($_apkSize)", const Color(0xFFFFE74C));
        } else {
          _pollBuildStatus();
        }
      } else {
        setState(() {
          _building = false;
          _status = "FALLBACK";
        });
        _addLog("[!] ${data['error'] ?? 'Server tidak bisa build langsung'}", const Color(0xFFFF6B6B));
        _showManualInstructions();
      }
    } catch (e) {
      setState(() {
        _building = false;
        _status = "FALLBACK";
      });
      _addLog("[!] Server offline atau error: $e", const Color(0xFFFF6B6B));
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
    _addLog("5. Rename sebelum install", const Color(0xFFAAAAAA));
  }

  void _pollBuildStatus() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/build-status'),
        ).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final st = data['status'] ?? 'building';
          if (mounted) {
            setState(() {
              _progress = (data['progress'] ?? 0).toDouble();
            });
          }
          if (st == 'done') {
            timer.cancel();
            if (mounted) {
              setState(() {
                _building = false;
                _status = "SUCCESS";
                _apkUrl = data['apkUrl'] ?? '';
                _apkSize = data['apkSize'] ?? '';
              });
            }
            _addLog("[SUCCESS] Build selesai!", const Color(0xFF39FF14));
            if (_apkUrl.isNotEmpty) _addLog("[APK] $_apkUrl ($_apkSize)", const Color(0xFFFFE74C));
          } else if (st == 'error') {
            timer.cancel();
            if (mounted) {
              setState(() {
                _building = false;
                _status = "ERROR";
              });
            }
            _addLog("[ERROR] ${data['error'] ?? 'Build gagal'}", const Color(0xFFFF6B6B));
          }
        }
      } catch (_) {}
    });
  }

  void _copyCommand() {
    const cmd = "cd BASEPISING\\android\nbuild_apk.bat";
    Clipboard.setData(const ClipboardData(text: cmd));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Build command copied!"), backgroundColor: Color(0xFF39FF14)),
      );
    }
  }

  void _copyPackageId() {
    Clipboard.setData(ClipboardData(text: _packageName));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Package ID copied!"), backgroundColor: Color(0xFF00D4FF)),
      );
    }
  }

  bool _downloading = false;

  Future<void> _shareApk() async {
    if (_apkUrl.isEmpty || _downloading) return;
    try {
      setState(() { _downloading = true; });
      _addLog("[...] Downloading APK untuk share...", const Color(0xFFFFE74C));
      final fullUrl = '${ApiConfig.baseUrl}$_apkUrl';
      final res = await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 120));
      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/PRX_Panel.apk');
        await file.writeAsBytes(res.bodyBytes);
        _addLog("[OK] APK downloaded (${(res.bodyBytes.length / 1024 / 1024).toStringAsFixed(1)}MB)", const Color(0xFF39FF14));
        await Share.shareXFiles([XFile(file.path)], text: '$_appName APK Build', subject: 'PRX Panel APK');
        _addLog("[OK] Share dialog opened!", const Color(0xFF39FF14));
      } else {
        _addLog("[ERROR] Download gagal: ${res.statusCode}", const Color(0xFFFF6B6B));
      }
    } catch (e) {
      _addLog("[ERROR] Share gagal: $e", const Color(0xFFFF6B6B));
    } finally {
      setState(() { _downloading = false; });
    }
  }

  Future<void> _downloadApk() async {
    if (_apkUrl.isEmpty || _downloading) return;
    try {
      setState(() { _downloading = true; });
      _addLog("[...] Downloading APK...", const Color(0xFFFFE74C));
      final fullUrl = '${ApiConfig.baseUrl}$_apkUrl';
      final res = await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 120));
      if (res.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/PRX_Panel.apk');
        await file.writeAsBytes(res.bodyBytes);
        _addLog("[DONE] APK saved: ${file.path}", const Color(0xFF39FF14));
        _addLog("[INFO] Size: ${(res.bodyBytes.length / 1024 / 1024).toStringAsFixed(1)}MB", const Color(0xFF00D4FF));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("APK saved: ${file.path}"),
            backgroundColor: const Color(0xFF39FF14),
            action: SnackBarAction(label: "OPEN", textColor: Colors.black, onPressed: () {}),
          ));
        }
      } else {
        _addLog("[ERROR] Download gagal: ${res.statusCode}", const Color(0xFFFF6B6B));
      }
    } catch (e) {
      _addLog("[ERROR] Download gagal: $e", const Color(0xFFFF6B6B));
    } finally {
      setState(() { _downloading = false; });
    }
  }

  Color _statusColor() {
    switch (_status) {
      case "BUILDING":
      case "SENDING":
        return const Color(0xFFFFE74C);
      case "SUCCESS":
        return const Color(0xFF39FF14);
      case "ERROR":
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF666666);
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _copyPackageId,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF00D4FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, color: Color(0xFF00D4FF), size: 12),
                              SizedBox(width: 4),
                              Text("COPY PACKAGE ID", style: TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _copyCommand,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFFE74C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.terminal_rounded, color: Color(0xFFFFE74C), size: 12),
                              SizedBox(width: 4),
                              Text("COPY CMD", style: TextStyle(color: Color(0xFFFFE74C), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_building) ...[
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
                  if (_status == "SUCCESS" && _apkUrl.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF39FF14).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("APK SIAP", style: TextStyle(color: Color(0xFF39FF14), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
                          const SizedBox(height: 4),
                          Text("Size: $_apkSize", style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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
                            "Build dilakukan di server/PC. Setelah build, rename APK sebelum install.",
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
                          onTap: _building ? null : _triggerBuild,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _building ? const Color(0xFF333333) : const Color(0xFFFFE74C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: _building
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text("BUILD APK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Inter', letterSpacing: 1)),
                            ),
                          ),
                        ),
                      ),
                      if (_apkUrl.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _downloading ? null : _shareApk,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _downloading ? const Color(0xFF333333) : const Color(0xFF39FF14), borderRadius: BorderRadius.circular(10)),
                            child: _downloading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.share_rounded, color: Colors.black, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _downloading ? null : _downloadApk,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _downloading ? const Color(0xFF333333) : const Color(0xFF00D4FF), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _copyCommand,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF00D4FF), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.copy_rounded, color: Colors.black, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF181C28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2F3E), width: 1.5),
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
                    constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(8)),
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
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF181C28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2F3E), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("MANUAL BUILD (PC)", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
                  const SizedBox(height: 10),
                  _buildStep("1", "Buka terminal di PC"),
                  _buildStep("2", "cd BASEPISING\\android"),
                  _buildStep("3", "build_apk.bat"),
                  _buildStep("4", "APK di: app\\build\\outputs\\apk\\release\\"),
                  _buildStep("5", "Rename APK sesuai keinginan"),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _copyCommand,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFF00D4FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3), width: 1)),
                      child: const Center(
                        child: Text("COPY BUILD COMMAND", style: TextStyle(color: Color(0xFF00D4FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
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

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: const Color(0xFFFFE74C).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Center(child: Text(num, style: const TextStyle(color: Color(0xFFFFE74C), fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'Inter'))),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12, fontFamily: 'Inter')),
        ],
      ),
    );
  }
}
