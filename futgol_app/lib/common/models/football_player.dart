/// Veritabanındaki `players` tablosundan gelen zengin futbolcu kaydı.
/// Arama sonuçları, kadro kurulumu ve oyuncu kartlarında ortak olarak kullanılır.
class FootballPlayer {
  final int playerId;
  final String name;
  final String? imageUrl;
  final String? position;
  final String? subPosition;
  final String? country;
  final String? clubName;
  final int marketValue;
  final int? birthYear;
  final String? foot;

  const FootballPlayer({
    required this.playerId,
    required this.name,
    this.imageUrl,
    this.position,
    this.subPosition,
    this.country,
    this.clubName,
    this.marketValue = 0,
    this.birthYear,
    this.foot,
  });

  factory FootballPlayer.fromRow(Map<String, Object?> row) {
    final dob = row['date_of_birth']?.toString();
    int? year;
    if (dob != null && dob.length >= 4) {
      year = int.tryParse(dob.substring(0, 4));
    }
    return FootballPlayer(
      playerId: (row['player_id'] as num?)?.toInt() ?? 0,
      name: (row['name'] as String?) ?? 'Bilinmeyen Oyuncu',
      imageUrl: row['image_url'] as String?,
      position: row['position'] as String?,
      subPosition: row['sub_position'] as String?,
      country: row['country_of_citizenship'] as String?,
      clubName: row['current_club_name'] as String?,
      marketValue: (row['highest_market_value_in_eur'] as num?)?.toInt() ?? 0,
      birthYear: year,
      foot: row['foot'] as String?,
    );
  }

  /// Serbest metinle (veritabanı olmadan) eklenen oyuncular için.
  factory FootballPlayer.manual(String name) =>
      FootballPlayer(playerId: -1, name: name);

  bool get isManual => playerId <= 0;

  /// "Attack" -> "Forvet" gibi Türkçe mevki adı.
  String get positionTr => _positionMapTr[position ?? ''] ?? (position ?? 'Mevki ?');

  /// Kısa mevki rozeti: FRV / ORT / DEF / KLC
  String get positionBadge {
    switch (position) {
      case 'Goalkeeper':
        return 'KL';
      case 'Defender':
        return 'DF';
      case 'Midfield':
        return 'OS';
      case 'Attack':
        return 'FV';
      default:
        return '—';
    }
  }

  String get shortName {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first;
    return '${parts.first[0]}. ${parts.sublist(1).join(' ')}';
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  String get marketValueLabel => formatEuro(marketValue);

  static String formatEuro(num value) {
    if (value >= 1000000) {
      final m = value / 1000000;
      final txt = m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1);
      return '${txt.replaceAll('.0', '')}M €';
    }
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K €';
    return '$value €';
  }

  static const Map<String, String> _positionMapTr = {
    'Goalkeeper': 'Kaleci',
    'Defender': 'Defans',
    'Midfield': 'Orta Saha',
    'Attack': 'Forvet',
    'Centre-Back': 'Stoper',
    'Left-Back': 'Sol Bek',
    'Right-Back': 'Sağ Bek',
    'Defensive Midfield': 'Ön Libero',
    'Central Midfield': 'Merkez Orta Saha',
    'Attacking Midfield': 'Ofansif Orta Saha',
    'Left Winger': 'Sol Kanat',
    'Right Winger': 'Sağ Kanat',
    'Centre-Forward': 'Santrfor',
    'Second Striker': 'İkinci Forvet',
    'Left Midfield': 'Sol Orta Saha',
    'Right Midfield': 'Sağ Orta Saha',
    'Sweeper': 'Libero',
  };
}

/// Kadro kurulumu ve arama ekranlarında kullanılan hafif kulüp kaydı.
class FootballClub {
  final int clubId;
  final String name;
  final String? competitionId;
  final int squadSize;
  final int stadiumSeats;
  final String? stadiumName;

  const FootballClub({
    required this.clubId,
    required this.name,
    this.competitionId,
    this.squadSize = 0,
    this.stadiumSeats = 0,
    this.stadiumName,
  });

  factory FootballClub.fromRow(Map<String, Object?> row) => FootballClub(
        clubId: (row['club_id'] as num?)?.toInt() ?? 0,
        name: (row['name'] as String?) ?? 'Bilinmeyen Kulüp',
        competitionId: row['domestic_competition_id'] as String?,
        squadSize: (row['squad_size'] as num?)?.toInt() ?? 0,
        stadiumSeats: (row['stadium_seats'] as num?)?.toInt() ?? 0,
        stadiumName: row['stadium_name'] as String?,
      );

  /// "GB1" -> "🏴 Premier Lig" gibi okunabilir lig etiketi.
  String get leagueLabel => leagueNames[competitionId] ?? (competitionId ?? '');

  static const Map<String, String> leagueNames = {
    'GB1': 'Premier Lig',
    'ES1': 'LaLiga',
    'IT1': 'Serie A',
    'L1': 'Bundesliga',
    'FR1': 'Ligue 1',
    'TR1': 'Süper Lig',
    'NL1': 'Eredivisie',
    'PO1': 'Portekiz Ligi',
    'RU1': 'Rusya Ligi',
    'BE1': 'Belçika Ligi',
    'SC1': 'İskoçya Ligi',
    'GR1': 'Yunanistan Ligi',
    'DK1': 'Danimarka Ligi',
    'A1': 'Avusturya Ligi',
    'UKR1': 'Ukrayna Ligi',
    'RO1': 'Romanya Ligi',
    'MLS1': 'MLS',
    'BRA1': 'Brezilya Ligi',
    'ARG1': 'Arjantin Ligi',
    'SA1': 'Suudi Ligi',
    'MEX1': 'Meksika Ligi',
    'JAP1': 'Japonya Ligi',
    'KR1': 'Kore Ligi',
  };
}
