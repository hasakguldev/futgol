import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeobrutalistColors {
  static const Color yellow = Color(0xFFFFDE4D);
  static const Color pink = Color(0xFFFF5A92);
  static const Color pinkShadow = Color(0xFFC82E4B);
  static const Color green = Color(0xFF2ECC71);
  static const Color greenShadow = Color(0xFF25A65E);
  static const Color blue = Color(0xFF54A0FF);
  static const Color blueShadow = Color(0xFF2175D5);
  static const Color orange = Color(0xFFFFA043);
  static const Color orangeShadow = Color(0xFFD9781B);
  static const Color purple = Color(0xFF9065FF);
  static const Color purpleShadow = Color(0xFF6B3BC2);
  static const Color gray = Color(0xFF2E2D36);
  static const Color grayShadow = Color(0xFF1A191F);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color pitchGreen = Color(0xFF10B981);
}

class NeobrutalistStyles {
  // Kalın siyah kenarlık
  static Border border({double width = 4.0}) => Border.all(
        color: NeobrutalistColors.black,
        width: width,
      );

  // Sert siyah 3D gölge
  static List<BoxShadow> shadow({Offset offset = const Offset(6, 6)}) => [
        BoxShadow(
          color: NeobrutalistColors.black,
          offset: offset,
          blurRadius: 0,
        ),
      ];

  // Yumuşak kart köşe yarıçapı
  static BorderRadius get radius20 => BorderRadius.circular(20);
  static BorderRadius get radius24 => BorderRadius.circular(24);
  static BorderRadius get radius12 => BorderRadius.circular(12);

  // Yazı stilleri (Lexend ve Plus Jakarta Sans)
  static TextStyle headlineStyle({
    required double fontSize,
    Color color = NeobrutalistColors.black,
    FontWeight fontWeight = FontWeight.w900,
  }) {
    return GoogleFonts.lexend(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle bodyStyle({
    required double fontSize,
    Color color = NeobrutalistColors.black,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

// Ortak Kullanılacak 3D Neobrutalist Buton
class NeobrutalistButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color shadowColor;
  final double height;
  final double? width;
  final EdgeInsets? padding;
  final bool disabled;

  const NeobrutalistButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor = NeobrutalistColors.pink,
    this.shadowColor = NeobrutalistColors.pinkShadow,
    this.height = 56.0,
    this.width,
    this.padding,
    this.disabled = false,
  });

  @override
  State<NeobrutalistButton> createState() => _NeobrutalistButtonState();
}

class _NeobrutalistButtonState extends State<NeobrutalistButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double offsetVal = _isPressed ? 2.0 : 6.0;

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.disabled) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (!widget.disabled) {
          setState(() => _isPressed = false);
          widget.onPressed();
        }
      },
      onTapCancel: () {
        if (!widget.disabled) {
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        height: widget.height,
        width: widget.width,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
        margin: EdgeInsets.only(
          top: _isPressed ? 4.0 : 0.0,
          bottom: _isPressed ? 0.0 : 4.0,
        ),
        decoration: BoxDecoration(
          color: widget.disabled ? NeobrutalistColors.gray : widget.backgroundColor,
          border: NeobrutalistStyles.border(),
          borderRadius: NeobrutalistStyles.radius20,
          boxShadow: [
            BoxShadow(
              color: NeobrutalistColors.black,
              offset: Offset(widget.disabled ? 6.0 : offsetVal, widget.disabled ? 6.0 : offsetVal),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

// Ortak Kullanılacak Neobrutalist Kart
class NeobrutalistCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final double? height;
  final double? width;
  final EdgeInsets? padding;

  const NeobrutalistCard({
    super.key,
    required this.child,
    this.backgroundColor = NeobrutalistColors.white,
    this.height,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: NeobrutalistStyles.border(width: 3.5),
        borderRadius: NeobrutalistStyles.radius24,
        boxShadow: NeobrutalistStyles.shadow(offset: const Offset(8, 8)),
      ),
      child: child,
    );
  }
}
