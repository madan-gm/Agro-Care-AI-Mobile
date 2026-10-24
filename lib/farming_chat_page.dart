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
  const _ChatMessage({required this.text, required this.isUser});

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
      setState(() => _messages.add(_ChatMessage(text: answer, isUser: false)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: _t(
              'Sorry, I could not get a response. Check your internet connection and Firebase AI Logic setup, then try again.',
              'à²•à³à²·à²®à²¿à²¸à²¿, à²‰à²¤à³à²¤à²° à²ªà²¡à³†à²¯à²²à³ à²¸à²¾à²§à³à²¯à²µà²¾à²—à²²à²¿à²²à³à²². à²‡à²‚à²Ÿà²°à³à²¨à³†à²Ÿà³ à²¸à²‚à²ªà²°à³à²• à²®à²¤à³à²¤à³ Firebase AI Logic à²¸à³†à²Ÿà²ªà³ à²ªà²°à²¿à²¶à³€à²²à²¿à²¸à²¿ à²®à²¤à³à²¤à³† à²ªà³à²°à²¯à²¤à³à²¨à²¿à²¸à²¿.',
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
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _kn
        ? <String>[
            'à²Ÿà³Šà²®à³‡à²Ÿà³Š à²Žà²²à³†à²—à²³à²²à³à²²à²¿ à²¹à²³à²¦à²¿ à²•à²²à³†à²—à²³à³ à²à²•à³† à²¬à²°à³à²¤à³à²¤à²µà³†?',
            'à²¬à³†à²³à³†à²—à³† à²Žà²·à³à²Ÿà³ à²¬à²¾à²°à²¿ à²¨à³€à²°à³ à²¹à²¾à²•à²¬à³‡à²•à³?',
            'à²¸à²¸à³à²¯ à²°à³‹à²—à²—à²³à²¨à³à²¨à³ à²¤à²¡à³†à²¯à³à²µà³à²¦à³ à²¹à³‡à²—à³†?',
          ]
        : <String>[
            'Why are there yellow spots on tomato leaves?',
            'How often should I water my crop?',
            'How can I prevent plant diseases?',
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Agro AI Farming Assistant', 'à²…à²—à³à²°à³‹ AI à²•à³ƒà²·à²¿ à²¸à²¹à²¾à²¯à²•')),
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
                        _t('How can I help your farm?', 'à²¨à²¿à²®à³à²® à²•à³ƒà²·à²¿à²—à³† à²¨à²¾à²¨à³ à²¹à³‡à²—à³† à²¸à²¹à²¾à²¯ à²®à²¾à²¡à²²à²¿?'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _t(
                          'Ask about crop care, diseases, irrigation, or soil health.',
                          'à²¬à³†à²³à³† à²†à²°à³ˆà²•à³†, à²°à³‹à²—à²—à²³à³, à²¨à³€à²°à²¾à²µà²°à²¿ à²…à²¥à²µà²¾ à²®à²£à³à²£à²¿à²¨ à²†à²°à³‹à²—à³à²¯à²¦ à²¬à²—à³à²—à³† à²•à³‡à²³à²¿.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      _t('Try asking', 'à²‡à²¦à²¨à³à²¨à³ à²•à³‡à²³à²¿'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    for (final question in suggestions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: OutlinedButton(
                          onPressed: _sending ? null : () => _send(question),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            minimumSize: const Size(double.infinity, 48),
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
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const SizedBox(
                          height: 18,
                          width: 38,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
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
                        maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: message.isUser ? Colors.green.shade700 : Colors.grey.shade100,
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
                          horizontalRuleDecoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
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
                        hintText: _t('Ask a farming question...', 'à²•à³ƒà²·à²¿ à²ªà³à²°à²¶à³à²¨à³†à²¯à²¨à³à²¨à³ à²•à³‡à²³à²¿...'),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
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
                    tooltip: _t('Send message', 'à²¸à²‚à²¦à³‡à²¶ à²•à²³à³à²¹à²¿à²¸à²¿'),
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
