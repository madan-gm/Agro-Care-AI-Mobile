import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class AiService {
  Interpreter? _interpreter;

  List<String> _classes = [];

  Map<String, dynamic> _advisory = {};

  Future<void> loadModel() async {
    // Load TFLite model
    _interpreter = await Interpreter.fromAsset(
      'assets/models/mobilenetv2_finetuned.tflite',
    );

    // Load class names
    final classData = await rootBundle.loadString(
      'assets/classes.json',
    );

    _classes = List<String>.from(
      jsonDecode(classData),
    );

    // Load disease advisory
    final advisoryData = await rootBundle.loadString(
      'assets/advisory/advisory.json',
    );

    _advisory = Map<String, dynamic>.from(
      jsonDecode(advisoryData),
    );

    print('TFLite model loaded successfully.');
    print('Number of classes: ${_classes.length}');
    print(
      'Number of advisory entries: ${_advisory.length}',
    );
    print(
      'Input shape: ${_interpreter!.getInputTensor(0).shape}',
    );
    print(
      'Output shape: ${_interpreter!.getOutputTensor(0).shape}',
    );
  }

  Future<PredictionResult> predictImage(
    Uint8List imageBytes,
    String selectedCrop,
  ) async {
    if (_interpreter == null) {
      throw Exception('Model is not loaded.');
    }

    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('Could not decode the image.');
    }

    final resizedImage = img.copyResize(
      decodedImage,
      width: 224,
      height: 224,
    );

    final input = Float32List(224 * 224 * 3);

    int index = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);

        input[index++] = pixel.r.toDouble();
        input[index++] = pixel.g.toDouble();
        input[index++] = pixel.b.toDouble();
      }
    }

    final output = List.generate(
      1,
      (_) => List<double>.filled(
        _classes.length,
        0.0,
      ),
    );

    _interpreter!.run(
      input.reshape([1, 224, 224, 3]),
      output,
    );

    final probabilities = output[0];

    int startIndex;
    int endIndex;

    switch (selectedCrop) {
      case 'Corn':
        startIndex = 0;
        endIndex = 3;
        break;

      case 'Potato':
        startIndex = 4;
        endIndex = 6;
        break;

      case 'Tomato':
        startIndex = 7;
        endIndex = 14;
        break;

      default:
        throw Exception(
          'Invalid crop selected: $selectedCrop',
        );
    }

    int bestIndex = startIndex;

    for (int i = startIndex + 1; i <= endIndex; i++) {
      if (probabilities[i] > probabilities[bestIndex]) {
        bestIndex = i;
      }
    }

    final className = _classes[bestIndex];

    return PredictionResult(
      classIndex: bestIndex,
      className: className,
      confidence: probabilities[bestIndex],
    );
  }

  /// Returns the advisory information for a disease.
  Map<String, dynamic>? getAdvisory(String disease) {
    final advisory = _advisory[disease];

    if (advisory == null) {
      return null;
    }

    return Map<String, dynamic>.from(advisory);
  }

  void close() {
    _interpreter?.close();
  }
}

class PredictionResult {
  final int classIndex;
  final String className;
  final double confidence;

  PredictionResult({
    required this.classIndex,
    required this.className,
    required this.confidence,
  });
}