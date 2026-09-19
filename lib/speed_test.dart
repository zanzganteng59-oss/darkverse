import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:darkverse/theme/app_theme.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> with SingleTickerProviderStateMixin {
  bool _isTesting = false;
  double _ping = 0;
  double _downloadMbps = 0;
  double _uploadMbps = 0;
  String _status = 'Siap melakukan test';
  String _phase = '';
  double _progress = 0;

  late AnimationController _dialController;
  late Animation<double> _dialAnim;

  @override
  void initState() {
    super.initState();
    _dialController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _dialAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _dialController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _dialController.dispose();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() { _isTesting = true; _ping = 0; _downloadMbps = 0; _uploadMbps = 0; _progress = 0; });

    setState(() { _phase = 'ping'; _status = 'Mengukur latency...'; });
    final pings = <double>[];
    for (int i = 0; i < 5; i++) {
      try {
        final sw = Stopwatch()..start();
        await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
        sw.stop();
        pings.add(sw.elapsedMilliseconds.toDouble());
      } catch (_) { pings.add(999); }
      setState(() => _progress = (i + 1) / 5 * 0.2);
    }
    pings.sort();
    setState(() => _ping = pings[pings.length ~/ 2]);

    setState(() { _phase = 'download'; _status = 'Mengukur download speed...'; });
    double totalDl = 0;
    final dlUrls = ['https://speed.cloudflare.com/__down?bytes=1000000', 'https://httpbin.org/bytes/500000'];
    for (int i = 0; i < dlUrls.length; i++) {
      try {
        final sw = Stopwatch()..start();
        final resp = await http.get(Uri.parse(dlUrls[i])).timeout(const Duration(seconds: 10));
        sw.stop();
        final bytes = resp.bodyBytes.length;
        final seconds = sw.elapsedMilliseconds / 1000;
        if (seconds > 0 && bytes > 1000) totalDl += (bytes * 8) / (seconds * 1000000);
      } catch (_) {}
      setState(() => _progress = 0.2 + (i + 1) / dlUrls.length * 0.4);
    }
    setState(() => _downloadMbps = totalDl > 0 ? totalDl / 2 : 0);
    _dialController.forward(from: 0);

    setState(() { _phase = 'upload'; _status = 'Mengukur upload speed...'; });
    double totalUl = 0;
    for (int i = 0; i < 2; i++) {
      try {
        final data = List.filled(250000, 0);
        final sw = Stopwatch()..start();
        await http.post(Uri.parse('https://httpbin.org/post'), body: data, headers: {'Content-Type': 'application/octet-stream'}).timeout(const Duration(seconds: 10));
        sw.stop();
        final seconds = sw.elapsedMilliseconds / 1000;
        if (seconds > 0) totalUl += (250000 * 8) / (seconds * 1000000);
      } catch (_) {}
      setState(() => _progress = 0.6 + (i + 1) / 2 * 0.4);
    }
    setState(() { _uploadMbps = totalUl > 0 ? totalUl / 2 : 0; _isTesting = false; _phase = 'done'; _status = 'Test selesai!'; _progress = 1.0; });
  }

  String _rating(double dl) {
    if (dl <= 0) return '-';
    if (dl < 1) return 'Sangat Lambat';
    if (dl < 5) return 'Lambat';
    if (dl < 25) return 'Cukup';
    if (dl < 100) return 'Cepat';
    if (dl < 500) return 'Sangat Cepat';
    return 'Luar Biasa';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text("SPEED TEST", style: AppTheme.headingM),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: AppTheme.cardDecor(),
              child: Column(children: [
                SizedBox(
                  width: 200, height: 200,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox(
                      width: 180, height: 180,
                      child: CircularProgressIndicator(
                        value: _isTesting ? _progress : (_phase == 'done' ? 1.0 : 0),
                        backgroundColor: AppTheme.bgInput,
                        color: _phase == 'ping' ? AppTheme.gold : _phase == 'download' ? AppTheme.teal : _phase == 'upload' ? AppTheme.lavender : _phase == 'done' ? AppTheme.mint : AppTheme.sky,
                        strokeWidth: 12, strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_phase == 'download' || _phase == 'done')
                        Text(_downloadMbps > 0 ? _downloadMbps.toStringAsFixed(1) : '--', style: AppTheme.headingL.copyWith(color: AppTheme.teal, fontFamily: 'Orbitron'))
                      else if (_phase == 'ping')
                        Text(_ping > 0 ? '${_ping.round()}ms' : '--', style: AppTheme.headingM.copyWith(color: AppTheme.gold, fontFamily: 'Orbitron'))
                      else
                        Text('--', style: AppTheme.headingL.copyWith(color: AppTheme.textMuted, fontFamily: 'Orbitron')),
                      Text(_phase == 'ping' ? 'PING' : 'Mbps', style: AppTheme.caption),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),
                Text(_status, style: AppTheme.caption),
              ]),
            ),
            const SizedBox(height: 20),

            Row(children: [
              Expanded(child: _statCard("PING", _ping > 0 ? '${_ping.round()} ms' : '--', Icons.swap_horiz, AppTheme.gold)),
              const SizedBox(width: 12),
              Expanded(child: _statCard("DOWNLOAD", _downloadMbps > 0 ? '${_downloadMbps.toStringAsFixed(1)} Mbps' : '--', Icons.download, AppTheme.teal)),
              const SizedBox(width: 12),
              Expanded(child: _statCard("UPLOAD", _uploadMbps > 0 ? '${_uploadMbps.toStringAsFixed(1)} Mbps' : '--', Icons.upload, AppTheme.lavender)),
            ]),
            const SizedBox(height: 20),

            if (_phase == 'done') ...[
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: AppTheme.accentCardDecor(AppTheme.mint),
                child: Row(children: [
                  const Icon(Icons.speed, color: AppTheme.mint, size: 22),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("KUALITAS KONEKSI", style: AppTheme.label.copyWith(color: AppTheme.textSecondary)),
                    Text(_rating(_downloadMbps), style: AppTheme.headingM),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isTesting ? null : _startTest,
                style: AppTheme.primaryButton(AppTheme.lavender),
                child: _isTesting
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text("TESTING...", style: AppTheme.headingS),
                      ])
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.play_circle_outline, color: Colors.white),
                        const SizedBox(width: 10),
                        Text("MULAI TEST", style: AppTheme.headingS),
                      ]),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: AppTheme.accentCardDecor(color),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(label, style: AppTheme.caption),
      const SizedBox(height: 4),
      Text(value, style: AppTheme.headingS.copyWith(color: color, fontFamily: 'Orbitron'), textAlign: TextAlign.center),
    ]),
  );
}
