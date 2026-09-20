import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

class SourceGrabberPage extends StatefulWidget {
  const SourceGrabberPage({super.key});
  @override
  State<SourceGrabberPage> createState() => _SourceGrabberPageState();
}

class _SourceGrabberPageState extends State<SourceGrabberPage> {
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _resultCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _fetchSource() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = "Masukkan URL atau domain. Contoh: example.com atau https://google.com");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _resultCtrl.clear();
    });
    try {
      final resp = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/source-fetch"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"url": url}),
      ).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        setState(() {
          _error = "Server error ${resp.statusCode}. Pastikan server sudah restart.";
          _loading = false;
        });
        return;
      }
      final data = jsonDecode(resp.body);
      if (data['source'] != null) {
        setState(() {
          _resultCtrl.text = data['source'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error'] ?? "Gagal mengambil source";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        final msg = e.toString();
        if (msg.contains("Connection refused") || msg.contains("SocketException")) {
          _error = "Server offline. Pastikan server aktif.";
        } else if (msg.contains("TimeoutException")) {
          _error = "Request timeout. Target terlalu lambat.";
        } else {
          _error = "Error: $msg";
        }
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text("SOURCE GRABBER", style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Inter', fontWeight: FontWeight.w900, letterSpacing: 1)),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111118),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.link, color: Colors.cyanAccent, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _urlCtrl,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: "example.com atau https://google.com",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      onSubmitted: (_) => _fetchSource(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _fetchSource,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      color: Colors.cyanAccent,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.search, color: Colors.black, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontFamily: 'Inter', fontSize: 13)),
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D14),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Stack(
                    children: [
                      TextField(
                        controller: _resultCtrl,
                        readOnly: true,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(12),
                          border: InputBorder.none,
                        ),
                      ),
                      if (_resultCtrl.text.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              _resultCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _resultCtrl.text.length);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              color: Colors.cyanAccent,
                              child: const Text("SELECT ALL", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
