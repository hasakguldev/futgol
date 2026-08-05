import 'package:flutter/material.dart';
import '../models/football_player.dart';
import '../theme/neobrutalist_theme.dart';

/// Veritabanındaki `players.image_url` alanını kullanan neobrutalist oyuncu
/// portresi. İnternet yoksa veya görsel yüklenemezse baş harflere düşer —
/// oyun asla görsel yüzünden bloke olmaz.
class PlayerAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double size;
  final Color background;
  final double borderWidth;
  final bool dimmed;

  const PlayerAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackText,
    this.size = 48,
    this.background = NeobrutalistColors.white,
    this.borderWidth = 2.5,
    this.dimmed = false,
  });

  factory PlayerAvatar.of(
    FootballPlayer player, {
    double size = 48,
    Color background = NeobrutalistColors.white,
    double borderWidth = 2.5,
    bool dimmed = false,
  }) =>
      PlayerAvatar(
        imageUrl: player.imageUrl,
        fallbackText: player.initials,
        size: size,
        background: background,
        borderWidth: borderWidth,
        dimmed: dimmed,
      );

  @override
  Widget build(BuildContext context) {
    final Widget content = (imageUrl == null || imageUrl!.isEmpty)
        ? _buildFallback()
        : Image.network(
            imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _buildFallback(),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : _buildFallback(),
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        border: NeobrutalistStyles.border(width: borderWidth),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: dimmed
          ? BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(size * 0.28),
            )
          : null,
      child: content,
    );
  }

  Widget _buildFallback() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: background,
        child: Text(
          fallbackText,
          style: NeobrutalistStyles.headlineStyle(fontSize: size * 0.36),
        ),
      );
}
