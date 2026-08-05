/// Türkçe ve Avrupa dillerindeki aksanlı harflerle mücadele eden metin yardımcıları.
///
/// Veritabanı (Transfermarkt kaynaklı) isimleri orijinal yazımıyla tutar:
/// "Arda Güler", "Mesut Özil", "Thomas Müller", "Braian Cufré"...
/// Kullanıcı ise klavyeden genellikle "guler", "ozil", "muller" yazar.
/// SQLite'ın `LIKE` operatörü sadece ASCII için harf duyarsızdır; bu yüzden
/// karakter sınıflarını destekleyen `GLOB` ile aksan duyarsız arama üretiyoruz.
class DbText {
  /// Bir ASCII harfin eşleşebileceği tüm aksanlı varyantları.
  static const Map<String, String> _variants = {
    'a': 'aàáâãäåāăąAÀÁÂÃÄÅĀĂĄ',
    'b': 'bB',
    'c': 'cçćĉčċCÇĆĈČĊ',
    'd': 'dđďdDĐĎ',
    'e': 'eèéêëēĕėęěEÈÉÊËĒĔĖĘĚ',
    'f': 'fF',
    'g': 'gğĝġģGĞĜĠĢ',
    'h': 'hĥħHĤĦ',
    'i': 'iıíìîïĩīĭįIİÍÌÎÏĨĪĬĮ',
    'j': 'jĵJĴ',
    'k': 'kķKĶ',
    'l': 'lĺļľłLĹĻĽŁ',
    'm': 'mM',
    'n': 'nñńņňNÑŃŅŇ',
    'o': 'oòóôõöøōŏőOÒÓÔÕÖØŌŎŐ',
    'p': 'pP',
    'q': 'qQ',
    'r': 'rŕŗřRŔŖŘ',
    's': 'sşśŝšSŞŚŜŠ',
    't': 'tţťŧTŢŤŦ',
    'u': 'uùúûüũūŭůűųUÙÚÛÜŨŪŬŮŰŲ',
    'v': 'vV',
    'w': 'wŵWŴ',
    'x': 'xX',
    'y': 'yýÿŷYÝŸŶ',
    'z': 'zźżžZŹŻŽ',
  };

  /// Aksan/büyük-küçük harf duyarsız `GLOB` deseni üretir.
  /// "guler" -> `*[gğĝ...][uùúûü...][lL][eèéê...][rR]*`
  static String globPattern(String query) {
    final buffer = StringBuffer('*');
    for (final rune in query.trim().toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      final variants = _variants[ch];
      if (variants != null) {
        buffer.write('[$variants]');
      } else if (ch == ' ') {
        buffer.write(' ');
      } else if (ch == '*' || ch == '?' || ch == '[' || ch == ']') {
        // GLOB joker karakterlerini yoksay, aksi halde desen bozulur.
        continue;
      } else {
        buffer.write(ch);
      }
    }
    buffer.write('*');
    return buffer.toString();
  }

  /// Karşılaştırma amaçlı sadeleştirme: aksanları düşürür, küçük harfe çevirir.
  static String normalize(String text) {
    final sb = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      var mapped = ch;
      for (final entry in _variants.entries) {
        if (entry.value.contains(ch)) {
          mapped = entry.key;
          break;
        }
      }
      sb.write(mapped);
    }
    return sb
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Tahmin doğrulamada kullanılan esnek isim karşılaştırması.
  /// Tam eşleşme, soyadı eşleşmesi ve aksansız eşleşmeyi kabul eder.
  static bool namesMatch(String guess, String actual) {
    final g = normalize(guess);
    final a = normalize(actual);
    if (g.isEmpty || a.isEmpty) return false;
    if (g == a) return true;

    final gParts = g.split(' ');
    final aParts = a.split(' ');
    // Sadece soyadı yazıldıysa ve soyadı 4+ harfliyse kabul et.
    if (gParts.length == 1 && gParts.first.length >= 4) {
      return aParts.contains(gParts.first);
    }
    // "messi lionel" gibi ters yazımları da kabul et.
    if (gParts.length == aParts.length) {
      final gSorted = [...gParts]..sort();
      final aSorted = [...aParts]..sort();
      if (gSorted.join(' ') == aSorted.join(' ')) return true;
    }
    return false;
  }
}
