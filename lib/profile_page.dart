import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;

  const ProfilePage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String _currentDeviceId = '';

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _loadProfileImage();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${widget.username}');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _loadDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      setState(() => _currentDeviceId = android.id ?? '');
    } catch (_) {}
  }

  String _censorText(String text, {bool isPassword = false}) {
    if (text.isEmpty) return "N/A";
    if (isPassword) return "••••••••";
    if (text.length <= 2) return "${text.substring(0, 1)}••";
    return "${text.substring(0, 2)}${'•' * (text.length - 2)}";
  }

  Future<void> _showImageSourceDialog() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: AppTheme.cardDecor().copyWith(
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.sky, size: 18),
                ),
                title: Text(
                  "Kamera",
                  style: AppTheme.bodyL.copyWith(fontFamily: 'ShareTechMono', letterSpacing: 1),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: AppTheme.cardDecor().copyWith(
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: const Icon(Icons.photo_library, color: AppTheme.lavender, size: 18),
                ),
                title: Text(
                  "Galeri",
                  style: AppTheme.bodyL.copyWith(fontFamily: 'ShareTechMono', letterSpacing: 1),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_${widget.username}', imageFile.path);
        setState(() {
          _profileImage = imageFile;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.sky.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: AppTheme.sky.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.sky,
              shape: BoxShape.circle,
              boxShadow: AppTheme.softGlow(AppTheme.sky, blur: 6, opacity: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.role.toUpperCase(),
            style: AppTheme.label.copyWith(color: AppTheme.sky, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fullWidth ? 18 : 14,
        vertical: 16,
      ),
      decoration: AppTheme.cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.bgDeep,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
                ),
                child: Icon(icon, color: AppTheme.lavender, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.label.copyWith(color: AppTheme.textMuted, letterSpacing: 1.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTheme.bodyL.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontFamily: 'ShareTechMono',
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.bgCard,
                AppTheme.bgCardLight.withValues(alpha: 0.6 + _glowAnimation.value * 0.4),
                AppTheme.bgCard,
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: AppTheme.lavender.withValues(alpha: 0.3 + _glowAnimation.value * 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lavender.withValues(alpha: _glowAnimation.value * 0.08),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordPage(
                      username: widget.username,
                      sessionKey: widget.sessionKey,
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_reset_rounded, color: AppTheme.lavender, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    "CHANGE PASSWORD",
                    style: AppTheme.label.copyWith(letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: AppTheme.cardDecor().copyWith(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "MY PROFILE",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.borderSubtle.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, _) {
                        return Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.lavender.withValues(alpha: 0.4 + _glowAnimation.value * 0.3),
                                AppTheme.bgCard,
                              ],
                            ),
                            border: Border.all(
                              color: AppTheme.lavender.withValues(alpha: 0.3 + _glowAnimation.value * 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.lavender.withValues(alpha: _glowAnimation.value * 0.12),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _profileImage != null
                                ? Image.file(_profileImage!, fit: BoxFit.cover)
                                : Center(
                                    child: Icon(
                                      FontAwesomeIcons.userAstronaut,
                                      size: 40,
                                      color: AppTheme.textPrimary.withValues(alpha: 0.25),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.bgDeep, width: 3),
                          boxShadow: AppTheme.softGlow(AppTheme.sky, blur: 8, opacity: 0.3),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: AppTheme.sky),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.username,
              style: AppTheme.headingL.copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            _buildRoleBadge(),
            const SizedBox(height: 32),
            _buildSectionTitle("ACCOUNT DATA"),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildInfoCard(icon: Icons.person_outline, label: "USERNAME", value: _censorText(widget.username))),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard(icon: Icons.lock_outline, label: "PASSWORD", value: _censorText(widget.password, isPassword: true))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoCard(icon: Icons.verified_user_outlined, label: "ROLE", value: widget.role.toUpperCase())),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard(icon: Icons.calendar_today_outlined, label: "EXPIRED", value: widget.expiredDate)),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.vpn_key_rounded,
              label: "SESSION KEY",
              value: "${widget.sessionKey.substring(0, 8)}...",
              fullWidth: true,
            ),
            const SizedBox(height: 40),
            _buildSectionTitle("DEVICE SECURITY"),
            const SizedBox(height: 14),
            _buildDeviceSecurityCard(),
            const SizedBox(height: 32),
            _buildChangePasswordButton(),
            const SizedBox(height: 32),
            _buildFooter(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.sky,
            borderRadius: BorderRadius.circular(2),
            boxShadow: AppTheme.softGlow(AppTheme.sky, blur: 6, opacity: 0.4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTheme.label.copyWith(letterSpacing: 3, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildDeviceSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: AppTheme.sky, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Biometric Login",
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              _BiometricToggle(
                username: widget.username,
                sessionKey: widget.sessionKey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, AppTheme.borderSubtle.withValues(alpha: 0.4), Colors.transparent]),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.devices, color: AppTheme.sky, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Trusted Devices",
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<Map<String, dynamic>>(
            future: _loadTrustedDevices(),
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.sky))),
                );
              }
              final devices = (snap.data?['devices'] as List?) ?? [];
              if (devices.isEmpty) {
                return Text("Belum ada device terdaftar", style: AppTheme.bodyM);
              }
              return Column(
                children: devices.map<Widget>((d) {
                  final isCurrent = d['id'] == _currentDeviceId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppTheme.sky.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: isCurrent ? AppTheme.sky.withValues(alpha: 0.3) : AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(isCurrent ? Icons.phone_android : Icons.devices_other, color: isCurrent ? AppTheme.sky : AppTheme.textSecondary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['name'] ?? 'Unknown', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                              if (isCurrent) Text("Perangkat ini", style: AppTheme.caption.copyWith(color: AppTheme.sky)),
                            ],
                          ),
                        ),
                        if (!isCurrent)
                          GestureDetector(
                            onTap: () => _revokeDevice(d['id']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.coral.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                              ),
                              child: Text("HAPUS", style: AppTheme.caption.copyWith(color: AppTheme.coral, fontWeight: FontWeight.w800)),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadTrustedDevices() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/device/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username, 'deviceId': android.id}),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'trusted': false, 'devices': []};
    }
  }

  Future<void> _revokeDevice(String deviceId) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/device/revoke'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username, 'deviceId': deviceId}),
      );
      setState(() {});
    } catch (_) {}
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.borderSubtle.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 25,
              height: 1,
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.circle, color: AppTheme.borderSubtle, size: 4),
            const SizedBox(width: 8),
            Container(
              width: 25,
              height: 1,
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "DARKVERSE PROFILE",
          style: AppTheme.caption.copyWith(letterSpacing: 3),
        ),
      ],
    );
  }
}

class _BiometricToggle extends StatefulWidget {
  final String username;
  final String sessionKey;
  const _BiometricToggle({required this.username, required this.sessionKey});

  @override
  State<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends State<_BiometricToggle> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool("biometric_enabled") ?? false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(width: 44, height: 24, child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.sky))));
    }
    return Switch(
      value: _enabled,
      activeColor: AppTheme.sky,
      activeTrackColor: AppTheme.sky.withValues(alpha: 0.3),
      onChanged: (val) async {
        if (val) {
          try {
            final didAuth = await _localAuth.authenticate(
              localizedReason: 'Verifikasi untuk mengaktifkan biometric login',
              options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
            );
            if (!didAuth) return;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool("biometric_enabled", true);

            try {
              final deviceInfo = DeviceInfoPlugin();
              final android = await deviceInfo.androidInfo;
              await http.post(
                Uri.parse("${ApiConfig.baseUrl}/api/device/trust"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "username": widget.username,
                  "deviceId": android.id,
                  "deviceName": android.model ?? "Android Device",
                }),
              );
            } catch (_) {}

            setState(() => _enabled = true);
          } catch (_) {}
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("biometric_enabled", false);

          try {
            final deviceInfo = DeviceInfoPlugin();
            final android = await deviceInfo.androidInfo;
            await http.post(
              Uri.parse("${ApiConfig.baseUrl}/api/device/revoke"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"username": widget.username, "deviceId": android.id}),
            );
          } catch (_) {}

          setState(() => _enabled = false);
        }
      },
    );
  }
}
