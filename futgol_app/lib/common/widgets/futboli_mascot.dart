import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/neobrutalist_theme.dart';

class FutboliMascot extends StatelessWidget {
  final double size;

  const FutboliMascot({super.key, this.size = 180.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: NeobrutalistColors.white,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: NeobrutalistColors.black, width: 4.0),
        ),
        boxShadow: [
          BoxShadow(
            color: NeobrutalistColors.black,
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ana Çizim (Futbol Topu ve Gözler)
          Positioned.fill(
            child: CustomPaint(
              painter: FutboliPainter(),
            ),
          ),
          
          // Konuşma Balonu
          Positioned(
            top: -24,
            right: -55,
            child: Transform.rotate(
              angle: 6 * pi / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NeobrutalistColors.white,
                  border: NeobrutalistStyles.border(width: 3),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: NeobrutalistColors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  "Ben Futboli! 👋",
                  style: NeobrutalistStyles.headlineStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FutboliPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = min(cx, cy) - 4; // kenarlık taşmaması için pay bırakıyoruz

    final blackPaint = Paint()
      ..color = NeobrutalistColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final blackFillPaint = Paint()
      ..color = NeobrutalistColors.black
      ..style = PaintingStyle.fill;

    // --- 1. FUTBOL TOPU DESENLERİ (BEŞGENLER VE ÇİZGİLER) ---
    // Merkez Beşgen
    final Path centerPentagon = Path();
    final double pSize = r * 0.28;
    for (int i = 0; i < 5; i++) {
      double angle = (72 * i - 90) * pi / 180;
      double px = cx + pSize * cos(angle);
      double py = cy + pSize * sin(angle);
      if (i == 0) {
        centerPentagon.moveTo(px, py);
      } else {
        centerPentagon.lineTo(px, py);
      }
    }
    centerPentagon.close();
    canvas.drawPath(centerPentagon, blackFillPaint);

    // Beşgen Köşelerinden Dışa Giden Çizgiler
    for (int i = 0; i < 5; i++) {
      double angle = (72 * i - 90) * pi / 180;
      double px = cx + pSize * cos(angle);
      double py = cy + pSize * sin(angle);
      
      double outerAngle = (72 * i - 90) * pi / 180;
      double ox = cx + r * 0.75 * cos(outerAngle);
      double oy = cy + r * 0.75 * sin(outerAngle);
      
      canvas.drawLine(Offset(px, py), Offset(ox, oy), blackPaint);
    }

    // --- 2. PÖRTLEK BÜYÜK GÖZLER ---
    final whitePaint = Paint()
      ..color = NeobrutalistColors.white
      ..style = PaintingStyle.fill;

    // Sol Göz
    final double eyeRadius = r * 0.26;
    final double leftEyeX = cx - r * 0.3;
    final double leftEyeY = cy - r * 0.15;
    canvas.drawCircle(Offset(leftEyeX, leftEyeY), eyeRadius, whitePaint);
    canvas.drawCircle(Offset(leftEyeX, leftEyeY), eyeRadius, blackPaint);

    // Sol Göz Bebegi
    canvas.drawCircle(Offset(leftEyeX + 3, leftEyeY), eyeRadius * 0.45, blackFillPaint);
    // Sol Göz Işıltısı
    canvas.drawCircle(Offset(leftEyeX - 1, leftEyeY - 4), eyeRadius * 0.18, Paint()..color = NeobrutalistColors.white);

    // Sağ Göz
    final double rightEyeX = cx + r * 0.3;
    final double rightEyeY = cy - r * 0.15;
    canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeRadius, whitePaint);
    canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeRadius, blackPaint);

    // Sağ Göz Bebegi
    canvas.drawCircle(Offset(rightEyeX - 3, rightEyeY), eyeRadius * 0.45, blackFillPaint);
    // Sağ Göz Işıltısı
    canvas.drawCircle(Offset(rightEyeX - 7, rightEyeY - 4), eyeRadius * 0.18, Paint()..color = NeobrutalistColors.white);

    // --- 3. SEVİMLİ AĞIZ ---
    final smilePaint = Paint()
      ..color = NeobrutalistColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final Path mouthPath = Path();
    mouthPath.moveTo(cx - r * 0.18, cy + r * 0.25);
    mouthPath.quadraticBezierTo(cx, cy + r * 0.4, cx + r * 0.18, cy + r * 0.25);
    canvas.drawPath(mouthPath, smilePaint);

    // --- 4. HAKEM DÜDÜĞÜ ---
    // Düdüğün asılı durduğu konum (Ağzın sağ tarafı)
    final double whistleX = cx + r * 0.05;
    final double whistleY = cy + r * 0.25;

    // Düdük Askısı / İpi
    final Paint cordPaint = Paint()
      ..color = NeobrutalistColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(whistleX, whistleY + 1), radius: 6),
      0,
      pi,
      false,
      cordPaint,
    );

    // Düdük Ana Gövdesi (Pembe kutu)
    final Paint whistleBodyPaint = Paint()
      ..color = NeobrutalistColors.pink
      ..style = PaintingStyle.fill;
    
    final Paint whistleOutlinePaint = Paint()
      ..color = NeobrutalistColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final RRect whistleBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(whistleX, whistleY + 5, r * 0.22, r * 0.16),
      Radius.circular(r * 0.04),
    );
    canvas.drawRRect(whistleBody, whistleBodyPaint);
    canvas.drawRRect(whistleBody, whistleOutlinePaint);

    // Düdük Ağızlığı (Turuncu kısım)
    final Paint mouthpiecePaint = Paint()
      ..color = NeobrutalistColors.orange
      ..style = PaintingStyle.fill;

    final RRect mouthpiece = RRect.fromRectAndRadius(
      Rect.fromLTWH(whistleX + r * 0.18, whistleY + 8, r * 0.12, r * 0.10),
      Radius.circular(r * 0.02),
    );
    canvas.drawRRect(mouthpiece, mouthpiecePaint);
    canvas.drawRRect(mouthpiece, whistleOutlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
