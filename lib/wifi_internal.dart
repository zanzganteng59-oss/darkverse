import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'package:darkverse/theme/app_theme.dart';

class WifiInternalPage extends StatefulWidget {
  final String sessionKey;
  const WifiInternalPage({super.key, required this.sessionKey});

  @override
  State<WifiInternalPage> createState() => _WifiInternalPageState();
}

class _WifiInternalPageState extends State<WifiInternalPage> {
  String publicIp = "-";
  String region = "-";
  String asn = "-";
  bool isVpn = false;
  bool isLoading = true;
  bool isAttacking = false;

  @override
  void initState() {
    super.initState();
    _loadPublicInfo();
  }

  Future<void> _loadPublicInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final ipRes = await http.get(Uri.parse("https://api.ipify.org?format=json"));
      final ipJson = jsonDecode(ipRes.body);
      final ip = ipJson['ip'];

      final infoRes = await http.get(Uri.parse("http://ip-api.com/json/$ip?fields=as,regionName,status,query"));
      final info = jsonDecode(infoRes.body);

      final asnRaw = (info['as'] as String).toLowerCase();
      final isBlockedAsn = asnRaw.contains("vpn") ||
          asnRaw.contains("cloud") ||
          asnRaw.contains("digitalocean") ||
          asnRaw.contains("aws") ||
          asnRaw.contains("google");

      setState(() {
        publicIp = ip;
        region = info['regionName'] ?? "-";
        asn = info['as'] ?? "-";
        isVpn = isBlockedAsn;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        publicIp = region = asn = "Error";
        isLoading = false;
      });
    }
  }

  Future<void> _attackTarget() async {
    setState(() => isAttacking = true);
    final url = Uri.parse(
        "${ApiConfig.baseUrl3}/killWifi?key=${widget.sessionKey}&target=$publicIp&duration=120");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        _showAlert("Attack Sent", "WiFi attack sent to $publicIp");
      } else {
        _showAlert("Failed", "Server rejected request.");
      }
    } catch (e) {
      _showAlert("Error", "Network error: $e");
    } finally {
      setState(() => isAttacking = false);
    }
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: AppTheme.teal)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecor(),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.teal),
        title: Text(title, style: AppTheme.headingS),
        subtitle: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Text("WiFi Killer ( Internal )", style: AppTheme.headingM),
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.lavender))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("System Information", style: AppTheme.headingL),
              const SizedBox(height: 12),

              _infoCard("IP Address", publicIp, Icons.language),
              _infoCard("Region", region, Icons.map),
              _infoCard("ASN", asn, Icons.storage),

              const SizedBox(height: 20),

              if (isVpn)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.accentCardDecor(AppTheme.coral),
                  child: Text(
                    "⚠️ Target berasal dari VPN/Hosting.\nSerangan dibatalkan.",
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyL,
                  ),
                ),

              if (!isVpn)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: isAttacking ? null : _attackTarget,
                    icon: const Icon(Icons.wifi_off, color: AppTheme.bgDeep),
                    label: Text(
                      isAttacking ? "ATTACKING..." : "START KILL",
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.bgDeep),
                    ),
                    style: AppTheme.primaryButton(AppTheme.teal),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
