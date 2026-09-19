import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'api.dart';

class OwnerPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const OwnerPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> with TickerProviderStateMixin {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = [
    'developer',
    'all_akses',
    'owner',
    'vip',
    'reseller',
    'member',
  ];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  final deleteController = TextEditingController();
  final editUsernameController = TextEditingController();
  final editDayController = TextEditingController();

  String newUserRole = 'member';
  bool isLoading = false;

  late final AnimationController _entranceCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _fetchUsers();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _glowCtrl.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    deleteController.dispose();
    editUsernameController.dispose();
    editDayController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl2}/listUsers?key=$sessionKey',
        ),
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

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _alert("Peringatan", "Masukkan username yang ingin dihapus.");
      return;
    }
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl2}/deleteUser?key=$sessionKey&username=$username',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _alert("Sukses", "User berhasil dihapus.");
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

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
      final url = Uri.parse(
        '${ApiConfig.baseUrl2}/userAdd?key=$sessionKey&username=$u&password=$p&day=$d&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);
      if (data['created'] == true) {
        _alert(
          "Sukses",
          "Akun berhasil dibuat sebagai ${newUserRole.toUpperCase()}.",
        );
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
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
      final url = Uri.parse(
        '${ApiConfig.baseUrl2}/editUser?key=$sessionKey&username=$u&addDays=$d',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);
      if (data['edited'] == true) {
        _alert("Sukses", "Durasi berhasil diperbarui.");
        editUsernameController.clear();
        editDayController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal mengubah durasi.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  void _alert(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: AppTheme.cardDecor().copyWith(
                color: AppTheme.bgCard.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient(AppTheme.teal),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: AppTheme.softGlow(AppTheme.teal, blur: 12, opacity: 0.4),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: AppTheme.headingM.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    style: AppTheme.bodyL,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient(AppTheme.teal),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "MENGERTI",
                          style: TextStyle(
                            color: AppTheme.bgDeep,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1,
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

  Widget _glassPanel({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: AppTheme.cardDecor().copyWith(
            color: AppTheme.bgCard.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color accent,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient(accent),
            borderRadius: BorderRadius.circular(11),
            boxShadow: AppTheme.softGlow(accent, blur: 14, opacity: 0.35),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.headingM.copyWith(
                  fontSize: 14.5,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.caption.copyWith(
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 7),
      child: Text(
        text,
        style: AppTheme.label.copyWith(
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          Container(
            height: 46,
            decoration: AppTheme.inputDecor().copyWith(
              borderRadius: BorderRadius.circular(13),
            ),
            child: TextField(
              controller: controller,
              keyboardType: type,
              cursorColor: AppTheme.teal,
              style: AppTheme.bodyL.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: Icon(
                    icon,
                    color: AppTheme.teal.withValues(alpha: 0.8),
                    size: 15,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePicker({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final role = items[index];
          final active = role == value;
          return GestureDetector(
            onTap: () => onChanged(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active
                    ? AppTheme.accentGradient(AppTheme.teal)
                    : null,
                color: active ? null : AppTheme.bgSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: active ? Colors.transparent : AppTheme.borderSubtle,
                ),
                boxShadow: active
                    ? AppTheme.softGlow(AppTheme.teal, blur: 12, opacity: 0.35)
                    : [],
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  color: active ? Colors.white : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionBtn({
    required String text,
    required IconData icon,
    required Color c1,
    required Color c2,
    required VoidCallback? onPressed,
    bool showLoader = false,
  }) {
    final disabled = onPressed == null;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        gradient: disabled ? null : LinearGradient(colors: [c1, c2]),
        color: disabled ? AppTheme.bgSurface.withValues(alpha: 0.3) : null,
        borderRadius: BorderRadius.circular(13),
        boxShadow: disabled
            ? []
            : AppTheme.softGlow(c1, blur: 18, opacity: 0.35),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onPressed,
          child: Center(
            child: showLoader
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: disabled ? AppTheme.textMuted : Colors.white,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        text,
                        style: TextStyle(
                          color: disabled ? AppTheme.textMuted : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required List<Widget> children,
  }) {
    final anim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(
        (index * 0.1).clamp(0.0, 0.6),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _glassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionHeader(
                  icon: icon,
                  title: title,
                  subtitle: subtitle,
                  accent: accent,
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _userItem(Map user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppTheme.cardDecor().copyWith(
        color: AppTheme.bgSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient(AppTheme.teal),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.teal.withValues(alpha: 0.25),
                            AppTheme.sky.withValues(alpha: 0.25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (user['role'] ?? '').toString().toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.teal,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppTheme.textMuted,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user['expiredDate'] ?? '-',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.6),
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.cardDecor().copyWith(
                            color: AppTheme.bgCard.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Konfirmasi",
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Hapus user ini secara permanen?",
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: AppTheme.borderSubtle,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "Batal",
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.accentGradient(AppTheme.coral),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                          onTap: () =>
                                              Navigator.pop(context, true),
                                          child: const Center(
                                            child: Text(
                                              "Hapus",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                if (confirm == true) {
                  deleteController.text = user['username'];
                  _deleteUser();
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: AppTheme.accentCardDecor(AppTheme.coral).copyWith(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.coral,
                  size: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: active
              ? AppTheme.accentGradient(AppTheme.teal)
              : null,
          color: active ? null : AppTheme.bgSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? Colors.transparent : AppTheme.borderSubtle),
          boxShadow: active
              ? AppTheme.softGlow(AppTheme.teal, blur: 10, opacity: 0.35)
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppTheme.textSecondary,
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        return _pageBtn(
          label: "$page",
          active: currentPage == page,
          onTap: () => setState(() => currentPage = page),
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
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (context, _) {
              return Positioned(
                top: -140 + (_glowCtrl.value * 30),
                left: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.teal.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (context, _) {
              return Positioned(
                bottom: -160 + (_glowCtrl.value * -25),
                right: -120,
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.sky.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _entranceCtrl,
                    child: _glassPanel(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient(AppTheme.teal),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppTheme.softGlow(AppTheme.teal, blur: 16, opacity: 0.4),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [AppTheme.textPrimary, AppTheme.teal],
                                      ).createShader(bounds),
                                  child: const Text(
                                    "OWNER PANEL",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppTheme.mint,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.mint.withValues(alpha: 0.6),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      widget.username,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.teal.withValues(alpha: 0.3),
                                            AppTheme.sky.withValues(alpha: 0.3),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: const Text(
                                        "ROOT",
                                        style: TextStyle(
                                          color: AppTheme.teal,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  _sectionCard(
                    index: 0,
                    icon: FontAwesomeIcons.trash,
                    title: "Delete User",
                    subtitle: "Hapus akun secara permanen",
                    accent: AppTheme.coral,
                    children: [
                      _buildInput(
                        label: "USERNAME TARGET",
                        controller: deleteController,
                        icon: FontAwesomeIcons.user,
                      ),
                      _actionBtn(
                        text: "DELETE ACCOUNT",
                        icon: FontAwesomeIcons.trash,
                        c1: AppTheme.coral,
                        c2: AppTheme.coral,
                        onPressed: isLoading ? null : _deleteUser,
                      ),
                    ],
                  ),

                  _sectionCard(
                    index: 1,
                    icon: FontAwesomeIcons.userPlus,
                    title: "Create Account",
                    subtitle: "Buat akun baru dengan role tertentu",
                    accent: AppTheme.mint,
                    children: [
                      _buildInput(
                        label: "USERNAME",
                        controller: createUsernameController,
                        icon: FontAwesomeIcons.user,
                      ),
                      _buildInput(
                        label: "PASSWORD",
                        controller: createPasswordController,
                        icon: FontAwesomeIcons.lock,
                      ),
                      _buildInput(
                        label: "DURASI (HARI)",
                        controller: createDayController,
                        icon: FontAwesomeIcons.calendarDay,
                        type: TextInputType.number,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel("ROLE"),
                          _buildRolePicker(
                            value: newUserRole,
                            items: roleOptions,
                            onChanged: (val) =>
                                setState(() => newUserRole = val ?? 'member'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _actionBtn(
                        text: "CREATE ACCOUNT",
                        icon: FontAwesomeIcons.plus,
                        c1: AppTheme.mint,
                        c2: AppTheme.teal,
                        onPressed: isLoading ? null : _createAccount,
                        showLoader: isLoading,
                      ),
                    ],
                  ),

                  _sectionCard(
                    index: 2,
                    icon: FontAwesomeIcons.calendarPlus,
                    title: "Extend Duration",
                    subtitle: "Tambah masa aktif akun",
                    accent: AppTheme.lavender,
                    children: [
                      _buildInput(
                        label: "USERNAME TARGET",
                        controller: editUsernameController,
                        icon: FontAwesomeIcons.userEdit,
                      ),
                      _buildInput(
                        label: "TAMBAH HARI",
                        controller: editDayController,
                        icon: FontAwesomeIcons.calendarPlus,
                        type: TextInputType.number,
                      ),
                      _actionBtn(
                        text: "ADD DAYS",
                        icon: FontAwesomeIcons.plus,
                        c1: AppTheme.lavender,
                        c2: AppTheme.sky,
                        onPressed: isLoading ? null : _editUser,
                        showLoader: isLoading,
                      ),
                    ],
                  ),

                  _sectionCard(
                    index: 3,
                    icon: FontAwesomeIcons.users,
                    title: "User List",
                    subtitle: "Lihat & kelola seluruh pengguna",
                    accent: AppTheme.teal,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel("FILTER ROLE"),
                          _buildRolePicker(
                            value: selectedRole,
                            items: roleOptions,
                            onChanged: (val) {
                              if (val != null) {
                                selectedRole = val;
                                _filterAndPaginate();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people_alt_rounded,
                              color: AppTheme.textMuted,
                              size: 13,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${filteredList.length} user",
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                            const Spacer(),
                            if (totalPages > 1)
                              Text(
                                "page $currentPage/$totalPages",
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: AppTheme.teal,
                                  ),
                                ),
                              ),
                            )
                          : filteredList.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox_rounded,
                                      color: AppTheme.textMuted.withValues(alpha: 0.6),
                                      size: 30,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Tidak ada data",
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                ..._getCurrentPageData().map(
                                  (u) => _userItem(u as Map),
                                ),
                                const SizedBox(height: 14),
                                _buildPagination(),
                              ],
                            ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.teal, AppTheme.sky],
                      ).createShader(bounds),
                      child: const Text(
                        "\u25c6  MEGATRON  \u25c6",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
