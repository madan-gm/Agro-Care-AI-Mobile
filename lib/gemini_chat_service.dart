
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiChatService {
  GeminiChatService()
      : _chat = FirebaseAI.googleAI()
            .generativeModel(
              model: 'gemini-3.5-flash',
              systemInstruction: Content.text(
                'You are Agro Care AI, a helpful agricultural assistant for farmers in India. '
                'Answer clearly and practically. Support crop diseases, crop care, irrigation, '
                'soil health, and weather-aware farming questions. Do not claim certainty from '
                'symptoms alone. Encourage users to consult local agricultural officers for '
                'serious crop losses or pesticide decisions. Never recommend mixing pesticides. '
                'Reply in the same language as the user. If the user asks in Kannada, answer in Kannada.',
              ),
            )
            .startChat();

  final ChatSession _chat;

  Future<String> sendMessage(String message) async {
    final trimmed = message.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError('Message cannot be empty.');
    }

    try {
      final response = await _chat.sendMessage(Content.text(trimmed));
      final answer = response.text?.trim();

      if (answer == null || answer.isEmpty) {
        throw Exception('Firebase returned an empty response.');
      }

      return answer;
    } catch (e, stackTrace) {
      debugPrint('🔥 Firebase AI Logic error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
