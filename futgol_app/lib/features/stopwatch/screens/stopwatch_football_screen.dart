import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futgol_app/common/models/football_player.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/utils/audio_helper.dart';
import 'package:futgol_app/features/stopwatch/models/stopwatch_models.dart';
import 'package:futgol_app/features/stopwatch/widgets/stopwatch_game_widgets.dart';
import 'package:futgol_app/features/stopwatch/widgets/team_setup_screen.dart';
import 'package:futgol_app/features/stopwatch/widgets/player_half_widget.dart';
import 'package:futgol_app/features/stopwatch/widgets/match_scoreboard.dart';

class StopwatchFootballScreen extends StatefulWidget {
  final VoidCallback onBackToMenu;

  const StopwatchFootballScreen({super.key, required this.onBackToMenu});

  @override
  State<StopwatchFootballScreen> createState() => _StopwatchFootballScreenState();
}

class _StopwatchFootballScreenState extends State<StopwatchFootballScreen> {
  static const double kReserveMs = 30000.0;
  static const int kMoveMs = 5000;

  // Maç Durumları
  bool _showOnhold = true;
  bool _setupComplete = false;
  bool _isMatchStarted = false;

  String _team1Name = '1. Oyuncu';
  String _team2Name = '2. Oyuncu';
  List<MatchPlayer> _roster1 = [];
  List<MatchPlayer> _roster2 = [];

  int _score1 = 0; // 1. Oyuncu (Üst) skoru
  int _score2 = 0; // 2. Oyuncu (Alt) skoru

  double _timeReserve1 = kReserveMs;
  double _timeReserve2 = kReserveMs;
  bool _isTimeUp1 = false;
  bool _isTimeUp2 = false;

  int _activePlayer = 2; // Sıradaki oyuncu (2 = Alt, 1 = Üst)
  String _stage = 'select';
  int _moveTimer = kMoveMs;

  // Kronometre Sayaçları (Her iki oyuncu için bağımsız)
  double _stopwatchVal1 = 0.00;
  double _stopwatchVal2 = 0.00;
  bool _isTimerRunning = false;

  int? _selectedSlot; // STOP_1'de kilitlenen kadro numarası

  /// Son hamle: kim yaptı, ne oldu. Ekranda cümle değil, ad + hareket basılır.
  MatchAction _action = MatchAction.kickoff;

  /// Orta banttaki maç olayları şeridi (goller, kartlar, sakatlıklar).
  final List<MatchEvent> _events = [];

  Timer? _gameTicker;
  Timer? _stopwatchTicker;

  @override
  void initState() {
    super.initState();
    _loadOnboardingStatus();
  }

  Future<void> _loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool shown = prefs.getBool('onboarding_shown_stopwatch') ?? false;
    if (!mounted) return;
    setState(() {
      _showOnhold = !shown;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_shown_stopwatch', true);
    if (!mounted) return;
    setState(() {
      _showOnhold = false;
    });
  }

  void _onSetupComplete(
    List<FootballPlayer> r1,
    List<FootballPlayer> r2,
    String t1Name,
    String t2Name,
  ) {
    setState(() {
      _team1Name = t1Name;
      _team2Name = t2Name;
      _roster1 = List.generate(r1.length, (i) => MatchPlayer(slot: i, profile: r1[i]));
      _roster2 = List.generate(r2.length, (i) => MatchPlayer(slot: i, profile: r2[i]));
      _setupComplete = true;
    });
    _startMatch();
  }

  List<MatchPlayer> _rosterOf(int playerNum) => playerNum == 1 ? _roster1 : _roster2;

  void _startMatch() {
    _gameTicker?.cancel();
    _stopwatchTicker?.cancel();

    setState(() {
      _isMatchStarted = true;
      _score1 = 0;
      _score2 = 0;
      _timeReserve1 = kReserveMs;
      _timeReserve2 = kReserveMs;
      _isTimeUp1 = false;
      _isTimeUp2 = false;
      _activePlayer = 2;
      _stage = 'select';
      _moveTimer = kMoveMs;
      _selectedSlot = null;
      _isTimerRunning = false;
      _stopwatchVal1 = 0;
      _stopwatchVal2 = 0;
      _events.clear();
      _action = MatchAction.kickoff;
      for (final p in [..._roster1, ..._roster2]) {
        p.goals = 0;
        p.ownGoals = 0;
        p.yellowCards = 0;
        p.hasRedCard = false;
        p.injured = false;
        p.injuryCountdown = 0;
      }
    });
    AudioHelper().playSuccess();

    // Ana oyun saat döngüsü (100 ms hassasiyet)
    _gameTicker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isMatchStarted || _stage == 'finished') return;

      setState(() {
        // Süre erimesi sadece kronometre çalışırken olur.
        if (_isTimerRunning) {
          _moveTimer -= 100;

          if (_activePlayer == 1) {
            _timeReserve1 -= 100;
            if (_timeReserve1 <= 0) {
              _timeReserve1 = 0;
              _isTimeUp1 = true;
              _isTimerRunning = false;
              _stopwatchTicker?.cancel();
              _setAction(
                owner: 1,
                headline: 'REZERV SÜRE BİTTİ',
                detail: '$_team1Name için zaman havuzu tükendi.',
                emoji: '⌛',
                color: NeobrutalistColors.gray,
              );
              _switchTurn();
            }
          } else {
            _timeReserve2 -= 100;
            if (_timeReserve2 <= 0) {
              _timeReserve2 = 0;
              _isTimeUp2 = true;
              _isTimerRunning = false;
              _stopwatchTicker?.cancel();
              _setAction(
                owner: 2,
                headline: 'REZERV SÜRE BİTTİ',
                detail: '$_team2Name için zaman havuzu tükendi.',
                emoji: '⌛',
                color: NeobrutalistColors.gray,
              );
              _switchTurn();
            }
          }
        }

        if (_isTimeUp1 && _isTimeUp2) {
          _endMatch();
          return;
        }

        // Hamle süresi biterse atak başarısız olur, sıra rakibe geçer
        if (_isTimerRunning && _moveTimer <= 0) {
          _isTimerRunning = false;
          _stopwatchTicker?.cancel();
          _setAction(
            owner: _activePlayer,
            headline: 'SÜRE DOLDU',
            detail: 'Atak süresi aşıldı, hamle geçersiz.',
            emoji: '⏰',
            color: NeobrutalistColors.pink,
            tone: ActionTone.bad,
          );
          AudioHelper().playWrong();
          _switchTurn();
        }
      });
    });
  }

  /// Ekrandaki büyük aksiyon sahnesini günceller.
  /// `owner` alanı, kartın HANGİ oyuncunun yarısında görüneceğini belirler —
  /// sıra rakibe geçtikten sonra bile hamle sahibinin ekranında kalır.
  void _setAction({
    required int owner,
    required String headline,
    required String detail,
    required String emoji,
    required Color color,
    MatchPlayer? player,
    ActionTone tone = ActionTone.neutral,
  }) {
    _action = MatchAction(
      ownerPlayerNum: owner,
      headline: headline,
      detail: detail,
      emoji: emoji,
      color: color,
      playerName: player?.name,
      playerSlot: player?.slot,
      playerImageUrl: player?.profile.imageUrl,
      tone: tone,
    );
  }

  void _logEvent(int playerNum, String icon, String text) {
    _events.insert(0, MatchEvent(playerNum: playerNum, icon: icon, text: text));
    if (_events.length > 12) _events.removeLast();
  }

  void _switchTurn() {
    if (_isTimeUp1 && _isTimeUp2) {
      _endMatch();
      return;
    }

    // Bir oyuncunun süresi bittiyse diğeri tek başına devam eder.
    if (_activePlayer == 1) {
      _activePlayer = _isTimeUp2 ? 1 : 2;
    } else {
      _activePlayer = _isTimeUp1 ? 2 : 1;
    }

    _stage = 'select';
    _moveTimer = kMoveMs;
    _selectedSlot = null;
    _isTimerRunning = false;

    // Sakatlık geri sayımı, sırası gelen takımın başında azalır.
    for (final player in _rosterOf(_activePlayer)) {
      if (player.injured) {
        player.injuryCountdown--;
        if (player.injuryCountdown <= 0) {
          player.injured = false;
          player.injuryCountdown = 0;
        }
      }
    }
  }

  void _endMatch() {
    _stage = 'finished';
    _isMatchStarted = false;
    _gameTicker?.cancel();
    _stopwatchTicker?.cancel();
    _isTimerRunning = false;
    _setAction(
      owner: 0,
      headline: _getWinnerHeadline(),
      detail: 'Final skoru: $_team1Name $_score1 - $_score2 $_team2Name',
      emoji: '🏁',
      color: NeobrutalistColors.green,
    );
    AudioHelper().playSuccess();
  }

  void _startStopwatch() {
    if (_isTimerRunning) return;

    if ((_activePlayer == 1 && _isTimeUp1) || (_activePlayer == 2 && _isTimeUp2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rezerv süreniz bittiği için hamle yapamazsınız.")),
      );
      return;
    }

    AudioHelper().playSuccess();
    setState(() {
      _isTimerRunning = true;
      if (_activePlayer == 1) {
        _stopwatchVal1 = 0.00;
      } else {
        _stopwatchVal2 = 0.00;
      }
    });

    _stopwatchTicker = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        if (_activePlayer == 1) {
          _stopwatchVal1 += 0.01;
          if (_stopwatchVal1 >= 5.00) _stopwatchVal1 = 0.00;
        } else {
          _stopwatchVal2 += 0.01;
          if (_stopwatchVal2 >= 5.00) _stopwatchVal2 = 0.00;
        }
      });
    });
  }

  void _stopStopwatch() {
    if (!_isTimerRunning) return;
    _stopwatchTicker?.cancel();

    final double currentVal = _activePlayer == 1 ? _stopwatchVal1 : _stopwatchVal2;
    final int centisec = (currentVal * 100).round() % 100;
    final int digit = centisec % 10;

    setState(() {
      _isTimerRunning = false;

      switch (_stage) {
        case 'select':
          _handleSelectResult(digit);
          break;
        case 'shoot':
          _handleShootResult(digit);
          break;
        case 'special_corner':
          _handleSpecialCorner(digit);
          break;
        case 'special_penalty':
          _handleSpecialPenalty(digit);
          break;
      }
    });
  }

  // AŞAMA 1: Futbolcu Seçimi (STOP_1)
  void _handleSelectResult(int digit) {
    final roster = _rosterOf(_activePlayer);
    if (roster.isEmpty) return;

    final int slot = digit % roster.length;
    _selectedSlot = slot;
    final player = roster[slot];

    if (player.hasRedCard || player.injured) {
      _setAction(
        owner: _activePlayer,
        headline: player.hasRedCard ? 'CEZALI FUTBOLCU' : 'SAKAT FUTBOLCU',
        detail: player.hasRedCard
            ? 'Kırmızı kart gördüğü için sahada değil — atak söndü.'
            : 'Tedavisi sürüyor (${player.injuryCountdown} el) — atak söndü.',
        emoji: player.hasRedCard ? '🟥' : '🏥',
        color: NeobrutalistColors.pink,
        player: player,
        tone: ActionTone.bad,
      );
      AudioHelper().playWrong();
      _switchTurn();
    } else {
      _stage = 'shoot';
      _moveTimer = kMoveMs;
      _setAction(
        owner: _activePlayer,
        headline: 'TOPLA BULUŞTU',
        detail: player.isOnBooking
            ? 'Dikkat: kart sınırında! Aksiyon için kronometreyi tekrar başlat.'
            : 'Aksiyon için kronometreyi tekrar başlat.',
        emoji: '🎯',
        color: NeobrutalistColors.blue,
        player: player,
      );
      AudioHelper().playCorrect();
    }
  }

  // AŞAMA 2: Aksiyon Belirleme (STOP_2)
  void _handleShootResult(int digit) {
    final roster = _rosterOf(_activePlayer);
    final slot = _selectedSlot;
    if (slot == null || slot >= roster.length) return;
    final player = roster[slot];

    switch (digit) {
      case 0: // GOL!
        player.goals++;
        _addScore(_activePlayer);
        _setAction(
          owner: _activePlayer,
          headline: 'GOOOL!',
          detail: 'Ağlar havalandı, tribünler ayakta!',
          emoji: '⚽',
          color: NeobrutalistColors.green,
          player: player,
          tone: ActionTone.good,
        );
        _logEvent(_activePlayer, '⚽', player.displayName);
        AudioHelper().playSuccess();
        _switchTurn();
        break;

      case 1: // DİREK
        _setAction(
          owner: _activePlayer,
          headline: 'DİREKTEN DÖNDÜ',
          detail: 'Vuruş direğe çarptı, gol olmadı.',
          emoji: '🥅',
          color: NeobrutalistColors.orange,
          player: player,
          tone: ActionTone.bad,
        );
        AudioHelper().playWrong();
        _switchTurn();
        break;

      case 2: // OFSAYT
        _setAction(
          owner: _activePlayer,
          headline: 'OFSAYT',
          detail: 'Yardımcı hakem bayrağı kaldırdı.',
          emoji: '🚩',
          color: NeobrutalistColors.pink,
          player: player,
          tone: ActionTone.bad,
        );
        AudioHelper().playWrong();
        _switchTurn();
        break;

      case 3: // KORNER
        _stage = 'special_corner';
        _moveTimer = kMoveMs;
        _setAction(
          owner: _activePlayer,
          headline: 'KORNER KAZANDI',
          detail: 'Köşe vuruşu için kronometreyi başlat.',
          emoji: '📐',
          color: NeobrutalistColors.blue,
          player: player,
        );
        AudioHelper().playCorrect();
        break;

      case 4: // KENDİ KALESİNE GOL
        player.ownGoals++;
        _addScore(_activePlayer == 1 ? 2 : 1);
        _setAction(
          owner: _activePlayer,
          headline: 'KENDİ KALESİNE!',
          detail: 'Talihsiz bir müdahale, rakip 1 sayı kazandı.',
          emoji: '🤦',
          color: NeobrutalistColors.pink,
          player: player,
          tone: ActionTone.bad,
        );
        _logEvent(_activePlayer == 1 ? 2 : 1, '🤦', '${player.displayName} (k.k.)');
        AudioHelper().playWrong();
        _switchTurn();
        break;

      case 5: // PENALTI
        _stage = 'special_penalty';
        _moveTimer = kMoveMs;
        _setAction(
          owner: _activePlayer,
          headline: 'PENALTI!',
          detail: 'Büyük fırsat. Vuruş için kronometreyi başlat.',
          emoji: '🎯',
          color: NeobrutalistColors.green,
          player: player,
          tone: ActionTone.good,
        );
        AudioHelper().playSuccess();
        break;

      case 6: // KIRMIZI KART
        player.hasRedCard = true;
        _setAction(
          owner: _activePlayer,
          headline: 'KIRMIZI KART',
          detail: 'Sert faul — doğrudan oyun dışı, kadro 1 eksildi.',
          emoji: '🟥',
          color: NeobrutalistColors.pink,
          player: player,
          tone: ActionTone.bad,
        );
        _logEvent(_activePlayer, '🟥', player.displayName);
        AudioHelper().playWrong();
        _checkForfeit();
        if (_stage != 'finished') _switchTurn();
        break;

      case 7:
      case 8: // SARI KART
        player.yellowCards++;
        if (player.yellowCards >= 2) {
          player.hasRedCard = true;
          _setAction(
            owner: _activePlayer,
            headline: '2. SARI ▸ KIRMIZI',
            detail: 'İkinci sarı kartla oyundan atıldı.',
            emoji: '🟨🟥',
            color: NeobrutalistColors.pink,
            player: player,
            tone: ActionTone.bad,
          );
          _logEvent(_activePlayer, '🟥', player.displayName);
        } else {
          _setAction(
            owner: _activePlayer,
            headline: 'SARI KART',
            detail: 'Artık kart sınırında — bir sarı daha oyun dışı demek.',
            emoji: '🟨',
            color: NeobrutalistColors.orange,
            player: player,
            tone: ActionTone.bad,
          );
          _logEvent(_activePlayer, '🟨', player.displayName);
        }
        AudioHelper().playWrong();
        _checkForfeit();
        if (_stage != 'finished') _switchTurn();
        break;

      case 9: // SAKATLIK
        player.injured = true;
        player.injuryCountdown = 4;
        _setAction(
          owner: _activePlayer,
          headline: 'SAKATLANDI',
          detail: '4 el boyunca kadro dışı kalacak.',
          emoji: '🏥',
          color: NeobrutalistColors.orange,
          player: player,
          tone: ActionTone.bad,
        );
        _logEvent(_activePlayer, '🏥', player.displayName);
        AudioHelper().playWrong();
        _switchTurn();
        break;
    }
  }

  void _addScore(int playerNum) {
    if (playerNum == 1) {
      _score1++;
    } else {
      _score2++;
    }
  }

  MatchPlayer? get _selectedPlayer {
    final roster = _rosterOf(_activePlayer);
    final slot = _selectedSlot;
    if (slot == null || slot >= roster.length) return null;
    return roster[slot];
  }

  // Özel Köşe Vuruşu Alt Süreci
  void _handleSpecialCorner(int digit) {
    final player = _selectedPlayer;
    final int outcome = digit % 3;

    if (outcome == 0) {
      _moveTimer = kMoveMs;
      _setAction(
        owner: _activePlayer,
        headline: 'KORNER TEKRAR',
        detail: 'Defans araya girdi, köşe vuruşu tekrarlanıyor.',
        emoji: '📐',
        color: NeobrutalistColors.orange,
        player: player,
      );
      AudioHelper().playWrong();
    } else if (outcome == 1) {
      player?.goals++;
      _addScore(_activePlayer);
      _setAction(
        owner: _activePlayer,
        headline: 'KAFAYLA GOL!',
        detail: 'Köşe vuruşunda ceza sahasının kralı oldu.',
        emoji: '⚽',
        color: NeobrutalistColors.green,
        player: player,
        tone: ActionTone.good,
      );
      if (player != null) _logEvent(_activePlayer, '⚽', player.displayName);
      AudioHelper().playSuccess();
      _switchTurn();
    } else {
      _setAction(
        owner: _activePlayer,
        headline: 'AUT',
        detail: 'Orta kaleyi bulmadı, top dışarı çıktı.',
        emoji: '❌',
        color: NeobrutalistColors.pink,
        player: player,
        tone: ActionTone.bad,
      );
      AudioHelper().playWrong();
      _switchTurn();
    }
  }

  // Özel Penaltı Alt Süreci
  void _handleSpecialPenalty(int digit) {
    final player = _selectedPlayer;
    final int outcome = digit % 3;

    if (outcome == 0) {
      player?.goals++;
      _addScore(_activePlayer);
      _setAction(
        owner: _activePlayer,
        headline: 'PENALTI GOLÜ!',
        detail: 'Kaleci köşeyi tahmin edemedi.',
        emoji: '⚽',
        color: NeobrutalistColors.green,
        player: player,
        tone: ActionTone.good,
      );
      if (player != null) _logEvent(_activePlayer, '⚽', player.displayName);
      AudioHelper().playSuccess();
      _switchTurn();
    } else if (outcome == 1) {
      _setAction(
        owner: _activePlayer,
        headline: 'DİREKTE PATLADI',
        detail: 'Penaltı direğe çarpıp dışarı gitti.',
        emoji: '🥅',
        color: NeobrutalistColors.orange,
        player: player,
        tone: ActionTone.bad,
      );
      AudioHelper().playWrong();
      _switchTurn();
    } else {
      _setAction(
        owner: _activePlayer,
        headline: 'DIŞARI GİTTİ',
        detail: 'Vuruş direğin yanından auta gitti.',
        emoji: '❌',
        color: NeobrutalistColors.pink,
        player: player,
        tone: ActionTone.bad,
      );
      AudioHelper().playWrong();
      _switchTurn();
    }
  }

  // Hükmen Yenilgi Denetimi
  void _checkForfeit() {
    final redCount1 = _roster1.where((p) => p.hasRedCard).length;
    final redCount2 = _roster2.where((p) => p.hasRedCard).length;

    if (redCount1 >= 4 || redCount2 >= 4) {
      final int loser = redCount1 >= 4 ? 1 : 2;
      final String loserName = loser == 1 ? _team1Name : _team2Name;

      if (loser == 1) {
        _score1 = 0;
        _score2 = _score2 > 3 ? _score2 : 3;
      } else {
        _score2 = 0;
        _score1 = _score1 > 3 ? _score1 : 3;
      }

      _stage = 'finished';
      _isMatchStarted = false;
      _gameTicker?.cancel();
      _stopwatchTicker?.cancel();
      _setAction(
        owner: 0,
        headline: 'HÜKMEN YENİLGİ',
        detail: '$loserName 4 kırmızı karta ulaştı — maç 3-0 tescil edildi.',
        emoji: '💀',
        color: NeobrutalistColors.pink,
        tone: ActionTone.bad,
      );
      AudioHelper().playWrong();
    }
  }

  String _getWinnerHeadline() {
    if (_score1 > _score2) return '$_team1Name KAZANDI! 🏆';
    if (_score2 > _score1) return '$_team2Name KAZANDI! 🏆';
    return 'BERABERE — DOSTLUK KAZANDI 🤝';
  }

  void _confirmExit() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeobrutalistColors.white,
        shape: RoundedRectangleBorder(
          side: NeobrutalistStyles.border(width: 3).top,
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('MAÇTAN ÇIKILSIN MI?',
            style: NeobrutalistStyles.headlineStyle(fontSize: 13)),
        content: Text(
          'Mevcut skor ($_score1-$_score2) kaydedilmeyecek.',
          style: NeobrutalistStyles.bodyStyle(fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('DEVAM ET',
                style: NeobrutalistStyles.headlineStyle(fontSize: 11)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onBackToMenu();
            },
            child: Text('ÇIK',
                style: NeobrutalistStyles.headlineStyle(
                    fontSize: 11, color: NeobrutalistColors.pink)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnhold) {
      return StopwatchOnboardingCard(onStart: _completeOnboarding);
    }

    if (!_setupComplete) {
      return TeamSetupScreen(
        onSetupComplete: _onSetupComplete,
        onCancel: widget.onBackToMenu,
      );
    }

    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: Column(
          children: [
            // 1. ÜST OYUNCU (180 DERECE TERS — karşılıklı oynanır)
            Expanded(
              child: Transform.rotate(
                angle: 3.14159,
                child: PlayerHalfWidget(
                  playerNum: 1,
                  activePlayer: _activePlayer,
                  timeReserve: _timeReserve1,
                  maxReserve: kReserveMs,
                  teamName: _team1Name,
                  isTimeUp: _isTimeUp1,
                  action: _action,
                  stopwatchVal: _stopwatchVal1,
                  moveTimer: _moveTimer,
                  maxMoveTimer: kMoveMs,
                  isTimerRunning: _isTimerRunning,
                  stage: _stage,
                  roster: _roster1,
                  selectedSlot: _selectedSlot,
                  score: _score1,
                  onStartStopwatch: _startStopwatch,
                  onStopStopwatch: _stopStopwatch,
                ),
              ),
            ),

            // 2. ORTA SKOR TABLOSU + OLAY ŞERİDİ
            MatchScoreboard(
              team1Name: _team1Name,
              team2Name: _team2Name,
              score1: _score1,
              score2: _score2,
              activePlayer: _activePlayer,
              isFinished: _stage == 'finished',
              events: _events,
              onExit: _confirmExit,
              onRestart: _stage == 'finished' ? _startMatch : null,
            ),

            // 3. ALT OYUNCU (DÜZ)
            Expanded(
              child: PlayerHalfWidget(
                playerNum: 2,
                activePlayer: _activePlayer,
                timeReserve: _timeReserve2,
                maxReserve: kReserveMs,
                teamName: _team2Name,
                isTimeUp: _isTimeUp2,
                action: _action,
                stopwatchVal: _stopwatchVal2,
                moveTimer: _moveTimer,
                maxMoveTimer: kMoveMs,
                isTimerRunning: _isTimerRunning,
                stage: _stage,
                roster: _roster2,
                selectedSlot: _selectedSlot,
                score: _score2,
                onStartStopwatch: _startStopwatch,
                onStopStopwatch: _stopStopwatch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameTicker?.cancel();
    _stopwatchTicker?.cancel();
    super.dispose();
  }
}
