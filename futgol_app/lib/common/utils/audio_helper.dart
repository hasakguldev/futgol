import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioHelper {
  static final AudioHelper _instance = AudioHelper._internal();
  factory AudioHelper() => _instance;
  AudioHelper._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  // Yerel ses dosyalarının yolları (assets/sounds/ klasörü altında)
  static const String _whistlePath = "sounds/whistle.wav";
  static const String _tickPath = "sounds/tick.wav";
  static const String _goalPath = "sounds/goal.wav";
  static const String _missPath = "sounds/miss.wav";
  static const String _correctPath = "sounds/correct.wav";
  static const String _wrongPath = "sounds/wrong.wav";
  static const String _successPath = "sounds/success.wav";

  // Arka planda tetiklenen, ana iş akışını (main thread) asla bloke etmeyen asenkron ses çalma fonksiyonu
  void _playSound(String path) {
    if (!_soundEnabled) return;
    
    // Hızlı tıklamalarda veya yavaş cihazlarda ana thread'in donmaması ve 
    // TimeoutException alınmaması için ses işlemini asenkron bir void fonksiyonda 
    // try-catch ile izole ediyoruz (fire-and-forget).
    Future.microtask(() async {
      try {
        await _player.stop();
        // AssetSource kullanıyoruz, eğer dosya diskte bulunamazsa hata yakalanır
        await _player.play(AssetSource(path)).timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {
            debugPrint("Ses çalma zaman aşımına uğradı, sessizce devam ediliyor: $path");
            return;
          },
        );
      } catch (e) {
        // Çevrimdışı durumlarda, dosya henüz yüklenmemişse veya platform hatalarında sessizce devam et
        debugPrint("Ses çalınamadı (dosya eksik veya platform hatası), sessiz geçiliyor: $e");
      }
    });
  }

  void playWhistle() => _playSound(_whistlePath);
  void playTick() => _playSound(_tickPath);
  void playGoal() => _playSound(_goalPath);
  void playMiss() => _playSound(_missPath);
  void playCorrect() => _playSound(_correctPath);
  void playWrong() => _playSound(_wrongPath);
  void playSuccess() => _playSound(_successPath);
}
