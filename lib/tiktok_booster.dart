import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:darkverse/theme/app_theme.dart';
import 'api.dart';

class TiktokBoosterPage extends StatefulWidget {
  final String sessionKey;
  const TiktokBoosterPage({super.key, required this.sessionKey});
  @override
  State<TiktokBoosterPage> createState() => _TiktokBoosterPageState();
}

class _TiktokBoosterPageState extends State<TiktokBoosterPage> with TickerProviderStateMixin {
  static String get _base => ApiConfig.tiktokBoosterUrl;

  bool _running = false;
  String? _jobId;
  int _elapsed = 0, _duration = 180;
  int _views = 0, _viewsPerSec = 0, _targetViews = 5000;
  String _taskType = 'view';
  String _region = 'ID';

  final _urlCtrl = TextEditingController();
  final _viewsCtrl = TextEditingController(text: '5000');
  final _durCtrl  = TextEditingController(text: '180');

  Timer? _countTimer, _trackTimer, _statusTimer;
  late AnimationController _glowCtrl, _rotCtrl, _pulseCtrl;
  late Animation<double> _glowAnim, _rotAnim, _pulseAnim;

  static const _tasks = [
    {'label': 'Views',      'icon': '👁',  'type': 'view'},
    {'label': 'Likes',      'icon': '❤',  'type': 'like'},
    {'label': 'Comments',   'icon': '💬', 'type': 'comment'},
    {'label': 'Followers',  'icon': '👤', 'type': 'follow'},
    {'label': 'Shares',     'icon': '↗',  'type': 'share'},
    {'label': 'Saves',      'icon': '🔖', 'type': 'save'},
  ];

  static const _regions = [
    {'label': 'Indonesia', 'code': 'ID', 'flag': '🇮🇩'},
    {'label': 'USA',       'code': 'US', 'flag': '🇺🇸'},
    {'label': 'Europe',    'code': 'EU', 'flag': '🇪🇺'},
    {'label': 'Japan',     'code': 'JP', 'flag': '🇯🇵'},
    {'label': 'Korea',     'code': 'KR', 'flag': '🇰🇷'},
    {'label': 'India',     'code': 'IN', 'flag': '🇮🇳'},
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _rotCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _glowAnim  = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _rotAnim   = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _rotCtrl, curve: Curves.linear));
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose(); _rotCtrl.dispose(); _pulseCtrl.dispose();
    _countTimer?.cancel(); _trackTimer?.cancel(); _statusTimer?.cancel();
    _urlCtrl.dispose(); _viewsCtrl.dispose(); _durCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) { _showAlert('Error', 'Masukkan URL video TikTok!'); return; }
    _targetViews = int.tryParse(_viewsCtrl.text) ?? 5000;
    _duration    = int.tryParse(_durCtrl.text)   ?? 180;

    setState(() { _running = true; _elapsed = 0; _views = 0; _viewsPerSec = 0; });

    try {
      final res = await http.post(
        Uri.parse('$_base/api/boost/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url, 'type': _taskType, 'region': _region, 'targetViews': _targetViews, 'duration': _duration}),
      ).timeout(const Duration(seconds: 15));

      final body = res.body;
      if (body.trimLeft().startsWith('<')) throw Exception('Server error');
      final data = jsonDecode(body);

      if (data['success'] == true) {
        _jobId = data['jobId']?.toString();
        _countTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) { t.cancel(); return; }
          setState(() { _elapsed++; });
          if (_elapsed >= _duration) { t.cancel(); _finish(); }
        });
        _trackTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
          if (!mounted || !_running) return;
          final n = Random().nextInt(50) + 30;
          setState(() { _views += n; _viewsPerSec = n * 2; });
        });
        _statusTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollStatus());
      } else {
        _showAlert('Failed', data['message'] ?? 'Gagal memulai boost');
        setState(() { _running = false; });
      }
    } catch (e) {
      _showAlert('Error', '$e');
      setState(() { _running = false; });
    }
  }

  Future<void> _pollStatus() async {
    if (_jobId == null || !_running) return;
    try {
      final res = await http.get(Uri.parse('$_base/api/boost/status/$_jobId')).timeout(const Duration(seconds: 5));
      final body = res.body;
      if (body.trimLeft().startsWith('<')) return;
      final data = jsonDecode(body);
      if (mounted && data['active'] == true) {
        setState(() {
          _views = (data['current'] as num?)?.toInt() ?? _views;
          _viewsPerSec = (data['speed'] as num?)?.toInt() ?? _viewsPerSec;
        });
      }
    } catch (_) {}
  }

  Future<void> _stop() async {
    _countTimer?.cancel(); _trackTimer?.cancel(); _statusTimer?.cancel();
    if (_jobId != null) {
      try { await http.post(Uri.parse('$_base/api/boost/stop/$_jobId')).timeout(const Duration(seconds: 8)); } catch (_) {}
    }
    setState(() { _running = false; });
  }

  void _finish() {
    _trackTimer?.cancel(); _statusTimer?.cancel();
    if (!mounted) return;
    setState(() { _running = false; });
  }

  void _showAlert(String title, String body) {
    if (!mounted) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM), side: const BorderSide(color: AppTheme.borderSubtle)),
      title: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppTheme.coral, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTheme.headingS.copyWith(color: AppTheme.coral)),
      ]),
      content: Text(body, style: AppTheme.bodyL),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: AppTheme.teal)))],
    ));
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: RadialGradient(center: Alignment.topCenter, radius: 1.4,
            colors: [AppTheme.coral.withValues(alpha: 0.04), Colors.transparent])))),
        SafeArea(child: Column(children: [
          _header(),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(13, 6, 13, 10),
            child: Column(children: [
              _taskPicker(),
              const SizedBox(height: 10),
              _configCard(),
              const SizedBox(height: 10),
              _regionPicker(),
              if (_running) ...[const SizedBox(height: 10), _progressCard()],
            ]),
          )),
          _launchBtn(),
        ])),
      ]),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.fromLTRB(13, 10, 13, 4),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: AppTheme.cardDecor().copyWith(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [BoxShadow(color: AppTheme.coral.withValues(alpha: 0.06), blurRadius: 18)],
      ),
      child: Row(children: [
        AnimatedBuilder(animation: Listenable.merge([_glowAnim, _rotAnim]), builder: (_, __) =>
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient(AppTheme.coral),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppTheme.coral.withValues(alpha: 0.3 + _glowAnim.value * 0.25), blurRadius: 16)]),
            child: Transform.rotate(angle: _rotAnim.value * 2 * pi,
              child: const Icon(Icons.trending_up_rounded, color: AppTheme.bgDeep, size: 19)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('TIKTOK BOOSTER', style: AppTheme.label.copyWith(color: AppTheme.coral, letterSpacing: 2)),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: AppTheme.coral.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.coral.withValues(alpha: 0.3))),
              child: Text('multi-thread', style: AppTheme.caption.copyWith(color: AppTheme.coral, fontSize: 7))),
          ]),
          Text('Views · Likes · Followers · Shares', style: AppTheme.bodyM),
        ])),
        _statusBadge(),
      ]),
    );
  }

  Widget _statusBadge() {
    final c = _running ? AppTheme.coral : AppTheme.mint;
    final l = _running ? 'LIVE' : 'READY';
    return AnimatedBuilder(animation: _pulseAnim, builder: (_, __) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.35 + _pulseAnim.value * 0.45)),
          boxShadow: _running ? [BoxShadow(color: c.withValues(alpha: _pulseAnim.value * 0.3), blurRadius: 12)] : []),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(
            color: c, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.withValues(alpha: _pulseAnim.value), blurRadius: 6)])),
          const SizedBox(width: 5),
          Text(l, style: AppTheme.caption.copyWith(color: c, letterSpacing: 1)),
        ])));
  }

  Widget _taskPicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _hdr(Icons.category_rounded, 'BOOST TYPE'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 3.2, mainAxisSpacing: 7, crossAxisSpacing: 7),
          itemCount: _tasks.length,
          itemBuilder: (_, i) {
            final t = _tasks[i];
            final on = _taskType == t['type'];
            final c = on ? AppTheme.coral : AppTheme.textMuted;
            return GestureDetector(
              onTap: () => setState(() => _taskType = t['type']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: on ? AppTheme.coral.withValues(alpha: 0.10) : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: on ? AppTheme.coral : AppTheme.borderSubtle, width: on ? 1.5 : 1),
                  boxShadow: on ? [BoxShadow(color: AppTheme.coral.withValues(alpha: 0.12), blurRadius: 8)] : []),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(t['icon']!, style: TextStyle(fontSize: 13, color: c)),
                  const SizedBox(height: 2),
                  Text(t['label']!, style: AppTheme.caption.copyWith(color: c, fontSize: 8.5)),
                ])));
          }),
      ]),
    );
  }

  Widget _configCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _hdr(Icons.tune_rounded, 'CONFIGURATION'),
        const SizedBox(height: 12),
        Container(
          decoration: AppTheme.inputDecor(),
          child: TextField(controller: _urlCtrl,
            style: AppTheme.bodyL.copyWith(color: AppTheme.coral, fontFamily: 'Courier', fontSize: 12),
            cursorColor: AppTheme.coral,
            decoration: InputDecoration(
              labelText: 'VIDEO URL', hintText: 'https://vm.tiktok.com/...',
              hintStyle: AppTheme.bodyM.copyWith(color: AppTheme.textMuted),
              labelStyle: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
              prefixIcon: Icon(Icons.link_rounded, color: AppTheme.coral.withValues(alpha: 0.5), size: 14),
              filled: false, border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _field(_viewsCtrl, 'TARGET VIEWS', Icons.visibility_rounded, TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: _field(_durCtrl, 'DURATION (s)', Icons.timer_rounded, TextInputType.number)),
        ]),
      ]),
    );
  }

  Widget _regionPicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _hdr(Icons.language_rounded, 'TARGET REGION'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 3.0, mainAxisSpacing: 7, crossAxisSpacing: 7),
          itemCount: _regions.length,
          itemBuilder: (_, i) {
            final r = _regions[i];
            final on = _region == r['code'];
            return GestureDetector(
              onTap: () => setState(() => _region = r['code']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: on ? AppTheme.sky.withValues(alpha: 0.10) : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: on ? AppTheme.sky : AppTheme.borderSubtle, width: on ? 1.5 : 1)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(r['flag']!, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 5),
                  Text(r['label']!, style: AppTheme.caption.copyWith(color: on ? AppTheme.sky : AppTheme.textSecondary, fontSize: 8.5)),
                ])));
          }),
      ]),
    );
  }

  Widget _progressCard() {
    final progress = _targetViews > 0 ? (_views / _targetViews).clamp(0.0, 1.0) : 0.0;
    return AnimatedBuilder(animation: _glowAnim, builder: (_, __) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.accentCardDecor(AppTheme.coral).copyWith(
          boxShadow: [
            BoxShadow(color: AppTheme.coral.withValues(alpha: _glowAnim.value * 0.12), blurRadius: 24),
            BoxShadow(color: AppTheme.coral.withValues(alpha: _glowAnim.value * 0.06), blurRadius: 48)]),
        child: Column(children: [
          Row(children: [
            AnimatedBuilder(animation: _pulseAnim, builder: (_, __) =>
              Container(width: 10, height: 10, decoration: BoxDecoration(
                color: AppTheme.coral, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.coral.withValues(alpha: _pulseAnim.value), blurRadius: 8, spreadRadius: 1)]))),
            const SizedBox(width: 8),
            Text('BOOST IN PROGRESS', style: AppTheme.label.copyWith(color: AppTheme.coral, letterSpacing: 1.5)),
            const Spacer(),
            Text('${(_elapsed / _duration * 100).toInt()}%', style: AppTheme.headingM.copyWith(color: AppTheme.coral, fontFamily: 'Courier',
              shadows: [Shadow(color: AppTheme.coral.withValues(alpha: _glowAnim.value * 0.8), blurRadius: 10)])),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _statBox('CURRENT', _fmt(_views), AppTheme.coral),
            const SizedBox(width: 6),
            _statBox('TARGET', _fmt(_targetViews), AppTheme.sky),
            const SizedBox(width: 6),
            _statBox('SPEED', '${_viewsPerSec}/s', AppTheme.mint),
            const SizedBox(width: 6),
            _statBox('LEFT', '${(_duration - _elapsed).clamp(0, _duration)}s', AppTheme.gold),
          ]),
          const SizedBox(height: 14),
          Stack(children: [
            Container(height: 8, decoration: BoxDecoration(
              color: AppTheme.bgInput, borderRadius: BorderRadius.circular(4))),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.sky, AppTheme.coral, AppTheme.lavender]),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: AppTheme.coral.withValues(alpha: _glowAnim.value * 0.9), blurRadius: 10, spreadRadius: 1),
                    BoxShadow(color: AppTheme.coral.withValues(alpha: _glowAnim.value * 0.5), blurRadius: 20)]))),
          ]),
        ])));
  }

  Widget _launchBtn() {
    return AnimatedBuilder(animation: _glowAnim, builder: (_, __) {
      return Container(
        margin: const EdgeInsets.fromLTRB(13, 6, 13, 16),
        child: GestureDetector(
          onTap: _running ? _stop : _launch,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 62,
            decoration: BoxDecoration(
              gradient: _running
                ? LinearGradient(colors: [AppTheme.coral.withValues(alpha: 0.3), AppTheme.coral, AppTheme.coral])
                : LinearGradient(colors: [AppTheme.sky.withValues(alpha: 0.3), AppTheme.sky, AppTheme.coral]),
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(color: (_running ? AppTheme.coral : AppTheme.coral).withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(color: (_running ? AppTheme.coral : AppTheme.coral).withValues(alpha: _glowAnim.value * 0.5), blurRadius: 28, spreadRadius: 2),
                BoxShadow(color: (_running ? AppTheme.coral : AppTheme.coral).withValues(alpha: _glowAnim.value * 0.2), blurRadius: 60, spreadRadius: 8)]),
            child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_running ? Icons.stop_circle_rounded : Icons.rocket_launch_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(_running ? 'STOP BOOST' : 'LAUNCH BOOST',
                style: AppTheme.headingM.copyWith(fontFamily: 'Courier', letterSpacing: 2)),
            ])))));
    });
  }

  Widget _hdr(IconData icon, String title) => Row(children: [
    Icon(icon, color: AppTheme.coral, size: 13), const SizedBox(width: 7),
    Text(title, style: AppTheme.label.copyWith(color: AppTheme.coral, letterSpacing: 1.3)),
    const Spacer(),
    Container(width: 26, height: 1, color: AppTheme.borderSubtle),
  ]);

  Widget _field(TextEditingController c, String label, IconData icon, TextInputType kb) =>
    Container(
      decoration: AppTheme.inputDecor(),
      child: TextField(controller: c, keyboardType: kb,
        style: AppTheme.bodyL.copyWith(color: AppTheme.coral, fontFamily: 'Courier', fontSize: 13),
        cursorColor: AppTheme.coral,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.coral.withValues(alpha: 0.5), size: 14),
          filled: false, border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
      ),
    );

  Widget _statBox(String label, String val, Color c) =>
    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 7),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(AppTheme.radiusS), border: Border.all(color: c.withValues(alpha: 0.18))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTheme.caption.copyWith(color: c.withValues(alpha: 0.45), fontSize: 6.5, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(val, style: AppTheme.bodyM.copyWith(color: c, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      ])));
}
