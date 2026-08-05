import 'package:flutter/material.dart';
import 'package:futgol_app/common/models/football_player.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/widgets/autocomplete_field.dart';
import 'guess_game_widgets.dart';

class GuessCardWidget extends StatelessWidget {
  final bool isPlayerMode;
  final String item1;
  final String item2;
  final FootballPlayer? profile1;
  final FootballPlayer? profile2;
  final String feedbackMsg;
  final bool feedbackIsError;
  final TextEditingController searchController;
  final bool isProcessing;
  final List<FootballPlayer> suggestions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSuggestionSelected;
  final ValueChanged<String> onSubmitGuess;
  final int passes;
  final VoidCallback onPass;

  const GuessCardWidget({
    super.key,
    required this.isPlayerMode,
    required this.item1,
    required this.item2,
    required this.feedbackMsg,
    required this.searchController,
    required this.isProcessing,
    required this.suggestions,
    required this.onSearchChanged,
    required this.onSuggestionSelected,
    required this.onSubmitGuess,
    required this.passes,
    required this.onPass,
    this.profile1,
    this.profile2,
    this.feedbackIsError = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeobrutalistCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: NeobrutalistColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isPlayerMode
                ? 'BU İKİSİYLE DE AYNI TAKIMDA OYNAYAN FUTBOLCU KİM?'
                : 'HER İKİ KULÜPTE DE FORMA GİYEN FUTBOLCU KİM?',
            textAlign: TextAlign.center,
            style: NeobrutalistStyles.headlineStyle(fontSize: 9, color: Colors.grey[700]!),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ItemCard(
                  text: item1,
                  color: NeobrutalistColors.pink,
                  imageUrl: isPlayerMode ? profile1?.imageUrl : null,
                  subtitle: isPlayerMode ? _subtitle(profile1) : null,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.0),
                  child: Center(child: Text("🤝", style: TextStyle(fontSize: 22))),
                ),
                ItemCard(
                  text: item2,
                  color: NeobrutalistColors.purple,
                  imageUrl: isPlayerMode ? profile2?.imageUrl : null,
                  subtitle: isPlayerMode ? _subtitle(profile2) : null,
                ),
              ],
            ),
          ),
          if (feedbackMsg.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: feedbackIsError
                    ? const Color(0xFFFFE4EC)
                    : const Color(0xFFF3F4F6),
                border: NeobrutalistStyles.border(width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                feedbackMsg,
                textAlign: TextAlign.center,
                style: NeobrutalistStyles.headlineStyle(fontSize: 10),
              ),
            ),
          ],
          const SizedBox(height: 16),

          NeobrutalistAutocompleteField(
            controller: searchController,
            hintText: isPlayerMode
                ? "Ortak takım arkadaşını yazın..."
                : "İki kulüpte de oynayan futbolcuyu yazın...",
            enabled: !isProcessing,
            isSearching: isProcessing,
            playerSuggestions: suggestions,
            onSuggestionSelected: onSuggestionSelected,
            onChanged: onSearchChanged,
            accentColor: NeobrutalistColors.purple,
          ),
          const SizedBox(height: 12),
          NeobrutalistButton(
            onPressed: () => onSubmitGuess(searchController.text),
            disabled: isProcessing,
            backgroundColor: NeobrutalistColors.blue,
            shadowColor: NeobrutalistColors.black,
            child: Text(
              isProcessing ? "KONTROL EDİLİYOR..." : "TAHMİN ET",
              style: NeobrutalistStyles.headlineStyle(
                  fontSize: 12, color: NeobrutalistColors.white),
            ),
          ),
          if (passes > 0) ...[
            const SizedBox(height: 10),
            NeobrutalistButton(
              onPressed: onPass,
              disabled: isProcessing,
              height: 44,
              backgroundColor: NeobrutalistColors.orange,
              shadowColor: NeobrutalistColors.black,
              child: Text(
                "PAS GEÇ ($passes HAK)",
                style: NeobrutalistStyles.headlineStyle(
                    fontSize: 11, color: NeobrutalistColors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String? _subtitle(FootballPlayer? player) {
    if (player == null) return null;
    final parts = <String>[
      player.positionTr,
      if (player.country != null && player.country!.isNotEmpty) player.country!,
    ];
    return parts.join(' · ');
  }
}
