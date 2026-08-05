import 'package:flutter/material.dart';
import 'package:futgol_app/common/models/football_player.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/services/database_service.dart';
import 'package:futgol_app/common/widgets/player_avatar.dart';

/// MAÇ ÖNCESİ KADRO KURULUM EKRANI
///
/// Veritabanını gerçek anlamda kullanır:
///  • Aksan duyarsız oyuncu araması ("guler" → Arda Güler)
///  • Arama sonuçlarında fotoğraf, mevki, kulüp ve piyasa değeri
///  • "HAZIR KADRO" — popüler bir kulübün en çok forma giymiş 10 futbolcusunu
///    tek dokunuşla yükler (10 ismi tek tek aramak yerine)
///  • Takım adı düzenlenebilir
class TeamSetupScreen extends StatefulWidget {
  final Function(
    List<FootballPlayer> team1Roster,
    List<FootballPlayer> team2Roster,
    String t1Name,
    String t2Name,
  ) onSetupComplete;
  final VoidCallback onCancel;

  const TeamSetupScreen({
    super.key,
    required this.onSetupComplete,
    required this.onCancel,
  });

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  static const int kSquadSize = 10;

  int _step = 1; // 1: 1. Oyuncu kadrosu, 2: 2. Oyuncu kadrosu
  final TextEditingController _team1NameController =
      TextEditingController(text: '1. OYUNCU');
  final TextEditingController _team2NameController =
      TextEditingController(text: '2. OYUNCU');

  final List<FootballPlayer> _team1Roster = [];
  final List<FootballPlayer> _team2Roster = [];

  final TextEditingController _searchController = TextEditingController();
  List<FootballPlayer> _suggestions = [];
  bool _isSearching = false;

  List<FootballClub> _popularClubs = [];
  bool _isFillingSquad = false;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _loadPopularClubs();
  }

  List<FootballPlayer> get _currentRoster => _step == 1 ? _team1Roster : _team2Roster;

  Future<void> _loadPopularClubs() async {
    final clubs = await DatabaseService().getPopularClubs(limit: 20);
    if (!mounted) return;
    setState(() => _popularClubs = clubs);
  }

  Future<void> _onSearchChanged(String query) async {
    final token = ++_searchToken;
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await DatabaseService().searchPlayers(query, limit: 8);
    if (!mounted || token != _searchToken) return;
    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  void _addPlayer(FootballPlayer player) {
    if (_currentRoster.length >= kSquadSize) {
      _toast('Kadro dolu — önce birini çıkarın.');
      return;
    }
    final exists = _currentRoster.any((p) => p.playerId > 0
        ? p.playerId == player.playerId
        : p.name.toLowerCase() == player.name.toLowerCase());
    if (exists) {
      _toast('${player.name} zaten kadroda.');
      return;
    }
    setState(() {
      _currentRoster.add(player);
      _searchController.clear();
      _suggestions = [];
    });
  }

  void _addManual() {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;
    _addPlayer(FootballPlayer.manual(text));
  }

  Future<void> _fillFromClub(FootballClub club) async {
    setState(() => _isFillingSquad = true);
    final squad = await DatabaseService().getSquadForClub(club.clubId, limit: kSquadSize);
    if (!mounted) return;

    if (squad.isEmpty) {
      setState(() => _isFillingSquad = false);
      _toast('${club.name} için kadro verisi bulunamadı.');
      return;
    }

    setState(() {
      _currentRoster
        ..clear()
        ..addAll(squad.take(kSquadSize));
      if (_step == 1) {
        _team1NameController.text = club.name.toUpperCase();
      } else {
        _team2NameController.text = club.name.toUpperCase();
      }
      _isFillingSquad = false;
      _suggestions = [];
      _searchController.clear();
    });
    _toast('${club.name} kadrosu yüklendi (${squad.length} futbolcu).');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: NeobrutalistStyles.headlineStyle(fontSize: 10, color: Colors.white)),
        backgroundColor: NeobrutalistColors.black,
        duration: const Duration(milliseconds: 1400),
      ));
  }

  void _onContinue() {
    if (_currentRoster.length < kSquadSize) {
      _toast('Kadroyu $kSquadSize futbolcuya tamamlayın (${_currentRoster.length}/$kSquadSize).');
      return;
    }
    if (_step == 1) {
      setState(() {
        _step = 2;
        _searchController.clear();
        _suggestions = [];
      });
      return;
    }
    widget.onSetupComplete(
      _team1Roster,
      _team2Roster,
      _team1NameController.text.trim().isEmpty ? '1. OYUNCU' : _team1NameController.text.trim(),
      _team2NameController.text.trim().isEmpty ? '2. OYUNCU' : _team2NameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _step == 1 ? NeobrutalistColors.pink : NeobrutalistColors.blue;
    final controller = _step == 1 ? _team1NameController : _team2NameController;

    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(accent),
              const SizedBox(height: 8),
              _buildTeamNameField(controller, accent),
              const SizedBox(height: 8),
              _buildQuickFillRow(),
              const SizedBox(height: 8),
              Expanded(child: _buildRosterGrid(accent)),
              const SizedBox(height: 6),
              _buildSearchArea(accent),
              const SizedBox(height: 8),
              NeobrutalistButton(
                height: 48,
                onPressed: _onContinue,
                backgroundColor: _currentRoster.length >= kSquadSize
                    ? NeobrutalistColors.green
                    : NeobrutalistColors.gray,
                shadowColor: NeobrutalistColors.black,
                child: Text(
                  _step == 1 ? '2. OYUNCUYA GEÇ ▸' : 'MAÇI BAŞLAT ⚽',
                  style: NeobrutalistStyles.headlineStyle(
                      fontSize: 13, color: NeobrutalistColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (_step == 2) {
              setState(() {
                _step = 1;
                _suggestions = [];
                _searchController.clear();
              });
            } else {
              widget.onCancel();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: NeobrutalistColors.pink,
              border: NeobrutalistStyles.border(width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('◂ GERİ',
                style: NeobrutalistStyles.headlineStyle(
                    fontSize: 9, color: NeobrutalistColors.white)),
          ),
        ),
        const Spacer(),
        // Adım göstergesi
        Row(
          children: [
            _stepDot(1, accent),
            Container(width: 16, height: 3, color: NeobrutalistColors.black),
            _stepDot(2, accent),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: accent,
            border: NeobrutalistStyles.border(width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${_currentRoster.length}/$kSquadSize',
              style: NeobrutalistStyles.headlineStyle(
                  fontSize: 11, color: NeobrutalistColors.white)),
        ),
      ],
    );
  }

  Widget _stepDot(int step, Color accent) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _step >= step ? accent : NeobrutalistColors.white,
          border: NeobrutalistStyles.border(width: 2),
          shape: BoxShape.circle,
        ),
        child: Text('$step',
            style: NeobrutalistStyles.headlineStyle(
              fontSize: 10,
              color: _step >= step ? NeobrutalistColors.white : NeobrutalistColors.black,
            )),
      );

  Widget _buildTeamNameField(TextEditingController controller, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: NeobrutalistColors.white,
        border: NeobrutalistStyles.border(width: 3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: NeobrutalistStyles.shadow(offset: const Offset(4, 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 26,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              style: NeobrutalistStyles.headlineStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'TAKIM ADI',
              ),
            ),
          ),
          const Icon(Icons.edit, size: 15),
        ],
      ),
    );
  }

  Widget _buildQuickFillRow() {
    if (_popularClubs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('⚡ HAZIR KADRO YÜKLE',
                style: NeobrutalistStyles.headlineStyle(fontSize: 9)),
            const SizedBox(width: 6),
            if (_isFillingSquad)
              const SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _popularClubs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final club = _popularClubs[i];
              return GestureDetector(
                onTap: _isFillingSquad ? null : () => _fillFromClub(club),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NeobrutalistColors.white,
                    border: NeobrutalistStyles.border(width: 2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(club.name,
                      style: NeobrutalistStyles.headlineStyle(fontSize: 9)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRosterGrid(Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: NeobrutalistColors.white,
        border: NeobrutalistStyles.border(width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: NeobrutalistStyles.shadow(offset: const Offset(5, 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KADRO · numara = kronometre hanesi',
            style: NeobrutalistStyles.headlineStyle(fontSize: 8, color: Colors.grey[600]!),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: kSquadSize,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                if (i >= _currentRoster.length) return _emptySlot(i);
                return _filledSlot(i, _currentRoster[i], accent);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySlot(int index) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[400]!, width: 1.5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            _slotBadge(index, Colors.grey[400]!),
            const SizedBox(width: 10),
            Text('Boş kadro yeri',
                style: NeobrutalistStyles.bodyStyle(fontSize: 10, color: Colors.grey[500]!)),
          ],
        ),
      );

  Widget _filledSlot(int index, FootballPlayer player, Color accent) => Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: NeobrutalistColors.white,
          border: NeobrutalistStyles.border(width: 2),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            _slotBadge(index, accent),
            const SizedBox(width: 8),
            PlayerAvatar.of(player, size: 28, borderWidth: 1.8),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NeobrutalistStyles.headlineStyle(fontSize: 10)),
                  if (!player.isManual)
                    Text(
                      '${player.positionTr} · ${player.country ?? '—'} · ${player.marketValueLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NeobrutalistStyles.bodyStyle(fontSize: 7.5, color: Colors.grey[600]!),
                    )
                  else
                    Text('elle eklendi',
                        style: NeobrutalistStyles.bodyStyle(
                            fontSize: 7.5, color: Colors.grey[500]!)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _currentRoster.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: NeobrutalistColors.pink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      );

  Widget _slotBadge(int index, Color color) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: NeobrutalistColors.black, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$index',
            style: NeobrutalistStyles.headlineStyle(
                fontSize: 10, color: NeobrutalistColors.white)),
      );

  Widget _buildSearchArea(Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Öneriler klavyenin kapatmaması için giriş kutusunun ÜSTÜNDE.
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 170),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: NeobrutalistColors.white,
              border: NeobrutalistStyles.border(width: 3),
              borderRadius: BorderRadius.circular(12),
              boxShadow: NeobrutalistStyles.shadow(offset: const Offset(4, 4)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, i) {
                final p = _suggestions[i];
                return InkWell(
                  onTap: () => _addPlayer(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1.5)),
                    ),
                    child: Row(
                      children: [
                        PlayerAvatar.of(p, size: 30, borderWidth: 1.8),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NeobrutalistStyles.headlineStyle(fontSize: 10)),
                              Text(
                                '${p.positionTr} · ${p.clubName ?? 'Serbest'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NeobrutalistStyles.bodyStyle(
                                    fontSize: 7.5, color: Colors.grey[600]!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(p.marketValueLabel,
                              style: NeobrutalistStyles.headlineStyle(
                                  fontSize: 8, color: NeobrutalistColors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _addManual(),
                style: NeobrutalistStyles.headlineStyle(fontSize: 11),
                decoration: InputDecoration(
                  hintText: 'Futbolcu ara (guler, ozil, muller...)',
                  hintStyle: NeobrutalistStyles.bodyStyle(fontSize: 10, color: Colors.grey[400]!),
                  prefixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          ),
                        )
                      : const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: NeobrutalistColors.black, width: 2.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: accent, width: 3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: NeobrutalistColors.white,
                ),
              ),
            ),
            const SizedBox(width: 7),
            GestureDetector(
              onTap: _addManual,
              child: Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NeobrutalistColors.blue,
                  border: NeobrutalistStyles.border(width: 2.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _team1NameController.dispose();
    _team2NameController.dispose();
    super.dispose();
  }
}
