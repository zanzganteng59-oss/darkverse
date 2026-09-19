import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api.dart';

class StatusPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  const StatusPage({super.key, required this.sessionKey, required this.username});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  List<Map<String, dynamic>> _statuses = [];
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchStatuses();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchStatuses());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatuses() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/status/list')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() { _statuses = List<Map<String, dynamic>>.from(data['statuses'] ?? []); _loading = false; _error = null; });
      } else {
        if (mounted) setState(() { _loading = false; _error = 'Server error ${res.statusCode}'; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Gagal koneksi: $e'; });
    }
  }

  Future<void> _viewStatus(String statusId) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/status/view'),
        body: jsonEncode({'key': widget.sessionKey, 'statusId': statusId, 'username': widget.username}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
    } catch (e) {}
  }

  Future<List<String>> _getViewers(String statusId) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/status/viewers/$statusId')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<String>.from(data['viewers'] ?? []);
      }
    } catch (e) {}
    return [];
  }

  Future<void> _deleteStatus(String statusId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/status/delete'),
        body: jsonEncode({'key': widget.sessionKey, 'statusId': statusId, 'username': widget.username}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() { _statuses.removeWhere((s) => s['id'] == statusId); });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status dihapus"), backgroundColor: Color(0xFFFFE74C)));
        }
      }
    } catch (e) {}
  }

  Map<String, List<Map<String, dynamic>>> _groupByUser() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final s in _statuses) {
      final u = s['username'] ?? 'unknown';
      map.putIfAbsent(u, () => []).add(s);
    }
    return map;
  }

  void _openViewer(List<Map<String, dynamic>> userStatuses, int startIndex) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _StatusViewer(
        statuses: userStatuses,
        initialIndex: startIndex,
        sessionKey: widget.sessionKey,
        username: widget.username,
        onView: _viewStatus,
        onDelete: _deleteStatus,
      ),
    )).then((_) => _fetchStatuses());
  }

  void _showCreateDialog() {
    final textCtrl = TextEditingController();
    File? pickedImage;
    bool posting = false;
    String? postError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.add_circle_rounded, color: Color(0xFFFFE74C), size: 22),
                  const SizedBox(width: 10),
                  const Text("POST STATUS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: 1)),
                  const Spacer(),
                  GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close_rounded, color: Colors.grey, size: 22)),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) setModalState(() { pickedImage = File(picked.path); });
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF333333), width: 2),
                  ),
                  child: pickedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(pickedImage!, fit: BoxFit.cover))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF555555), size: 36),
                            SizedBox(height: 8),
                            Text("Tap untuk pilih foto (opsional)", style: TextStyle(color: Color(0xFF555555), fontSize: 12, fontFamily: 'Inter')),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textCtrl,
                maxLines: 3,
                maxLength: 500,
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                decoration: InputDecoration(
                  hintText: "Tulis status kamu...",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333), width: 2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333), width: 2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFE74C), width: 2)),
                ),
              ),
              if (postError != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(postError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'Inter')),
                ),
              ],
              const SizedBox(height: 14),
              GestureDetector(
                onTap: posting ? null : () async {
                  if (textCtrl.text.trim().isEmpty) return;
                  setModalState(() { posting = true; postError = null; });
                  try {
                    String? imageUrl;
                    if (pickedImage != null) {
                      final bytes = await pickedImage!.readAsBytes();
                      final b64 = base64Encode(bytes);
                      final uploadRes = await http.post(
                        Uri.parse('${ApiConfig.baseUrl}/api/chat/upload'),
                        body: jsonEncode({'key': widget.sessionKey, 'data': 'data:image/jpeg;base64,' + b64, 'filename': 'status_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg', 'username': widget.username}),
                        headers: {'Content-Type': 'application/json'},
                      ).timeout(const Duration(seconds: 30));
                      if (uploadRes.statusCode == 200) {
                        final uploadData = jsonDecode(uploadRes.body);
                        imageUrl = '${ApiConfig.baseUrl}' + uploadData['url'].toString();
                      } else {
                        setModalState(() { posting = false; postError = 'Upload foto gagal (' + uploadRes.statusCode.toString() + ')'; });
                        return;
                      }
                    }
                    final postRes = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/api/status/create'),
                      body: jsonEncode({'key': widget.sessionKey, 'text': textCtrl.text.trim(), 'imageUrl': imageUrl, 'username': widget.username}),
                      headers: {'Content-Type': 'application/json'},
                    ).timeout(const Duration(seconds: 10));
                    final postData = jsonDecode(postRes.body);
                    if (postRes.statusCode == 200 && postData['success'] == true) {
                      if (mounted) {
                        Navigator.pop(ctx);
                        await _fetchStatuses();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status diposting!"), backgroundColor: Color(0xFF39FF14)));
                      }
                    } else {
                      setModalState(() { posting = false; postError = postData['error'] ?? 'Gagal post'; });
                    }
                  } catch (e) {
                    setModalState(() { posting = false; postError = 'Error: ' + e.toString(); });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: posting ? Colors.grey[800] : const Color(0xFFFFE74C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: posting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text("POST", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'Inter')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(dynamic ts) {
    final diff = DateTime.now().millisecondsSinceEpoch - (ts is int ? ts : 0);
    if (diff < 60000) return "Baru saja";
    if (diff < 3600000) return "${(diff / 60000).floor()}m lalu";
    if (diff < 86400000) return "${(diff / 3600000).floor()}j lalu";
    return "${(diff / 86400000).floor()}h lalu";
  }

  Color _userColor(String name) {
    final colors = [const Color(0xFFFFE74C), const Color(0xFF39FF14), const Color(0xFF00D4FF), const Color(0xFFFF6B6B), const Color(0xFFC084FC), const Color(0xFFFF9F43)];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByUser();
    final userOrder = grouped.keys.toList();
    userOrder.sort((a, b) {
      if (a == widget.username) return -1;
      if (b == widget.username) return 1;
      final aLatest = grouped[a]!.map((s) => s['createdAt'] as int).reduce((x, y) => x > y ? x : y);
      final bLatest = grouped[b]!.map((s) => s['createdAt'] as int).reduce((x, y) => x > y ? x : y);
      return bLatest.compareTo(aLatest);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text("STATUS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'Inter')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: () { setState(() { _loading = true; }); _fetchStatuses(); }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFFFFE74C),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFE74C)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13, fontFamily: 'Inter'), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () { setState(() { _loading = true; _error = null; }); _fetchStatuses(); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(color: const Color(0xFFFFE74C), borderRadius: BorderRadius.circular(10)),
                          child: const Text("RETRY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Inter', letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      height: 110,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          GestureDetector(
                            onTap: _showCreateDialog,
                            child: Column(
                              children: [
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF1A1A1A),
                                    border: Border.all(color: const Color(0xFF333333), width: 2),
                                  ),
                                  child: const Icon(Icons.add_rounded, color: Color(0xFFFFE74C), size: 28),
                                ),
                                const SizedBox(height: 6),
                                const Text("Kamu", style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontFamily: 'Inter')),
                              ],
                            ),
                          ),
                          ...userOrder.map((user) {
                            final statuses = grouped[user]!;
                            final color = _userColor(user);
                            final isMine = user == widget.username;
                            final latest = statuses.map((s) => s['createdAt'] as int).reduce((x, y) => x > y ? x : y);
                            final idx = statuses.indexWhere((s) => (s['createdAt'] as int) == latest);
                            return GestureDetector(
                              onTap: () => _openViewer(statuses, idx >= 0 ? idx : 0),
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 68, height: 68,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [color, color.withValues(alpha: 0.3)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF0B0D14),
                                          border: Border.all(color: const Color(0xFF0B0D14), width: 3),
                                        ),
                                        child: Center(
                                          child: Text(user[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22, fontFamily: 'Inter')),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isMine ? "Kamu" : user,
                                      style: TextStyle(color: isMine ? const Color(0xFFFFE74C) : Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(statuses.length.toString() + " status", style: const TextStyle(color: Color(0xFF666666), fontSize: 9, fontFamily: 'Inter')),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFF222222), height: 1),
                    Expanded(
                      child: userOrder.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.campaign_rounded, color: Colors.grey[700], size: 48),
                                  const SizedBox(height: 12),
                                  const Text("Belum ada status", style: TextStyle(color: Color(0xFF555555), fontSize: 14, fontFamily: 'Inter')),
                                  const SizedBox(height: 6),
                                  const Text("Tap + untuk post status pertama kamu", style: TextStyle(color: Color(0xFF444444), fontSize: 12, fontFamily: 'Inter')),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchStatuses,
                              color: const Color(0xFFFFE74C),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: userOrder.length,
                                itemBuilder: (ctx, i) {
                                  final user = userOrder[i];
                                  final statuses = grouped[user]!;
                                  final color = _userColor(user);
                                  final isMine = user == widget.username;
                                  final latest = statuses.reduce((a, b) => (a['createdAt'] as int) > (b['createdAt'] as int) ? a : b);
                                  final count = statuses.length;
                                  return GestureDetector(
                                    onTap: () => _openViewer(statuses, statuses.indexWhere((s) => s['id'] == latest['id'])),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF181C28),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: isMine ? color.withValues(alpha: 0.3) : const Color(0xFF2A2F3E), width: 1.5),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 56, height: 56,
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [color, color.withValues(alpha: 0.3)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF181C28),
                                                border: Border.all(color: const Color(0xFF181C28), width: 3),
                                              ),
                                              child: Center(
                                                child: Text(user[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'Inter')),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(user, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter')),
                                                    if (isMine) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                                        child: Text("KAMU", style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: 1)),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  count.toString() + (count > 1 ? ' status' : ' status') + ' \u00b7 ' + _timeAgo(latest['createdAt']),
                                                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12, fontFamily: 'Inter'),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (latest['imageUrl'] != null)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.network(latest['imageUrl'], width: 52, height: 52, fit: BoxFit.cover),
                                            )
                                          else
                                            Container(
                                              width: 52, height: 52,
                                              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                              child: Center(
                                                child: Text((latest['text'] ?? '').toString().substring(0, (latest['text'] ?? '').toString().length.clamp(0, 2)), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Inter')),
                                              ),
                                            ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[700], size: 14),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _StatusViewer extends StatefulWidget {
  final List<Map<String, dynamic>> statuses;
  final int initialIndex;
  final String sessionKey;
  final String username;
  final Future<void> Function(String) onView;
  final Future<void> Function(String) onDelete;

  const _StatusViewer({
    required this.statuses,
    required this.initialIndex,
    required this.sessionKey,
    required this.username,
    required this.onView,
    required this.onDelete,
  });

  @override
  State<_StatusViewer> createState() => _StatusViewerState();
}

class _StatusViewerState extends State<_StatusViewer> {
  late PageController _pageCtrl;
  late int _current;
  double _progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _current);
    _startTimer();
    _markViewed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _markViewed() {
    if (_current < widget.statuses.length) {
      widget.onView(widget.statuses[_current]['id']);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { _progress += 0.02; });
      if (_progress >= 1.0) {
        t.cancel();
        _next();
      }
    });
  }

  void _next() {
    if (_current < widget.statuses.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_current > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  String _timeAgo(dynamic ts) {
    final diff = DateTime.now().millisecondsSinceEpoch - (ts is int ? ts : 0);
    if (diff < 60000) return "Baru saja";
    if (diff < 3600000) return "${(diff / 60000).floor()}m lalu";
    if (diff < 86400000) return "${(diff / 3600000).floor()}j lalu";
    return "${(diff / 86400000).floor()}h lalu";
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.statuses[_current];
    final isMine = s['username'] == widget.username;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (d) {
              final w = MediaQuery.of(context).size.width;
              if (d.localPosition.dx < w / 3) _prev();
              else if (d.localPosition.dx > w * 2 / 3) _next();
              else {
                if (_timer?.isActive == true) _timer?.cancel();
                else _startTimer();
              }
            },
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.statuses.length,
              onPageChanged: (i) {
                setState(() { _current = i; _progress = 0; });
                _startTimer();
                _markViewed();
              },
              itemBuilder: (ctx, i) {
                final st = widget.statuses[i];
                final hasImage = st['imageUrl'] != null && st['imageUrl'].toString().isNotEmpty;
                final hasText = st['text']?.toString().isNotEmpty == true;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(st['imageUrl'], fit: BoxFit.contain, width: double.infinity, height: double.infinity)
                    else
                      Container(
                        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0B0D14), Color(0xFF111111)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                      ),
                    if (hasText && !hasImage)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(st['text'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Inter', height: 1.4), textAlign: TextAlign.center),
                        ),
                      ),
                    if (hasText && hasImage)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 30, 16, 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          ),
                          child: Text(st['text'], style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Inter', height: 1.4)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 8, right: 8),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: Column(
                children: [
                  Row(
                    children: [
                      ...List.generate(widget.statuses.length, (i) => Expanded(
                        child: Container(
                          height: 3, margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: i < _current ? 1.0 : (i == _current ? _progress : 0),
                            child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                          ),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFFFE74C),
                        child: Text((s['username'] ?? '?')[0].toString().toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s['username'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter')),
                        Text(_timeAgo(s['createdAt']), style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Inter')),
                      ])),
                      if (isMine)
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 22),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1A1A),
                                title: const Text("Hapus status?", style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                                content: const Text("Status ini akan dihapus permanen.", style: TextStyle(color: Colors.grey, fontFamily: 'Inter')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await widget.onDelete(s['id']);
                              if (mounted) Navigator.pop(context);
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (s['viewCount'] != null && (s['viewCount'] as int) > 0)
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(s['viewCount'].toString() + " dilihat", style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
