import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'farming_chat_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'scan_history_service.dart';
import 'scan_history_page.dart';
import 'dashboard_page.dart';

import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'notification_service.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ai_service.dart';
import 'weather_page.dart';
import 'app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidDebugProvider(),
  );

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
      home: const HomePage(),
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
  final ScanHistoryService _historyService = ScanHistoryService();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _modelLoaded = false;
  bool _isPredicting = false;
  String _status = appText('Loading AI model...', 'AI à²®à²¾à²¦à²°à²¿ à²²à³‹à²¡à³ à²†à²—à³à²¤à³à²¤à²¿à²¦à³†...');
  String? _selectedCrop;
  String? _disease;
  double? _confidence;
  Map<String, dynamic>? _advisory;
  Uint8List? _selectedImage;
  // Uses the app-wide language selected on the Home page.
  String _selectedLanguage = appLanguage.value;
  Future<void> _speakAdvisory() async {
  if (_disease == null) return;

  final diseaseName = _formatDiseaseName(_disease!);

  final about = _getAdvisoryText('about');
  final treatment = _getAdvisoryText('treatment');
  final prevention = _getAdvisoryText('prevention');

  final languageCode =
      _selectedLanguage == 'kn' ? 'kn-IN' : 'en-IN';

  final speechText = _selectedLanguage == 'kn'
      ? 'à²°à³‹à²—à²¦ à²¹à³†à²¸à²°à³: $diseaseName. '
          'à²°à³‹à²—à²¦ à²¬à²—à³à²—à³†: $about. '
          'à²šà²¿à²•à²¿à²¤à³à²¸à³†: $treatment. '
          'à²¤à²¡à³†à²—à²Ÿà³à²Ÿà³à²µà²¿à²•à³†: $prevention.'
      : 'Detected disease: $diseaseName. '
          'About the disease: $about. '
          'Treatment: $treatment. '
          'Prevention: $prevention.';

  await _flutterTts.stop();
  await _flutterTts.setLanguage(languageCode);
  await _flutterTts.setSpeechRate(0.45);
  await _flutterTts.setPitch(1.0);

  setState(() => _isSpeaking = true);

  await _flutterTts.speak(speechText);
}

Future<void> _pauseSpeech() async {
  await _flutterTts.pause();
  if (mounted) {
    setState(() => _isSpeaking = false);
  }
}

Future<void> _stopSpeech() async {
  await _flutterTts.stop();
  if (mounted) {
    setState(() => _isSpeaking = false);
  }
}
  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onAppLanguageChanged);
    _selectedLanguage = appLanguage.value;
    _loadModel();
  }
  void _onAppLanguageChanged() {
    if (!mounted) return;
    setState(() {
      _selectedLanguage = appLanguage.value;
    });
  }

  Future<void> _loadModel() async {
    try {
      await _aiService.loadModel();
      setState(() {
        _modelLoaded = true;
        _status = appText('Select a crop to get started', 'à²ªà³à²°à²¾à²°à²‚à²­à²¿à²¸à²²à³ à²¬à³†à²³à³†à²¯à²¨à³à²¨à³ à²†à²¯à³à²•à³†à²®à²¾à²¡à²¿');
      });
    } catch (e) {
      setState(() {
        _status = appText('Failed to load AI model: $e', 'AI à²®à²¾à²¦à²°à²¿ à²²à³‹à²¡à³ à²†à²—à²²à²¿à²²à³à²²: $e');
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
      _status = appText('Analyzing your leaf...', 'à²¨à²¿à²®à³à²® à²Žà²²à³†à²¯à²¨à³à²¨à³ à²µà²¿à²¶à³à²²à³‡à²·à²¿à²¸à²²à²¾à²—à³à²¤à³à²¤à²¿à²¦à³†...');
    });
    try {
      final result = await _aiService.predictImage(
        bytes,
        _selectedCrop!,
      );
      final advisory = _aiService.getAdvisory(
        result.className,
      );
      await _historyService.saveScan(
        crop: _selectedCrop!,
        disease: result.className,
        confidence: result.confidence,
        imageBytes: bytes,
        advisory: advisory,
      );
      setState(() {
        _disease = result.className;
        _confidence = result.confidence;
        _advisory = advisory;
        _isPredicting = false;
        _status = appText('Analysis completed', 'à²µà²¿à²¶à³à²²à³‡à²·à²£à³† à²ªà³‚à²°à³à²£à²—à³Šà²‚à²¡à²¿à²¦à³†');
      });
      if (advisory != null) {
        await Future.delayed(
          const Duration(milliseconds: 800),
        );

        if (!mounted) return;

        await _speakAdvisory();
      }
    } catch (e) {
      setState(() {
        _isPredicting = false;
        _status = appText('Prediction failed: $e', 'à²®à³à²¨à³à²¸à³‚à²šà²¨à³† à²µà²¿à²«à²²à²µà²¾à²—à²¿à²¦à³†: $e');
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



Future<void> _pickFromFiles() async {
  if (!_modelLoaded || _selectedCrop == null || _isPredicting) {
    return;
  }

  try {
    final file = await FilePicker.pickFile(
      type: FileType.image,
    );

    if (file == null) {
      return;
    }

    final Uint8List bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read this image. Please choose another.'),
        ),
      );
      return;
    }

    await _predictImage(bytes);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to select image: $e'),
      ),
    );
  }
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
      appLanguage.value = language;
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
      return appText('High Confidence', 'à²¹à³†à²šà³à²šà²¿à²¨ à²µà²¿à²¶à³à²µà²¾à²¸');
    } else if (confidence >= 0.50) {
      return appText('Moderate Confidence', 'à²®à²§à³à²¯à²® à²µà²¿à²¶à³à²µà²¾à²¸');
    } else {
      return appText('Low Confidence', 'à²•à²¡à²¿à²®à³† à²µà²¿à²¶à³à²µà²¾à²¸');
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
    appLanguage.removeListener(_onAppLanguageChanged);
    _flutterTts.stop();
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
  title: Text(
    'Agro Care AI',
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
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
              Text(
                appText('Smart Crop Health Check', 'à²¸à³à²®à²¾à²°à³à²Ÿà³ à²¬à³†à²³à³† à²†à²°à³‹à²—à³à²¯ à²ªà²°à²¿à²¶à³€à²²à²¨à³†'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                appText('Detect crop diseases using AI', 'AI à²¬à²³à²¸à²¿ à²¬à³†à²³à³† à²°à³‹à²—à²—à²³à²¨à³à²¨à³ à²ªà²¤à³à²¤à³†à²¹à²šà³à²šà²¿'),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              _buildStatusCard(),
              const SizedBox(height: 25),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  appText('1. Select your crop', '1. à²¨à²¿à²®à³à²® à²¬à³†à²³à³†à²¯à²¨à³à²¨à³ à²†à²¯à³à²•à³†à²®à²¾à²¡à²¿'),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    appText('2. Add a leaf photo', '2. à²Žà²²à³†à²¯ à²«à³‹à²Ÿà³‹ à²¸à³‡à²°à²¿à²¸à²¿'),
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

              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isPredicting ? null : _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(appText('Take Photo', 'à²«à³‹à²Ÿà³‹ à²¤à³†à²—à³†à²¯à²¿à²°à²¿')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPredicting ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: Text(appText('Gallery', 'à²—à³à²¯à²¾à²²à²°à²¿')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isPredicting ? null : _pickFromFiles,
                      icon: const Icon(Icons.folder_open),
                      label: Text(appText('Upload from Files', 'à²«à³ˆà²²à³â€Œà²—à²³à²¿à²‚à²¦ à²…à²ªà³â€Œà²²à³‹à²¡à³ à²®à²¾à²¡à²¿')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
                Text(
                  appText('AI is analyzing the leaf...', 'AI à²Žà²²à³†à²¯à²¨à³à²¨à³ à²µà²¿à²¶à³à²²à³‡à²·à²¿à²¸à³à²¤à³à²¤à²¿à²¦à³†...'),
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
          Text(
            appText('AI ANALYSIS', 'AI à²µà²¿à²¶à³à²²à³‡à²·à²£à³†'),
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              appText('Confidence', 'à²µà²¿à²¶à³à²µà²¾à²¸ à²®à²Ÿà³à²Ÿ'),
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
                        ? appText('The AI is confident in this prediction.', 'à²ˆ à²®à³à²¨à³à²¸à³‚à²šà²¨à³†à²¯ à²¬à²—à³à²—à³† AI à²—à³† à²¹à³†à²šà³à²šà²¿à²¨ à²µà²¿à²¶à³à²µà²¾à²¸à²µà²¿à²¦à³†.')
                        : confidence >= 0.50
                            ? appText('The prediction has moderate confidence. Check the image quality.', 'à²®à³à²¨à³à²¸à³‚à²šà²¨à³†à²¯ à²µà²¿à²¶à³à²µà²¾à²¸ à²®à²§à³à²¯à²®à²µà²¾à²—à²¿à²¦à³†. à²šà²¿à²¤à³à²°à²¦ à²—à³à²£à²®à²Ÿà³à²Ÿà²µà²¨à³à²¨à³ à²ªà²°à²¿à²¶à³€à²²à²¿à²¸à²¿.')
                            : appText('Low confidence. Please take a clearer leaf photo.', 'à²µà²¿à²¶à³à²µà²¾à²¸ à²•à²¡à²¿à²®à³†à²¯à²¾à²—à²¿à²¦à³†. à²¦à²¯à²µà²¿à²Ÿà³à²Ÿà³ à²Žà²²à³†à²¯ à²¸à³à²ªà²·à³à²Ÿà²µà²¾à²¦ à²«à³‹à²Ÿà³‹ à²¤à³†à²—à³†à²¯à²¿à²°à²¿.'),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                appText('3. Disease Advisory', '3. à²°à³‹à²—à²¦ à²¸à²²à²¹à³†'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _buildLanguageSelector(),
            const SizedBox(height: 12),

Wrap(
  spacing: 10,
  runSpacing: 10,
  alignment: WrapAlignment.center,
  children: [
    ElevatedButton.icon(
      onPressed: _speakAdvisory,
      icon: const Icon(Icons.volume_up),
      label: Text(
        _selectedLanguage == 'kn'
            ? 'à²¸à²²à²¹à³† à²•à³‡à²³à²¿'
            : 'Listen to Advice',
      ),
    ),
    OutlinedButton.icon(
      onPressed: _pauseSpeech,
      icon: const Icon(Icons.pause),
      label: Text(
        _selectedLanguage == 'kn' ? 'à²µà²¿à²°à²¾à²®' : 'Pause',
      ),
    ),
    OutlinedButton.icon(
      onPressed: _stopSpeech,
      icon: const Icon(Icons.stop),
      label: Text(
        _selectedLanguage == 'kn' ? 'à²¨à²¿à²²à³à²²à²¿à²¸à²¿' : 'Stop',
      ),
    ),
  ],
),

const SizedBox(height: 12),
            const SizedBox(height: 18),
            _advisorySection(
              title: _selectedLanguage == 'en'
                  ? appText('About the Disease', 'à²°à³‹à²—à²¦ à²¬à²—à³à²—à³†')
                  : 'à²°à³‹à²—à²¦ à²¬à²—à³à²—à³†',
              icon: Icons.info_outline,
              text: _getAdvisoryText('about'),
              color: Colors.blue,
            ),
            const SizedBox(height: 15),
            _advisorySection(
              title: _selectedLanguage == 'en'
                  ? appText('Treatment', 'à²šà²¿à²•à²¿à²¤à³à²¸à³†')
                  : 'à²šà²¿à²•à²¿à²¤à³à²¸à³†',
              icon: Icons.medical_services_outlined,
              text: _getAdvisoryText('treatment'),
              color: Colors.orange,
            ),
            const SizedBox(height: 15),
            _advisorySection(
              title: _selectedLanguage == 'en'
                  ? appText('Prevention', 'à²¤à²¡à³†à²—à²Ÿà³à²Ÿà³à²µà²¿à²•à³†')
                  : 'à²¤à²¡à³†à²—à²Ÿà³à²Ÿà³à²µà²¿à²•à³†',
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
                  'à²•à²¨à³à²¨à²¡',
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color darkGreen = Color(0xFF174A2B);
  static const Color lightGreen = Color(0xFFE8F5E9);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String get _language => appLanguage.value;

  void _setLanguage(String language) {
    setState(() {
      appLanguage.value = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool kannada = _language == 'kn';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCEBDD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LanguageOption(
                          label: 'English',
                          selected: !kannada,
                          onTap: () => _setLanguage('en'),
                        ),
                        _LanguageOption(
                          label: 'à²•à²¨à³à²¨à²¡',
                          selected: kannada,
                          onTap: () => _setLanguage('kn'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Image.asset(
                  'assets/agro_care_ai_logo.png',
                  height: 135,
                  width: 135,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'Agro Care AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: HomePage.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kannada
                      ? 'à²¸à³à²®à²¾à²°à³à²Ÿà³ à²•à³ƒà²·à²¿ à²‡à²²à³à²²à²¿à²‚à²¦ à²ªà³à²°à²¾à²°à²‚à²­à²µà²¾à²—à³à²¤à³à²¤à²¦à³†'
                      : 'Smart farming starts here',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),
                // Farmer Dashboard card
                _HomeOptionCard(
                  icon: Icons.dashboard_outlined,
                  title: kannada ? 'à²°à³ˆà²¤à²° à²¡à³à²¯à²¾à²¶à³â€Œà²¬à³‹à²°à³à²¡à³' : 'Farmer Dashboard',
                  subtitle: kannada
                      ? 'à²’à²Ÿà³à²Ÿà³ à²¸à³à²•à³à²¯à²¾à²¨à³â€Œà²—à²³à³ à²®à²¤à³à²¤à³ à²¬à³†à²³à³† à²†à²°à³‹à²—à³à²¯à²¦ à²µà²¿à²µà²°à²—à²³à³'
                      : 'View total scans and crop health statistics',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const FarmerDashboardPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),
                // Weather card
                _HomeOptionCard(
                  icon: Icons.cloud_outlined,
                  title: kannada ? 'à²¹à²µà²¾à²®à²¾à²¨' : 'Weather',
                  subtitle: kannada
                      ? 'à²®à³à²¨à³à²¸à³‚à²šà²¨à³†, à²®à²³à³† à²®à²¤à³à²¤à³ à²¬à²¿à²¸à²¿à²²à²¿à²¨ à²Žà²šà³à²šà²°à²¿à²•à³†à²—à²³à³'
                      : 'Forecasts, rain and heat alerts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const WeatherPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // AI Farming Assistant card
                _HomeOptionCard(
                  icon: Icons.chat_bubble_outline,
                  title: kannada
                      ? 'AI à²•à³ƒà²·à²¿ à²¸à²¹à²¾à²¯à²•'
                      : 'AI Farming Assistant',
                  subtitle: kannada
                      ? 'à²•à³ƒà²·à²¿ à²ªà³à²°à²¶à³à²¨à³†à²—à²³à²¿à²—à³† à²‰à²¤à³à²¤à²° à²ªà²¡à³†à²¯à²¿à²°à²¿'
                      : 'Ask questions about farming and crop care',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const FarmingChatPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Plant Disease Detection card
                _HomeOptionCard(
                  icon: Icons.eco_outlined,
                  title: kannada
                      ? 'à²¸à²¸à³à²¯ à²°à³‹à²— à²ªà²¤à³à²¤à³†'
                      : 'Plant Disease Detection',
                  subtitle: kannada
                      ? 'à²¬à³†à²³à³† à²Žà²²à³†à²¯ à²šà²¿à²¤à³à²°à²µà²¨à³à²¨à³ à²¤à³†à²—à³†à²¯à²¿à²°à²¿ à²…à²¥à²µà²¾ à²…à²ªà³â€Œà²²à³‹à²¡à³ à²®à²¾à²¡à²¿'
                      : 'Scan or upload a crop leaf image',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PredictionPage(),
                      ),
                    );
                  },
                ),
                  const SizedBox(height: 18),

                  _HomeOptionCard(
                    icon: Icons.history,
                    title: kannada ? 'à²¸à³à²•à³à²¯à²¾à²¨à³ à²‡à²¤à²¿à²¹à²¾à²¸' : 'Scan History',
                    subtitle: kannada
                        ? 'à²¹à²¿à²‚à²¦à²¿à²¨ à²¸à³à²•à³à²¯à²¾à²¨à³â€Œà²—à²³à³ à²®à²¤à³à²¤à³ à²šà²¿à²•à²¿à²¤à³à²¸à³†à²¯ à²¸à²²à²¹à³†à²—à²³à²¨à³à²¨à³ à²¨à³‹à²¡à²¿'
                        : 'View previous scans and treatment advice',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ScanHistoryPage(),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 28),
                Text(
                  kannada
                      ? 'à²†à²°à³‹à²—à³à²¯à²•à²° à²¬à³†à²³à³†à²—à²³à³ à²®à²¤à³à²¤à³ à²¸à³à²¸à³à²¥à²¿à²° à²•à³ƒà²·à²¿à²—à³† à²¬à³†à²‚à²¬à²²'
                      : 'Supporting healthier crops and sustainable farming',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _HomeOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFDCEBDD)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 34, color: const Color(0xFF236B3C)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF174A2B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF236B3C)),
            ],
          ),
        ),
      ),
    );
  }
}

