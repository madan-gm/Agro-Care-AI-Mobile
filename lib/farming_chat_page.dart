
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'app_language.dart';
import 'gemini_chat_service.dart';

class FarmingChatPage extends StatefulWidget {
  const FarmingChatPage({super.key});

  @override
  State<FarmingChatPage> createState() => _FarmingChatPageState();
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}

class _FarmingChatPageState extends State<FarmingChatPage> {
  final GeminiChatService _service = GeminiChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _sending = false;

  bool get _kn => appLanguage.value == 'kn';

  String _t(String en, String kn) => _kn ? kn : en;

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_languageChanged);
  }

  void _languageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    appLanguage.removeListener(_languageChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggested]) async {
    final text = (suggested ?? _controller.text).trim();

    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final answer = await _service.sendMessage(text);

      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(text: answer, isUser: false),
        );
      });
    } catch (e, stackTrace) {
      debugPrint('Farming Assistant error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            text: _t(
              'Sorry, I could not get a response. Please check your internet connection and try again.',
              'ಕ್ಷಮಿಸಿ, ಉತ್ತರ ಪಡೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
            ),
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _kn
        ? <String>[
            'ಟೊಮೇಟೊ ಎಲೆಗಳಲ್ಲಿ ಹಳದಿ ಕಲೆಗಳು ಏಕೆ ಬರುತ್ತವೆ?',
            'ಬೆಳೆಗೆ ಎಷ್ಟು ಬಾರಿ ನೀರು ಹಾಕಬೇಕು?',
            'ಸಸ್ಯ ರೋಗಗಳನ್ನು ತಡೆಯುವುದು ಹೇಗೆ?',
          ]
        : <String>[
            'Why are there yellow spots on tomato leaves?',
            'How often should I water my crop?',
            'How can I prevent plant diseases?',
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(
            'Agro AI Farming Assistant',
            'ಅಗ್ರೋ AI ಕೃಷಿ ಸಹಾಯಕ',
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_messages.isEmpty)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.agriculture,
                          size: 54,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        _t(
                          'How can I help your farm?',
                          'ನಿಮ್ಮ ಕೃಷಿಗೆ ನಾನು ಹೇಗೆ ಸಹಾಯ ಮಾಡಲಿ?',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _t(
                          'Ask about crop care, diseases, irrigation, or soil health.',
                          'ಬೆಳೆ ಆರೈಕೆ, ರೋಗಗಳು, ನೀರಾವರಿ ಅಥವಾ ಮಣ್ಣಿನ ಆರೋಗ್ಯದ ಬಗ್ಗೆ ಕೇಳಿ.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      _t('Try asking', 'ಇದನ್ನು ಕೇಳಿ'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final question in suggestions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: OutlinedButton(
                          onPressed:
                              _sending ? null : () => _send(question),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            minimumSize:
                                const Size(double.infinity, 48),
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(question),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_sending && index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final message = _messages[index];

                  return Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.sizeOf(context).width * 0.82,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Colors.green.shade700
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: message.isUser
                          ? SelectableText(
                              message.text,
                              style: const TextStyle(
                                height: 1.4,
                                color: Colors.white,
                              ),
                            )
                          : MarkdownBody(
                              data: message.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                                h1: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                h2: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                h3: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                listBullet: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                                blockquote: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _t(
                          'Ask a farming question...',
                          'ಕೃಷಿ ಪ್ರಶ್ನೆಯನ್ನು ಕೇಳಿ...',
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : () => _send(),
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(50, 50),
                    ),
                    tooltip: _t(
                      'Send message',
                      'ಸಂದೇಶ ಕಳುಹಿಸಿ',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
