import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ══════════════════════════════════════════
  //  CYBER / HACKER / ROBOT THEME
  // ══════════════════════════════════════════

  // Backgrounds — deep void black with green tint
  static const Color bgDeep = Color(0xFF020A06);
  static const Color bgSurface = Color(0xFF061210);
  static const Color bgCard = Color(0xFF0A1A14);
  static const Color bgCardLight = Color(0xFF0E2218);
  static const Color bgInput = Color(0xFF081410);
  static const Color bgGlass = Color(0x1400FF41);

  // Primary — Matrix / Cyber Green
  static const Color gold = Color(0xFF00FF41);
  static const Color mint = Color(0xFF00FF41);
  static const Color neonGreen = Color(0xFF39FF14);

  // Accents — Neon Cyber
  static const Color coral = Color(0xFFFF0040);
  static const Color lavender = Color(0xFF00FFFF);
  static const Color sky = Color(0xFF0080FF);
  static const Color rose = Color(0xFFFF0066);
  static const Color peach = Color(0xFFFF6600);
  static const Color teal = Color(0xFF00FFAA);

  // Backward compat neon aliases
  static const Color neonYellow = Color(0xFFCCFF00);
  static const Color neonPink = Color(0xFFFF0066);
  static const Color neonBlue = Color(0xFF0080FF);
  static const Color neonOrange = Color(0xFFFF6600);
  static const Color neonPurple = Color(0xFF00FFFF);
  static const Color neonCyan = Color(0xFF00FFEE);
  static const Color neonRed = Color(0xFFFF0040);
  static const Color neonFuchsia = Color(0xFFFF00FF);
  static const Color neonLime = Color(0xFF39FF14);
  static const Color neonElectric = Color(0xFF0066FF);

  // Text — cold white with green tint
  static const Color textPrimary = Color(0xFFD0FFE0);
  static const Color textSecondary = Color(0xFF6B8F7A);
  static const Color textMuted = Color(0xFF3A5A48);

  // Borders — cyber grid
  static const Color borderSubtle = Color(0xFF0D2A1A);
  static const Color borderMedium = Color(0xFF143D28);
  static const Color borderBold = Color(0xFF1A5030);

  // Neon borders
  static const Color neonBorderGold = Color(0x9900FF41);
  static const Color neonBorderCyan = Color(0x9900FFEE);
  static const Color neonBorderPink = Color(0x99FF0040);
  static const Color neonBorderBlue = Color(0x990080FF);

  // Radius
  static const double radiusS = 6.0;
  static const double radiusM = 10.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Border width — sharp, precise
  static const double borderW = 1.5;

  // ══════════════════════════════════════════
  //  SHADOWS — CYBER GLOW
  // ══════════════════════════════════════════

  static List<BoxShadow> softGlow(Color color, {double blur = 20, double opacity = 0.15}) {
    return [
      BoxShadow(color: color.withValues(alpha: opacity), blurRadius: blur, spreadRadius: -2),
    ];
  }

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: const Color(0xFF00FF41).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(color: const Color(0xFF00FF41).withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 6)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 32, offset: const Offset(0, 12)),
  ];

  // Cyber glow — sharp neon edges
  static List<BoxShadow> neoShadow(Color color, {double offset = 3}) {
    return [
      BoxShadow(color: color.withValues(alpha: 0.3), offset: Offset(offset, offset), blurRadius: 0),
      BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 3)),
    ];
  }

  // Intense neon glow
  static List<BoxShadow> neonGlow(Color color, {double blur = 20, double opacity = 0.25}) {
    return [
      BoxShadow(color: color.withValues(alpha: opacity), blurRadius: blur, spreadRadius: -4),
      BoxShadow(color: color.withValues(alpha: opacity * 0.4), blurRadius: blur * 2, spreadRadius: -8),
    ];
  }

  // Terminal green glow
  static List<BoxShadow> terminalGlow({double blur = 16, double opacity = 0.2}) {
    return [
      BoxShadow(color: const Color(0xFF00FF41).withValues(alpha: opacity), blurRadius: blur, spreadRadius: -2),
      BoxShadow(color: const Color(0xFF00FF41).withValues(alpha: opacity * 0.3), blurRadius: blur * 2.5, spreadRadius: -6),
    ];
  }

  // ══════════════════════════════════════════
  //  GRADIENTS
  // ══════════════════════════════════════════

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF020A06), Color(0xFF041008)],
  );

  static LinearGradient cardGradient(Color accent) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [bgCard, bgCard.withValues(alpha: 0.9)],
    );
  }

  static LinearGradient accentGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color, color.withValues(alpha: 0.6)],
    );
  }

  // Cyber scanline gradient
  static LinearGradient cyberGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A1A14), Color(0xFF061210), Color(0xFF0A1A14)],
    );
  }

  // ══════════════════════════════════════════
  //  DECORATIONS
  // ══════════════════════════════════════════

  static BoxDecoration cardDecor({Color? accent, Color? border}) {
    return BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(color: border ?? borderBold, width: borderW),
      boxShadow: accent != null ? neoShadow(accent) : cardShadow,
    );
  }

  static BoxDecoration accentCardDecor(Color color) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.03)],
      ),
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(color: color.withValues(alpha: 0.4), width: borderW),
      boxShadow: neoShadow(color),
    );
  }

  static BoxDecoration glassCardDecor() {
    return BoxDecoration(
      color: bgGlass,
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(color: const Color(0xFF00FF41).withValues(alpha: 0.15), width: 1),
      boxShadow: cardShadow,
    );
  }

  static BoxDecoration inputDecor() {
    return BoxDecoration(
      color: bgInput,
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(color: borderBold, width: borderW),
    );
  }

  // Cyber terminal-style card
  static BoxDecoration terminalCardDecor({Color? accent}) {
    return BoxDecoration(
      color: const Color(0xFF040E08),
      borderRadius: BorderRadius.circular(radiusS),
      border: Border.all(
        color: (accent ?? const Color(0xFF00FF41)).withValues(alpha: 0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: (accent ?? const Color(0xFF00FF41)).withValues(alpha: 0.05),
          blurRadius: 12,
          spreadRadius: -2,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  //  TEXT STYLES
  // ══════════════════════════════════════════

  static const TextStyle headingL = TextStyle(
    color: textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1,
    fontFamily: 'Orbitron',
  );
  static const TextStyle headingM = TextStyle(
    color: textPrimary, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5,
    fontFamily: 'Orbitron',
  );
  static const TextStyle headingS = TextStyle(
    color: textPrimary, fontSize: 13, fontWeight: FontWeight.w700,
    fontFamily: 'ShareTechMono',
  );
  static const TextStyle bodyL = TextStyle(
    color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5,
    fontFamily: 'ShareTechMono',
  );
  static const TextStyle bodyM = TextStyle(
    color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4,
    fontFamily: 'ShareTechMono',
  );
  static const TextStyle caption = TextStyle(
    color: textMuted, fontSize: 11, fontWeight: FontWeight.w600,
    fontFamily: 'ShareTechMono',
  );
  static const TextStyle label = TextStyle(
    color: textPrimary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2,
    fontFamily: 'ShareTechMono',
  );

  // ══════════════════════════════════════════
  //  BUTTON STYLES
  // ══════════════════════════════════════════

  static ButtonStyle primaryButton(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: bgDeep,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: borderW),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'ShareTechMono'),
    );
  }

  static ButtonStyle ghostButton(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.4), width: borderW),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'ShareTechMono'),
    );
  }

  // ══════════════════════════════════════════
  //  SECTION LABEL
  // ══════════════════════════════════════════

  static Widget sectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Text(text.toUpperCase(), style: label.copyWith(color: textMuted, letterSpacing: 3)),
      ],
    );
  }

  // ══════════════════════════════════════════
  //  CYBER HELPERS
  // ══════════════════════════════════════════

  // Glitch-style text shadow
  static List<Shadow> glitchShadow(Color color) {
    return [
      Shadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
      Shadow(color: color.withValues(alpha: 0.2), blurRadius: 20),
    ];
  }

  // Cyber divider
  static Widget cyberDivider({Color? color}) {
    final c = color ?? const Color(0xFF00FF41);
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, c.withValues(alpha: 0.3), Colors.transparent],
        ),
      ),
    );
  }

  // Terminal prompt style
  static TextStyle terminalStyle({Color? color, double? fontSize}) {
    return TextStyle(
      color: color ?? const Color(0xFF00FF41),
      fontSize: fontSize ?? 12,
      fontWeight: FontWeight.w500,
      fontFamily: 'ShareTechMono',
    );
  }
}
