import 'package:flutter/material.dart';

class Neo {
  // ══════════════════════════════════════════
  //  CYBER / HACKER / ROBOT WIDGETS
  // ══════════════════════════════════════════

  static const Color gold      = Color(0xFF00FF41);
  static const Color coral     = Color(0xFFFF0040);
  static const Color lavender  = Color(0xFF00FFFF);
  static const Color mint      = Color(0xFF39FF14);
  static const Color sky       = Color(0xFF0080FF);
  static const Color rose      = Color(0xFFFF0066);
  static const Color peach     = Color(0xFFFF6600);
  static const Color teal      = Color(0xFF00FFAA);
  static const Color cream     = Color(0xFF0A1A14);

  static const Color yellow    = Color(0xFFCCFF00);
  static const Color pink      = coral;
  static const Color purple    = lavender;
  static const Color cyan      = lavender;
  static const Color lime      = mint;
  static const Color orange    = peach;
  static const Color red       = coral;
  static const Color blue      = sky;

  static const Color bg        = Color(0xFF020A06);
  static const Color bgDark    = Color(0xFF020A06);
  static const Color black     = Color(0xFF020A06);
  static const Color textDark  = Color(0xFFD0FFE0);
  static const Color textMuted = Color(0xFF3A5A48);
  static const Color white     = Color(0xFF0A1A14);

  static const double borderW   = 1.5;
  static const double borderWB  = 2.0;
  static const double radiusS   = 6.0;
  static const double radiusM   = 10.0;
  static const double radiusL   = 16.0;
  static const double shadowOff = 3.0;

  static List<BoxShadow> shadow({Color? color, double offset = shadowOff}) {
    final c = color ?? const Color(0xFF00FF41);
    return [
      BoxShadow(
        color: c.withValues(alpha: 0.2),
        offset: Offset(offset, offset),
        blurRadius: 0,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ];
  }

  static List<BoxShadow> shadowPressed() => const [];
}

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double borderW;
  final double shadowOffset;
  final VoidCallback? onTap;
  final bool flat;

  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.radius = Neo.radiusM,
    this.borderW = Neo.borderW,
    this.shadowOffset = Neo.shadowOff,
    this.onTap,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Neo.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? const Color(0xFF00FF41).withValues(alpha: 0.15),
          width: borderW,
        ),
        boxShadow: flat ? const [] : Neo.shadow(offset: shadowOffset),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return StatefulBuilder(builder: (context, setState) {
      return Listener(
        onPointerDown: (_) => setState(() {}),
        onPointerUp: (_) => setState(() {}),
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      );
    });
  }
}

class NeoButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final VoidCallback? onPressed;
  final double height;
  final double radius;
  final double borderW;
  final double shadowOffset;
  final bool expand;
  final Widget? trailing;

  const NeoButton({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.textColor,
    this.onPressed,
    this.height = 56,
    this.radius = Neo.radiusM,
    this.borderW = Neo.borderW,
    this.shadowOffset = Neo.shadowOff,
    this.expand = true,
    this.trailing,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final offset = _pressed ? 0.0 : widget.shadowOffset;
    final dy = _pressed ? widget.shadowOffset : 0.0;

    final btn = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      width: widget.expand ? double.infinity : null,
      height: widget.height,
      transform: Matrix4.translationValues(0, dy, 0),
      decoration: BoxDecoration(
        color: disabled ? Neo.cream : (widget.color ?? Neo.gold),
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: (widget.color ?? Neo.gold).withValues(alpha: 0.5),
          width: widget.borderW,
        ),
        boxShadow: disabled ? [] : Neo.shadow(offset: offset),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: widget.textColor ?? Neo.textDark, size: 20),
            const SizedBox(width: 10),
          ],
          Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              color: widget.textColor ?? Neo.textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontFamily: 'ShareTechMono',
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      child: btn,
    );
  }
}

class NeoChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const NeoChip({super.key, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Neo.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: c,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }
}

class NeoInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final int? maxLines;

  const NeoInput({
    super.key,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Neo.white,
        borderRadius: BorderRadius.circular(Neo.radiusM),
        border: Border.all(color: const Color(0xFF00FF41).withValues(alpha: 0.2), width: Neo.borderW),
        boxShadow: Neo.shadow(),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        readOnly: readOnly,
        maxLines: obscureText ? 1 : maxLines,
        style: const TextStyle(
          color: Neo.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: 'ShareTechMono',
        ),
        decoration: InputDecoration(
          filled: false,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Neo.textMuted,
            fontWeight: FontWeight.w500,
            fontFamily: 'ShareTechMono',
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF00FF41).withValues(alpha: 0.5), size: 20)
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class NeoSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  const NeoSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Neo.gold;
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: c.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, size: 14, color: c),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: c,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontFamily: 'ShareTechMono',
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Neo.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
