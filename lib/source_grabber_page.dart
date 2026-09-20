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
      setState(() => _error = "Masukkan URL website");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _resultCtrl.clear();
    });
    try {
      final target = url.startsWith("http") ? url : "http://$url";
      final resp = await http.get(
        Uri.parse(target),
        headers: {"User-Agent": "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36"},
      ).timeout(const Duration(seconds: 15));
      setState(() {
        _resultCtrl.text = utf8.decode(resp.bodyBytes);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Gagal mengambil source: $e";
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
                        hintText: "https://example.com",
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
                      child: const Icon(Icons.search, color: Colors.black, size: 22),
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
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontFamily: 'Inter')),
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
