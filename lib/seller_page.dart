import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'api.dart';

class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> with TickerProviderStateMixin {
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = ['member'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();

  final editUsernameController = TextEditingController();
  final editDayController = TextEditingController();

  bool isLoading = false;

  late final AnimationController _entranceCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _scanCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _glowAnim = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _fetchUsers();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _glowCtrl.dispose();
    _scanCtrl.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    editUsernameController.dispose();
    editDayController.dispose();
    super.dispose();
  }

  Animation<double> _staggerFade(double startAt) {
    final end = (startAt + 0.45).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(startAt, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _staggered({required double delay, required Widget child}) {
    final anim = _staggerFade(delay);
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * 26),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/listUsers?key=${widget.keyToken}'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _alert("Info", data['message'] ?? 'Gagal memuat user.');
      }
    } catch (_) {
      _alert("Error", "Gagal terhubung ke server.");
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList
          .where((u) => u['role'] == selectedRole)
          .toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _createAccount() async {
    final u = createUsernameController.text.trim();
    final p = createPasswordController.text.trim();
    final d = createDayController.text.trim();

    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
          "${ApiConfig.baseUrl}/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d"));
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _alert("Sukses", "Akun berhasil dibuat!");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        _fetchUsers();
      } else {
        String msg = data['message'] ?? 'Gagal membuat akun.';
        if (data['invalidDay'] == true) {
          msg += " (Max 30 hari untuk Reseller)";
        }
        _alert("Gagal", msg);
      }
    } catch (e) {
      _alert("Error", "Koneksi error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _editUser() async {
    final u = editUsernameController.text.trim();
    final d = editDayController.text.trim();

    if (u.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
          "${ApiConfig.baseUrl}/editUser?key=${widget.keyToken}&username=$u&addDays=$d"));
      final data = jsonDecode(res.body);

      if (data['edited'] == true) {
        _alert("Sukses", "Durasi berhasil diperbarui.");
        editUsernameController.clear();
        editDayController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal mengubah durasi.');
      }
    } catch (e) {
      _alert("Error", "Koneksi error: $e");
    }
    setState(() => isLoading = false);
  }

  void _alert(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: AppTheme.cardDecor().copyWith(
                  color: AppTheme.bgCard.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.teal.withValues(alpha: 0.18),
                            AppTheme.teal.withValues(alpha: 0.02),
                          ],
                        ),
                        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.35), width: 1.2),
                      ),
                      child: const Icon(Icons.info_outline_rounded, color: AppTheme.teal, size: 28),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyL,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient(AppTheme.teal),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: AppTheme.softGlow(AppTheme.teal, blur: 18, opacity: 0.25),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(13),
                            onTap: () => Navigator.pop(context),
                            child: const Center(
                              child: Text(
                                "MENGERTI",
                                style: TextStyle(
                                  color: AppTheme.bgDeep,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.4,
                                  fontSize: 13,
                                ),
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
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String hint = "",
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: type,
        cursorColor: AppTheme.teal,
        style: AppTheme.bodyL.copyWith(
          color: AppTheme.textPrimary,
          fontSize: 14.5,
          letterSpacing: 0.2,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: AppTheme.teal.withValues(alpha: 0.9), size: 15),
            ),
          ),
          filled: true,
          fillColor: AppTheme.bgSurface.withValues(alpha: 0.55),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: const BorderSide(color: AppTheme.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: const BorderSide(color: AppTheme.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: BorderSide(color: AppTheme.teal.withValues(alpha: 0.65), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, _) {
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: AppTheme.teal.withValues(alpha: 0.1),
                border: Border.all(color: AppTheme.teal.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.teal.withValues(alpha: _glowAnim.value * 0.28),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: AppTheme.teal, size: 20),
            );
          },
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.teal.withValues(alpha: 0.8),
            boxShadow: [
              BoxShadow(color: AppTheme.teal.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 26),
          padding: const EdgeInsets.all(22),
          decoration: AppTheme.cardDecor().copyWith(
            color: AppTheme.bgCard.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.sky.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader(title: title, subtitle: subtitle, icon: icon),
                  const SizedBox(height: 18),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.borderSubtle,
                          AppTheme.borderSubtle,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient(AppTheme.teal),
          borderRadius: BorderRadius.circular(15),
          boxShadow: AppTheme.softGlow(AppTheme.teal, blur: 18, opacity: 0.32),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppTheme.bgDeep,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: AppTheme.bgDeep, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppTheme.bgDeep,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 13,
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

  Widget _buildUserItem(Map user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.cardDecor().copyWith(
        color: AppTheme.bgSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.teal.withValues(alpha: 0.16),
                  AppTheme.teal.withValues(alpha: 0.04),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.teal.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.person_rounded, color: AppTheme.teal, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${user['username']}",
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: AppTheme.accentCardDecor(AppTheme.teal).copyWith(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        "${user['role']}".toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.teal,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule_rounded, size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "${user['expiredDate']}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.cardDecor().copyWith(
              color: AppTheme.bgSurface.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(FontAwesomeIcons.userSlash, color: AppTheme.textMuted, size: 24),
          ),
          const SizedBox(height: 14),
          const Text(
            "Belum ada member",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        final bool active = currentPage == page;
        return InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => setState(() => currentPage = page),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: active
                  ? AppTheme.accentGradient(AppTheme.teal)
                  : null,
              color: active ? null : AppTheme.bgSurface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: active ? Colors.transparent : AppTheme.borderSubtle),
              boxShadow: active
                  ? AppTheme.softGlow(AppTheme.teal, blur: 12, opacity: 0.28)
                  : null,
            ),
            child: Text(
              "$page",
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? AppTheme.bgDeep : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.bgDeep, AppTheme.bgCard, AppTheme.bgDeep],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SubtleGridPainter(progress: _scanCtrl.value),
                );
              },
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, _) {
                return Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.teal.withValues(alpha: _glowAnim.value * 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, _) {
                return Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.sky.withValues(alpha: _glowAnim.value * 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _staggered(
                    delay: 0.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (context, _) {
                            return Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.teal.withValues(alpha: 0.18),
                                    AppTheme.sky.withValues(alpha: 0.05),
                                  ],
                                ),
                                border: Border.all(
                                    color: AppTheme.teal.withValues(alpha: 0.35), width: 1.3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 26,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: AppTheme.teal.withValues(alpha: _glowAnim.value * 0.22),
                                    blurRadius: 34,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.storefront_rounded, color: AppTheme.teal, size: 36),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            colors: [AppTheme.textPrimary, AppTheme.teal],
                          ).createShader(rect),
                          child: const Text(
                            "SELLER DASHBOARD",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          "Kelola akun member dengan mudah & aman",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, letterSpacing: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 64,
                          height: 2.4,
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient(AppTheme.teal),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: AppTheme.softGlow(AppTheme.teal, blur: 8, opacity: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  _staggered(
                    delay: 0.12,
                    child: _buildGlassCard(
                      title: "BUAT MEMBER",
                      subtitle: "Registrasi akun member baru",
                      icon: FontAwesomeIcons.userPlus,
                      children: [
                        _buildInput(
                          label: "Username Baru",
                          controller: createUsernameController,
                          icon: FontAwesomeIcons.user,
                        ),
                        _buildInput(
                          label: "Password",
                          controller: createPasswordController,
                          icon: FontAwesomeIcons.lock,
                        ),
                        _buildInput(
                          label: "Durasi (Hari)",
                          controller: createDayController,
                          icon: FontAwesomeIcons.calendarDay,
                          type: TextInputType.number,
                          hint: "Maksimal 30 hari",
                        ),
                        const SizedBox(height: 6),
                        _buildActionButton(
                          label: "CREATE ACCOUNT",
                          icon: FontAwesomeIcons.circlePlus,
                          onTap: isLoading ? null : _createAccount,
                        ),
                      ],
                    ),
                  ),

                  _staggered(
                    delay: 0.22,
                    child: _buildGlassCard(
                      title: "PERPANJANG DURASI",
                      subtitle: "Tambah masa aktif member",
                      icon: FontAwesomeIcons.clock,
                      children: [
                        _buildInput(
                          label: "Username Target",
                          controller: editUsernameController,
                          icon: FontAwesomeIcons.userPen,
                          hint: "Username member yang ingin diperpanjang",
                        ),
                        _buildInput(
                          label: "Tambah Hari",
                          controller: editDayController,
                          icon: FontAwesomeIcons.calendarPlus,
                          type: TextInputType.number,
                          hint: "Maksimal 30 hari",
                        ),
                        const SizedBox(height: 6),
                        _buildActionButton(
                          label: "ADD DAYS",
                          icon: FontAwesomeIcons.arrowsRotate,
                          onTap: isLoading ? null : _editUser,
                        ),
                      ],
                    ),
                  ),

                  _staggered(
                    delay: 0.32,
                    child: _buildGlassCard(
                      title: "DAFTAR MEMBER",
                      subtitle: "${filteredList.length} akun terdaftar",
                      icon: FontAwesomeIcons.users,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: AppTheme.inputDecor().copyWith(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedRole,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.bgCard,
                                    icon: const Icon(Icons.expand_more_rounded, color: AppTheme.teal),
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                    items: roleOptions.map((role) {
                                      return DropdownMenuItem(
                                        value: role,
                                        child: Text(
                                          role.toUpperCase(),
                                          style: const TextStyle(letterSpacing: 0.8),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        selectedRole = val;
                                        _filterAndPaginate();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(13),
                              onTap: isLoading ? null : _fetchUsers,
                              child: Container(
                                padding: const EdgeInsets.all(13),
                                decoration: AppTheme.inputDecor().copyWith(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(Icons.refresh_rounded, color: AppTheme.teal, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.teal,
                                    strokeWidth: 2.4,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  if (_getCurrentPageData().isEmpty)
                                    _buildEmptyState()
                                  else
                                    ..._getCurrentPageData()
                                        .map((u) => _buildUserItem(u))
                                        .toList(),
                                  const SizedBox(height: 12),
                                  _buildPagination(),
                                ],
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _staggered(
                    delay: 0.4,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_moon_rounded, size: 12, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Text(
                            "SECURE PANEL \u2022 ${DateTime.now().year}",
                            style: TextStyle(
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                              fontSize: 10.5,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtleGridPainter extends CustomPainter {
  final double progress;
  _SubtleGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.borderSubtle.withValues(alpha: 0.4)
      ..strokeWidth = 0.6;

    const spacing = 42.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          AppTheme.teal.withValues(alpha: 0.035),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(
        -size.width + (progress * size.width * 2),
        0,
        size.width,
        size.height,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _SubtleGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
