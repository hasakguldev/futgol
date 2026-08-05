import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/neobrutalist_theme.dart';

class CountdownOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const CountdownOverlay({super.key, required this.onFinished});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
  int _seconds = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 1) {
        setState(() {
          _seconds--;
        });
      } else if (_seconds == 1) {
        setState(() {
          _seconds = 0;
        });
      } else {
        _timer?.cancel();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String text = _seconds.toString();
    if (_seconds == 0) {
      text = "BAŞLA! ⚽";
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Text(
          text,
          key: ValueKey<String>(text),
          style: GoogleFonts.outfit(
            fontSize: _seconds == 0 ? 64 : 96,
            fontWeight: FontWeight.w900,
            color: NeobrutalistColors.yellow,
          ),
        ),
      ),
    );
  }
}
