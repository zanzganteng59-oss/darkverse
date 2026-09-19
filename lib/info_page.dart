import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:darkverse/theme/app_theme.dart';
import 'api.dart';

class InfoPage extends StatefulWidget {
  final String sessionKey;

  const InfoPage({super.key, required this.sessionKey});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with TickerProviderStateMixin {
  Map<String, dynamic>? serverInfo;
  bool isLoading = true;

  bool isApiOnline = false;
  int apiPingMs = 0;
  Color apiStatusColor = AppTheme.textMuted;
  String apiStatusText = "Checking...";
  Timer? _pingTimer;

  late AnimationController _entranceController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _fetchServerInfo();
    _startApiPingLoop();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _entranceController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _fetchServerInfo() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl4}/getServerInfo?key=${widget.sessionKey}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          serverInfo = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _startApiPingLoop() {
    _checkApiPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkApiPing());
  }

  Future<void> _checkApiPing() async {
    final start = DateTime.now();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl4}/ping?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 3));
      final end = DateTime.now();
      final duration = end.difference(start).inMilliseconds;
      if (res.statusCode == 200) {
        setState(() {
          isApiOnline = true;
          apiPingMs = duration;
          if (duration < 200) {
            apiStatusColor = AppTheme.mint;
          } else if (duration < 500) {
            apiStatusColor = AppTheme.gold;
          } else {
            apiStatusColor = AppTheme.coral;
          }
          apiStatusText = "Online (${duration}ms)";
        });
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      setState(() {
        isApiOnline = false;
        apiPingMs = 0;
        apiStatusColor = AppTheme.textMuted;
        apiStatusText = "Offline";
      });
    }
  }

  Widget _staggeredItem({required int index, required Widget child, int total = 12}) {
    final double start = (index * 0.5 / total).clamp(0.0, 0.85);
    final double end = (start + 0.35).clamp(0.0, 1.0);
    final Animation<double> animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double value = animation.value;
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset((1 - value) * 40, 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _darkCard({
    required Widget child,
    EdgeInsets? padding,
    Decoration? decoration,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration ?? AppTheme.cardDecor(),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: AppTheme.bgDeep,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _darkCard(
                  padding: const EdgeInsets.all(24),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppTheme.coral,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "LOADING...",
                  style: AppTheme.label.copyWith(letterSpacing: 3),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient(AppTheme.gold),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> rulesList = [
      {
        "title": "Larangan Barter Akun",
        "desc": "Akun tidak boleh ditukar dengan barang, jasa, atau akun lain dalam bentuk apa pun.",
        "icon": Icons.swap_horiz_rounded,
        "color": AppTheme.coral,
      },
      {
        "title": "Larangan Membagikan Akun",
        "desc": "Setiap akun bersifat pribadi dan hanya boleh digunakan oleh pemilik akun yang terdaftar.",
        "icon": Icons.no_accounts_rounded,
        "color": AppTheme.sky,
      },
      {
        "title": "Larangan Menjual Akun",
        "desc": "Member TIDAK diperbolehkan menjual akun. Penjualan akun hanya boleh dilakukan oleh role yang diizinkan secara resmi.",
        "icon": Icons.block_rounded,
        "color": AppTheme.coral,
      },
      {
        "title": "Larangan Jual Durasi Ilegal",
        "desc": "Dilarang menjual akses harian, mingguan, trial, atau sejenisnya di luar ketentuan yang telah ditetapkan.",
        "icon": Icons.timer_off_rounded,
        "color": AppTheme.gold,
      },
      {
        "title": "Larangan Banting Harga",
        "desc": "Dilarang merusak atau menurunkan harga yang telah ditentukan (banting harga) di bawah ketentuan MEGATRON.",
        "icon": Icons.price_change_rounded,
        "color": AppTheme.peach,
      },
    ];

    return Container(
      color: AppTheme.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgDeep,
                border: Border(bottom: BorderSide(color: AppTheme.borderSubtle, width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "PERATURAN & INFO",
                    style: AppTheme.headingL.copyWith(fontFamily: 'Orbitron', letterSpacing: 2),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient(AppTheme.coral),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("MEGATRON", style: AppTheme.caption),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient(AppTheme.gold),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _staggeredItem(index: 0, child: _buildApiStatusCard()),
                    const SizedBox(height: 20),
                    _staggeredItem(index: 1, child: _buildSectionHeader()),
                    const SizedBox(height: 12),
                    _staggeredItem(
                      index: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 16),
                        child: Text(
                          "Wajib dibaca dan dipatuhi oleh seluruh pengguna. Pelanggaran akan dikenakan sanksi tegas.",
                          style: AppTheme.bodyL.copyWith(color: AppTheme.textSecondary, height: 1.5),
                        ),
                      ),
                    ),
                    ...rulesList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rule = entry.value;
                      return _staggeredItem(
                        index: index + 3,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRuleCard(index, rule),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    _staggeredItem(index: rulesList.length + 3, child: _buildSanksiCard()),
                    const SizedBox(height: 32),
                    _staggeredItem(index: rulesList.length + 4, child: _buildFooter()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiStatusCard() {
    return _darkCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.cardDecor(),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, _) {
              final double scale = 1 + (_bounceController.value * 0.15);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: apiStatusColor,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softGlow(apiStatusColor, blur: 6, opacity: 0.4),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SYSTEM STATUS", style: AppTheme.label),
                const SizedBox(height: 2),
                Text(
                  apiStatusText.toUpperCase(),
                  style: AppTheme.headingS.copyWith(color: AppTheme.textPrimary, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          if (isApiOnline && apiPingMs > 0)
            _darkCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: AppTheme.accentCardDecor(AppTheme.gold),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, color: AppTheme.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "${apiPingMs}ms",
                    style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            )
          else if (!isApiOnline)
            _darkCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: AppTheme.accentCardDecor(AppTheme.textMuted),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, color: AppTheme.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text("OFFLINE", style: AppTheme.bodyM.copyWith(color: AppTheme.textMuted, letterSpacing: 0.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return _darkCard(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecor(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient(AppTheme.coral),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(Icons.gavel_rounded, color: AppTheme.bgDeep, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PERATURAN PENGGUNA",
                  style: AppTheme.headingS.copyWith(color: AppTheme.textPrimary, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text("USER TERMS & CONDITIONS", style: AppTheme.label),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient(AppTheme.gold),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Text(
              "\u00d75",
              style: AppTheme.headingS.copyWith(color: AppTheme.bgDeep, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(int index, Map<String, dynamic> rule) {
    final Color accentColor = rule['color'] as Color;
    return _darkCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: AppTheme.accentCardDecor(accentColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient(accentColor),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Text(
                  "$index",
                  style: TextStyle(color: AppTheme.bgDeep, fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rule['title'] as String,
                  style: AppTheme.headingS.copyWith(color: AppTheme.textPrimary, letterSpacing: 0.3),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgInput,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.borderSubtle, width: 1),
                ),
                child: Icon(rule['icon'] as IconData, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.borderSubtle, AppTheme.borderSubtle.withValues(alpha: 0), AppTheme.borderSubtle],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            rule['desc'] as String,
            style: AppTheme.bodyL.copyWith(color: AppTheme.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSanksiCard() {
    return _darkCard(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.coral.withValues(alpha: 0.1),
            AppTheme.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.coral.withValues(alpha: 0.3), width: 1),
        boxShadow: AppTheme.softGlow(AppTheme.coral, blur: 20, opacity: 0.12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient(AppTheme.coral),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              boxShadow: AppTheme.softGlow(AppTheme.coral, blur: 12, opacity: 0.2),
            ),
            child: Icon(Icons.warning_amber_rounded, color: AppTheme.bgDeep, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            "SANKSI PELANGGARAN",
            style: AppTheme.headingL.copyWith(fontFamily: 'Orbitron', letterSpacing: 2, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text("VIOLATION PENALTY", style: AppTheme.label),
          const SizedBox(height: 14),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.borderSubtle, AppTheme.borderSubtle.withValues(alpha: 0), AppTheme.borderSubtle],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Jika pengguna terbukti melanggar salah satu peraturan yang berlaku:",
            style: AppTheme.bodyL.copyWith(color: AppTheme.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _darkCard(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecor(),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient(AppTheme.coral),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Akun akan DIHAPUS secara permanen",
                        style: AppTheme.headingS.copyWith(color: AppTheme.textPrimary, fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient(AppTheme.coral),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Icon(Icons.close_rounded, color: AppTheme.bgDeep, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.coral.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(color: AppTheme.coral.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.coral, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Tanpa pengembalian akun, saldo, atau kompensasi apa pun.",
                          style: AppTheme.bodyM.copyWith(color: AppTheme.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.cardDecor(),
            child: Icon(Icons.shield_moon_rounded, color: AppTheme.coral, size: 32),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.cardDecor(),
            child: Text(
              "Peraturan ini dibuat untuk menjaga keamanan, kenyamanan, dan kestabilan ekosistem MEGATRON App. Dengan menggunakan aplikasi ini, pengguna dianggap telah menyetujui seluruh peraturan yang berlaku.",
              style: AppTheme.bodyM.copyWith(color: AppTheme.textSecondary, height: 1.7),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 4,
            width: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient(AppTheme.gold),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text("MEGATRON \u2022 SECURE ECOSYSTEM", style: AppTheme.label),
          const SizedBox(height: 4),
          Text(
            "\u00a9 ${DateTime.now().year} All rights reserved",
            style: AppTheme.caption.copyWith(color: AppTheme.textMuted.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
