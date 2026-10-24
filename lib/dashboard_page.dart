import 'package:flutter/material.dart';

import 'app_language.dart';
import 'scan_history_service.dart';

class FarmerDashboardPage extends StatefulWidget {
  const FarmerDashboardPage({super.key});

  @override
  State<FarmerDashboardPage> createState() => _FarmerDashboardPageState();
}

class _FarmerDashboardPageState extends State<FarmerDashboardPage> {
  final ScanHistoryService _historyService = ScanHistoryService();

  bool _loading = true;
  String? _error;
  int _totalScans = 0;
  int _healthyScans = 0;
  int _diseasedScans = 0;

  bool get _kn => appLanguage.value == 'kn';

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLanguageChanged);
    _loadStats();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final records = await _historyService.getHistory();
      int healthy = 0;

      for (final record in records) {
        final disease = (record['disease'] ?? '').toString().toLowerCase();
        if (disease.contains('healthy')) {
          healthy++;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalScans = records.length;
        _healthyScans = healthy;
        _diseasedScans = records.length - healthy;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_kn ? 'ರೈತರ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್' : 'Farmer Dashboard'),
        actions: [
          IconButton(
            tooltip: _kn ? 'ಮರುಲೋಡ್' : 'Refresh',
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.agriculture,
                      size: 44, color: Color(0xFF236B3C)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _kn ? 'ನಿಮ್ಮ ಬೆಳೆ ಆರೋಗ್ಯದ ಸಾರಾಂಶ' : 'Your crop health at a glance',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF174A2B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _kn
                              ? 'ಉಳಿಸಿದ ಸ್ಕ್ಯಾನ್‌ಗಳ ಆಧಾರದ ಮೇಲೆ'
                              : 'Based on your saved plant scans',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        _kn
                            ? 'ಸ್ಕ್ಯಾನ್ ಅಂಕಿಅಂಶಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.'
                            : 'Could not load scan statistics.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _loadStats,
                        icon: const Icon(Icons.refresh),
                        label: Text(_kn ? 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ' : 'Try again'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _StatCard(
                title: _kn ? 'ಒಟ್ಟು ಸ್ಕ್ಯಾನ್‌ಗಳು' : 'Total Scans',
                value: _totalScans,
                icon: Icons.document_scanner_outlined,
                color: const Color(0xFF236B3C),
                background: const Color(0xFFE8F5E9),
              ),
              const SizedBox(height: 14),
              _StatCard(
                title: _kn ? 'ಆರೋಗ್ಯಕರ ಎಲೆಗಳು' : 'Healthy Leaves',
                value: _healthyScans,
                icon: Icons.check_circle_outline,
                color: const Color(0xFF237A45),
                background: const Color(0xFFE8F5E9),
              ),
              const SizedBox(height: 14),
              _StatCard(
                title: _kn ? 'ರೋಗಪೀಡಿತ ಎಲೆಗಳು' : 'Diseased Leaves',
                value: _diseasedScans,
                icon: Icons.health_and_safety_outlined,
                color: const Color(0xFFB76513),
                background: const Color(0xFFFFF3E0),
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _kn ? 'ಅಂಕಿಅಂಶಗಳ ಬಗ್ಗೆ' : 'About these statistics',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _kn
                            ? 'ಈ ಅಂಕಿಅಂಶಗಳು ನಿಮ್ಮ ಸಾಧನದಲ್ಲಿ ಉಳಿಸಿದ ಸ್ಕ್ಯಾನ್‌ಗಳನ್ನು ಆಧರಿಸಿವೆ. “ಆರೋಗ್ಯಕರ” ಎಂದು ಗುರುತಿಸದ ಇತರ ಎಲ್ಲಾ ಮುನ್ಸೂಚನೆಗಳನ್ನು ಉಳಿದ ವಿಭಾಗದಲ್ಲಿ ಎಣಿಸಲಾಗುತ್ತದೆ.'
                            : 'These numbers are based on scans saved on this device. Any prediction not labelled “healthy” is counted as diseased. AI results can be incorrect, so use the advisory as guidance and confirm serious crop problems with an agricultural expert.',
                        style: const TextStyle(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.home_outlined),
              label: Text(_kn ? 'ಮುಖಪುಟಕ್ಕೆ ಹಿಂತಿರುಗಿ' : 'Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFDCEBDD)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 29),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
