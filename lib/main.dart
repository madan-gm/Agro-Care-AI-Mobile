import 'dart:typed_data';
import 'notification_service.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ai_service.dart';
import 'weather_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();
  await NotificationService.requestPermission();

  runApp(const AgroCareApp());
}

class AgroCareApp extends StatelessWidget {
  const AgroCareApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agro Care AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FBF7),
      ),
      home: const PredictionPage(),
    );
  }
}
class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});
  @override
  State<PredictionPage> createState() => _PredictionPageState();
}
class _PredictionPageState extends State<PredictionPage> {
  final AiService _aiService = AiService();
  final ImagePicker _picker = ImagePicker();
  bool _modelLoaded = false;
  bool _isPredicting = false;
  String _status = 'Loading AI model...';
  String? _selectedCrop;
  String? _disease;
  double? _confidence;
  Map<String, dynamic>? _advisory;
  Uint8List? _selectedImage;
  // English by default.
  String _selectedLanguage = 'en';
  @override
  void initState() {
    super.initState();
    _loadModel();
  }
  Future<void> _loadModel() async {
    try {
      await _aiService.loadModel();
      setState(() {
        _modelLoaded = true;
        _status = 'Select a crop to get started';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to load AI model: $e';
      });
    }
  }
  Future<void> _predictImage(Uint8List bytes) async {
    setState(() {
      _selectedImage = bytes;
      _disease = null;
      _confidence = null;
      _advisory = null;
      _isPredicting = true;
      _status = 'Analyzing your leaf...';
    });
    try {
      final result = await _aiService.predictImage(
        bytes,
        _selectedCrop!,
      );
      final advisory = _aiService.getAdvisory(
        result.className,
      );
      setState(() {
        _disease = result.className;
        _confidence = result.confidence;
        _advisory = advisory;
        _isPredicting = false;
        _status = 'Analysis completed';
      });
    } catch (e) {
      setState(() {
        _isPredicting = false;
        _status = 'Prediction failed: $e';
      });
    }
  }
  Future<void> _takePhoto() async {
    if (!_modelLoaded || _selectedCrop == null) {
      return;
    }
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile == null) {
      return;
    }
    final bytes = await pickedFile.readAsBytes();
    await _predictImage(bytes);
  }
  Future<void> _pickFromGallery() async {
    if (!_modelLoaded || _selectedCrop == null) {
      return;
    }
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return;
    }
    final bytes = await pickedFile.readAsBytes();
    await _predictImage(bytes);
  }
  void _selectCrop(String crop) {
    setState(() {
      _selectedCrop = crop;
      _disease = null;
      _confidence = null;
      _advisory = null;
      _selectedImage = null;
      _status = 'Take or select a clear $crop leaf photo';
    });
  }
  void _selectLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }
  String _formatDiseaseName(String disease) {
    String name = disease;
    name = name.replaceAll('___', ' - ');
    name = name.replaceAll('_', ' ');
    return name;
  }
  String _confidenceLabel(double confidence) {
    if (confidence >= 0.70) {
      return 'High Confidence';
    } else if (confidence >= 0.50) {
      return 'Moderate Confidence';
    } else {
      return 'Low Confidence';
    }
  }
  IconData _confidenceIcon(double confidence) {
    if (confidence >= 0.70) {
      return Icons.check_circle;
    } else if (confidence >= 0.50) {
      return Icons.info;
    } else {
      return Icons.warning;
    }
  }
  Color _confidenceColor(double confidence) {
    if (confidence >= 0.70) {
      return Colors.green;
    } else if (confidence >= 0.50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  @override
  void dispose() {
    _aiService.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  centerTitle: true,
  title: const Text(
    'Agro Care AI',
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
  actions: [
    IconButton(
      tooltip: 'Farm Weather',
      icon: const Icon(
        Icons.cloud_outlined,
        color: Colors.green,
        size: 28,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const WeatherPage(),
          ),
        );
      },
    ),
  ],
),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/agro_care_ai_logo.png',
                height: 130,
                width: 130,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              const Text(
                'Smart Crop Health Check',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Detect crop diseases using AI',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              _buildStatusCard(),
              const SizedBox(height: 25),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '1. Select your crop',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _cropCard(
                      crop: 'Tomato',
                      icon: Icons.eco,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _cropCard(
                      crop: 'Potato',
                      icon: Icons.grass,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _cropCard(
                      crop: 'Corn',
                      icon: Icons.agriculture,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              if (_selectedCrop != null) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '2. Add a leaf photo',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                if (_selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      _selectedImage!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (_selectedImage != null)
                  const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isPredicting ? null : _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _isPredicting
                                ? null
                                : _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_isPredicting) ...[
                const SizedBox(height: 25),
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                const Text(
                  'AI is analyzing the leaf...',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (_disease != null && _confidence != null) ...[
                const SizedBox(height: 30),
                _buildPredictionCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _modelLoaded
                ? Icons.check_circle
                : Icons.hourglass_top,
            color: _modelLoaded
                ? Colors.green
                : Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _status,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPredictionCard() {
    final confidence = _confidence!;
    final confidenceColor = _confidenceColor(confidence);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.green.shade100,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.biotech,
            size: 42,
            color: Colors.green,
          ),
          const SizedBox(height: 10),
          const Text(
            'AI ANALYSIS',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              _selectedImage!,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _selectedCrop!,
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _formatDiseaseName(_disease!),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Confidence',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                confidenceColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _confidenceLabel(confidence),
                style: TextStyle(
                  color: confidenceColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(confidence * 100).toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: confidence >= 0.70
                  ? Colors.green.shade50
                  : confidence >= 0.50
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _confidenceIcon(confidence),
                  color: confidenceColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    confidence >= 0.70
                        ? 'The AI is confident in this prediction.'
                        : confidence >= 0.50
                            ? 'The prediction has moderate confidence. Check the image quality.'
                            : 'Low confidence. Please take a clearer leaf photo.',
                    style: TextStyle(
                      color: confidenceColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // -----------------------------------------
          // ADVISORY SECTION
          // -----------------------------------------
          if (_advisory != null) ...[
            const SizedBox(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '3. Disease Advisory',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _buildLanguageSelector(),
            const SizedBox(height: 18),
            _advisorySection(
              title: _selectedLanguage == 'en'
                  ? 'About the Disease'
                  : 'ರೋಗದ ಬಗ್ಗೆ',
              icon: Icons.info_outline,
              text: _getAdvisoryText('about'),
              color: Colors.blue,
            ),
            const SizedBox(height: 15),
            _advisorySection(
              title: _selectedLanguage == 'en'
                  ? 'Treatment'
                  : 'ಚಿಕಿತ್ಸೆ',
              icon: Icons.medical_services_outlined,
              text: _getAdvisoryText('treatment'),
              color: Colors.orange,
            ),
            const SizedBox(height: 15),
            _advisorySection(
              title: _selectedLanguage == 'en'
                  ? 'Prevention'
                  : 'ತಡೆಗಟ್ಟುವಿಕೆ',
              icon: Icons.shield_outlined,
              text: _getAdvisoryText('prevention'),
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildLanguageSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectLanguage('en'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _selectedLanguage == 'en'
                      ? Colors.green
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'English',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedLanguage == 'en'
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectLanguage('kn'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _selectedLanguage == 'kn'
                      ? Colors.green
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ಕನ್ನಡ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedLanguage == 'kn'
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  String _getAdvisoryText(String section) {
    if (_advisory == null) {
      return 'Advisory information is not available.';
    }
    final languageData =
        _advisory![_selectedLanguage];
    if (languageData is Map) {
      final value = languageData[section];
      if (value != null) {
        return value.toString();
      }
    }
    return 'Information is not available.';
  }
  Widget _advisorySection({
    required String title,
    required IconData icon,
    required String text,
    required MaterialColor color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
  Widget _cropCard({
    required String crop,
    required IconData icon,
  }) {
    final bool selected = _selectedCrop == crop;
    return GestureDetector(
      onTap: _modelLoaded
          ? () => _selectCrop(crop)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.green.shade50
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.green
                : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 34,
              color: selected
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              crop,
              style: TextStyle(
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: selected
                    ? Colors.green.shade800
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
