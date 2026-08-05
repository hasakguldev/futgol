import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';

// 1. OYUN İÇİ ONBOARDING KARTI
class StopwatchOnboardingCard extends StatelessWidget {
  final VoidCallback onStart;

  const StopwatchOnboardingCard({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeobrutalistColors.pink,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: NeobrutalistCard(
              padding: const EdgeInsets.all(24),
              backgroundColor: NeobrutalistColors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("⏱️", style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    "KRONOMETRE FUTBOLU",
                    style: NeobrutalistStyles.headlineStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Telefonu masaya koyun, karşılıklı oturun. Ekranın üst yarısı "
                    "1. oyuncunun, alt yarısı 2. oyuncunundur.\n",
                    style: NeobrutalistStyles.bodyStyle(fontSize: 10),
                  ),
                  Text(
                    "NASIL OYNANIR?",
                    style: NeobrutalistStyles.headlineStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "1️⃣  Kadronuza 10 futbolcu seçersiniz. Her futbolcunun 0-9 arası "
                    "bir numarası olur.\n"
                    "2️⃣  Kronometreyi başlatıp durdurursunuz. Yakalanan salisenin "
                    "SON HANESİ o numaralı futbolcuyu sahaya çıkarır.\n"
                    "3️⃣  Kronometreyi ikinci kez durdurursunuz; bu sefer son hane "
                    "hareketi belirler:",
                    style: NeobrutalistStyles.bodyStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  _outcomeTable(),
                  const SizedBox(height: 8),
                  Text(
                    "• Her oyuncunun 30 saniyelik zaman havuzu vardır; havuz sadece "
                    "kronometre dönerken erir.\n"
                    "• Bir hamleyi 5 saniye içinde tamamlamazsanız atak söner.\n"
                    "• Kırmızı kart gören ve sakatlanan futbolcular seçilirse atak "
                    "söner — kadro şeridinden durumlarını takip edin.\n"
                    "• 4 kırmızı kart = hükmen 3-0 yenilgi.",
                    style: NeobrutalistStyles.bodyStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 24),
                  NeobrutalistButton(
                    onPressed: onStart,
                    backgroundColor: NeobrutalistColors.yellow,
                    shadowColor: NeobrutalistColors.black,
                    child: Text(
                      "ANLADIM, BAŞLA",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 12),
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

  /// Salise hanesi → hareket eşlemesini görsel tablo olarak gösterir.
  /// Kullanıcı hangi rakamın ne anlama geldiğini artık ezberlemek zorunda değil.
  Widget _outcomeTable() {
    const outcomes = [
      ['0', '⚽', 'GOL'],
      ['1', '🥅', 'Direk'],
      ['2', '🚩', 'Ofsayt'],
      ['3', '📐', 'Korner'],
      ['4', '🤦', 'Kendi kalesine'],
      ['5', '🎯', 'Penaltı'],
      ['6', '🟥', 'Kırmızı kart'],
      ['7', '🟨', 'Sarı kart'],
      ['8', '🟨', 'Sarı kart'],
      ['9', '🏥', 'Sakatlık'],
    ];

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: outcomes
          .map((o) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: NeobrutalistColors.yellow,
                  border: NeobrutalistStyles.border(width: 1.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 15,
                      height: 15,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: NeobrutalistColors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(o[0],
                          style: NeobrutalistStyles.headlineStyle(
                              fontSize: 8, color: NeobrutalistColors.white)),
                    ),
                    const SizedBox(width: 4),
                    Text('${o[1]} ${o[2]}',
                        style: NeobrutalistStyles.headlineStyle(fontSize: 8)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

