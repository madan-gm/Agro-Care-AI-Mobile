
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'scan_history_service.dart';
import 'app_language.dart';

class ScanHistoryPage extends StatefulWidget {
  const ScanHistoryPage({super.key});

  @override
  State<ScanHistoryPage> createState() => _ScanHistoryPageState();
}

class _ScanHistoryPageState extends State<ScanHistoryPage> {
  final ScanHistoryService _historyService = ScanHistoryService();

  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  bool get _kn => appLanguage.value == 'kn';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final records = await _historyService.getHistory();

      if (!mounted) return;

      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _kn
                ? 'ಸ್ಕ್ಯಾನ್ ಇತಿಹಾಸವನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ'
                : 'Could not load scan history: $e',
          ),
        ),
      );
    }
  }

  Future<void> _deleteRecord(int id) async {
    await _historyService.deleteScan(id);
    await _loadHistory();
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();

    if (date == null) return value;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = (date.hour % 12 == 0 ? 12 : date.hour % 12)
        .toString()
        .padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year  $hour:$minute $period';
  }

  String _formatDisease(String disease) {
    return disease
        .replaceAll('___', ' - ')
        .replaceAll('_', ' ');
  }

  void _showDetails(Map<String, dynamic> record) {
    final advisoryJson = record['advisory'] as String?;
    Map<String, dynamic>? advisory;

    if (advisoryJson != null) {
      try {
        advisory = Map<String, dynamic>.from(
          jsonDecode(advisoryJson) as Map,
        );
      } catch (_) {
        advisory = null;
      }
    }

    final languageData = advisory?[_kn ? 'kn' : 'en'];
    final advice = languageData is Map
        ? Map<String, dynamic>.from(languageData)
        : <String, dynamic>{};

    final imageData = record['image'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _kn ? 'ಸ್ಕ್ಯಾನ್ ವಿವರಗಳು' : 'Scan Details',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (imageData != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      Uint8List.fromList(
                        List<int>.from(imageData as List),
                      ),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  '${_kn ? 'ಬೆಳೆ' : 'Crop'}: ${record['crop']}',
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDisease(record['disease'] as String),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_kn ? 'ವಿಶ್ವಾಸ ಮಟ್ಟ' : 'Confidence'}: '
                  '${((record['confidence'] as num).toDouble() * 100).toStringAsFixed(2)}%',
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(record['scanned_at'] as String),
                ),
                for (final section in ['about', 'treatment', 'prevention'])
                  if (advice[section] != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      section == 'about'
                          ? (_kn ? 'ರೋಗದ ಬಗ್ಗೆ' : 'About the Disease')
                          : section == 'treatment'
                              ? (_kn ? 'ಚಿಕಿತ್ಸೆ' : 'Treatment')
                              : (_kn ? 'ತಡೆಗಟ್ಟುವಿಕೆ' : 'Prevention'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(advice[section].toString()),
                  ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_kn ? 'ಸ್ಕ್ಯಾನ್ ಇತಿಹಾಸ' : 'Scan History'),
        actions: [
          IconButton(
            tooltip: _kn ? 'ಮರುಲೋಡ್' : 'Refresh',
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.history,
                          size: 72,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _kn
                              ? 'ಇನ್ನೂ ಯಾವುದೇ ಸ್ಕ್ಯಾನ್‌ಗಳನ್ನು ಉಳಿಸಲಾಗಿಲ್ಲ'
                              : 'No scans saved yet',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _kn
                              ? 'ಒಂದು ಎಲೆಯನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಿದ ನಂತರ ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತದೆ.'
                              : 'Your saved plant scans will appear here.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      final confidence =
                          (record['confidence'] as num).toDouble();
                      final imageData = record['image'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: imageData != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    Uint8List.fromList(
                                      List<int>.from(imageData as List),
                                    ),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.eco,
                                  size: 42,
                                  color: Colors.green,
                                ),
                          title: Text(
                            _formatDisease(record['disease'] as String),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${record['crop']} • '
                              '${(confidence * 100).toStringAsFixed(1)}%\n'
                              '${_formatDate(record['scanned_at'] as String)}',
                            ),
                          ),
                          isThreeLine: true,
                          onTap: () => _showDetails(record),
                          trailing: IconButton(
                            tooltip: _kn ? 'ಅಳಿಸಿ' : 'Delete',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    _kn ? 'ಸ್ಕ್ಯಾನ್ ಅಳಿಸಬೇಕೇ?' : 'Delete scan?',
                                  ),
                                  content: Text(
                                    _kn
                                        ? 'ಈ ಸ್ಕ್ಯಾನ್ ಇತಿಹಾಸದಿಂದ ಅಳಿಸಲಾಗುತ್ತದೆ.'
                                        : 'This scan will be removed from history.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: Text(
                                        _kn ? 'ರದ್ದುಮಾಡಿ' : 'Cancel',
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: Text(
                                        _kn ? 'ಅಳಿಸಿ' : 'Delete',
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                await _deleteRecord(record['id'] as int);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
