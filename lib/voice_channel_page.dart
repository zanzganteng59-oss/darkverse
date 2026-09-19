import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class VoiceChannelPage extends StatefulWidget {
  final WebSocketChannel ws;
  final String username;
  final String role;

  const VoiceChannelPage({
    super.key,
    required this.ws,
    required this.username,
    required this.role,
  });

  @override
  State<VoiceChannelPage> createState() => _VoiceChannelPageState();
}

class _VoiceChannelPageState extends State<VoiceChannelPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _participants = [];
  bool _joined = false;
  bool _muted = false;
  bool _speakerOn = true;
  int _callDuration = 0;
  Timer? _durationTimer;
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late AnimationController _waveController;

  static const Color bgDark = Color(0xFF0D0D0D);
  static const Color bgCard = Color(0xFF1A1A1A);
  static const Color accentRed = Color(0xFFFF1744);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentPurple = Color(0xFFB388FF);
  static const Color accentBlue = Color(0xFF448AFF);
  static const Color accentOrange = Color(0xFFFF9100);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSub = Color(0xFF999999);
  static const Color textFaint = Color(0xFF555555);

  Color _alpha(Color c, double a) => Color.fromARGB((a * 255).round(), c.red, c.green, c.blue);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _listenWs();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    _ringController.dispose();
    _waveController.dispose();
    if (_joined) {
      widget.ws.sink.add(jsonEncode({"type": "voice:leave"}));
    }
    super.dispose();
  }

  void _listenWs() {
    widget.ws.stream.listen(
      (event) {
        final data = jsonDecode(event);
        if (!mounted) return;
        if (data['type'] == 'voice:participants') {
          final list = data['participants'] as List? ?? [];
          setState(() {
            _participants = list.map((p) => Map<String, dynamic>.from(p)).toList();
            final me = _participants.where((p) => p['username'] == widget.username);
            if (me.isEmpty && _joined) {
              _joined = false;
              _durationTimer?.cancel();
            }
          });
        }
        if (data['type'] == 'voice:speaking') {
          final uname = data['username'];
          final speaking = data['speaking'] ?? false;
          setState(() {
            final idx = _participants.indexWhere((p) => p['username'] == uname);
            if (idx != -1) _participants[idx]['speaking'] = speaking;
          });
        }
      },
      onError: (_) {},
    );
  }

  void _joinChannel() {
    widget.ws.sink.add(jsonEncode({"type": "voice:join"}));
    setState(() => _joined = true);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  void _leaveChannel() {
    widget.ws.sink.add(jsonEncode({"type": "voice:leave"}));
    setState(() {
      _joined = false;
      _callDuration = 0;
      _muted = false;
    });
    _durationTimer?.cancel();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    widget.ws.sink.add(jsonEncode({"type": "voice:mute", "muted": _muted}));
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'developer': return accentPurple;
      case 'all_akses': return accentBlue;
      case 'owner': return accentOrange;
      case 'vip': return const Color(0xFFFF80AB);
      case 'reseller': return accentGreen;
      default: return textSub;
    }
  }

  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: _joined ? _buildInCallView() : _buildLobbyView(),
      ),
    );
  }

  // ===== LOBBY (before join) =====
  Widget _buildLobbyView() {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: const Icon(Icons.arrow_back_ios_new, color: textWhite, size: 18),
                ),
              ),
              const Expanded(child: Center(
                child: Text("VOICE CHANNEL", style: TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Orbitron', letterSpacing: 3)),
              )),
              const SizedBox(width: 34),
            ],
          ),
        ),
        Expanded(child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_alpha(accentGreen, 0.15), _alpha(accentBlue, 0.15)]),
                  border: Border.all(color: _alpha(accentGreen, 0.3), width: 2),
                ),
                child: const Icon(Icons.mic, color: accentGreen, size: 48),
              ),
              const SizedBox(height: 24),
              const Text("VOICE CHANNEL", style: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Orbitron', letterSpacing: 2)),
              const SizedBox(height: 8),
              Text("${_participants.length} online", style: TextStyle(color: textSub, fontSize: 13)),
              const SizedBox(height: 32),
              // Participants preview
              if (_participants.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _participants.length,
                    itemBuilder: (ctx, i) => _buildLobbyAvatar(_participants[i]),
                  ),
                ),
            ],
          ),
        )),
        // Join button
        Padding(
          padding: const EdgeInsets.all(32),
          child: GestureDetector(
            onTap: _joinChannel,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentGreen,
                boxShadow: [BoxShadow(color: _alpha(accentGreen, 0.5), blurRadius: 20, spreadRadius: 2)],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 32),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLobbyAvatar(Map<String, dynamic> p) {
    final uname = p['username'] ?? '???';
    final role = p['role'] ?? 'member';
    final rc = _roleColor(role);
    return Container(
      width: 56, margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _alpha(rc, 0.2), border: Border.all(color: _alpha(rc, 0.4), width: 2)),
            child: Center(child: Text(uname[0].toString().toUpperCase(), style: TextStyle(color: rc, fontSize: 18, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(height: 4),
          Text(uname.toString().substring(0, min(uname.length, 8)).toUpperCase(), style: const TextStyle(color: textSub, fontSize: 9, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ===== IN-CALL VIEW (WhatsApp style) =====
  Widget _buildInCallView() {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () { _leaveChannel(); Navigator.pop(context); },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: const Icon(Icons.arrow_back_ios_new, color: textWhite, size: 18),
                ),
              ),
              const Expanded(child: Center(
                child: Text("VOICE CHANNEL", style: TextStyle(color: accentGreen, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Orbitron', letterSpacing: 3)),
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _alpha(accentGreen, 0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: accentGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text("${_participants.length}", style: const TextStyle(color: accentGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Call duration
        Text(_formatDuration(_callDuration), style: const TextStyle(color: textWhite, fontSize: 36, fontWeight: FontWeight.w100, fontFamily: 'Orbitron', letterSpacing: 4)),
        const SizedBox(height: 4),
        Text("Connected", style: TextStyle(color: _alpha(accentGreen, 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        // Participant grid
        Expanded(
          child: _participants.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedBuilder(animation: _pulseController, builder: (_, __) {
                    return Container(
                      width: 100 + _pulseController.value * 8, height: 100 + _pulseController.value * 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _alpha(accentGreen, 0.08 + _pulseController.value * 0.04), border: Border.all(color: _alpha(accentGreen, 0.2), width: 1)),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Text("Menunggu peserta lain...", style: TextStyle(color: textFaint, fontSize: 14)),
                ]))
              : _participants.length == 1
                  ? _buildSingleParticipant(_participants[0])
                  : _buildMultiParticipantGrid(),
        ),
        // Controls
        _buildWhatsAppControls(),
      ],
    );
  }

  Widget _buildSingleParticipant(Map<String, dynamic> p) {
    final uname = p['username'] ?? '???';
    final role = p['role'] ?? 'member';
    final rc = _roleColor(role);
    final isMuted = p['muted'] ?? false;
    final isSpeaking = p['speaking'] ?? false;
    final isMe = uname == widget.username;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated ring
          AnimatedBuilder(
            animation: _ringController,
            builder: (_, child) {
              return Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSpeaking
                        ? _alpha(accentGreen, 0.3 + sin(_ringController.value * pi * 2) * 0.3)
                        : _alpha(rc, 0.2),
                    width: isSpeaking ? 3 : 2,
                  ),
                ),
                child: Center(child: child),
              );
            },
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_alpha(rc, 0.3), _alpha(rc, 0.1)]),
              ),
              child: Center(
                child: Text(uname[0].toString().toUpperCase(), style: TextStyle(color: rc, fontSize: 48, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(isMe ? "YOU" : uname.toString().toUpperCase(), style: TextStyle(color: isMe ? accentGreen : textWhite, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Orbitron', letterSpacing: 2)),
          const SizedBox(height: 8),
          if (isSpeaking)
            Row(mainAxisSize: MainAxisSize.min, children: [
              ...List.generate(5, (i) => AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) {
                  final h = 4.0 + sin((_waveController.value * pi * 2) + i * 0.8).abs() * 12;
                  return Container(
                    width: 3, height: h, margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: accentGreen, borderRadius: BorderRadius.circular(2)),
                  );
                },
              )),
              const SizedBox(width: 8),
              const Text("Speaking", style: TextStyle(color: accentGreen, fontSize: 12)),
            ])
          else if (isMuted)
            const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.mic_off, color: accentRed, size: 16),
              SizedBox(width: 6),
              Text("Muted", style: TextStyle(color: accentRed, fontSize: 12)),
            ])
          else
            Text(isMe ? "Tap mic to speak" : "Listening", style: const TextStyle(color: textFaint, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMultiParticipantGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _participants.length <= 4 ? 2 : 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _participants.length,
      itemBuilder: (ctx, i) => _buildParticipantTile(_participants[i]),
    );
  }

  Widget _buildParticipantTile(Map<String, dynamic> p) {
    final uname = p['username'] ?? '???';
    final role = p['role'] ?? 'member';
    final rc = _roleColor(role);
    final isMuted = p['muted'] ?? false;
    final isSpeaking = p['speaking'] ?? false;
    final isMe = uname == widget.username;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ringController,
          builder: (_, child) {
            return Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSpeaking
                      ? _alpha(accentGreen, 0.4 + sin(_ringController.value * pi * 2) * 0.4)
                      : _alpha(rc, 0.25),
                  width: isSpeaking ? 2.5 : 1.5,
                ),
              ),
              child: Center(child: child),
            );
          },
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _alpha(rc, 0.15),
            ),
            child: Center(child: Text(uname[0].toString().toUpperCase(), style: TextStyle(color: rc, fontSize: 22, fontWeight: FontWeight.w900))),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isMe ? "YOU" : uname.toString().toUpperCase(),
          style: TextStyle(color: isMe ? accentGreen : textWhite, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (isSpeaking)
          AnimatedBuilder(
            animation: _waveController,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                width: 2, height: 4 + sin((_waveController.value * pi * 2) + i).abs() * 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: accentGreen, borderRadius: BorderRadius.circular(1)),
              )),
            ),
          )
        else if (isMuted)
          const Icon(Icons.mic_off, color: accentRed, size: 14)
        else
          Icon(Icons.mic_none, color: textFaint, size: 14),
      ],
    );
  }

  // ===== WHATSAPP-STYLE CONTROLS =====
  Widget _buildWhatsAppControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: _muted ? "Unmute" : "Mute",
                  isActive: _muted,
                  activeColor: accentRed,
                  onTap: _toggleMute,
                ),
                _buildControlButton(
                  icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  label: _speakerOn ? "Speaker" : "Earpiece",
                  isActive: !_speakerOn,
                  activeColor: accentOrange,
                  onTap: () => setState(() => _speakerOn = !_speakerOn),
                ),
                _buildControlButton(
                  icon: Icons.people_rounded,
                  label: "${_participants.length}",
                  isActive: false,
                  activeColor: accentBlue,
                  onTap: () {},
                ),
                // End call button
                GestureDetector(
                  onTap: () { _leaveChannel(); Navigator.pop(context); },
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFFFF1744), Color(0xFFFF5252)]),
                      boxShadow: [BoxShadow(color: _alpha(accentRed, 0.5), blurRadius: 16, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? _alpha(activeColor, 0.2) : const Color(0xFF222222),
              border: Border.all(color: isActive ? _alpha(activeColor, 0.5) : Colors.white10, width: 1.5),
            ),
            child: Icon(icon, color: isActive ? activeColor : textWhite, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: isActive ? activeColor : textSub, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
