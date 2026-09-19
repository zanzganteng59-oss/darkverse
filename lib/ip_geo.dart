import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:darkverse/theme/app_theme.dart';

class IpGeoPage extends StatefulWidget {
  const IpGeoPage({super.key});

  @override
  State<IpGeoPage> createState() => _IpGeoPageState();
}

class _IpGeoPageState extends State<IpGeoPage> with SingleTickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _ipData;
  String? _errorMessage;
  String? _myIp;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _fetchMyIp();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyIp() async {
    try {
      final resp = await http.get(Uri.parse('https://api.ipify.org?format=json')).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _myIp = data['ip']);
      }
    } catch (_) {}
  }

  Future<void> _checkIp([String? ipOverride]) async {
    final ip = (ipOverride ?? _ipController.text.trim());
    if (ip.isEmpty) { setState(() => _errorMessage = "Masukkan IP address."); return; }
    setState(() { _isLoading = true; _errorMessage = null; _ipData = null; });
    try {
      final resp = await http.get(Uri.parse('https://ipwho.is/$ip')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true) {
          setState(() => _ipData = data);
        } else {
          await _fallbackCheck(ip);
        }
      } else {
        await _fallbackCheck(ip);
      }
    } catch (e) {
      setState(() => _errorMessage = "Gagal mengambil data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fallbackCheck(String ip) async {
    try {
      final resp = await http.get(Uri.parse('http://ip-api.com/json/$ip?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,query,proxy,hosting,mobile')).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == 'success') {
          setState(() => _ipData = {
            'ip': data['query'], 'country': data['country'], 'country_code': data['countryCode'],
            'region': data['regionName'], 'city': data['city'], 'postal': data['zip'],
            'latitude': data['lat'], 'longitude': data['lon'],
            'timezone': {'id': data['timezone']},
            'connection': {'isp': data['isp'], 'org': data['org'], 'asn': data['as']},
            'security': {'proxy': data['proxy'], 'hosting': data['hosting'], 'mobile': data['mobile']},
          });
        } else {
          setState(() => _errorMessage = data['message'] ?? "IP tidak valid.");
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Gagal: $e");
    }
  }

  void _openMap() {
    if (_ipData == null) return;
    final lat = _ipData!['latitude'];
    final lon = _ipData!['longitude'];
    if (lat != null && lon != null) launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lon'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep, surfaceTintColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text("IP GEOLOCATION", style: AppTheme.headingM),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.teal.withValues(alpha: 0.06),
                    border: Border.all(color: AppTheme.teal.withValues(alpha: _glowAnim.value), width: 2),
                    boxShadow: [BoxShadow(color: AppTheme.teal.withValues(alpha: _glowAnim.value * 0.3), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: const Icon(Icons.public, color: AppTheme.teal, size: 46),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_myIp != null)
              Center(
                child: GestureDetector(
                  onTap: () { _ipController.text = _myIp!; _checkIp(_myIp!); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.teal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.my_location, color: AppTheme.teal, size: 14),
                      const SizedBox(width: 8),
                      Text("IP Saya: $_myIp", style: AppTheme.bodyM.copyWith(color: AppTheme.teal, fontFamily: 'ShareTechMono')),
                      const SizedBox(width: 8),
                      Icon(Icons.touch_app, color: AppTheme.teal.withValues(alpha: 0.5), size: 14),
                    ]),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Container(
              decoration: AppTheme.inputDecor(),
              child: TextField(
                controller: _ipController, keyboardType: TextInputType.number,
                style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary, fontFamily: 'ShareTechMono'),
                decoration: InputDecoration(
                  hintText: "Masukkan IP address (cth: 8.8.8.8)",
                  hintStyle: AppTheme.bodyM.copyWith(fontFamily: 'ShareTechMono'),
                  prefixIcon: const Icon(Icons.dns, color: AppTheme.lavender),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _checkIp(),
                style: AppTheme.primaryButton(AppTheme.teal).copyWith(foregroundColor: WidgetStateProperty.all(AppTheme.bgDeep)),
                child: _isLoading
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.teal, strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text("TRACING...", style: AppTheme.headingS),
                      ])
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.location_searching, color: Colors.white),
                        const SizedBox(width: 10),
                        Text("TRACE IP", style: AppTheme.headingS),
                      ]),
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(padding: const EdgeInsets.all(14), decoration: AppTheme.accentCardDecor(AppTheme.coral), child: Text(_errorMessage!, style: AppTheme.bodyM.copyWith(color: AppTheme.coral, fontFamily: 'ShareTechMono'))),

            if (_ipData != null) ...[
              Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: AppTheme.accentCardDecor(AppTheme.teal),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_getFlag(_ipData!['country_code'] ?? ''), style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_ipData!['ip'] ?? '-', style: AppTheme.headingL.copyWith(color: AppTheme.teal, fontFamily: 'ShareTechMono', letterSpacing: 2)),
                      Text("${_ipData!['city'] ?? '-'}, ${_ipData!['country'] ?? '-'}", style: AppTheme.bodyM),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  if (_ipData!['latitude'] != null && _ipData!['longitude'] != null)
                    GestureDetector(
                      onTap: _openMap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.sky.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppTheme.radiusS), border: Border.all(color: AppTheme.sky.withValues(alpha: 0.3))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.pin_drop, color: AppTheme.sky, size: 16),
                          const SizedBox(width: 8),
                          Text("${_ipData!['latitude']}, ${_ipData!['longitude']}", style: AppTheme.bodyM.copyWith(color: AppTheme.sky, fontFamily: 'ShareTechMono')),
                          const SizedBox(width: 8),
                          const Icon(Icons.open_in_new, color: AppTheme.sky, size: 14),
                        ]),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildInfoTile("NEGARA", _ipData!['country'] ?? '-', Icons.flag),
                  _buildInfoTile("REGION", _ipData!['region'] ?? '-', Icons.map),
                  _buildInfoTile("KOTA", _ipData!['city'] ?? '-', Icons.location_city),
                  _buildInfoTile("KODE POS", _ipData!['postal'] ?? '-', Icons.markunread_mailbox),
                  _buildInfoTile("TIMEZONE", _ipData!['timezone']?['id'] ?? _ipData!['timezone'] ?? '-', Icons.access_time),
                  _buildInfoTile("ISP", _ipData!['connection']?['isp'] ?? '-', Icons.business),
                ],
              ),

              const SizedBox(height: 16),

              _buildDetailCard("NETWORK INFO", [
                {'label': 'ASN', 'value': _ipData!['connection']?['asn'] ?? _ipData!['asn'] ?? '-'},
                {'label': 'Organisasi', 'value': _ipData!['connection']?['org'] ?? _ipData!['org'] ?? '-'},
                {'label': 'ISP', 'value': _ipData!['connection']?['isp'] ?? _ipData!['isp'] ?? '-'},
              ]),

              if (_ipData!['security'] != null) ...[
                const SizedBox(height: 16),
                _buildSecurityFlags(_ipData!['security']),
              ],

              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(icon, color: AppTheme.lavender, size: 14),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.caption),
        ]),
        Text(value, style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildDetailCard(String title, List<Map<String, String>> rows) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTheme.label.copyWith(color: AppTheme.lavender)),
        const Divider(color: AppTheme.borderSubtle, height: 16),
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 90, child: Text(row['label']!, style: AppTheme.caption)),
            Expanded(
              child: GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: row['value']!)),
                child: Text(row['value']!, style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary)),
              ),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _buildSecurityFlags(Map<String, dynamic> security) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("SECURITY FLAGS", style: AppTheme.label.copyWith(color: AppTheme.lavender)),
        const Divider(color: AppTheme.borderSubtle, height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildFlag("PROXY", security['proxy'] == true, Icons.vpn_lock),
          _buildFlag("HOSTING", security['hosting'] == true, Icons.cloud),
          _buildFlag("MOBILE", security['mobile'] == true, Icons.smartphone),
        ]),
      ]),
    );
  }

  Widget _buildFlag(String label, bool active, IconData icon) {
    final color = active ? AppTheme.peach : AppTheme.mint;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(height: 6),
      Text(label, style: AppTheme.caption),
      Text(active ? "YES" : "NO", style: AppTheme.headingS.copyWith(color: color)),
    ]);
  }

  String _getFlag(String countryCode) {
    if (countryCode.length != 2) return '🌐';
    return String.fromCharCodes(countryCode.toUpperCase().codeUnits.map((c) => c + 127397));
  }
}
