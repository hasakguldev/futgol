import 'package:flutter/material.dart';

class PlayerInfo {
  final String name;
  final String emoji;
  final Color color;
  final bool isProfileOwner;

  PlayerInfo({
    required this.name,
    required this.emoji,
    required this.color,
    required this.isProfileOwner,
  });
}
