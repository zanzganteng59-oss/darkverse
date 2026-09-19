import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'api.dart';
import 'services/lang.dart';

class ChatPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const ChatPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _imgPicker = ImagePicker();

  WebSocketChannel? _ws;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _onlineUsers = [];
  bool _connected = false;
  bool _sending = false;
  bool _disposed = false;
  Map<String, dynamic>? _replyTo;
  final Map<int, double> _swipeOffsets = {};

  @override
  void initState() {
    super.initState();
    _disposed = false;
    _connect();
  }

  @override
  void dispose() {
    _disposed = true;
    _ws?.sink.close(status.goingAway);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _connect() {
    if (_disposed) return;
    try {
      _ws = WebSocketChannel.connect(Uri.parse('wss://ws-dark.strideoryx.my.id'));
      _ws!.stream.listen(
        (event) {
          if (_disposed) return;
          final data = jsonDecode(event);
          _onMessage(data);
        },
        onDone: () {
          if (!_disposed && mounted) {
            setState(() => _connected = false);
            Future.delayed(const Duration(seconds: 3), () {
              if (!_disposed && mounted) _connect();
            });
          }
        },
        onError: (_) {
          if (!_disposed && mounted) setState(() => _connected = false);
        },
      );

      _ws!.sink.add(jsonEncode({"type": "auth", "key": widget.sessionKey}));
      if (!_disposed) setState(() => _connected = true);

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!_disposed && _connected && mounted) {
          _ws?.sink.add(jsonEncode({"type": "publicChat:join"}));
          _ws?.sink.add(jsonEncode({"type": "publicChat:history", "limit": 100}));
        }
      });
    } catch (_) {
      if (!_disposed) setState(() => _connected = false);
    }
  }

  void _onMessage(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'chatList') {
      _ws?.sink.add(jsonEncode({"type": "publicChat:join"}));
      _ws?.sink.add(jsonEncode({"type": "publicChat:history", "limit": 100}));
    }

    if (type == 'publicChat:message') {
      final msg = data['message'];
      if (msg == null) return;
      final id = msg['id'] ?? '';
      final exists = _messages.any((m) => m['id'] == id);
      if (!exists) {
        // Remove temp message from same sender with same content
        final tempIdx = _messages.indexWhere((m) =>
          m['id'].toString().startsWith('temp_') &&
          m['from'] == msg['from'] &&
          m['message'] == msg['message']);
        if (tempIdx >= 0) {
          setState(() {
            _messages[tempIdx] = Map<String, dynamic>.from(msg);
          });
        } else {
          setState(() => _messages.add(Map<String, dynamic>.from(msg)));
        }
        _scrollDown();
      }
    }

    if (type == 'publicChat:history') {
      final list = data['messages'] as List? ?? [];
      setState(() {
        _messages = list.map((m) => Map<String, dynamic>.from(m)).toList();
      });
      _scrollDown();
    }

    if (type == 'publicChat:online') {
      final list = data['users'] as List? ?? [];
      setState(() {
        _onlineUsers = list.map((u) => Map<String, dynamic>.from(u)).toList();
      });
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final tempMsg = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'from': widget.username,
      'role': widget.role,
      'message': text,
      'time': DateTime.now().toIso8601String(),
    };
    setState(() => _messages.add(tempMsg));
    _scrollDown();

    _ws?.sink.add(jsonEncode({
      "type": "publicChat:send",
      "message": text,
      "replyTo": _replyTo?['id'],
    }));

    _msgCtrl.clear();
    setState(() => _replyTo = null);
  }

  Future<void> _uploadAndSend(File file) async {
    setState(() => _sending = true);
    try {
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final ext = file.path.split('.').last.toLowerCase();
      final fname = 'chat_${widget.username}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      String mimeType;
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
        mimeType = 'image/$ext';
      } else {
        mimeType = 'image/$ext';
      }

      final sizeMB = bytes.length / (1024 * 1024);
      if (sizeMB > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("File terlalu besar (${sizeMB.toStringAsFixed(1)}MB). Maks 5MB."),
              backgroundColor: AppTheme.coral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
            ),
          );
        }
        setState(() => _sending = false);
        return;
      }

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': widget.sessionKey, 'data': 'data:$mimeType;base64,$b64', 'filename': fname}),
      ).timeout(const Duration(seconds: 60));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final url = '${ApiConfig.baseUrl}${data['url']}';
          final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
          final localMsg = <String, dynamic>{
            'id': tempId,
            'from': widget.username,
            'role': widget.role,
            'time': DateTime.now().toIso8601String(),
            'imageUrl': url,
          };
          setState(() => _messages.add(localMsg));
          _scrollDown();

          _ws?.sink.add(jsonEncode({
            "type": "publicChat:send",
            "imageUrl": url,
            "replyTo": _replyTo?['id'],
          }));
          setState(() => _replyTo = null);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['error'] ?? "Upload gagal"),
                backgroundColor: AppTheme.coral,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Upload gagal (${res.statusCode})"),
              backgroundColor: AppTheme.coral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload error: $e"),
            backgroundColor: AppTheme.coral,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
          ),
        );
      }
    }
    setState(() => _sending = false);
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.coral),
              title: Text('Kamera', style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.sky),
              title: Text('Galeri', style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      final picked = await _imgPicker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
      if (picked != null) _uploadAndSend(File(picked.path));
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'developer': return AppTheme.lavender;
      case 'all_akses': return AppTheme.sky;
      case 'owner': return AppTheme.peach;
      case 'vip': return const Color(0xFFFF80AB);
      case 'reseller': return AppTheme.mint;
      case 'admin': return AppTheme.coral;
      default: return AppTheme.textSecondary;
    }
  }

  String _time(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Widget _wrapWithSwipe(Widget child, Map<String, dynamic> msg, int index) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _swipeOffsets[index] = (_swipeOffsets[index] ?? 0) + details.delta.dx;
          if (_swipeOffsets[index]! > 100) _swipeOffsets[index] = 100.0;
          if (_swipeOffsets[index]! < 0) _swipeOffsets[index] = 0.0;
        });
      },
      onHorizontalDragEnd: (details) {
        final offset = _swipeOffsets[index] ?? 0;
        if (offset > 80) {
          HapticFeedback.lightImpact();
          setState(() {
            _replyTo = msg;
            _swipeOffsets[index] = 0;
          });
        } else {
          setState(() => _swipeOffsets[index] = 0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(_swipeOffsets[index] ?? 0, 0, 0),
        child: Stack(
          children: [
            if ((_swipeOffsets[index] ?? 0) > 10)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.reply,
                    color: AppTheme.sky.withValues(alpha: ((_swipeOffsets[index] ?? 0) / 100).clamp(0.0, 1.0)),
                    size: 22,
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                border: Border(bottom: BorderSide(color: AppTheme.borderSubtle, width: 1)),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: AppTheme.inputDecor().copyWith(
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _connected ? AppTheme.mint : AppTheme.coral,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.softGlow(
                        _connected ? AppTheme.mint : AppTheme.coral,
                        blur: 6,
                        opacity: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Lang.t('public_chat'),
                      style: AppTheme.headingM.copyWith(fontFamily: 'Orbitron', letterSpacing: 2),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showOnline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: AppTheme.inputDecor().copyWith(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8, height: 8, child: DecoratedBox(decoration: BoxDecoration(color: AppTheme.mint, shape: BoxShape.circle))),
                          const SizedBox(width: 6),
                          Text("${_onlineUsers.length}", style: const TextStyle(color: AppTheme.mint, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildMessages()),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 12),
            Text("Belum ada pesan", style: AppTheme.bodyL.copyWith(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        final isMe = msg['from'] == widget.username;
        final showName = i == 0 || _messages[i - 1]['from'] != msg['from'];
        return _wrapWithSwipe(_buildBubble(msg, isMe, showName), msg, i);
      },
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe, bool showName) {
    final role = msg['role'] ?? 'member';
    final rc = _roleColor(role);

    Map<String, dynamic>? replyMsg;
    if (msg['replyTo'] != null) {
      try {
        replyMsg = _messages.firstWhere((m) => m['id'] == msg['replyTo']);
      } catch (_) {}
    }

    return GestureDetector(
      onLongPress: () => _showOptions(msg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showName)
              Padding(
                padding: EdgeInsets.only(left: isMe ? 0 : 4, right: isMe ? 4 : 0, bottom: 4),
                child: Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rc.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(color: rc.withValues(alpha: 0.3)),
                      ),
                      child: Text(role.toString().toUpperCase(), style: TextStyle(color: rc, fontSize: 8, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (msg['from'] ?? '???').toString().toUpperCase(),
                      style: TextStyle(color: rc, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Orbitron', letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            if (replyMsg != null)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: AppTheme.cardDecor().copyWith(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((replyMsg['from'] ?? '').toString().toUpperCase(), style: TextStyle(color: _roleColor(replyMsg['role'] ?? ''), fontSize: 9, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      replyMsg['message'] ?? '[Media]',
                      style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: isMe
                  ? AppTheme.accentCardDecor(AppTheme.coral)
                  : AppTheme.cardDecor(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg['message'] != null)
                    Text(msg['message'].toString(), style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary, height: 1.4)),
                  if (msg['imageUrl'] != null && msg['imageUrl'].toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      child: Image.network(
                        msg['imageUrl'].toString(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : Padding(
                                padding: const EdgeInsets.all(20),
                                child: Center(child: CircularProgressIndicator(color: AppTheme.coral, strokeWidth: 2)),
                              ),
                        errorBuilder: (_, __, ___) => Padding(
                          padding: const EdgeInsets.all(20),
                          child: Icon(Icons.broken_image, color: AppTheme.textMuted, size: 48),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(_time(msg['time'] ?? ''), style: AppTheme.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: AppTheme.cardDecor(),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.sky,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Membalas ${(_replyTo!['from'] ?? '').toString().toUpperCase()}",
                          style: TextStyle(color: _roleColor(_replyTo!['role'] ?? ''), fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyTo!['message'] ?? '[Media]',
                          style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.sky,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softGlow(AppTheme.sky, blur: 8, opacity: 0.4),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: Lang.t('type_message'),
                    hintStyle: AppTheme.bodyL.copyWith(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.bgInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      borderSide: BorderSide(color: AppTheme.borderSubtle, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      borderSide: BorderSide(color: AppTheme.borderSubtle, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      borderSide: BorderSide(color: AppTheme.sky, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _msgCtrl.text.trim().isEmpty ? null : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _msgCtrl.text.trim().isEmpty ? AppTheme.textMuted : AppTheme.coral,
                    shape: BoxShape.circle,
                    boxShadow: _msgCtrl.text.trim().isEmpty
                        ? null
                        : AppTheme.softGlow(AppTheme.coral, blur: 8, opacity: 0.4),
                  ),
                  child: _sending
                      ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOnline() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
          border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ONLINE", style: AppTheme.headingS.copyWith(fontFamily: 'Orbitron', letterSpacing: 2)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _onlineUsers.length,
                itemBuilder: (ctx, i) {
                  final u = _onlineUsers[i];
                  final col = _roleColor(u['role'] ?? 'member');
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: col.withValues(alpha: 0.2),
                      child: Text(
                        (u['username'] ?? '?')[0].toString().toUpperCase(),
                        style: TextStyle(color: col, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(
                      (u['username'] ?? '').toString().toUpperCase(),
                      style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(color: col.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        (u['role'] ?? 'member').toString().toUpperCase(),
                        style: TextStyle(color: col, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
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

  void _showOptions(Map<String, dynamic> msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL))),
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
            border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.reply, color: AppTheme.sky),
                title: Text('Balas', style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _replyTo = msg);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
