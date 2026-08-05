import 'package:flutter_test/flutter_test.dart';
import 'package:futgol_app/common/services/db_text_utils.dart';

void main() {
  group('DbText.globPattern — aksan duyarsız arama', () {
    test('Türkçe harflerin ASCII karşılıklarını da kapsar', () {
      final pattern = DbText.globPattern('guler');
      // 'g' hem g hem ğ ile, 'u' hem u hem ü ile eşleşmeli
      expect(pattern.startsWith('*'), isTrue);
      expect(pattern.endsWith('*'), isTrue);
      expect(pattern.contains('ğ'), isTrue);
      expect(pattern.contains('ü'), isTrue);
    });

    test('GLOB joker karakterlerini ayıklar', () {
      final pattern = DbText.globPattern('me*ss?i');
      expect(pattern.substring(1, pattern.length - 1).contains('*'), isFalse);
      expect(pattern.substring(1, pattern.length - 1).contains('?'), isFalse);
    });

    test('boşlukları korur', () {
      expect(DbText.globPattern('arda guler').contains(' '), isTrue);
    });
  });

  group('DbText.normalize', () {
    test('aksanları düşürür', () {
      expect(DbText.normalize('Arda Güler'), 'arda guler');
      expect(DbText.normalize('Mesut Özil'), 'mesut ozil');
      expect(DbText.normalize('Braian Cufré'), 'braian cufre');
      expect(DbText.normalize('Şükrü Çalışkan'), 'sukru caliskan');
    });

    test('noktalama ve fazla boşluğu temizler', () {
      expect(DbText.normalize("  N'Golo   Kanté  "), 'ngolo kante');
    });
  });

  group('DbText.namesMatch — tahmin doğrulama', () {
    test('birebir eşleşme', () {
      expect(DbText.namesMatch('Arda Güler', 'Arda Güler'), isTrue);
    });

    test('aksansız yazım kabul edilir', () {
      expect(DbText.namesMatch('arda guler', 'Arda Güler'), isTrue);
      expect(DbText.namesMatch('mesut ozil', 'Mesut Özil'), isTrue);
      expect(DbText.namesMatch('thomas muller', 'Thomas Müller'), isTrue);
    });

    test('yalnızca soyadı kabul edilir', () {
      expect(DbText.namesMatch('Guler', 'Arda Güler'), isTrue);
      expect(DbText.namesMatch('messi', 'Lionel Messi'), isTrue);
    });

    test('çok kısa soyadı parçası kabul edilmez', () {
      expect(DbText.namesMatch('ard', 'Arda Güler'), isFalse);
    });

    test('ters yazım kabul edilir', () {
      expect(DbText.namesMatch('Messi Lionel', 'Lionel Messi'), isTrue);
    });

    test('yanlış isim reddedilir', () {
      expect(DbText.namesMatch('Cristiano Ronaldo', 'Lionel Messi'), isFalse);
      expect(DbText.namesMatch('', 'Lionel Messi'), isFalse);
    });
  });
}
