import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/widgets/player_avatar.dart';

// Oyun Sonu, Tebrikler vb. durumları gösteren büyük Neobrutalist Kartı
class StateCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String msg;
  final String btnText;
  final Color btnColor;
  final VoidCallback onBtnPressed;
  final Widget? additionalWidget;

  const StateCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.msg,
    required this.btnText,
    required this.btnColor,
    required this.onBtnPressed,
    this.additionalWidget,
  });

  @override
  Widget build(BuildContext context) {
    return NeobrutalistCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: NeobrutalistColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            title,
            style: NeobrutalistStyles.headlineStyle(fontSize: 22, color: NeobrutalistColors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            msg,
            style: NeobrutalistStyles.bodyStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ?additionalWidget,
          NeobrutalistButton(
            onPressed: onBtnPressed,
            backgroundColor: btnColor,
            shadowColor: NeobrutalistColors.black,
            child: Text(
              btnText,
              style: NeobrutalistStyles.headlineStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Oyuncu veya Kulüp isimlerini gösteren Neobrutalist etiket kartı.
// Oyuncu modunda veritabanındaki portre (players.image_url), mevki ve uyruk
// bilgisiyle birlikte gösterilir — soru artık iki kuru isimden ibaret değil.
class ItemCard extends StatelessWidget {
  final String text;
  final Color color;
  final String? imageUrl;
  final String? subtitle;

  const ItemCard({
    super.key,
    required this.text,
    required this.color,
    this.imageUrl,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final bool rich = imageUrl != null || subtitle != null;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          border: NeobrutalistStyles.border(width: 3),
          borderRadius: NeobrutalistStyles.radius12,
          boxShadow: NeobrutalistStyles.shadow(offset: const Offset(4, 4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (rich) ...[
              PlayerAvatar(
                imageUrl: imageUrl,
                fallbackText: _initials(text),
                size: 52,
                borderWidth: 2.5,
              ),
              const SizedBox(height: 6),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: NeobrutalistStyles.headlineStyle(
                  fontSize: 11, color: NeobrutalistColors.white),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NeobrutalistStyles.bodyStyle(
                  fontSize: 8,
                  color: NeobrutalistColors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
            if (!rich) const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

// Oyuncu ismi girişi için Neobrutalist Form Kartı
class NameInputCard extends StatefulWidget {
  final Function(String name) onSubmitted;

  const NameInputCard({super.key, required this.onSubmitted});

  @override
  State<NameInputCard> createState() => _NameInputCardState();
}

class _NameInputCardState extends State<NameInputCard> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return NeobrutalistCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: NeobrutalistColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text("👕", style: TextStyle(fontSize: 48))),
          const SizedBox(height: 12),
          Center(
            child: Text(
              "FUTBOLCU TAHMİN OYUNU",
              style: NeobrutalistStyles.headlineStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Lütfen oyuna başlamak için adınızı girin:",
              style: NeobrutalistStyles.bodyStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: NeobrutalistStyles.headlineStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Adınız",
              hintStyle: NeobrutalistStyles.bodyStyle(fontSize: 12, color: Colors.grey[400]!),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: NeobrutalistColors.black, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: NeobrutalistColors.pink, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 20),
          NeobrutalistButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                widget.onSubmitted(_nameController.text.trim());
              }
            },
            backgroundColor: NeobrutalistColors.green,
            shadowColor: NeobrutalistColors.black,
            child: Text(
              "OYUNA BAŞLA",
              style: NeobrutalistStyles.headlineStyle(fontSize: 12, color: NeobrutalistColors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

// Oyuna Özel Giriş Onboarding Ekranı
class GameOnboardingCard extends StatelessWidget {
  final VoidCallback onStart;

  const GameOnboardingCard({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeobrutalistColors.green,
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
                  const Text("👕", style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    "FUTBOLCU TAHMİN OYUNU",
                    style: NeobrutalistStyles.headlineStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Nasıl Oynanır?\n\n• Ekranda iki oyuncu veya kulüp kartı görürsünüz.\n• Bu iki kart arasındaki ortak bağı (Takım arkadaşı veya oynadıkları ortak kulüp) tahmin edin.\n• Arama alanına yazarak autocomplete listesinden seçim yapabilir ve onaylayabilirsiniz.\n• Her ipucu açtığınızda canınız (❤️) eksilir.\n• Doğru yüzdeleriniz İstatistikler menüsünde kaydedilir!",
                    style: NeobrutalistStyles.bodyStyle(fontSize: 10),
                    textAlign: TextAlign.left,
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
}
