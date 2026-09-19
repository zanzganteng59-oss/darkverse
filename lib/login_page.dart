import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'video_splash_page.dart';
import 'api.dart';
import 'services/lang.dart';
import 'package:darkverse/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;
  final LocalAuthentication _localAuth = LocalAuthentication();

  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _initAnim();
    initLogin();
  }

  void _initAnim() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  void _navigateToVideoSplash(Map<String, dynamic> args) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => VideoSplashPage(dashboardArgs: args)),
    );
  }

  Map<String, dynamic> _buildArgs(
    dynamic data,
    String username,
    String password,
  ) {
    return {
      "username": username,
      "password": password,
      "role": data['role'],
      "key": data['key'],
      "expiredDate": data['expiredDate'],
      "listBug": (data['listBug'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      "listDoos": (data['listDDoS'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      "news": (data['news'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    };
  }

  Future<void> initLogin() async {
    androidId = await getAndroidId();
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");
    final biometricEnabled = prefs.getBool("biometric_enabled") ?? false;
    final savedAndroidId = prefs.getString("android_id");

    if (savedAndroidId != null && savedAndroidId != androidId) {
      await prefs.remove("biometric_enabled");
      await prefs.remove("username");
      await prefs.remove("password");
      await prefs.remove("key");
      await prefs.remove("android_id");
      return;
    }

    if (savedUser != null && savedPass != null && savedKey != null) {
      if (biometricEnabled) {
        try {
          final bool canAuth = await _localAuth.canCheckBiometrics;
          if (canAuth) {
            final bool didAuth = await _localAuth.authenticate(
              localizedReason: 'Autentikasi untuk login cepat',
              options: const AuthenticationOptions(
                stickyAuth: true,
                biometricOnly: true,
              ),
            );
            if (!didAuth) return;
          } else {
            return;
          }
        } catch (_) {
          return;
        }
      }

      final uri = Uri.parse(
        "${ApiConfig.baseUrl}/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey",
      );
      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          await prefs.setString("android_id", androidId!);
          _navigateToVideoSplash(_buildArgs(data, savedUser, savedPass));
        }
      } catch (_) {}
    }
  }

  Future<String> getAndroidId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      return android.id ?? "unknown_device";
    } catch (_) {
      return "unknown_device";
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();
    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );
      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showPopup(
          title: "Access Expired",
          message: "Masa akses Anda telah habis.\nSilakan perpanjang akses.",
          showContact: true,
        );
      } else if (validData['needsVerification'] == true) {
        await _requestVerificationCode(username, password, androidId ?? "unknown_device");
      } else if (validData['valid'] != true) {
        final String errorMsg = (validData['message'] ?? "").toLowerCase();
        if (errorMsg.contains("perangkat") ||
            errorMsg.contains("device") ||
            errorMsg.contains("another")) {
          _showPopup(
            title: "Sesi Aktif",
            message: "Akun ini sedang login di perangkat lain.\nSilakan logout di perangkat lama.",
          );
        } else {
          _showPopup(
            title: "Login Gagal",
            message: "Username atau password salah.",
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("username", username);
        await prefs.setString("password", password);
        await prefs.setString("key", validData['key']);
        await prefs.setString("android_id", androidId ?? "unknown_device");

        final bool canBio = await _localAuth.canCheckBiometrics;
        final bool alreadyEnabled = prefs.getBool("biometric_enabled") ?? false;

        if (canBio && !alreadyEnabled) {
          _showBiometricSetupDialog(username, password, validData);
        } else {
          _navigateToVideoSplash(_buildArgs(validData, username, password));
        }
      }
    } catch (e) {
      debugPrint("Login error: $e");
      _showPopup(
        title: "Connection Error",
        message: "Gagal terhubung ke server.",
      );
    }

    setState(() => isLoading = false);
  }

  void _showBiometricSetupDialog(
    String username,
    String password,
    dynamic validData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          side: BorderSide(color: AppTheme.lavender.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lavender.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: const Icon(Icons.fingerprint, color: AppTheme.lavender, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Aktifkan Biometric?",
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Text(
          "Aktifkan login dengan sidik jari/face ID agar tidak perlu memasukkan password lagi?",
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToVideoSplash(_buildArgs(validData, username, password));
            },
            child: Text("Nanti Saja", style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: AppTheme.primaryButton(AppTheme.lavender),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final bool didAuth = await _localAuth.authenticate(
                  localizedReason: 'Verifikasi untuk mengaktifkan biometric login',
                  options: const AuthenticationOptions(
                    stickyAuth: true,
                    biometricOnly: true,
                  ),
                );
                if (didAuth) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool("biometric_enabled", true);
                  try {
                    final deviceInfo = DeviceInfoPlugin();
                    final android = await deviceInfo.androidInfo;
                    await http.post(
                      Uri.parse("${ApiConfig.baseUrl}/api/device/trust"),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "username": username,
                        "deviceId": androidId ?? "unknown_device",
                        "deviceName": android.model ?? "Android Device",
                      }),
                    );
                  } catch (_) {}
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Biometric login diaktifkan!"),
                        backgroundColor: AppTheme.mint,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                      ),
                    );
                  }
                }
              } catch (_) {}
              _navigateToVideoSplash(_buildArgs(validData, username, password));
            },
            child: const Text(
              "Aktifkan",
              style: TextStyle(color: AppTheme.bgDeep, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestVerificationCode(String username, String password, String deviceId) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      final deviceName = android.model ?? "Android Device";

      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/device/request-code"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "newDeviceId": deviceId,
          "newDeviceName": deviceName,
        }),
      );

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _showVerificationCodeDialog(username, password, deviceId);
      } else {
        _showPopup(title: "Error", message: data['message'] ?? "Gagal request kode verifikasi");
      }
    } catch (e) {
      _showPopup(title: "Error", message: "Gagal terhubung ke server");
    }
  }

  void _showVerificationCodeDialog(String username, String password, String deviceId) {
    final codeControllers = List.generate(6, (_) => TextEditingController());
    final codeFocusNodes = List.generate(6, (_) => FocusNode());
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            side: BorderSide(color: AppTheme.sky.withValues(alpha: 0.3)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.sky.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: const Icon(Icons.security, color: AppTheme.sky, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Verifikasi Perangkat",
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Masukkan 6 digit kode verifikasi dari perangkat lama yang sudah terdaftar.",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 44, height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: codeControllers[i],
                      focusNode: codeFocusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppTheme.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          borderSide: const BorderSide(color: AppTheme.sky, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && i < 5) {
                          codeFocusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          codeFocusNodes[i - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              const Text("Kode berlaku 5 menit", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Batal", style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: AppTheme.primaryButton(AppTheme.sky),
              onPressed: isVerifying ? null : () async {
                final code = codeControllers.map((c) => c.text).join();
                if (code.length != 6) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: const Text("Masukkan 6 digit kode"), backgroundColor: AppTheme.coral, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM))),
                  );
                  return;
                }
                setDialogState(() => isVerifying = true);
                try {
                  final res = await http.post(
                    Uri.parse("${ApiConfig.baseUrl}/api/device/verify-code"),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "username": username,
                      "code": code,
                      "newDeviceId": deviceId,
                    }),
                  );
                  final data = jsonDecode(res.body);
                  if (data['success'] == true) {
                    Navigator.pop(ctx);
                    login();
                  } else {
                    setDialogState(() => isVerifying = false);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(data['message'] ?? "Kode salah"), backgroundColor: AppTheme.coral, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM))),
                    );
                    codeControllers.forEach((c) => c.clear());
                    codeFocusNodes[0].requestFocus();
                  }
                } catch (_) {
                  setDialogState(() => isVerifying = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: const Text("Gagal terhubung server"), backgroundColor: AppTheme.coral, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM))),
                  );
                }
              },
              child: isVerifying
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDeep))
                  : const Text("Verifikasi", style: TextStyle(color: AppTheme.bgDeep, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPopup({
    required String title,
    required String message,
    bool showContact = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          side: BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: const Icon(Icons.info_outline, color: AppTheme.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
        actions: [
          if (showContact)
            ElevatedButton(
              style: AppTheme.primaryButton(AppTheme.gold),
              onPressed: () async {
                await launchUrl(
                  Uri.parse("https://t.me/ZXSZSNZ"),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text("Contact Admin", style: TextStyle(color: AppTheme.bgDeep, fontWeight: FontWeight.w800)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06,
                vertical: size.height * 0.03,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: AppTheme.cardDecor(accent: AppTheme.sky),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgCardLight,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    boxShadow: AppTheme.softGlow(AppTheme.sky, blur: 24, opacity: 0.2),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 70, height: 70, fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    "AUTHENTICATION",
                                    style: TextStyle(
                                      fontSize: 11, color: AppTheme.gold,
                                      fontWeight: FontWeight.w800, letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _buildTextField(
                                  controller: userController,
                                  hint: "${Lang.t('username')}",
                                  icon: Icons.person_outline,
                                  validator: (v) => v == null || v.isEmpty
                                      ? "Username wajib diisi" : null,
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  controller: passController,
                                  hint: "${Lang.t('password')}",
                                  icon: Icons.lock_outline,
                                  obscure: _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppTheme.textMuted, size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? "Password wajib diisi" : null,
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity, height: 50,
                                  child: ElevatedButton(
                                    style: AppTheme.primaryButton(AppTheme.gold),
                                    onPressed: isLoading ? null : login,
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 22, height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.bgDeep),
                                          )
                                        : Text(
                                            Lang.t('login'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 3, fontSize: 14,
                                              color: AppTheme.bgDeep,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.coral, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.coral, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
