import 'package:flutter/material.dart';

class SplitScreenWrapper extends StatelessWidget {
  final Widget topChild;
  final Widget bottomChild;
  final Widget centerChild;

  const SplitScreenWrapper({
    super.key,
    required this.topChild,
    required this.bottomChild,
    required this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RotatedBox(
                quarterTurns: 2,
                child: Container(
                  color: Colors.white,
                  child: topChild,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: centerChild,
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: bottomChild,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
