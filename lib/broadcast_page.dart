import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';

class BroadcastPage extends StatefulWidget {
  final String sessionKey;
  const BroadcastPage({super.key, required this.sessionKey});
  @override
  State<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _msgCtrl = TextEditingController();
  bool _sending = false;
  String? _result;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final resp = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/announcements"),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(resp.body);
      if (data['announcements'] != null) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(
            (data['announcements'] as List).map((a) => Map<String, dynamic>.from(a)),
          ).reversed.toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final message = _msgCtrl.text.trim();
    if (title.isEmpty || message.isEmpty) {
      setState(() => _result = "Isi title & message dulu!");
      return;
    }
    setState(() {
      _sending = true;
      _result = null;
    });
    try {
      final resp = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/broadcast"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "title": title,
          "message": message,
          "type": "info",
        }),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['ok'] == true) {
        setState(() {
          _result = "Terkirim ke ${data['sentTo']} users!";
          _sending = false;
        });
        _titleCtrl.clear();
        _msgCtrl.clear();
        _loadHistory();
      } else {
        setState(() {
          _result = data['error'] ?? "Gagal mengirim";
          _sending = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = "Error: $e";
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text("BROADCAST", style: TextStyle(color: Colors.amberAccent, fontFamily: 'Inter', fontWeight: FontWeight.w900, letterSpacing: 1)),
        iconTheme: const IconThemeData(color: Colors.amberAccent),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111118),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 8),
                    Text("Kirim Pengumuman", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: "Judul pengumuman",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.amberAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msgCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: "Isi pengumuman...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.amberAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: _sending ? Colors.grey[800] : Colors.amberAccent,
                    child: Center(
                      child: _sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text("KIRIM KE SEMUA USER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: 1)),
                    ),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  Text(_result!, style: TextStyle(
                    color: _result!.contains("Terkirim") ? Colors.greenAccent : Colors.redAccent,
                    fontFamily: 'Inter', fontSize: 12,
                  )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("RIWAYAT BROADCAST", style: TextStyle(color: Colors.amberAccent.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            Center(child: Text("Belum ada broadcast", style: TextStyle(color: Colors.grey[600], fontFamily: 'Inter')))
          else
            ..._history.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111118),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.15), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign, color: Colors.amberAccent.withValues(alpha: 0.5), size: 14),
                      const SizedBox(width: 6),
                      Expanded(child: Text(a['title'] ?? '', style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Inter'))),
                      Text(_timeAgo(a['time']), style: TextStyle(color: Colors.grey[600], fontSize: 10, fontFamily: 'Inter')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(a['message'] ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontFamily: 'Inter')),
                ],
              ),
            )),
        ],
      ),
    );
  }

  String _timeAgo(String? iso) {
    if (iso == null) return "";
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return "baru saja";
      if (diff.inHours < 1) return "${diff.inMinutes}m lalu";
      if (diff.inDays < 1) return "${diff.inHours}h lalu";
      return "${diff.inDays}d lalu";
    } catch (_) {
      return "";
    }
  }
}
