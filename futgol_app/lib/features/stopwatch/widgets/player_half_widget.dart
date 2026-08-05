import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import '../models/stopwatch_models.dart';
import 'action_stage_card.dart';
import 'roster_strip.dart';

/// Ekranın bir oyuncuya ait yarısı.
///
/// Yerleşim (yukarıdan aşağıya):
///   1. Takım adı + rezerv süre + kadro özeti (kart/sakat sayısı)
///   2. Büyük aksiyon sahnesi — SADECE hamleyi yapan oyuncunun tarafında
///   3. Kronometre + atak süresi çubuğu
///   4. Kadro şeridi (0-9 numaralı futbolcular, canlı durumlarıyla)
///   5. Tek büyük buton
class PlayerHalfWidget extends StatelessWidget {
  final int playerNum;
  final int activePlayer;
  final double timeReserve;
  final double maxReserve;
  final String teamName;
  final bool isTimeUp;
  final MatchAction action;
  final double stopwatchVal;
  final int moveTimer;
  final int maxMoveTimer;
  final bool isTimerRunning;
  final String stage;
  final List<MatchPlayer> roster;
  final int? selectedSlot;
  final int score;
  final VoidCallback onStartStopwatch;
  final VoidCallback onStopStopwatch;

  const PlayerHalfWidget({
    super.key,
    required this.playerNum,
    required this.activePlayer,
    required this.timeReserve,
    required this.maxReserve,
    required this.teamName,
    required this.isTimeUp,
    required this.action,
    required this.stopwatchVal,
    required this.moveTimer,
    required this.maxMoveTimer,
    required this.isTimerRunning,
    required this.stage,
    required this.roster,
    required this.selectedSlot,
    required this.score,
    required this.onStartStopwatch,
    required this.onStopStopwatch,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMyTurn = activePlayer == playerNum;
    final bool isFinished = stage == 'finished';
    // Aksiyon kartı, hamleyi YAPAN oyuncunun yarısında gösterilir.
    // (Eski sürümde sıra rakibe geçtiği için hamlenin sonucu daima
    //  karşı tarafın ekranında beliriyordu.)
    final bool showActionHere =
        action.ownerPlayerNum == playerNum || action.ownerPlayerNum == 0;

    final Color accent =
        playerNum == 1 ? NeobrutalistColors.pink : NeobrutalistColors.blue;
    final Color bg =
        playerNum == 1 ? const Color(0xFFFFE1E9) : const Color(0xFFDCEEFF);

    final double reserveRatio =
        maxReserve <= 0 ? 0 : (timeReserve / maxReserve).clamp(0.0, 1.0);
    final double moveRatio =
        maxMoveTimer <= 0 ? 0 : (moveTimer / maxMoveTimer).clamp(0.0, 1.0);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeader(accent, reserveRatio),

          // Aksiyon sahnesi / bekleme paneli
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: showActionHere
                  ? ActionStageCard(action: action)
                  : OpponentWaitCard(
                      lastOpponentAction: action,
                      isMyTurn: isMyTurn,
                      isTimeUp: isTimeUp,
                      isFinished: isFinished,
                    ),
            ),
          ),

          _buildStopwatch(isMyTurn, isFinished, accent, moveRatio),

          const SizedBox(height: 6),
          RosterStrip(
            roster: roster,
            selectedSlot: selectedSlot,
            isMyTurn: isMyTurn,
            accent: accent,
          ),
          const SizedBox(height: 6),

          _buildButton(isMyTurn, isFinished),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accent, double reserveRatio) {
    final int red = roster.where((p) => p.hasRedCard).length;
    final int injured = roster.where((p) => p.injured).length;
    final int booking = roster.where((p) => p.isOnBooking).length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accent,
            border: NeobrutalistStyles.border(width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$teamName · $score',
            style: NeobrutalistStyles.headlineStyle(
              fontSize: 10,
              color: NeobrutalistColors.white,
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Kadro sağlık özeti
        if (red > 0 || injured > 0 || booking > 0)
          Expanded(
            child: Text(
              [
                if (red > 0) '🟥$red',
                if (booking > 0) '⚠️$booking',
                if (injured > 0) '🏥$injured',
              ].join('  '),
              style: const TextStyle(fontSize: 10),
            ),
          )
        else
          const Spacer(),

        // Rezerv süre göstergesi (çubuk + rakam)
        SizedBox(
          width: 86,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTimeUp ? 'SÜRE BİTTİ' : '⏱ ${(timeReserve / 1000).toStringAsFixed(1)}s',
                style: NeobrutalistStyles.headlineStyle(
                  fontSize: 10,
                  color: isTimeUp
                      ? NeobrutalistColors.pink
                      : reserveRatio < 0.25
                          ? NeobrutalistColors.pink
                          : NeobrutalistColors.black,
                ),
              ),
              const SizedBox(height: 2),
              _bar(reserveRatio,
                  reserveRatio < 0.25 ? NeobrutalistColors.pink : NeobrutalistColors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(double ratio, Color color) => Container(
        height: 6,
        decoration: BoxDecoration(
          color: NeobrutalistColors.white,
          border: Border.all(color: NeobrutalistColors.black, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: ratio,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );

  Widget _buildStopwatch(bool isMyTurn, bool isFinished, Color accent, double moveRatio) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          decoration: BoxDecoration(
            color: isMyTurn ? NeobrutalistColors.black : Colors.grey[400],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            stopwatchVal.toStringAsFixed(2),
            style: NeobrutalistStyles.headlineStyle(
              fontSize: 30,
              color: isTimerRunning && isMyTurn
                  ? NeobrutalistColors.yellow
                  : NeobrutalistColors.white,
            ),
          ),
        ),
        if (isMyTurn && !isFinished) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _stageLabel,
                style: NeobrutalistStyles.headlineStyle(fontSize: 8, color: accent),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _bar(
                  moveRatio,
                  moveRatio < 0.35 ? NeobrutalistColors.pink : NeobrutalistColors.orange,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${(moveTimer / 1000).toStringAsFixed(1)}s',
                style: NeobrutalistStyles.headlineStyle(fontSize: 8),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String get _stageLabel {
    switch (stage) {
      case 'select':
        return 'ADIM 1 · FUTBOLCU SEÇ';
      case 'shoot':
        return 'ADIM 2 · AKSİYON';
      case 'special_corner':
        return 'KORNER VURUŞU';
      case 'special_penalty':
        return 'PENALTI VURUŞU';
      default:
        return '';
    }
  }

  Widget _buildButton(bool isMyTurn, bool isFinished) {
    final bool disabled = !isMyTurn || isFinished || isTimeUp;
    final String label = isFinished
        ? 'MAÇ BİTTİ'
        : isTimeUp
            ? 'SÜRENİZ BİTTİ'
            : !isMyTurn
                ? 'RAKİBİ BEKLE'
                : isTimerRunning
                    ? 'DURDUR ▸ ${_actionVerb()}'
                    : 'KRONOMETREYİ BAŞLAT';

    return SizedBox(
      width: double.infinity,
      child: NeobrutalistButton(
        disabled: disabled,
        height: 46,
        onPressed: isTimerRunning ? onStopStopwatch : onStartStopwatch,
        backgroundColor:
            isTimerRunning ? NeobrutalistColors.pink : NeobrutalistColors.green,
        shadowColor: NeobrutalistColors.black,
        child: Text(
          label,
          maxLines: 1,
          style: NeobrutalistStyles.headlineStyle(
            fontSize: 12,
            color: NeobrutalistColors.white,
          ),
        ),
      ),
    );
  }

  String _actionVerb() {
    switch (stage) {
      case 'select':
        return 'FUTBOLCU SEÇ';
      case 'shoot':
        return 'AKSİYON YAP';
      case 'special_corner':
        return 'KORNER AT';
      case 'special_penalty':
        return 'PENALTI KULLAN';
      default:
        return 'SEÇ';
    }
  }
}
