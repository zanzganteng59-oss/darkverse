import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'api.dart';

class RiwayatPage extends StatefulWidget {
  final String sessionKey;
  final String role;

  const RiwayatPage({
    super.key,
    required this.sessionKey,
    required this.role,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  List<ActivityModel> activities = [];
  bool isLoading = true;

  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadActivities();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl2}/getMyActivity?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid']) {
          List<dynamic> rawList = data['activities'];

          setState(() {
            activities = rawList.map((item) {
              return ActivityModel(
                type: item['type'] ?? 'system',
                title: item['title'] ?? 'Aktivitas',
                description: item['description'] ?? '-',
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                    item['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
              );
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        debugPrint("Server Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  String _dateSectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return "HARI INI";
    if (diff == 1) return "KEMARIN";
    return DateFormat('dd MMMM yyyy').format(date).toUpperCase();
  }

  Map<String, List<ActivityModel>> _groupedActivities() {
    final Map<String, List<ActivityModel>> grouped = {};
    for (final a in activities) {
      final key = _dateSectionLabel(a.timestamp);
      grouped.putIfAbsent(key, () => []).add(a);
    }
    return grouped;
  }

  int _countByType(String type) =>
      activities.where((a) => a.type == type).length;

  ({Color iconColor, IconData icon, String label, Color badgeBg, Color badgeText})
      _typeStyle(String type) {
    switch (type) {
      case 'login':
        return (
          iconColor: AppTheme.mint,
          icon: Icons.login_rounded,
          label: "LOGIN",
          badgeBg: AppTheme.mint.withValues(alpha: 0.10),
          badgeText: AppTheme.mint,
        );
      case 'bug':
        return (
          iconColor: AppTheme.coral,
          icon: Icons.gpp_maybe_rounded,
          label: "ATTACK",
          badgeBg: AppTheme.coral.withValues(alpha: 0.10),
          badgeText: AppTheme.coral,
        );
      case 'create':
        return (
          iconColor: AppTheme.gold,
          icon: Icons.person_add_alt_1_rounded,
          label: "ACCOUNT",
          badgeBg: AppTheme.gold.withValues(alpha: 0.10),
          badgeText: AppTheme.gold,
        );
      default:
        return (
          iconColor: AppTheme.teal,
          icon: Icons.info_outline_rounded,
          label: "SYSTEM",
          badgeBg: AppTheme.teal.withValues(alpha: 0.08),
          badgeText: AppTheme.teal,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _GridGlowPainter(
                    glow: _glowController.value,
                    accentColor: AppTheme.teal,
                    border: AppTheme.borderSubtle,
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.bgDeep.withValues(alpha: 0.8),
                    AppTheme.bgDeep,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: isLoading
                ? _buildLoadingState()
                : activities.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadActivities,
                        color: AppTheme.teal,
                        backgroundColor: AppTheme.bgCard,
                        strokeWidth: 2.5,
                        child: _buildActivityList(),
                      ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.bgCard,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppTheme.teal, AppTheme.sky],
            ).createShader(bounds),
            child: const Text(
              "ACTIVITY LOG",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "SYSTEM HISTORY TRACE",
            style: AppTheme.caption.copyWith(letterSpacing: 3),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: isLoading ? null : _loadActivities,
          icon: Icon(
            Icons.refresh_rounded,
            color: isLoading ? AppTheme.textMuted : AppTheme.teal,
            size: 20,
          ),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.teal.withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(color: AppTheme.teal, strokeWidth: 2.5),
                Icon(Icons.shield_moon_outlined, color: AppTheme.teal.withValues(alpha: 0.5), size: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "MEMUAT DATA AKTIVITAS...",
            style: AppTheme.caption.copyWith(letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.teal.withValues(alpha: 0.10), width: 2),
                  boxShadow: AppTheme.softGlow(AppTheme.teal, blur: 30, opacity: 0.06),
                ),
                child: Icon(Icons.history_toggle_off, size: 52, color: AppTheme.teal.withValues(alpha: 0.25)),
              ),
              const SizedBox(height: 28),
              Text(
                "NO ACTIVITY YET",
                style: AppTheme.headingM.copyWith(color: AppTheme.teal, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              Text(
                "Belum ada catatan aktivitas.\nPastikan server aktif.",
                textAlign: TextAlign.center,
                style: AppTheme.bodyM.copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadActivities,
                icon: Icon(Icons.refresh_rounded, size: 16, color: AppTheme.teal),
                label: Text(
                  "MUAT ULANG",
                  style: AppTheme.label.copyWith(color: AppTheme.teal),
                ),
                style: AppTheme.ghostButton(AppTheme.teal),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityList() {
    final grouped = _groupedActivities();
    int runningIndex = 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _buildSummaryHeader(),
        const SizedBox(height: 22),
        for (final entry in grouped.entries) ...[
          _buildSectionDivider(entry.key, entry.value.length),
          const SizedBox(height: 10),
          for (final activity in entry.value) ...[
            _buildActivityCard(activity, runningIndex++),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSummaryHeader() {
    final total = activities.length;
    final stats = [
      (_typeStyle('login'), _countByType('login')),
      (_typeStyle('bug'), _countByType('bug')),
      (_typeStyle('create'), _countByType('create')),
      (_typeStyle('system'), _countByType('system')),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: AppTheme.cardDecor(accent: AppTheme.teal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.teal.withValues(alpha: 0.18)),
                ),
                child: FaIcon(FontAwesomeIcons.satelliteDish, size: 16, color: AppTheme.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$total",
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      "TOTAL AKTIVITAS TERCATAT",
                      style: AppTheme.caption.copyWith(letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: AppTheme.mint,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.softGlow(AppTheme.mint, blur: 8, opacity: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppTheme.borderSubtle, height: 1),
          const SizedBox(height: 14),
          Row(
            children: stats.map((s) {
              final style = s.$1;
              final count = s.$2;
              return Expanded(
                child: Column(
                  children: [
                    Icon(style.icon, color: style.iconColor.withValues(alpha: 0.85), size: 16),
                    const SizedBox(height: 6),
                    Text(
                      "$count",
                      style: TextStyle(
                        color: AppTheme.textPrimary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      style.label,
                      style: AppTheme.caption.copyWith(fontSize: 8, letterSpacing: 0.6),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String label, int count) {
    return Row(
      children: [
        Icon(Icons.chevron_right_rounded, size: 14, color: AppTheme.teal.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.bodyM.copyWith(color: AppTheme.teal, fontWeight: FontWeight.w800, letterSpacing: 1.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.borderSubtle, Colors.transparent],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "$count",
          style: AppTheme.caption,
        ),
      ],
    );
  }

  Widget _buildActivityCard(ActivityModel activity, int index) {
    final style = _typeStyle(activity.type);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index % 6) * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: AppTheme.cardDecor(),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      style.iconColor.withValues(alpha: 0.9),
                      style.iconColor.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: style.iconColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          border: Border.all(color: style.iconColor.withValues(alpha: 0.15)),
                        ),
                        child: Icon(style.icon, color: style.iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        "#${(index + 1).toString().padLeft(2, '0')}",
                                        style: AppTheme.caption,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          activity.title,
                                          style: AppTheme.bodyL.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: style.badgeBg,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                    border: Border.all(color: style.badgeText.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    style.label,
                                    style: TextStyle(
                                      color: style.badgeText,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.bgCardLight.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Text(
                                activity.description,
                                style: AppTheme.bodyM.copyWith(height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded, size: 13, color: AppTheme.textMuted),
                                const SizedBox(width: 5),
                                Text(
                                  _formatDate(activity.timestamp),
                                  style: AppTheme.caption,
                                ),
                                const Spacer(),
                                Icon(Icons.circle, size: 4, color: style.iconColor.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  activity.type.toUpperCase(),
                                  style: TextStyle(
                                    color: style.iconColor.withValues(alpha: 0.55),
                                    fontSize: 9,
                                    letterSpacing: 1,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _GridGlowPainter extends CustomPainter {
  final double glow;
  final Color accentColor;
  final Color border;

  _GridGlowPainter({
    required this.glow,
    required this.accentColor,
    required this.border,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = border.withValues(alpha: 0.35)
      ..strokeWidth = 0.6;

    const spacing = 34.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.10 + 0.05 * glow),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.05),
          radius: 260 + 30 * glow,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GridGlowPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

class ActivityModel {
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;

  ActivityModel({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });
}
