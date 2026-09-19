import 'package:flutter/material.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api.dart';

class ChangePasswordPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const ChangePasswordPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> _changePassword() async {
    final oldPass = oldPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMessage("Semua field harus diisi.");
      return;
    }

    if (newPass != confirmPass) {
      _showMessage("Password baru tidak cocok dengan konfirmasi.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/changepass"),
        body: {
          "username": widget.username,
          "oldPass": oldPass,
          "newPass": newPass,
          "sessionKey": widget.sessionKey,
        },
      );

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        _showMessage("Password berhasil diubah!", isSuccess: true);
        oldPassCtrl.clear();
        newPassCtrl.clear();
        confirmPassCtrl.clear();
      } else {
        _showMessage(data['message'] ?? "Gagal mengubah password");
      }
    } catch (e) {
      _showMessage("Koneksi error: $e");
    }

    setState(() => isLoading = false);
  }

  void _showMessage(String msg, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          side: BorderSide(color: AppTheme.teal.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.info_outline,
              color: AppTheme.teal,
            ),
            const SizedBox(width: 10),
            Text(
              isSuccess ? "Sukses" : "Peringatan",
              style: AppTheme.headingM,
            ),
          ],
        ),
        content: Text(msg, style: AppTheme.bodyL),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppTheme.primaryButton(AppTheme.teal),
              child: const Text("OK"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, [bool isPassword = false]) {
    return Container(
      height: 55,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: AppTheme.inputDecor(),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.teal),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.teal),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "CHANGE PASSWORD",
          style: AppTheme.headingM.copyWith(
            letterSpacing: 2,
            shadows: [Shadow(color: AppTheme.sky.withValues(alpha: 0.8), blurRadius: 10)],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.accentGradient(AppTheme.teal),
                  boxShadow: AppTheme.softGlow(AppTheme.teal, blur: 20, opacity: 0.4),
                ),
                child: const Icon(Icons.lock_reset, color: AppTheme.textPrimary, size: 50),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "SECURITY UPDATE",
                style: AppTheme.headingL.copyWith(letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Masukkan password lama dan baru.",
                style: AppTheme.bodyL.copyWith(fontFamily: 'ShareTechMono'),
              ),
            ),
            const SizedBox(height: 40),
            _buildInput(oldPassCtrl, "Old Password", Icons.lock_outline, true),
            _buildInput(newPassCtrl, "New Password", Icons.vpn_key, true),
            _buildInput(confirmPassCtrl, "Confirm Password", Icons.enhanced_encryption, true),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient(AppTheme.teal),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: AppTheme.softGlow(AppTheme.teal, blur: 10, opacity: 0.4),
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textPrimary,
                        ),
                      )
                    : Text(
                        "UPDATE PASSWORD",
                        style: AppTheme.headingS.copyWith(letterSpacing: 1),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
