import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/theme/neobrutalist_theme.dart';
import '../../../common/models/user_profile.dart';
import '../../../common/services/profile_service.dart';
import '../../../common/utils/audio_helper.dart';

class ProfileCreationScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const ProfileCreationScreen({super.key, required this.onSuccess});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedEmoji = ProfileService.defaultEmojis.first;
  String? _errorMsg;

  void _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMsg = "Lütfen bir isim girin.";
      });
      AudioHelper().playWrong();
      return;
    }

    final profile = UserProfile(
      name: name,
      emoji: _selectedEmoji,
      createdAt: DateTime.now(),
    );

    await ProfileService().saveProfile(profile);
    AudioHelper().playSuccess();
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  "FUTGOL",
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Profilini oluşturarak oyuna başla!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 4),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(8, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "İSMİNİZ",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        maxLength: 15,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "Örn: Hasan",
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: NeobrutalistColors.green,
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMsg!,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      Text(
                        "AVATAR SEÇİN",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: ProfileService.defaultEmojis.length,
                            itemBuilder: (context, index) {
                              final emoji = ProfileService.defaultEmojis[index];
                              final isSelected = emoji == _selectedEmoji;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedEmoji = emoji;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? NeobrutalistColors.pink : Colors.white,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: isSelected ? 3 : 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: _saveProfile,
                        child: Container(
                          decoration: BoxDecoration(
                            color: NeobrutalistColors.orange,
                            border: Border.all(color: Colors.black, width: 4),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(4, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text(
                            "KAYDET VE BAŞLA",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
