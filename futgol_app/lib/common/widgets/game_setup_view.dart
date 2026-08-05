import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/neobrutalist_theme.dart';
import '../services/difficulty_rules_service.dart';
import '../services/profile_service.dart';
import '../services/multiplayer_service.dart';
import '../models/user_profile.dart';
import '../models/player_info.dart';

class SoccerGameSetupView extends StatefulWidget {
  final String gameKey; // Benzersiz oyun anahtarı (Örn: 'career_path')
  final String gameTitle;
  final String gameDescription;
  final Map<String, String>? modes; // E.g., {"player": "TAKIM ARKADAŞI", "team": "AYNI KULÜP"}
  final List<String>? difficulties; // E.g., ["easy", "medium", "hard", "veteran"]
  final String initialMode;
  final String initialDifficulty;
  final Function(String difficulty, String mode) onStart;
  final VoidCallback onBackToMenu;
  final bool isDbRequired;
  final bool isDbLoaded;
  final bool supportsH2H; // H2H modunu destekliyor mu?

  const SoccerGameSetupView({
    super.key,
    required this.gameKey,
    required this.gameTitle,
    required this.gameDescription,
    this.modes,
    this.difficulties,
    this.initialMode = '',
    this.initialDifficulty = 'easy',
    required this.onStart,
    required this.onBackToMenu,
    this.isDbRequired = true,
    this.isDbLoaded = true,
    this.supportsH2H = false,
  });

  @override
  State<SoccerGameSetupView> createState() => _SoccerGameSetupViewState();
}

class _SoccerGameSetupViewState extends State<SoccerGameSetupView> {
  late String _selectedMode;
  late String _selectedDifficulty;

  int _playerCount = 1;
  String _multiplayerMode = 'marathon';
  int _h2hRounds = 5;
  bool _showPlayerRegistration = false;

  UserProfile? _ownerProfile;
  final List<String> _playerNames = ['', '', '']; // 2., 3., 4. oyuncu isimleri
  final List<String> _playerEmojis = [];

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    if (_selectedMode.isEmpty && widget.modes != null && widget.modes!.isNotEmpty) {
      _selectedMode = widget.modes!.keys.first;
    }
    _selectedDifficulty = widget.initialDifficulty;

    // Default Emojileri ata
    _playerEmojis.addAll([
      ProfileService.defaultEmojis[1],
      ProfileService.defaultEmojis[2],
      ProfileService.defaultEmojis[3],
    ]);

    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.gameKey;
    _ownerProfile = await ProfileService().getProfile();

    setState(() {
      _selectedDifficulty = prefs.getString('game_setup_${key}_difficulty') ?? widget.initialDifficulty;
      _selectedMode = prefs.getString('game_setup_${key}_mode') ?? widget.initialMode;
      if (_selectedMode.isEmpty && widget.modes != null && widget.modes!.isNotEmpty) {
        _selectedMode = widget.modes!.keys.first;
      }
      _playerCount = prefs.getInt('game_setup_${key}_player_count') ?? 1;
      _multiplayerMode = prefs.getString('game_setup_${key}_multiplayer_mode') ?? 'marathon';
      _h2hRounds = prefs.getInt('game_setup_${key}_h2h_rounds') ?? 5;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.gameKey;
    await prefs.setString('game_setup_${key}_difficulty', _selectedDifficulty);
    await prefs.setString('game_setup_${key}_mode', _selectedMode);
    await prefs.setInt('game_setup_${key}_player_count', _playerCount);
    await prefs.setString('game_setup_${key}_multiplayer_mode', _multiplayerMode);
    await prefs.setInt('game_setup_${key}_h2h_rounds', _h2hRounds);
  }

  void _onStartPressed() async {
    await _saveSettings();

    if (_playerCount == 1) {
      // Solo Mod
      final owner = _ownerProfile ?? UserProfile(name: "Oyuncu 1", emoji: "⚽", createdAt: DateTime.now());
      MultiplayerService().setupMultiplayer(
        selectedPlayers: [
          PlayerInfo(name: owner.name, emoji: owner.emoji, color: NeobrutalistColors.green, isProfileOwner: true)
        ],
        selectedMode: 'solo',
      );
      widget.onStart(_selectedDifficulty, _selectedMode);
    } else {
      // Çoklu Oyuncu İsim Kayıt Ekranına Geç
      setState(() {
        _showPlayerRegistration = true;
      });
    }
  }

  void _onFinalStartPressed() {
    final owner = _ownerProfile ?? UserProfile(name: "Oyuncu 1", emoji: "⚽", createdAt: DateTime.now());
    final List<PlayerInfo> selectedPlayers = [
      PlayerInfo(name: owner.name, emoji: owner.emoji, color: NeobrutalistColors.green, isProfileOwner: true)
    ];

    final colors = [NeobrutalistColors.pink, NeobrutalistColors.orange, NeobrutalistColors.purple];

    for (int i = 0; i < _playerCount - 1; i++) {
      String name = _playerNames[i].trim();
      if (name.isEmpty) {
        name = "${i + 2}. Oyuncu";
      }
      selectedPlayers.add(PlayerInfo(
        name: name,
        emoji: _playerEmojis[i],
        color: colors[i % colors.length],
        isProfileOwner: false,
      ));
    }

    MultiplayerService().setupMultiplayer(
      selectedPlayers: selectedPlayers,
      selectedMode: _multiplayerMode,
      h2hRounds: _h2hRounds,
    );

    widget.onStart(_selectedDifficulty, _selectedMode);
  }

  void _selectEmojiForPlayer(int playerIdx) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.black, width: 4),
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: NeobrutalistColors.yellow,
          title: Text(
            "AVATAR SEÇ",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: ProfileService.defaultEmojis.length,
              itemBuilder: (context, index) {
                final emoji = ProfileService.defaultEmojis[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _playerEmojis[playerIdx] = emoji;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeBtn(String label, String key, Color activeColor) {
    final bool isSelected = _selectedMode == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMode = key;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : NeobrutalistColors.white,
            border: NeobrutalistStyles.border(width: 2.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected 
              ? null 
              : NeobrutalistStyles.shadow(offset: const Offset(2.5, 2.5)),
          ),
          child: Text(
            label,
            style: NeobrutalistStyles.headlineStyle(
              fontSize: 9, 
              color: isSelected && activeColor != NeobrutalistColors.yellow 
                ? NeobrutalistColors.white 
                : NeobrutalistColors.black
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBtn(String diffKey) {
    final bool isSelected = _selectedDifficulty == diffKey;
    final rulesService = DifficultyRulesService();
    final config = rulesService.getDifficultyConfig(diffKey);
    final displayName = config['display_name'] ?? diffKey;
    final title = config['title'] ?? '';
    final icon = config['icon'] ?? '';

    Color activeColor;
    if (diffKey == 'easy') {
      activeColor = NeobrutalistColors.green;
    } else if (diffKey == 'medium') {
      activeColor = NeobrutalistColors.orange;
    } else if (diffKey == 'hard') {
      activeColor = NeobrutalistColors.pink;
    } else {
      activeColor = NeobrutalistColors.purple;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDifficulty = diffKey;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : NeobrutalistColors.white,
            border: NeobrutalistStyles.border(width: 2.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected 
              ? null 
              : NeobrutalistStyles.shadow(offset: const Offset(2.5, 2.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                displayName.split(' ').first,
                style: NeobrutalistStyles.headlineStyle(
                  fontSize: 8, 
                  color: isSelected ? NeobrutalistColors.white : NeobrutalistColors.black
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: NeobrutalistStyles.bodyStyle(
                  fontSize: 7, 
                  color: isSelected ? NeobrutalistColors.white.withValues(alpha: 0.8) : Colors.grey[600]!
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showPlayerRegistration) {
      return _buildPlayerRegistrationView();
    }

    final rulesService = DifficultyRulesService();
    final config = rulesService.getDifficultyConfig(_selectedDifficulty);
    final displayName = config['display_name'] ?? _selectedDifficulty;
    final title = config['title'] ?? '';
    final icon = config['icon'] ?? '';

    // Açıklama artık kural kitabından geliyor; kurallar değişince metin de
    // değişir. Eskiden burada sabit metinler vardı ve kurallarla çelişiyordu
    // (örn. "30M€+" yazarken kural 40M€'ye çıkmıştı).
    final diffDescription = '$title $icon · $displayName — ${rulesService.describe(_selectedDifficulty)}';
    final diffChips = rulesService.summaryChips(_selectedDifficulty);

    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: NeobrutalistColors.white,
                      border: NeobrutalistStyles.border(width: 3),
                      borderRadius: NeobrutalistStyles.radius20,
                      boxShadow: NeobrutalistStyles.shadow(offset: const Offset(5, 5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.gameTitle,
                          style: NeobrutalistStyles.headlineStyle(fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "OYUN AYARLARI",
                          style: NeobrutalistStyles.bodyStyle(fontSize: 9, color: Colors.grey[600]!),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Açıklama
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: NeobrutalistStyles.border(width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.gameDescription,
                            style: NeobrutalistStyles.bodyStyle(fontSize: 9, color: NeobrutalistColors.black),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Mod Seçimi
                        if (widget.modes != null && widget.modes!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("OYUN MODU SEÇİN:", style: NeobrutalistStyles.headlineStyle(fontSize: 10)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: widget.modes!.entries.map((entry) {
                              final isFirst = entry.key == widget.modes!.keys.first;
                              return [
                                if (!isFirst) const SizedBox(width: 10),
                                _buildModeBtn(entry.value, entry.key, NeobrutalistColors.pink),
                              ];
                            }).expand((w) => w).toList(),
                          ),
                        ],

                        // Oyuncu Sayısı Seçimi
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("OYUNCU SAYISI:", style: NeobrutalistStyles.headlineStyle(fontSize: 10)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPlayerCountBtn(1, "1 👤", NeobrutalistColors.green),
                            const SizedBox(width: 6),
                            _buildPlayerCountBtn(2, "2 👥", NeobrutalistColors.pink),
                            const SizedBox(width: 6),
                            _buildPlayerCountBtn(3, "3 👥👤", NeobrutalistColors.orange),
                            const SizedBox(width: 6),
                            _buildPlayerCountBtn(4, "4 👥👥", NeobrutalistColors.purple),
                          ],
                        ),

                        // Çoklu Oyuncu Modu (Sadece Oyuncu Sayısı > 1 ise)
                        if (_playerCount > 1) ...[
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("ÇOKLU OYUNCU TÜRÜ:", style: NeobrutalistStyles.headlineStyle(fontSize: 10)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildMultiModeBtn('marathon', "Maraton 🏃", NeobrutalistColors.orange),
                              const SizedBox(width: 8),
                              _buildMultiModeBtn('turn_based', "Sıralı 🔄", NeobrutalistColors.green),
                              if (widget.supportsH2H && _playerCount == 2) ...[
                                const SizedBox(width: 8),
                                _buildMultiModeBtn('head_to_head', "H2H ⚔️", NeobrutalistColors.pink),
                              ],
                            ],
                          ),

                          // H2H Raund Sayısı Seçici (Sadece H2H ise)
                          if (_multiplayerMode == 'head_to_head' && _playerCount == 2) ...[
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("H2H RAUND SAYISI (TUR):", style: NeobrutalistStyles.headlineStyle(fontSize: 10)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [3, 5, 7, 10, 15, 20].map((rounds) {
                                final isSelected = _h2hRounds == rounds;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _h2hRounds = rounds;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? NeobrutalistColors.pink : Colors.white,
                                        border: Border.all(color: Colors.black, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        rounds.toString(),
                                        textAlign: TextAlign.center,
                                        style: NeobrutalistStyles.headlineStyle(
                                          fontSize: 9,
                                          color: isSelected ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],

                        // Zorluk Seçimi
                        if (widget.difficulties != null && widget.difficulties!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("ZORLUK DERECESİ SEÇİN:", style: NeobrutalistStyles.headlineStyle(fontSize: 10)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: widget.difficulties!.map((diff) {
                              final isFirst = diff == widget.difficulties!.first;
                              return [
                                if (!isFirst) const SizedBox(width: 8),
                                _buildDifficultyBtn(diff),
                              ];
                            }).expand((w) => w).toList(),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.black, width: 1.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Seçilen seviyenin ölçütleri, tahmin yerine
                                // kural kitabındaki gerçek eşiklerden üretiliyor
                                if (diffChips.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 5,
                                    children: diffChips
                                        .map((c) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: NeobrutalistColors.black,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                c,
                                                style: NeobrutalistStyles.headlineStyle(
                                                    fontSize: 7,
                                                    color: NeobrutalistColors.white),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 7),
                                ],
                                Text(
                                  diffDescription,
                                  style: NeobrutalistStyles.bodyStyle(
                                      fontSize: 8, color: Colors.grey[700]!),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        if (widget.isDbRequired && !widget.isDbLoaded) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: NeobrutalistColors.pink,
                              border: NeobrutalistStyles.border(width: 2.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.warning, color: NeobrutalistColors.white, size: 28),
                                const SizedBox(height: 8),
                                Text(
                                  "OYUN VERİTABANI EKSİK!",
                                  style: NeobrutalistStyles.headlineStyle(fontSize: 12, color: NeobrutalistColors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Oynayabilmek için ana menüden veritabanını indirmelisiniz.",
                                  style: NeobrutalistStyles.bodyStyle(fontSize: 9, color: NeobrutalistColors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          NeobrutalistButton(
                            onPressed: _onStartPressed,
                            backgroundColor: NeobrutalistColors.black,
                            shadowColor: Colors.grey[800]!,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "OYUNA BAŞLA",
                                  style: NeobrutalistStyles.headlineStyle(fontSize: 12, color: NeobrutalistColors.yellow),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.play_arrow, color: NeobrutalistColors.yellow, size: 16),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: widget.onBackToMenu,
                          child: Text(
                            "Ana Menüye Dön",
                            style: NeobrutalistStyles.headlineStyle(
                              fontSize: 10, 
                              color: NeobrutalistColors.black,
                            ).copyWith(decoration: TextDecoration.underline),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCountBtn(int count, String label, Color activeColor) {
    final bool isSelected = _playerCount == count;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _playerCount = count;
            // Modu güvenceye al
            if (_playerCount == 1) {
              _multiplayerMode = 'solo';
            } else if (_multiplayerMode == 'solo') {
              _multiplayerMode = 'marathon';
            }
            // H2H kontrolü (Sadece 2 oyuncuda)
            if (_multiplayerMode == 'head_to_head' && _playerCount != 2) {
              _multiplayerMode = 'marathon';
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            border: Border.all(color: Colors.black, width: 2.5),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? null : NeobrutalistStyles.shadow(offset: const Offset(2, 2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: NeobrutalistStyles.headlineStyle(fontSize: 9),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiModeBtn(String mMode, String label, Color activeColor) {
    final bool isSelected = _multiplayerMode == mMode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _multiplayerMode = mMode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            border: Border.all(color: Colors.black, width: 2.5),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? null : NeobrutalistStyles.shadow(offset: const Offset(2, 2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: NeobrutalistStyles.headlineStyle(
              fontSize: 9,
              color: isSelected && activeColor != NeobrutalistColors.green ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerRegistrationView() {
    final ownerName = _ownerProfile?.name ?? "Profil Sahibi";
    final ownerEmoji = _ownerProfile?.emoji ?? "⚽";

    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 3),
                borderRadius: NeobrutalistStyles.radius20,
                boxShadow: NeobrutalistStyles.shadow(offset: const Offset(5, 5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "ÇOKLU OYUNCU KAYIT",
                    style: NeobrutalistStyles.headlineStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Player 1 (Profil Sahibi)
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: NeobrutalistColors.green,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(ownerEmoji, style: const TextStyle(fontSize: 22)),
                    ),
                    title: Text(
                      "$ownerName (Siz)",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 11),
                    ),
                    subtitle: Text(
                      "Ev Sahibi Profil",
                      style: NeobrutalistStyles.bodyStyle(fontSize: 8, color: Colors.grey[600]!),
                    ),
                  ),
                  const Divider(color: Colors.black, thickness: 2),

                  // Player 2, 3, 4 Inputs
                  for (int i = 0; i < _playerCount - 1; i++) ...[
                    const SizedBox(height: 12),
                    Text(
                      "${i + 2}. OYUNCU",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 9),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _selectEmojiForPlayer(i),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.black, width: 2.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(_playerEmojis[i], style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            maxLength: 15,
                            onChanged: (val) {
                              _playerNames[i] = val;
                            },
                            style: NeobrutalistStyles.headlineStyle(fontSize: 10),
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: "İsim yazın...",
                              filled: true,
                              fillColor: Colors.grey[50],
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.black, width: 2.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.black, width: 2.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  NeobrutalistButton(
                    onPressed: _onFinalStartPressed,
                    backgroundColor: NeobrutalistColors.black,
                    shadowColor: Colors.grey[800]!,
                    child: Text(
                      "KAYDET VE BAŞLA",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 12, color: NeobrutalistColors.yellow),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showPlayerRegistration = false;
                      });
                    },
                    child: Text(
                      "Geri Dön",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 10).copyWith(
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
