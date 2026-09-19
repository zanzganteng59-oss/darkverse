import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:darkverse/theme/app_theme.dart';

class WhoisPage extends StatefulWidget {
  const WhoisPage({super.key});

  @override
  State<WhoisPage> createState() => _WhoisPageState();
}

class _WhoisPageState extends State<WhoisPage> {
  final TextEditingController _domainCtrl = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _lookup() async {
    String domain = _domainCtrl.text.trim().toLowerCase().replaceAll('https://', '').replaceAll('http://', '').split('/').first;
    if (domain.isEmpty) { setState(() => _error = "Masukkan domain."); return; }
    setState(() { _isLoading = true; _error = null; _result = null; });
    try {
      final rdapUrl = 'https://rdap.org/domain/$domain';
      final resp = await http.get(Uri.parse(rdapUrl), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _parseRdap(data, domain);
      } else {
        final resp2 = await http.get(Uri.parse('https://api.siputzx.my.id/api/tools/whois?domain=$domain')).timeout(const Duration(seconds: 10));
        if (resp2.statusCode == 200) {
          final data2 = jsonDecode(resp2.body);
          if (data2['status'] == true) {
            setState(() => _result = _flattenMap(data2['data'] ?? {}));
          } else {
            setState(() => _error = "Data WHOIS tidak tersedia untuk domain ini.");
          }
        } else {
          setState(() => _error = "Gagal mengambil data WHOIS.");
        }
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _parseRdap(Map<String, dynamic> data, String domain) {
    final result = <String, dynamic>{};
    result['Domain'] = domain.toUpperCase();
    final statuses = (data['status'] as List?)?.join(', ') ?? '-';
    result['Status'] = statuses;
    for (final e in (data['events'] ?? []) as List) {
      final action = e['eventAction'] ?? '';
      final date = e['eventDate'] ?? '';
      if (action == 'registration') result['Terdaftar'] = date.toString().substring(0, 10);
      if (action == 'expiration') result['Kadaluarsa'] = date.toString().substring(0, 10);
      if (action == 'last changed') result['Terakhir Update'] = date.toString().substring(0, 10);
    }
    final ns = <String>[];
    for (final n in (data['nameservers'] ?? []) as List) { ns.add(n['ldhName'] ?? ''); }
    if (ns.isNotEmpty) result['Nameservers'] = ns.join('\n');
    for (final entity in (data['entities'] ?? []) as List) {
      final roles = (entity['roles'] as List?) ?? [];
      if (roles.contains('registrar')) {
        final vcardArray = entity['vcardArray'] as List?;
        if (vcardArray != null && vcardArray.length > 1) {
          for (final vcard in vcardArray[1] as List) {
            if ((vcard as List).isNotEmpty && vcard[0] == 'fn') result['Registrar'] = vcard[3] ?? '-';
          }
        }
      }
      if (roles.contains('registrant')) {
        final vcardArray = entity['vcardArray'] as List?;
        if (vcardArray != null && vcardArray.length > 1) {
          for (final vcard in vcardArray[1] as List) {
            if ((vcard as List).isNotEmpty && vcard[0] == 'org') result['Pemilik'] = vcard[3] ?? '-';
          }
        }
      }
    }
    result['Handle'] = data['handle'] ?? '-';
    setState(() => _result = result);
  }

  Map<String, dynamic> _flattenMap(Map<String, dynamic> map, [String prefix = '']) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result.addAll(_flattenMap(value, '$key.'));
      } else {
        result['$prefix$key'] = value?.toString() ?? '-';
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("WHOIS LOOKUP", style: AppTheme.headingM),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.teal.withValues(alpha: 0.08),
                  border: Border.all(color: AppTheme.teal.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.manage_search, color: AppTheme.teal, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text("Cek informasi registrasi domain", style: AppTheme.bodyM),
            const SizedBox(height: 24),

            Container(
              decoration: AppTheme.inputDecor(),
              child: TextField(
                controller: _domainCtrl,
                style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary, fontFamily: 'ShareTechMono'),
                decoration: InputDecoration(
                  hintText: "google.com",
                  hintStyle: AppTheme.bodyM.copyWith(fontFamily: 'ShareTechMono'),
                  prefixIcon: const Icon(Icons.domain, color: AppTheme.teal),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _lookup,
                style: AppTheme.primaryButton(AppTheme.teal).copyWith(foregroundColor: WidgetStateProperty.all(AppTheme.bgDeep)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.search, color: Colors.white),
                        const SizedBox(width: 10),
                        Text("WHOIS LOOKUP", style: AppTheme.headingS),
                      ]),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.accentCardDecor(AppTheme.coral),
                child: Text(_error!, style: AppTheme.bodyM.copyWith(color: AppTheme.coral, fontFamily: 'ShareTechMono')),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: AppTheme.accentCardDecor(AppTheme.teal),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("WHOIS DATA", style: AppTheme.label.copyWith(color: AppTheme.teal)),
                    IconButton(
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                      icon: const Icon(Icons.copy_all, color: AppTheme.teal, size: 18),
                      onPressed: () {
                        final text = _result!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text("Disalin!"), backgroundColor: AppTheme.teal, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS))),
                        );
                      },
                    ),
                  ]),
                  const Divider(color: AppTheme.borderSubtle, height: 20),
                  ..._result!.entries.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 110, child: Text(entry.key, style: AppTheme.caption)),
                      const Text(": ", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Clipboard.setData(ClipboardData(text: entry.value.toString())),
                          child: Text(entry.value.toString(), style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary)),
                        ),
                      ),
                    ]),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
