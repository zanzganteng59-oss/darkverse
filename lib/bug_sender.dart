import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:darkverse/theme/app_theme.dart';
import 'api.dart';

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage>
    with TickerProviderStateMixin {
  List<dynamic> senderList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _listSlideController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _listSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fetchSenders();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _listSlideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchSenders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            "${ApiConfig.baseUrl}/mySender?key=${widget.sessionKey}"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          if (mounted) {
            setState(() {
              senderList = data["connections"] ?? [];
            });
            _listSlideController.forward(from: 0);
          }
        } else {
          if (mounted) {
            setState(() => errorMessage = data["message"] ?? "Failed to fetch");
          }
        }
      } else {
        if (mounted) {
          setState(() => errorMessage = "Server error: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (mounted) setState(() => errorMessage = "Connection failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchSenders();
  }

  void _showAddSenderDialog() {
    final phoneController = TextEditingController();
    final focusNode = FocusNode();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) {
        final scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutCubic),
        );
        return ScaleTransition(
          scale: scaleAnim,
          child: AlertDialog(
            backgroundColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              side: const BorderSide(color: AppTheme.borderMedium),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.cardDecor(),
                  child: const Icon(Icons.add_link_rounded,
                      color: AppTheme.teal, size: 22),
                ),
                const SizedBox(height: 18),
                const Text(
                  "New Sender",
                  style: AppTheme.headingL,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Masukkan nomor WhatsApp target yang ingin dihubungkan sebagai Sender Node.",
                  style: AppTheme.bodyM,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  decoration: AppTheme.inputDecor(),
                  child: TextField(
                    controller: phoneController,
                    focusNode: focusNode,
                    keyboardType: TextInputType.phone,
                    cursorColor: AppTheme.teal,
                    style: AppTheme.bodyL.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: AppTheme.caption,
                      hintText: "628xxx...",
                      hintStyle: AppTheme.bodyM.copyWith(
                        color: AppTheme.textMuted.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: const Icon(Icons.phone_android,
                            color: AppTheme.teal, size: 16),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.textMuted.withValues(alpha: 0.5), size: 13),
                      const SizedBox(width: 6),
                      Text(
                        "Gunakan format kode negara tanpa +",
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textMuted.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: AppTheme.inputDecor(),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient(AppTheme.teal),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.softGlow(AppTheme.teal),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          onTap: () async {
                            final number = phoneController.text.trim();
                            if (number.isEmpty) {
                              Navigator.pop(context);
                              _showSnackBar(
                                  "Number cannot be empty",
                                  isError: true);
                              return;
                            }
                            Navigator.pop(context);
                            await _addSender(number);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt_rounded,
                                  color: AppTheme.bgDeep, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "Generate Pairing",
                                style: TextStyle(
                                  color: AppTheme.bgDeep,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addSender(String number) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          "${ApiConfig.baseUrl}/getPairing?key=${widget.sessionKey}&number=$number"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          _showPairingCodeDialog(number, data['pairingCode']);
          _showSnackBar("Pairing sequence generated!", isError: false);
        } else {
          _showSnackBar(data['message'] ?? "Pairing failed", isError: true);
        }
      } else {
        _showSnackBar("Server Error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection Fault: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
      _fetchSenders();
    }
  }

  void _showPairingCodeDialog(String number, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (context) {
        final scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutBack),
        );
        return ScaleTransition(
          scale: scaleAnim,
          child: AlertDialog(
            backgroundColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              side: const BorderSide(color: AppTheme.borderMedium),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecor(accent: AppTheme.mint).copyWith(
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      color: AppTheme.teal, size: 38),
                ),
                const SizedBox(height: 22),
                const Text(
                  "Pairing Required",
                  style: AppTheme.headingL,
                ),
                const SizedBox(height: 6),
                const Text(
                  "Masukkan kode ini ke perangkat target",
                  style: AppTheme.bodyM,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_android_rounded,
                          color: AppTheme.textMuted, size: 13),
                      const SizedBox(width: 8),
                      Text(
                        number,
                        style: AppTheme.caption.copyWith(
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: AppTheme.accentCardDecor(AppTheme.teal),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          code.length,
                          (i) => Padding(
                            padding: EdgeInsets.only(
                                right: i < code.length - 1 ? 10 : 0),
                            child: Container(
                              width: 38,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderMedium),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                code[i],
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: AppTheme.cardDecor(accent: AppTheme.teal),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        _showSnackBar(
                            "Sequence copied to clipboard!", isError: false);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.copy_all_rounded,
                              color: AppTheme.teal, size: 18),
                          const SizedBox(width: 10),
                          const Text(
                            "Copy to Clipboard",
                            style: TextStyle(
                              color: AppTheme.teal,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient(AppTheme.teal),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchSenders();
                  },
                  child: const Text(
                    "Close & Refresh",
                    style: TextStyle(
                      color: AppTheme.bgDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteSender(String senderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (context) {
        final scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutCubic),
        );
        return ScaleTransition(
          scale: scaleAnim,
          child: AlertDialog(
            backgroundColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              side: BorderSide(color: AppTheme.coral.withValues(alpha: 0.12)),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.accentCardDecor(AppTheme.coral),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.coral, size: 22),
                ),
                const SizedBox(width: 14),
                const Text(
                  "Hapus Node",
                  style: AppTheme.headingM,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Apakah Anda yakin ingin menghapus Sender Node ini selamanya?",
                  style: AppTheme.bodyL,
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: AppTheme.accentCardDecor(AppTheme.coral),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.coral.withValues(alpha: 0.6), size: 14),
                      const SizedBox(width: 8),
                      Text(
                        "Proses ini tidak dapat dibatalkan",
                        style: TextStyle(
                          color: AppTheme.coral.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: AppTheme.inputDecor(),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient(AppTheme.coral),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.softGlow(AppTheme.coral),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          onTap: () => Navigator.pop(context, true),
                          child: const Center(
                            child: Text(
                              "Hapus",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
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
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      setState(() => isLoading = true);
      try {
        final response = await http.delete(Uri.parse(
            "${ApiConfig.baseUrl}/deleteSender?key=${widget.sessionKey}&id=$senderId"));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["valid"] == true) {
            _showSnackBar("Node berhasil dihapus.", isError: false);
            _fetchSenders();
          } else {
            _showSnackBar(
                data["message"] ?? "Failed to purge node", isError: true);
          }
        } else {
          _showSnackBar("Server error: ${response.statusCode}", isError: true);
        }
      } catch (e) {
        _showSnackBar("Connection failed: $e", isError: true);
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isError
                    ? AppTheme.coral.withValues(alpha: 0.12)
                    : AppTheme.mint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? AppTheme.coral : AppTheme.mint,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? AppTheme.coral : AppTheme.mint,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: isError
                  ? AppTheme.coral.withValues(alpha: 0.12)
                  : AppTheme.mint.withValues(alpha: 0.12)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  Widget _buildSenderCard(Map<String, dynamic> sender, int index) {
    final name = sender['sessionName'] ?? 'WhatsApp Sender';
    final idStr = sender['id']?.toString() ?? '';
    final shortId = idStr.length >= 8 ? idStr.substring(0, 8) : idStr;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _listSlideController,
        curve: Interval(
          (index * 0.08).clamp(0.0, 0.6),
          1.0,
          curve: Curves.easeOutCubic,
        ),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _listSlideController,
          curve: Interval(
            (index * 0.08).clamp(0.0, 0.6),
            1.0,
            curve: Curves.easeOut,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: AppTheme.cardDecor().copyWith(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderMedium),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.borderMedium.withValues(alpha: 0.3),
                              AppTheme.borderSubtle.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: const Icon(Icons.hub_outlined,
                              color: AppTheme.teal, size: 21),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: AppTheme.headingM.copyWith(
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Text(
                                "ID: $shortId",
                                style: AppTheme.caption.copyWith(
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: AppTheme.accentCardDecor(AppTheme.mint),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: AppTheme.mint,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.mint.withValues(
                                            alpha: _pulseAnimation.value),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              "Online",
                              style: TextStyle(
                                color: AppTheme.mint,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.borderSubtle.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor:
                                AppTheme.textPrimary.withValues(alpha: 0.03),
                            highlightColor:
                                AppTheme.textPrimary.withValues(alpha: 0.02),
                            onTap: () => _refreshSenders(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sync_rounded,
                                      size: 14, color: AppTheme.textMuted),
                                  SizedBox(width: 8),
                                  Text(
                                    "Sync",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          color: AppTheme.borderSubtle),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor:
                                AppTheme.coral.withValues(alpha: 0.03),
                            highlightColor:
                                AppTheme.coral.withValues(alpha: 0.02),
                            onTap: () => _deleteSender(sender['id']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 14, color: AppTheme.coral),
                                  SizedBox(width: 8),
                                  Text(
                                    "Hapus",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: AppTheme.coral,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeController,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.bgSurface,
                    border: Border.all(color: AppTheme.borderSubtle),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderMedium),
                    ),
                    child: const Icon(Icons.router_outlined,
                        color: AppTheme.teal, size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                "Belum Ada Node",
                style: AppTheme.headingL,
              ),
              const SizedBox(height: 12),
              const Text(
                "Sistem tidak mendeteksi koneksi pengirim.\nTambahkan WhatsApp node pertama Anda.",
                style: AppTheme.bodyM,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient(AppTheme.teal),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softGlow(AppTheme.teal, blur: 16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _showAddSenderDialog,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_link_rounded,
                            color: AppTheme.bgDeep, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Tambah Sender",
                          style: TextStyle(
                            color: AppTheme.bgDeep,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.accentCardDecor(AppTheme.coral).copyWith(
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppTheme.coral, size: 38),
            ),
            const SizedBox(height: 32),
            const Text(
              "Koneksi Gagal",
              style: AppTheme.headingL,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Unknown connection error occurred",
              style: AppTheme.bodyL,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient(AppTheme.teal),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softGlow(AppTheme.teal, blur: 14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _fetchSenders,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: AppTheme.bgDeep, size: 18),
                      SizedBox(width: 10),
                      Text(
                        "Coba Lagi",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.bgDeep,
                          fontSize: 14,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: FadeTransition(
        opacity: _fadeController,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard.withValues(alpha: 0.85),
                  border: const Border(
                    bottom: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: AppTheme.inputDecor(),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: AppTheme.textSecondary, size: 14),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sender Nodes",
                            style: AppTheme.headingL,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppTheme.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Kelola perangkat pengirim",
                                style: AppTheme.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: AppTheme.inputDecor(),
                      child: IconButton(
                        icon: Icon(
                          Icons.sync_rounded,
                          color: isLoading
                              ? AppTheme.textMuted.withValues(alpha: 0.3)
                              : AppTheme.teal,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: isLoading ? null : _refreshSenders,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecor(),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: const Icon(Icons.devices_rounded,
                                  color: AppTheme.teal, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${senderList.length}",
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  "Node Aktif",
                                  style: AppTheme.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecor(),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: const Icon(Icons.shield_outlined,
                                  color: AppTheme.teal, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.role.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    "Akses Level",
                                    style: AppTheme.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.borderSubtle.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              if (senderList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        "TERHUBUNG",
                        style: AppTheme.label.copyWith(
                          color: AppTheme.textMuted.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppTheme.borderSubtle.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${senderList.length} UNIT",
                        style: AppTheme.label.copyWith(
                          color: AppTheme.textMuted.withValues(alpha: 0.5),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: isLoading && senderList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(10),
                              decoration: AppTheme.inputDecor(),
                              child: const CircularProgressIndicator(
                                color: AppTheme.teal,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              "Memuat data...",
                              style: AppTheme.bodyM,
                            ),
                          ],
                        ),
                      )
                    : errorMessage != null && senderList.isEmpty
                        ? _buildErrorState()
                        : senderList.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: AppTheme.teal,
                                backgroundColor: AppTheme.bgCard,
                                onRefresh: _refreshSenders,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(
                                      top: 6, bottom: 100),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: senderList.length,
                                  itemBuilder: (context, index) =>
                                      _buildSenderCard(
                                          Map<String, dynamic>.from(
                                              senderList[index]),
                                          index),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: senderList.isNotEmpty
          ? Container(
              height: 54,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient(AppTheme.teal),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softGlow(AppTheme.teal),
              ),
              child: FloatingActionButton.extended(
                onPressed: _showAddSenderDialog,
                backgroundColor: Colors.transparent,
                elevation: 0,
                highlightElevation: 0,
                icon: const Icon(Icons.add_rounded,
                    color: AppTheme.bgDeep, size: 20),
                label: const Text(
                  "Tambah Node",
                  style: TextStyle(
                    color: AppTheme.bgDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
