import 'package:flutter/material.dart';
import '../models/football_player.dart';
import '../theme/neobrutalist_theme.dart';
import 'player_avatar.dart';

/// Ortak arama kutusu.
///
/// İki modda çalışır:
///  • `suggestions` (List&lt;String&gt;) — sade metin listesi (eski davranış)
///  • `playerSuggestions` (List&lt;FootballPlayer&gt;) — fotoğraflı, mevkili,
///    kulüplü ve piyasa değerli zengin kart listesi. Veritabanındaki
///    `image_url`, `position`, `current_club_name` alanlarını kullanır.
class NeobrutalistAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final List<String> suggestions;
  final List<FootballPlayer> playerSuggestions;
  final ValueChanged<String> onSuggestionSelected;
  final ValueChanged<String> onChanged;
  final IconData prefixIcon;
  final double suggestionsMaxHeight;
  final bool isSearching;
  final Color accentColor;

  const NeobrutalistAutocompleteField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSuggestionSelected,
    required this.onChanged,
    this.suggestions = const [],
    this.playerSuggestions = const [],
    this.enabled = true,
    this.prefixIcon = Icons.search,
    this.suggestionsMaxHeight = 200.0,
    this.isSearching = false,
    this.accentColor = NeobrutalistColors.pink,
  });

  bool get _hasRich => playerSuggestions.isNotEmpty;
  bool get _hasAny => _hasRich || suggestions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Öneriler, sanal klavyenin listeyi kapatmaması için TextField'ın ÜSTÜNDE.
        if (_hasAny)
          Container(
            constraints: BoxConstraints(maxHeight: suggestionsMaxHeight),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: NeobrutalistColors.white,
              border: NeobrutalistStyles.border(width: 3),
              borderRadius: NeobrutalistStyles.radius12,
              boxShadow: NeobrutalistStyles.shadow(offset: const Offset(4, 4)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: _hasRich ? playerSuggestions.length : suggestions.length,
              itemBuilder: (context, i) => _hasRich
                  ? _richTile(playerSuggestions[i])
                  : _plainTile(suggestions[i]),
            ),
          ),

        // Arama Giriş Kutusu
        TextField(
          controller: controller,
          onChanged: onChanged,
          enabled: enabled,
          textInputAction: TextInputAction.search,
          style: NeobrutalistStyles.headlineStyle(fontSize: 11),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: NeobrutalistStyles.bodyStyle(
              fontSize: 11,
              color: Colors.grey[400]!,
            ),
            prefixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: NeobrutalistColors.black),
                    ),
                  )
                : Icon(prefixIcon, size: 18),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: enabled
                        ? () {
                            controller.clear();
                            onChanged('');
                          }
                        : null,
                  ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: NeobrutalistColors.black, width: 2.5),
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[400]!, width: 2.5),
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: accentColor, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _plainTile(String name) => InkWell(
        onTap: enabled ? () => onSuggestionSelected(name) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1.5)),
          ),
          child: Row(
            children: [
              const Text("⚽ ", style: TextStyle(fontSize: 14)),
              Expanded(
                child: Text(name, style: NeobrutalistStyles.headlineStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _richTile(FootballPlayer player) => InkWell(
        onTap: enabled ? () => onSuggestionSelected(player.name) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1.5)),
          ),
          child: Row(
            children: [
              PlayerAvatar.of(player, size: 32, borderWidth: 1.8),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NeobrutalistStyles.headlineStyle(fontSize: 11),
                    ),
                    Text(
                      '${player.positionTr} · ${player.clubName ?? 'Serbest'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NeobrutalistStyles.bodyStyle(
                          fontSize: 8, color: Colors.grey[600]!),
                    ),
                  ],
                ),
              ),
              if (player.marketValue > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    player.marketValueLabel,
                    style: NeobrutalistStyles.headlineStyle(
                        fontSize: 8, color: NeobrutalistColors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
