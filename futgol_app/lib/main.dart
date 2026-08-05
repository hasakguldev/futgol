import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common/theme/neobrutalist_theme.dart';
import 'common/services/database_service.dart';
import 'features/menu/screens/database_download_screen.dart';
import 'features/menu/screens/main_menu_screen.dart';
import 'features/stopwatch/screens/stopwatch_football_screen.dart';
import 'features/common_link/screens/common_link_finder_screen.dart';
import 'features/career_path/screens/career_path_screen.dart';
import 'features/market_value/screens/market_value_screen.dart';
import 'features/market_value/screens/market_value_quiz_screen.dart';
import 'features/market_value/screens/transfer_fee_screen.dart';
import 'features/career_path/screens/missing_lineup_screen.dart';
import 'features/career_path/screens/transfer_bridge_screen.dart';
import 'features/career_path/screens/match_goalscorer_screen.dart';
import 'features/career_path/screens/stadium_capacity_screen.dart';
import 'features/career_path/screens/card_king_screen.dart';
import 'features/career_path/screens/top_stats_screen.dart';
import 'features/career_path/screens/immaculate_grid_screen.dart';
import 'common/widgets/onboarding_widget.dart';
import 'common/widgets/stats_dashboard.dart';
import 'common/utils/audio_helper.dart';
import 'common/services/profile_service.dart';
import 'features/menu/screens/profile_creation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futgol',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const FutgolHomePage(),
    );
  }
}

class FutgolHomePage extends StatefulWidget {
  const FutgolHomePage({super.key});

  @override
  State<FutgolHomePage> createState() => _FutgolHomePageState();
}

class _FutgolHomePageState extends State<FutgolHomePage> {
  String _currentScreen = 'db_download';
  bool _soundEnabled = true;
  bool _onboardingCompleted = false;
  int _backButtonPressCount = 0;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _checkInitialDbStatus();
  }

  Future<void> _checkInitialDbStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    AudioHelper().setSoundEnabled(_soundEnabled);

    final bool isLoaded = await DatabaseService().checkDatabaseStatus();
    final bool hasProfile = await ProfileService().hasProfile();
    if (isLoaded) {
      setState(() {
        if (!_onboardingCompleted) {
          _currentScreen = 'onboarding';
        } else if (!hasProfile) {
          _currentScreen = 'profile_creation';
        } else {
          _currentScreen = 'menu';
        }
      });
    } else {
      setState(() {
        _currentScreen = 'db_download';
      });
    }
  }

  void _onDbDownloadSuccess() async {
    final bool hasProfile = await ProfileService().hasProfile();
    setState(() {
      if (!_onboardingCompleted) {
        _currentScreen = 'onboarding';
      } else if (!hasProfile) {
        _currentScreen = 'profile_creation';
      } else {
        _currentScreen = 'menu';
      }
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    final bool hasProfile = await ProfileService().hasProfile();
    setState(() {
      _onboardingCompleted = true;
      _currentScreen = hasProfile ? 'menu' : 'profile_creation';
    });
  }

  void _onSelectGame(String game) {
    setState(() {
      _currentScreen = game;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentWidget;
    switch (_currentScreen) {
      case 'db_download':
        currentWidget = DatabaseDownloadScreen(
          onSuccess: _onDbDownloadSuccess,
        );
        break;
      case 'onboarding':
        currentWidget = OnboardingWidget(
          onCompleted: _completeOnboarding,
        );
        break;
      case 'profile_creation':
        currentWidget = ProfileCreationScreen(
          onSuccess: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'menu':
        currentWidget = MainMenuScreen(
          onSelectGame: _onSelectGame,
          onOpenStats: () => setState(() => _currentScreen = 'stats'),
          onOpenSettings: () => setState(() => _currentScreen = 'settings'),
        );
        break;
      case 'stopwatch':
        currentWidget = StopwatchFootballScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'common_link':
      case 'commonLink':
        currentWidget = CommonLinkFinderScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'career_path':
        currentWidget = CareerPathScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'market_value':
        currentWidget = MarketValueScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'market_value_quiz':
        currentWidget = MarketValueQuizScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'transfer_fee':
        currentWidget = TransferFeeScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'missing_lineup':
        currentWidget = MissingLineupScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'transfer_bridge':
        currentWidget = TransferBridgeScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'match_goalscorer':
        currentWidget = MatchGoalscorerScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'stadium_capacity':
        currentWidget = StadiumCapacityScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'card_king':
        currentWidget = CardKingScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'top_stats':
        currentWidget = TopStatsScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'immaculate_grid':
        currentWidget = ImmaculateGridScreen(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'stats':
        currentWidget = StatsDashboard(
          onBackToMenu: () => setState(() => _currentScreen = 'menu'),
        );
        break;
      case 'settings':
        currentWidget = _buildSettingsScreen();
        break;
      default:
        currentWidget = MainMenuScreen(
          onSelectGame: _onSelectGame,
          onOpenStats: () => setState(() => _currentScreen = 'stats'),
          onOpenSettings: () => setState(() => _currentScreen = 'settings'),
        );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Eğer alt oyun sayfalarındaysak ana menüye dön
        if (_currentScreen != 'menu' && _currentScreen != 'db_download' && _currentScreen != 'onboarding' && _currentScreen != 'profile_creation') {
          setState(() {
            _currentScreen = 'menu';
          });
          return;
        }

        // Ana sayfadaysak (menu) 3 kez geri basma çıkış mantığı
        if (_currentScreen == 'menu') {
          final now = DateTime.now();
          if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
            _backButtonPressCount = 1;
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Çıkmak için 2 kez daha geri tuşuna basın.",
                  style: NeobrutalistStyles.headlineStyle(fontSize: 10, color: NeobrutalistColors.white),
                ),
                backgroundColor: NeobrutalistColors.pink,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            _backButtonPressCount++;
            _lastBackPressTime = now;
            if (_backButtonPressCount >= 3) {
              SystemNavigator.pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Çıkmak için ${3 - _backButtonPressCount} kez daha geri tuşuna basın.",
                    style: NeobrutalistStyles.headlineStyle(fontSize: 10, color: NeobrutalistColors.white),
                  ),
                  backgroundColor: NeobrutalistColors.pink,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      },
      child: currentWidget,
    );
  }



  // Yerleşik Ayarlar Ekranı
  Widget _buildSettingsScreen() {
    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: NeobrutalistCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: Text("⚙️", style: TextStyle(fontSize: 56))),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "AYARLAR",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: NeobrutalistStyles.border(width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ses Efektleri Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "SES EFEKTLERİ",
                              style: NeobrutalistStyles.headlineStyle(fontSize: 10, color: Colors.grey[600]!),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _soundEnabled = !_soundEnabled;
                                  AudioHelper().setSoundEnabled(_soundEnabled);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _soundEnabled ? NeobrutalistColors.green : NeobrutalistColors.pink,
                                  border: NeobrutalistStyles.border(width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _soundEnabled ? "AÇIK" : "KAPALI",
                                  style: NeobrutalistStyles.headlineStyle(fontSize: 9, color: NeobrutalistColors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.grey, height: 24),
                        // Kılavuz
                        Text(
                          "NASIL OYNANIR?",
                          style: NeobrutalistStyles.headlineStyle(fontSize: 8, color: Colors.grey[400]!),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "⏱️ Kronometre Futbolu: Sırası gelen oyuncu kronometreyi başlatıp durdurarak saliseyi yakalar. Yakalanan salise ile kadro hamlesi yapılır, süresi biten kaybeder!",
                          style: NeobrutalistStyles.bodyStyle(fontSize: 9, color: Colors.grey[800]!),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "👕 Futbolcu Tahmin Oyunu: Ekranda gösterilen iki futbolcu/takım arasındaki takım arkadaşlığı veya aynı kulüp bağını arama kutusundan bulup tahmin edin.",
                          style: NeobrutalistStyles.bodyStyle(fontSize: 9, color: Colors.grey[800]!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  NeobrutalistButton(
                    onPressed: () => setState(() => _currentScreen = 'menu'),
                    backgroundColor: NeobrutalistColors.blue,
                    shadowColor: NeobrutalistColors.blueShadow,
                    child: Text(
                      "MENÜYE DÖN",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 14, color: NeobrutalistColors.white),
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
