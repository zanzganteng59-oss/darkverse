import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:darkverse/theme/app_theme.dart';

const String _groqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: 'gsk_REDACTED');
const String _groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';
const String _model = 'llama-3.3-70b-versatile';

class AIPage extends StatefulWidget {
  final String username;
  final String sessionKey;
  const AIPage({super.key, required this.username, required this.sessionKey});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<String?> _sendToGroq(List<Map<String, dynamic>> messages) async {
    try {
      final res = await http.post(
        Uri.parse(_groqBaseUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_groqApiKey'},
        body: jsonEncode({'model': _model, 'messages': messages, 'temperature': 0.9, 'max_tokens': 1024}),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices']?[0]?['message']?['content'] ?? 'Maaf, tidak ada respons.';
      } else if (res.statusCode == 429) {
        return 'Rate limit Groq tercapai. Tunggu sebentar dan coba lagi.';
      } else if (res.statusCode == 401) {
        return 'API Key Groq tidak valid. Cek lagi di console.groq.com/keys';
      } else {
        final error = jsonDecode(res.body);
        return 'Error ${res.statusCode}: ${error['error']?['message'] ?? 'Unknown error'}';
      }
    } catch (e) {
      return 'Koneksi gagal: $e';
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;
    setState(() { _messages.add({'role': 'user', 'text': text}); _isLoading = true; });
    _inputCtrl.clear();
    _scrollToBottom();

    final groqMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': 'Kamu adalah MEGATRON, asisten AI yang cerdas, ramah, dan cepat. Jawab dalam bahasa Indonesia jika user pakai bahasa Indonesia. Gaya bahasa santai tapi informatif.'}
    ];
    for (final msg in _messages) {
      groqMessages.add({'role': msg['role'] == 'user' ? 'user' : 'assistant', 'content': msg['text']});
    }

    final reply = await _sendToGroq(groqMessages);
    setState(() {
      if (reply != null) {
        _messages.add({'role': 'model', 'text': reply});
      } else {
        _messages.add({'role': 'model', 'text': 'Gagal terhubung ke Groq. Periksa koneksi internetmu.'});
      }
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient(AppTheme.lavender),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MEGATRON', style: AppTheme.headingM.copyWith(fontFamily: 'Orbitron')),
            Text('Powered by Groq', style: AppTheme.caption.copyWith(color: AppTheme.lavender)),
          ]),
        ]),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.textMuted),
              tooltip: 'Hapus Chat',
              onPressed: () => setState(() => _messages.clear()),
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _messages.length) return _buildTypingIndicator();
                    final msg = _messages[i];
                    return _buildBubble(text: msg['text']!, isUser: msg['role'] == 'user');
                  },
                ),
        ),
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.lavender.withValues(alpha: 0.1)),
          child: const Icon(Icons.auto_awesome, color: AppTheme.lavender, size: 44),
        ),
        const SizedBox(height: 20),
        Text('MEGATRON Siap Membantu!', style: AppTheme.headingL),
        const SizedBox(height: 10),
        Text('Ultra-fast responses with Groq LPU', style: AppTheme.bodyL),
        const SizedBox(height: 30),
        Wrap(
          spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
          children: ['Ide konten TikTok', 'Tips keamanan siber', 'Cara coding Flutter', 'Apa itu AI?'].map((hint) => GestureDetector(
            onTap: () { _inputCtrl.text = hint; _sendMessage(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.lavender.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.3)),
              ),
              child: Text(hint, style: AppTheme.bodyM.copyWith(color: AppTheme.lavender)),
            ),
          )).toList(),
        ),
      ]),
    );
  }

  Widget _buildBubble({required String text, required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 10, left: isUser ? 60 : 0, right: isUser ? 0 : 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isUser ? AppTheme.accentGradient(AppTheme.lavender) : null,
          color: isUser ? null : AppTheme.bgCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4), bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppTheme.lavender.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: AppTheme.lavender.withValues(alpha: isUser ? 0.15 : 0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!isUser) ...[
            const Icon(Icons.auto_awesome, color: AppTheme.lavender, size: 14),
            const SizedBox(width: 6),
          ],
          Flexible(child: Text(text, style: TextStyle(color: isUser ? Colors.white : AppTheme.textPrimary, fontSize: 13.5, height: 1.5))),
        ]),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_awesome, color: AppTheme.lavender, size: 14),
          const SizedBox(width: 8),
          SizedBox(width: 40, height: 16, child: _DotsIndicator(color: AppTheme.lavender)),
        ]),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: const BoxDecoration(color: AppTheme.bgDeep, border: Border(top: BorderSide(color: AppTheme.borderSubtle))),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: AppTheme.inputDecor(),
            child: TextField(
              controller: _inputCtrl,
              style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary),
              maxLines: 4, minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Tulis pesan...', hintStyle: AppTheme.bodyM,
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: _isLoading ? null : AppTheme.accentGradient(AppTheme.lavender),
              color: _isLoading ? AppTheme.bgCardLight : null,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppTheme.lavender.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: _isLoading
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _DotsIndicator extends StatefulWidget {
  final Color color;
  const _DotsIndicator({required this.color});
  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          final delay = i / 3;
          final val = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final opacity = (val < 0.5 ? val * 2 : (1 - val) * 2).clamp(0.2, 1.0);
          return Opacity(opacity: opacity, child: Container(width: 7, height: 7, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)));
        }),
      ),
    );
  }
}
