import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VulnScannerPage extends StatefulWidget {
  const VulnScannerPage({super.key});
  @override
  State<VulnScannerPage> createState() => _VulnScannerPageState();
}

class _VulnScannerPageState extends State<VulnScannerPage> {
  final TextEditingController _urlCtrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];

  static const List<Map<String, dynamic>> _checks = [
    {"id": "headers", "label": "Security Headers", "desc": "X-Frame-Options, CSP, HSTS"},
    {"id": "ssl", "label": "SSL/TLS Check", "desc": "Sertifikat & enkripsi"},
    {"id": "directory", "label": "Directory Listing", "desc": "Cek /admin, /backup, /.env"},
    {"id": "cors", "label": "CORS Misconfig", "desc": "Cross-Origin Resource Sharing"},
    {"id": "info_disc", "label": "Info Disclosure", "desc": "Server header, version leak"},
    {"id": "injection", "label": "Basic Injection Test", "desc": "SQL error & XSS refleksi"},
    {"id": "open_redirect", "label": "Open Redirect", "desc": "Parameter redirect manipulation"},
  ];

  Future<void> _startScan() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    final target = url.startsWith("http") ? url : "http://$url";
    setState(() {
      _loading = true;
      _results = [];
    });
    List<Map<String, dynamic>> found = [];
    try {
      final resp = await http.get(
        Uri.parse(target),
        headers: {"User-Agent": "MEGATRON-Scanner/1.0"},
      ).timeout(const Duration(seconds: 15));
      final headers = resp.headers;
      final body = resp.body;

      // Security Headers
      final hasXfo = headers.containsKey("x-frame-options");
      final hasCsp = headers.containsKey("content-security-policy");
      final hasHsts = headers.containsKey("strict-transport-security");
      found.add({
        "label": "Security Headers",
        "status": (hasXfo && hasCsp && hasHsts) ? "safe" : "warn",
        "detail": "X-Frame: ${hasXfo ? "OK" : "MISSING"} | CSP: ${hasCsp ? "OK" : "MISSING"} | HSTS: ${hasHsts ? "OK" : "MISSING"}",
      });

      // Info Disclosure
      final server = headers["server"] ?? "Not found";
      final powered = headers["x-powered-by"] ?? "Not found";
      found.add({
        "label": "Info Disclosure",
        "status": (server != "Not found" || powered != "Not found") ? "warn" : "safe",
        "detail": "Server: $server | X-Powered-By: $powered",
      });

      // Directory Listing
      final dirUrls = ["/admin", "/backup", "/.env", "/wp-admin", "/.git", "/config", "/phpmyadmin"];
      List<String> foundDirs = [];
      for (final dir in dirUrls) {
        try {
          final dirResp = await http.head(Uri.parse("$target$dir")).timeout(const Duration(seconds: 5));
          if (dirResp.statusCode != 404) foundDirs.add(dir);
        } catch (_) {}
      }
      found.add({
        "label": "Directory Listing",
        "status": foundDirs.isNotEmpty ? "danger" : "safe",
        "detail": foundDirs.isEmpty ? "Tidak ada directory sensitif ditemukan" : "Ditemukan: ${foundDirs.join(", ")}",
      });

      // CORS
      final cors = headers["access-control-allow-origin"];
      found.add({
        "label": "CORS Check",
        "status": cors == "*" ? "danger" : "safe",
        "detail": cors == null ? "Tidak ada CORS header" : "Allow-Origin: $cors",
      });

      // XSS reflection test
      final xssPayload = '<script>alert(1)</script>';
      final xssUrl = target.contains("?") ? "$target&q=$xssPayload" : "$target?q=$xssPayload";
      try {
        final xssResp = await http.get(Uri.parse(xssUrl), headers: {"User-Agent": "MEGATRON-Scanner/1.0"}).timeout(const Duration(seconds: 5));
        final xssReflect = xssResp.body.contains(xssPayload);
        found.add({
          "label": "XSS Reflection",
          "status": xssReflect ? "danger" : "safe",
          "detail": xssReflect ? "Payload terefleksi di response!" : "Payload tidak terefleksi",
        });
      } catch (_) {
        found.add({"label": "XSS Reflection", "status": "info", "detail": "Gagal melakukan test"});
      }

      // SQL Injection test
      final sqliPayload = "'";
      final sqliUrl = target.contains("?") ? "$target?id=$sqliPayload" : "$target?id=$sqliPayload";
      try {
        final sqliResp = await http.get(Uri.parse(sqliUrl), headers: {"User-Agent": "MEGATRON-Scanner/1.0"}).timeout(const Duration(seconds: 5));
        final hasSqlError = RegExp(r"sql|mysql|syntax|error|query|warning|mysql_", caseSensitive: false).hasMatch(sqliResp.body);
        found.add({
          "label": "SQL Injection Test",
          "status": hasSqlError ? "danger" : "safe",
          "detail": hasSqlError ? "SQL error detected di response" : "Tidak ada SQL error",
        });
      } catch (_) {
        found.add({"label": "SQL Injection Test", "status": "info", "detail": "Gagal melakukan test"});
      }

      // Open Redirect
      found.add({"label": "Open Redirect", "status": "info", "detail": "Perlu manual testing - gunakan parameter ?redirect=evil.com"});
    } catch (e) {
      found.add({"label": "Connection", "status": "danger", "detail": "Gagal koneksi: $e"});
    }

    setState(() {
      _results = found;
      _loading = false;
    });
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
                        hintText: "https://target.com",
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
                          Text("Scanning...", style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.7), fontFamily: 'Inter', letterSpacing: 2)),
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
                                        Text(r['label'], style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
                                        const SizedBox(height: 4),
                                        Text(r['detail'], style: TextStyle(color: Colors.grey[500], fontSize: 11, fontFamily: 'Inter')),
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
