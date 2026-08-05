import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/widgets/player_avatar.dart';
import '../models/stopwatch_models.dart';

/// Kadronun 10 futbolcusunu, kronometre hanesiyle (0-9) eşleşen numaralarıyla
/// birlikte ekranda gösteren şerit.
///
/// Oyuncu bu şeride bakarak "3 gelirse kim çıkacak?", "kim sakat?",
/// "kim kart sınırında?", "kim gol atmış?" sorularının hepsini anında
/// görebilir. Önceki sürümde kadro hiç ekranda değildi.
class RosterStrip extends StatelessWidget {
  final List<MatchPlayer> roster;
  final int? selectedSlot;
  final bool isMyTurn;
  final Color accent;

  const RosterStrip({
    super.key,
    required this.roster,
    required this.selectedSlot,
    required this.isMyTurn,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (roster.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const int perRow = 5;
        const double gap = 4;
        final double chipWidth =
            (constraints.maxWidth - gap * (perRow - 1)) / perRow;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int row = 0; row * perRow < roster.length; row++) ...[
              if (row > 0) const SizedBox(height: gap),
              Row(
                children: [
                  for (int i = row * perRow;
                      i < (row + 1) * perRow && i < roster.length;
                      i++) ...[
                    if (i > row * perRow) const SizedBox(width: gap),
                    SizedBox(
                      width: chipWidth,
                      child: _RosterChip(
                        player: roster[i],
                        isSelected: selectedSlot == roster[i].slot && isMyTurn,
                        accent: accent,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RosterChip extends StatelessWidget {
  final MatchPlayer player;
  final bool isSelected;
  final Color accent;

  const _RosterChip({
    required this.player,
    required this.isSelected,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final bool out = !player.isAvailable;

    final Color bg = isSelected
        ? accent
        : out
            ? const Color(0xFFD6D6D6)
            : NeobrutalistColors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: NeobrutalistStyles.border(width: isSelected ? 3 : 1.8),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected
            ? NeobrutalistStyles.shadow(offset: const Offset(3, 3))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kronometre hanesi = kadro numarası
              Container(
                width: 15,
                height: 15,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: out ? Colors.grey[600] : NeobrutalistColors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${player.slot}',
                  style: NeobrutalistStyles.headlineStyle(
                    fontSize: 9,
                    color: NeobrutalistColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              PlayerAvatar.of(
                player.profile,
                size: 20,
                borderWidth: 1.5,
                dimmed: out,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _surname(player.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: NeobrutalistStyles.headlineStyle(
              fontSize: 7.5,
              color: out ? Colors.grey[700]! : NeobrutalistColors.black,
            ),
          ),
          SizedBox(
            height: 11,
            child: player.statusIcons.isEmpty
                ? (player.isOnBooking
                    ? const Text('⚠️', style: TextStyle(fontSize: 8))
                    : const SizedBox.shrink())
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      player.statusIcons.join(' '),
                      style: const TextStyle(fontSize: 8),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static String _surname(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.length == 1 ? parts.first : parts.last;
  }
}
