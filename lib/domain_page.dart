import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:darkverse/theme/app_theme.dart';

class DomainOsintPage extends StatefulWidget {
  const DomainOsintPage({super.key});

  @override
  State<DomainOsintPage> createState() => _DomainOsintPageState();
}

class _DomainOsintPageState extends State<DomainOsintPage> {
  final TextEditingController _domainController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _dnsData;
  List<dynamic>? _subdomainsData;
  String? _errorMessage;

  Future<void> _checkDomain() async {
    final domain = _domainController.text.trim();
    if (domain.isEmpty) {
      setState(() {
        _errorMessage = "Domain tidak boleh kosong.";
        _dnsData = null;
        _subdomainsData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _dnsData = null;
      _subdomainsData = null;
    });

    try {
      final dnsResult = await _fetchDnsInfo(domain);
      final subdoResult = await _fetchSubdomains(domain);

      if (dnsResult != null && subdoResult != null) {
        setState(() {
          _dnsData = dnsResult;
          _subdomainsData = subdoResult;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data domain.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchDnsInfo(String domain) async {
    final url = Uri.parse("https://api.siputzx.my.id/api/tools/dns?domain=$domain");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['status'] == true ? json['data'] : null;
    }
    return null;
  }

  Future<List<dynamic>?> _fetchSubdomains(String domain) async {
    final url = Uri.parse("https://api.siputzx.my.id/api/tools/subdomains?domain=$domain");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['status'] == true ? json['data'] : null;
    }
    return null;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin ke clipboard'),
        backgroundColor: AppTheme.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          side: const BorderSide(color: AppTheme.teal),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.teal, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTheme.headingS,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String? value,
    bool showCopyButton = false,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgInput,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyL.copyWith(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showCopyButton)
            IconButton(
              icon: const Icon(Icons.copy, color: AppTheme.teal, size: 20),
              onPressed: () => _copyToClipboard(value, label),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40),
              tooltip: 'Salin $label',
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDnsRecords() {
    if (_dnsData == null || _dnsData!['records'] == null) return [];

    final records = _dnsData!['records'] as Map<String, dynamic>;
    final widgets = <Widget>[];

    if (records['ns']?['response']?['answer'] != null) {
      final nsRecords = records['ns']!['response']!['answer'] as List;
      if (nsRecords.isNotEmpty) {
        widgets.addAll([
          Text('Name Servers', style: AppTheme.headingS),
          const SizedBox(height: 8),
          ...nsRecords.map((record) => _buildInfoRow(
            label: 'NS Record',
            value: record['record']?['target']?.toString(),
            showCopyButton: true,
          )),
          const SizedBox(height: 16),
        ]);
      }
    }

    if (records['soa']?['response']?['answer'] != null) {
      final soaRecords = records['soa']!['response']!['answer'] as List;
      if (soaRecords.isNotEmpty) {
        final soa = soaRecords.first['record'];
        widgets.addAll([
          Text('SOA Record', style: AppTheme.headingS),
          const SizedBox(height: 8),
          _buildInfoRow(label: 'Primary NS', value: soa?['host']?.toString(), showCopyButton: true),
          _buildInfoRow(label: 'Admin Email', value: soa?['admin']?.toString(), showCopyButton: true),
          _buildInfoRow(label: 'Serial', value: soa?['serial']?.toString()),
          _buildInfoRow(label: 'Refresh', value: soa?['refresh']?.toString()),
          _buildInfoRow(label: 'Retry', value: soa?['retry']?.toString()),
          _buildInfoRow(label: 'Expire', value: soa?['expire']?.toString()),
          _buildInfoRow(label: 'Minimum TTL', value: soa?['minimum']?.toString()),
          const SizedBox(height: 16),
        ]);
      }
    }

    if (records['a']?['response']?['answer'] != null) {
      final aRecords = records['a']!['response']!['answer'] as List;
      if (aRecords.isNotEmpty) {
        widgets.addAll([
          Text('A Records', style: AppTheme.headingS),
          const SizedBox(height: 8),
          ...aRecords.map((record) => _buildInfoRow(
            label: 'A Record',
            value: record['record']?['data']?.toString(),
            showCopyButton: true,
          )),
        ]);
      }
    }

    return widgets;
  }

  List<Widget> _buildSubdomainsList() {
    if (_subdomainsData == null) return [];

    final cleanSubdomains = _subdomainsData!
        .map((item) => item.toString().split('\n').last.trim())
        .where((subdomain) => subdomain.isNotEmpty && !subdomain.startsWith('*'))
        .toSet()
        .toList()
      ..sort();

    return [
      Text(
        'Ditemukan ${cleanSubdomains.length} subdomain',
        style: AppTheme.bodyL,
      ),
      const SizedBox(height: 12),
      ...cleanSubdomains.map((subdomain) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgInput,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: AppTheme.teal, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subdomain,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: AppTheme.teal, size: 18),
              onPressed: () => _copyToClipboard(subdomain, 'Subdomain'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36),
              tooltip: 'Salin subdomain',
            ),
          ],
        ),
      )).toList(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Text('DOMAIN OSINT', style: AppTheme.headingM),
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecor(),
                child: Column(
                  children: [
                    TextField(
                      controller: _domainController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Masukkan Domain',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        hintText: 'Contoh: nullxteam.fun',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.borderSubtle),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.teal, width: 2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        filled: true,
                        fillColor: AppTheme.bgInput,
                        suffixIcon: _isLoading
                            ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppTheme.teal,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                            : null,
                      ),
                      onSubmitted: (_) => _checkDomain(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkDomain,
                        style: AppTheme.primaryButton(AppTheme.teal),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isLoading ? Icons.hourglass_top : Icons.search, size: 20, color: AppTheme.bgDeep),
                            const SizedBox(width: 8),
                            Text(
                              _isLoading ? 'MEMPROSES...' : 'CEK DOMAIN',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.bgDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.accentCardDecor(AppTheme.coral),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.coral),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.coral, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              if (_dnsData != null || _subdomainsData != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_dnsData != null)
                          _buildCategoryCard(
                            title: "INFORMASI DOMAIN",
                            icon: Icons.domain,
                            children: [
                              _buildInfoRow(
                                label: "Domain",
                                value: _dnsData!['unicodeDomain']?.toString(),
                                showCopyButton: true,
                              ),
                              _buildInfoRow(
                                label: "Punycode",
                                value: _dnsData!['punycodeDomain']?.toString(),
                                showCopyButton: true,
                              ),
                              ..._buildDnsRecords(),
                            ],
                          ),

                        const SizedBox(height: 16),

                        if (_subdomainsData != null)
                          _buildCategoryCard(
                            title: "SUBDOMAINS",
                            icon: Icons.list,
                            children: _buildSubdomainsList(),
                          ),

                        const SizedBox(height: 16),

                        if (_dnsData != null && _dnsData!['records'] != null)
                          _buildCategoryCard(
                            title: "INFORMASI SERVER",
                            icon: Icons.dns,
                            children: [
                              if (_dnsData!['records']['a']?['query']?['server'] != null)
                                _buildInfoRow(
                                  label: "DNS Server",
                                  value: _dnsData!['records']['a']!['query']!['server']!['ip']?.toString(),
                                  showCopyButton: true,
                                ),
                              if (_dnsData!['records']['a']?['query']?['server']?['location'] != null)
                                _buildInfoRow(
                                  label: "Lokasi Server",
                                  value: "Lat: ${_dnsData!['records']['a']!['query']!['server']!['location']!['lat']}, Lon: ${_dnsData!['records']['a']!['query']!['server']!['location']!['lon']}",
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
