import 'package:flutter/material.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.textPrimary,
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "Customer Service",
          style: AppTheme.headingM.copyWith(
            color: AppTheme.coral,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppTheme.borderSubtle, height: 1),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.coral.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.coral.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: AppTheme.softGlow(
                      AppTheme.coral,
                      blur: 30,
                      opacity: 0.12,
                    ),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    size: 56,
                    color: AppTheme.coral,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "Need Help?",
                  style: AppTheme.headingL.copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Text(
                  "Hubungi kami melalui platform media sosial di bawah ini.",
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyL.copyWith(height: 1.5),
                ),
                const SizedBox(height: 40),
                _buildContactButton(
                  label: "Telegram",
                  subtitle: "@zanzsii_md",
                  icon: FontAwesomeIcons.telegram,
                  brandColor: const Color(0xFF2AABEE),
                  url: "https://t.me/zanzsii",
                ),
                const SizedBox(height: 12),
                _buildContactButton(
                  label: "WhatsApp",
                  subtitle: "+62 831-6766-2069",
                  icon: FontAwesomeIcons.whatsapp,
                  brandColor: AppTheme.mint,
                  url: "https://wa.me/6283167662069",
                ),
                const SizedBox(height: 12),
                _buildContactButton(
                  label: "TikTok",
                  subtitle: "@zsnthan",
                  icon: FontAwesomeIcons.tiktok,
                  brandColor: AppTheme.textPrimary,
                  url: "https://www.tiktok.com/@zsnthan?_r=1&_t=ZS-99k7wW8eV1Q",
                ),
                const SizedBox(height: 12),
                _buildContactButton(
                  label: "Instagram",
                  subtitle: "@darkness_reals",
                  icon: FontAwesomeIcons.instagram,
                  brandColor: AppTheme.coral,
                  url:
                      "https://www.instagram.com/darkness_reals?igsh=MWM2MDl5NXg0bTJpNg==",
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: AppTheme.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text("DarkVerse Support", style: AppTheme.caption),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color brandColor,
    required String url,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        splashColor: AppTheme.coral.withValues(alpha: 0.06),
        highlightColor: AppTheme.coral.withValues(alpha: 0.03),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(color: AppTheme.borderSubtle),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: brandColor.withValues(alpha: 0.15)),
                ),
                child: FaIcon(icon, color: brandColor, size: 22),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTheme.bodyM.copyWith(
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.textMuted,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
