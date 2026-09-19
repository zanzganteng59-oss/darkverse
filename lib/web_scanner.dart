import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:darkverse/theme/app_theme.dart';

class WebScannerPage extends StatefulWidget {
  const WebScannerPage({super.key});

  @override
  State<WebScannerPage> createState() => _WebScannerPageState();
}

class _WebScannerPageState extends State<WebScannerPage> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _scanResult;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;

  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(_scanLineController);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _addLog(String msg) {
    setState(() => _logs.add("[${DateTime.now().toString().substring(11, 19)}] $msg"));
  }

  Future<void> _startScan() async {
    String url = _urlController.text.trim();
    if (url.isEmpty) { setState(() => _errorMessage = "Masukkan URL target."); return; }
    if (!url.startsWith('http')) url = 'https://$url';

    setState(() { _isLoading = true; _errorMessage = null; _scanResult = null; _logs.clear(); });
    _addLog("Memulai scan target: $url");

    final results = <String, dynamic>{
      'url': url, 'headers': {}, 'security': {}, 'whois': {}, 'tech': [], 'ports': {},
    };

    try {
      _addLog("Menganalisis HTTP headers...");
      try {
        final resp = await http.get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0 NexaScanner/2.0'}).timeout(const Duration(seconds: 8));
        results['statusCode'] = resp.statusCode;
        final headers = Map<String, String>.from(resp.headers);
        results['headers'] = headers;
        final secChecks = <String, dynamic>{};
        secChecks['X-Frame-Options'] = headers.containsKey('x-frame-options') ? {'status': 'OK', 'value': headers['x-frame-options']} : {'status': 'MISSING', 'value': null};
        secChecks['X-Content-Type-Options'] = headers.containsKey('x-content-type-options') ? {'status': 'OK', 'value': headers['x-content-type-options']} : {'status': 'MISSING', 'value': null};
        secChecks['Strict-Transport-Security'] = headers.containsKey('strict-transport-security') ? {'status': 'OK', 'value': headers['strict-transport-security']} : {'status': 'MISSING', 'value': null};
        secChecks['Content-Security-Policy'] = headers.containsKey('content-security-policy') ? {'status': 'OK', 'value': headers['content-security-policy']} : {'status': 'MISSING', 'value': null};
        secChecks['X-XSS-Protection'] = headers.containsKey('x-xss-protection') ? {'status': 'OK', 'value': headers['x-xss-protection']} : {'status': 'MISSING', 'value': null};
        secChecks['Referrer-Policy'] = headers.containsKey('referrer-policy') ? {'status': 'OK', 'value': headers['referrer-policy']} : {'status': 'MISSING', 'value': null};
        results['security'] = secChecks;
        _addLog("Headers ditemukan: ${headers.length} entri");
        final techList = <String>[];
        final server = headers['server'] ?? '';
        final xPowered = headers['x-powered-by'] ?? '';
        if (server.isNotEmpty) techList.add('Server: $server');
        if (xPowered.isNotEmpty) techList.add('Powered-By: $xPowered');
        if (headers.containsKey('x-wp-super-cache') || headers.containsKey('x-pingback')) techList.add('WordPress');
        if (headers['server']?.toLowerCase().contains('nginx') == true) techList.add('NGINX');
        if (headers['server']?.toLowerCase().contains('apache') == true) techList.add('Apache');
        if (headers['server']?.toLowerCase().contains('cloudflare') == true) techList.add('Cloudflare');
        if (headers.containsKey('x-shopify-stage')) techList.add('Shopify');
        results['tech'] = techList;
        _addLog("Tech stack terdeteksi: ${techList.length} teknologi");
        results['ssl'] = url.startsWith('https') ? 'AKTIF' : 'TIDAK ADA';
        _addLog("SSL: ${results['ssl']}");
      } catch (e) {
        results['headers_error'] = e.toString();
        _addLog("Headers scan gagal: $e");
      }

      _addLog("Mengambil info DNS...");
      try {
        final domain = Uri.parse(url).host;
        final dnsResp = await http.get(Uri.parse('https://api.siputzx.my.id/api/tools/dns?domain=$domain')).timeout(const Duration(seconds: 8));
        if (dnsResp.statusCode == 200) {
          final dnsData = jsonDecode(dnsResp.body);
          if (dnsData['status'] == true) { results['dns'] = dnsData['data']; _addLog("DNS info berhasil diambil."); }
        }
      } catch (_) { _addLog("DNS lookup gagal."); }

      _addLog("Resolving IP address...");
      try {
        final domain = Uri.parse(url).host;
        final ipResp = await http.get(Uri.parse('https://ipwho.is/$domain')).timeout(const Duration(seconds: 8));
        if (ipResp.statusCode == 200) {
          final ipData = jsonDecode(ipResp.body);
          results['ip_info'] = {'ip': ipData['ip'], 'country': ipData['country'], 'city': ipData['city'], 'org': ipData['org'] ?? ipData['connection']?['org'], 'isp': ipData['connection']?['isp']};
          _addLog("IP: ${ipData['ip']} (${ipData['country']})");
        }
      } catch (_) { _addLog("IP lookup gagal."); }

      final securityMap = results['security'] as Map<String, dynamic>;
      final okCount = securityMap.values.where((v) => v is Map && v['status'] == 'OK').length;
      final totalChecks = securityMap.length;
      results['score'] = totalChecks > 0 ? (okCount / totalChecks * 100).round() : 0;
      _addLog("Security Score: ${results['score']}%");
      _addLog("Scan selesai!");
      setState(() => _scanResult = results);
    } catch (e) {
      setState(() => _errorMessage = "Scan gagal: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _scoreColor(int score) {
    if (score >= 70) return AppTheme.mint;
    if (score >= 40) return AppTheme.gold;
    return AppTheme.coral;
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
        title: Text("WEB SCANNER", style: AppTheme.headingM),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, height: 80,
              decoration: AppTheme.accentCardDecor(AppTheme.teal),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: Stack(children: [
                  if (_isLoading)
                    AnimatedBuilder(
                      animation: _scanLineAnim,
                      builder: (_, __) => Positioned(
                        top: _scanLineAnim.value * 70, left: 0, right: 0,
                        child: Container(height: 2, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppTheme.teal.withValues(alpha: 0.8), Colors.transparent]))),
                      ),
                    ),
                  Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.radar, color: AppTheme.teal, size: 28),
                    const SizedBox(width: 12),
                    Text(_isLoading ? "SCANNING TARGET..." : "READY TO SCAN", style: AppTheme.headingS.copyWith(color: AppTheme.teal, letterSpacing: 2)),
                  ])),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: AppTheme.inputDecor(),
              child: TextField(
                controller: _urlController,
                style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary, fontFamily: 'ShareTechMono'),
                decoration: InputDecoration(
                  hintText: "https://target.com",
                  hintStyle: AppTheme.bodyM.copyWith(fontFamily: 'ShareTechMono'),
                  prefixIcon: const Icon(Icons.language, color: AppTheme.lavender),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startScan,
                style: AppTheme.primaryButton(AppTheme.teal).copyWith(foregroundColor: WidgetStateProperty.all(AppTheme.bgDeep)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_isLoading ? Icons.hourglass_top : Icons.search, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(_isLoading ? "SCANNING..." : "START SCAN", style: AppTheme.headingS),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            if (_logs.isNotEmpty)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: AppTheme.accentCardDecor(AppTheme.mint),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.terminal, color: AppTheme.mint, size: 16),
                    const SizedBox(width: 8),
                    Text("SCAN LOG", style: AppTheme.caption.copyWith(color: AppTheme.mint)),
                  ]),
                  const SizedBox(height: 8),
                  ..._logs.map((log) => Text("> $log", style: AppTheme.bodyM.copyWith(color: AppTheme.mint.withValues(alpha: 0.8), fontFamily: 'ShareTechMono'))),
                ]),
              ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(14), decoration: AppTheme.accentCardDecor(AppTheme.coral), child: Text(_errorMessage!, style: AppTheme.bodyM.copyWith(color: AppTheme.coral, fontFamily: 'ShareTechMono'))),
            ],

            if (_scanResult != null) ...[
              const SizedBox(height: 24),
              if (_scanResult!['score'] != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.accentCardDecor(_scoreColor(_scanResult!['score'])),
                  child: Column(children: [
                    Text("SECURITY SCORE", style: AppTheme.label.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: 10),
                    Text("${_scanResult!['score']}%", style: AppTheme.headingL.copyWith(color: _scoreColor(_scanResult!['score']), fontFamily: 'Orbitron', fontSize: 48)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _scanResult!['score'] / 100, backgroundColor: AppTheme.bgInput, color: _scoreColor(_scanResult!['score']), minHeight: 8, borderRadius: BorderRadius.circular(4)),
                  ]),
                ),

              const SizedBox(height: 16),
              if (_scanResult!['ip_info'] != null)
                _buildResultCard("IP INFO", Icons.public, [
                  _buildRow("IP Address", _scanResult!['ip_info']['ip'] ?? '-'),
                  _buildRow("Country", _scanResult!['ip_info']['country'] ?? '-'),
                  _buildRow("City", _scanResult!['ip_info']['city'] ?? '-'),
                  _buildRow("ISP", _scanResult!['ip_info']['isp'] ?? _scanResult!['ip_info']['org'] ?? '-'),
                ]),
              const SizedBox(height: 16),
              _buildResultCard("STATUS SERVER", Icons.dns, [
                _buildRow("HTTP Status", _scanResult!['statusCode']?.toString() ?? '-'),
                _buildRow("SSL/HTTPS", _scanResult!['ssl'] ?? '-'),
              ]),
              const SizedBox(height: 16),
              if (_scanResult!['tech'] != null && (_scanResult!['tech'] as List).isNotEmpty)
                _buildResultCard("TECH STACK", Icons.layers, [...(_scanResult!['tech'] as List).map((t) => _buildRow("▸", t.toString()))]),
              const SizedBox(height: 16),
              if (_scanResult!['security'] != null)
                _buildSecurityHeadersCard(_scanResult!['security'] as Map<String, dynamic>),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, IconData icon, List<Widget> rows) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppTheme.lavender, size: 18),
          const SizedBox(width: 8),
          Text(title, style: AppTheme.label.copyWith(color: AppTheme.lavender)),
        ]),
        const Divider(color: AppTheme.borderSubtle, height: 20),
        ...rows,
      ]),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: AppTheme.caption)),
        Expanded(child: Text(value, style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary))),
        IconButton(
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          icon: Icon(Icons.copy, size: 14, color: AppTheme.textMuted),
          onPressed: () => Clipboard.setData(ClipboardData(text: value)),
        ),
      ]),
    );
  }

  Widget _buildSecurityHeadersCard(Map<String, dynamic> security) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.security, color: AppTheme.lavender, size: 18),
          const SizedBox(width: 8),
          Text("SECURITY HEADERS", style: AppTheme.label.copyWith(color: AppTheme.lavender)),
        ]),
        const Divider(color: AppTheme.borderSubtle, height: 20),
        ...security.entries.map((entry) {
          final isOk = entry.value['status'] == 'OK';
          final color = isOk ? AppTheme.mint : AppTheme.coral;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(isOk ? Icons.check_circle : Icons.cancel, color: color, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.key, style: AppTheme.bodyM.copyWith(color: isOk ? AppTheme.textPrimary : AppTheme.textMuted))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(isOk ? "OK" : "MISSING", style: TextStyle(color: color, fontFamily: 'ShareTechMono', fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}
