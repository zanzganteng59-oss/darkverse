import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

class VulnScannerPage extends StatefulWidget {
  const VulnScannerPage({super.key});
  @override
  State<VulnScannerPage> createState() => _VulnScannerPageState();
}

class _VulnScannerPageState extends State<VulnScannerPage> {
  final TextEditingController _urlCtrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];

  Future<void> _startScan() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _loading = true;
      _results = [];
    });
    try {
      final resp = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/vuln-scan"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"url": url}),
      ).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        setState(() {
          _results = [{"label": "Server", "status": "danger", "detail": "Server error ${resp.statusCode}. Pastikan server sudah restart."}];
          _loading = false;
        });
        return;
      }
      final data = jsonDecode(resp.body);
      if (data['results'] != null) {
        setState(() {
          _results = List<Map<String, dynamic>>.from(data['results'].map((r) => Map<String, dynamic>.from(r)));
          _loading = false;
        });
      } else {
        setState(() {
          _results = [{"label": "Error", "status": "danger", "detail": data['error'] ?? "Scan gagal"}];
          _loading = false;
        });
      }
    } catch (e) {
      final msg = e.toString();
      String detail;
      if (msg.contains("Connection refused") || msg.contains("SocketException")) {
        detail = "Server offline. Pastikan server aktif.";
      } else if (msg.contains("TimeoutException")) {
        detail = "Request timeout. Target terlalu lambat.";
      } else {
        detail = "Error: $msg";
      }
      setState(() {
        _results = [{"label": "Connection", "status": "danger", "detail": detail}];
        _loading = false;
      });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case "safe": return Colors.greenAccent;
      case "warn": return Colors.amberAccent;
      case "danger": return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case "safe": return Icons.check_circle;
      case "warn": return Icons.warning;
      case "danger": return Icons.dangerous;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dangerCount = _results.where((r) => r['status'] == 'danger').length;
    final warnCount = _results.where((r) => r['status'] == 'warn').length;
    final safeCount = _results.where((r) => r['status'] == 'safe').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text("VULN SCANNER", style: TextStyle(color: Colors.redAccent, fontFamily: 'Inter', fontWeight: FontWeight.w900, letterSpacing: 1)),
        iconTheme: const IconThemeData(color: Colors.redAccent),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111118),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 2),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.shield, color: Colors.redAccent, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _urlCtrl,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: "example.com atau https://target.com",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      onSubmitted: (_) => _startScan(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _startScan,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      color: Colors.redAccent,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _statChip("$dangerCount", "DANGER", Colors.redAccent),
                  const SizedBox(width: 8),
                  _statChip("$warnCount", "WARNING", Colors.amberAccent),
                  const SizedBox(width: 8),
                  _statChip("$safeCount", "SAFE", Colors.greenAccent),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text("Scanning via server...", style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.7), fontFamily: 'Inter', letterSpacing: 2)),
                        ],
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.redAccent.withValues(alpha: 0.3), size: 64),
                              const SizedBox(height: 12),
                              Text("Masukkan URL target\nlalu tekan SCAN", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontFamily: 'Inter')),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (ctx, i) {
                            final r = _results[i];
                            final c = _statusColor(r['status']);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111118),
                                border: Border.all(color: c.withValues(alpha: 0.4), width: 1),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(_statusIcon(r['status']), color: c, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r['label'] ?? '', style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
                                        const SizedBox(height: 4),
                                        Text(r['detail'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontFamily: 'Inter')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text("$count $label", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
    );
  }
}
