import 'package:flutter/material.dart';
import '../theme/neobrutalist_theme.dart';
import 'futboli_mascot.dart';

class OnboardingWidget extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingWidget({super.key, required this.onCompleted});

  @override
  State<OnboardingWidget> createState() => _OnboardingWidgetState();
}

class _OnboardingWidgetState extends State<OnboardingWidget> {
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'FUTGOL\'E HOŞ GELDİNİZ!',
      'description': 'Futbol bilginizi ve reflekslerinizi sınayacağınız eğlenceli, neobrutalist tarzda tasarlanmış native mobil oyun platformuna adım attınız!',
      'icon': const FutboliMascot(),
      'bgColor': NeobrutalistColors.yellow,
    },
    {
      'title': '⏱️ KRONOMETRE FUTBOLU',
      'description': 'Aynı cihazda iki oyuncuyla karşılıklı oynanan salise yakalama oyunudur. Yıl ve takım seçerek 5\'er kişilik kadrolarınızı kurun, reflekslerinizle goller atın!',
      'icon': const Text("⚽", style: TextStyle(fontSize: 72)),
      'bgColor': NeobrutalistColors.pink,
    },
    {
      'title': '👕 FUTBOLCU TAHMİN OYUNU',
      'description': 'İki efsane futbolcu arasındaki takım arkadaşlığı veya aynı kulüp bağını bulun. Autocomplete destekli arama kutusuyla tahminler yapıp rekor serinizi kırın!',
      'icon': const Text("👕", style: TextStyle(fontSize: 72)),
      'bgColor': NeobrutalistColors.blue,
    },
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: slide['bgColor'] as Color,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Üst Kısım: Sayfa İndikatörleri
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final bool isSelected = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 24 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: NeobrutalistColors.black,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: NeobrutalistColors.black, width: 1),
                    ),
                  );
                }),
              ),
              const Expanded(child: SizedBox(height: 20)),

              // Orta Kısım: Kart İçeriği
              NeobrutalistCard(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 280),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 120,
                        alignment: Alignment.center,
                        child: slide['icon'] as Widget,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        slide['title'] as String,
                        textAlign: TextAlign.center,
                        style: NeobrutalistStyles.headlineStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        slide['description'] as String,
                        textAlign: TextAlign.center,
                        style: NeobrutalistStyles.bodyStyle(fontSize: 10).copyWith(
                          color: NeobrutalistColors.black.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Expanded(child: SizedBox(height: 20)),

              // Alt Kısım: Butonlar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Geç Butonu
                  if (_currentPage < _slides.length - 1)
                    GestureDetector(
                      onTap: widget.onCompleted,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          "GEÇ",
                          style: NeobrutalistStyles.headlineStyle(fontSize: 11, color: NeobrutalistColors.black.withValues(alpha: 0.6)),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 50),

                  // Sonraki / Başla Butonu
                  NeobrutalistButton(
                    onPressed: _nextPage,
                    width: 140,
                    backgroundColor: NeobrutalistColors.white,
                    shadowColor: NeobrutalistColors.black,
                    child: Text(
                      _currentPage == _slides.length - 1 ? "BAŞLA" : "İLERLE",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
