import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

class PasswordCheckPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  const PasswordCheckPage({super.key, required this.sessionKey, required this.username});

  @override
  State<PasswordCheckPage> createState() => _PasswordCheckPageState();
}

class _PasswordCheckPageState extends State<PasswordCheckPage> {
  bool _loading = true;
  String? _error;
  String _password = "";
  String _role = "";
  String _expiredDate = "";
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _checkPassword();
  }

  Future<void> _checkPassword() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/check-password'),
        body: jsonEncode({'key': widget.sessionKey, 'username': widget.username}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        setState(() {
          _password = data['password'] ?? '';
          _role = data['role'] ?? 'member';
          _expiredDate = data['expiredDate'] ?? '';
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = data['error'] ?? 'Gagal memuat'; });
      }
    } catch (e) {
      setState(() { _loading = false; _error = 'Error: $e'; });
    }
  }

  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: _password));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password disalin!"), backgroundColor: Color(0xFF39FF14)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text("PASSWORD CHECK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'Inter')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFE74C)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13, fontFamily: 'Inter'), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _checkPassword,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(color: const Color(0xFFFFE74C), borderRadius: BorderRadius.circular(10)),
                          child: const Text("RETRY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Inter', letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFE74C).withValues(alpha: 0.1),
                          border: Border.all(color: const Color(0xFFFFE74C), width: 3),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Color(0xFFFFE74C), size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.username, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
                      const SizedBox(height: 4),
                      Text("Password kamu", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Inter')),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181C28),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2A2F3E), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("PASSWORD", style: TextStyle(color: Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, fontFamily: 'Inter')),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _obscured ? ("•" * _password.length) : _password,
                                    style: TextStyle(
                                      color: _obscured ? const Color(0xFF666666) : const Color(0xFF39FF14),
                                      fontSize: _obscured ? 20.0 : 16.0,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'ShareTechMono',
                                      letterSpacing: _obscured ? 4 : 1,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() { _obscured = !_obscured; }),
                                  child: Icon(_obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: const Color(0xFFFFE74C), size: 22),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _copyPassword,
                                  child: const Icon(Icons.copy_rounded, color: Color(0xFF00D4FF), size: 22),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFF181C28), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A2F3E), width: 1)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text("ROLE", style: TextStyle(color: Color(0xFF888888), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text(_role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFF181C28), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A2F3E), width: 1)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text("EXPIRED", style: TextStyle(color: Color(0xFF888888), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text(_expiredDate, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
                              ]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFFE74C).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFFFE74C), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("Password ditampilkan apa adanya dari server. Jangan share ke orang lain!", style: TextStyle(color: Color(0xFFFFE74C), fontSize: 11, fontFamily: 'Inter', height: 1.3)),
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
