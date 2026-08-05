import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/services/database_service.dart';
import 'package:futgol_app/common/utils/audio_helper.dart';

class DatabaseDownloadScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const DatabaseDownloadScreen({super.key, required this.onSuccess});

  @override
  State<DatabaseDownloadScreen> createState() => _DatabaseDownloadScreenState();
}

class _DatabaseDownloadScreenState extends State<DatabaseDownloadScreen> {
  String _stage = 'idle'; // 'idle', 'download', 'verify', 'unzip', 'load', 'error'
  double _percent = 0.0;
  String _errorMsg = '';

  Future<void> _startSetup() async {
    setState(() {
      _stage = 'download';
      _percent = 0.0;
      _errorMsg = '';
    });

    // Github Releases üzerindeki sıkıştırılmış SQLite veritabanı zip dosyası
    const String url = "https://github.com/hasakguldev/futgol/releases/download/ds/futgol.db.zip";
    // Dosya bütünlük hash'i (SHA-256)
    const String hash = "7322b8fa3755904436f8f5bc3625d398f17120df84b72cb2af4c60f5944c8bd9";

    try {
      await DatabaseService().setupDatabase(
        url: url,
        expectedHash: hash,
        onProgress: (stage, percent) {
          if (mounted) {
            setState(() {
              _stage = stage;
              _percent = percent;
            });
          }
        },
      );
      
      AudioHelper().playSuccess();
      widget.onSuccess();
    } catch (e) {
      AudioHelper().playWrong();
      if (mounted) {
        setState(() {
          _stage = 'error';
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // Aşama durumuna göre simge ve stil belirleme yardımcı metodu
  Map<String, dynamic> _getStageStatus(String targetStage) {
    const order = ['download', 'verify', 'unzip', 'load'];
    final currentIndex = order.indexOf(_stage);
    final targetIndex = order.indexOf(targetStage);

    if (_stage == 'error') {
      return {'icon': '❌', 'color': Colors.red, 'text': 'Hata oluştu'};
    }

    if (currentIndex > targetIndex) {
      return {'icon': '✅', 'color': Colors.green[600]!, 'text': 'Tamamlandı'};
    } else if (currentIndex == targetIndex) {
      return {'icon': '⏳', 'color': NeobrutalistColors.pink, 'text': 'Yapılıyor...'};
    } else {
      return {'icon': '⚪', 'color': Colors.grey[400]!, 'text': 'Bekliyor'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadStatus = _getStageStatus('download');
    final verifyStatus = _getStageStatus('verify');
    final unzipStatus = _getStageStatus('unzip');
    final loadStatus = _getStageStatus('load');

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
                  // FUTGOL Logosu
                  Center(
                    child: Text(
                      "FUTGOL",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_stage == 'idle') ...[
                    Text(
                      "Oyuna başlamak için ilişkisel futbolcu veritabanının telefona indirilip kurulması gerekmektedir (yaklaşık 329 MB).",
                      textAlign: TextAlign.center,
                      style: NeobrutalistStyles.bodyStyle(fontSize: 13, color: Colors.grey[800]!),
                    ),
                    const SizedBox(height: 24),
                    NeobrutalistButton(
                      onPressed: _startSetup,
                      backgroundColor: NeobrutalistColors.pink,
                      shadowColor: NeobrutalistColors.pinkShadow,
                      child: Text(
                        "KURULUMU BAŞLAT",
                        style: NeobrutalistStyles.headlineStyle(fontSize: 16, color: NeobrutalistColors.white),
                      ),
                    ),
                  ] else if (_stage == 'error') ...[
                    const Center(child: Text("⚠️", style: TextStyle(fontSize: 56))),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "KURULUM BAŞARISIZ!",
                        style: NeobrutalistStyles.headlineStyle(fontSize: 18, color: Colors.red[700]!),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: NeobrutalistStyles.border(width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _errorMsg,
                        style: NeobrutalistStyles.bodyStyle(fontSize: 10, color: Colors.red[900]!),
                      ),
                    ),
                    const SizedBox(height: 24),
                    NeobrutalistButton(
                      onPressed: _startSetup,
                      backgroundColor: NeobrutalistColors.yellow,
                      shadowColor: NeobrutalistColors.black,
                      child: Text(
                        "YENİDEN DENE",
                        style: NeobrutalistStyles.headlineStyle(fontSize: 16),
                      ),
                    ),
                  ] else ...[
                    // İlerleme Durumu başlığı
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _stage == 'download' ? 'İndiriliyor...' : _stage == 'verify' ? 'Hash Doğrulanıyor...' : _stage == 'unzip' ? 'Zip Açılıyor...' : 'Yükleniyor...',
                          style: NeobrutalistStyles.headlineStyle(fontSize: 12),
                        ),
                        Text(
                          "%${_percent.toStringAsFixed(0)}",
                          style: NeobrutalistStyles.headlineStyle(fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress Bar
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: NeobrutalistColors.white,
                        border: NeobrutalistStyles.border(width: 3),
                        borderRadius: NeobrutalistStyles.radius12,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double progressWidth = constraints.maxWidth * (_percent / 100);
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: progressWidth,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: NeobrutalistColors.pink,
                                borderRadius: BorderRadius.horizontal(
                                  left: const Radius.circular(8),
                                  right: Radius.circular(progressWidth >= constraints.maxWidth - 2 ? 8 : 0),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Adımlar Checkbox Listesi
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: NeobrutalistStyles.border(width: 2.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildStepRow("futgol.db.zip indiriliyor (329 MB)", downloadStatus),
                          const Divider(color: Colors.grey, height: 16),
                          _buildStepRow("SHA-256 bütünlük doğrulaması", verifyStatus),
                          const Divider(color: Colors.grey, height: 16),
                          _buildStepRow("Zip arşivi çıkarılıyor (875 MB)", unzipStatus),
                          const Divider(color: Colors.grey, height: 16),
                          _buildStepRow("SQLite veritabanı belleğe yazılıyor", loadStatus),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String title, Map<String, dynamic> status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(status['icon'] as String, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(
              title,
              style: NeobrutalistStyles.bodyStyle(
                fontSize: 11,
                color: status['color'] as Color,
              ),
            ),
          ],
        ),
        Text(
          status['text'] as String,
          style: NeobrutalistStyles.headlineStyle(
            fontSize: 8,
            color: Colors.grey[600]!,
          ),
        ),
      ],
    );
  }
}
