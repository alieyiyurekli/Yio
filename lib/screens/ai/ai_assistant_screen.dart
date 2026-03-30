import 'package:flutter/material.dart';
import '../../widgets/chat_bubble.dart';
import '../../core/constants/colors.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      content: 'Merhaba! Ben YIO Mutfak Asistanınım. Bugün ne tür bir tarif arıyorsunuz?',
      isUser: false,
    ),
  ];

  final List<String> suggestions = [
    'Ne pişirebilirim?',
    'Vegan tarif öner',
    'Düşük kalorili tarif',
    'Hızlı kahvaltı tarifleri',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(
        content: userMessage,
        isUser: true,
      ));
      _messageController.clear();
    });

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: _generateAIResponse(userMessage),
            isUser: false,
          ));
        });
      }
    });
  }

  String _generateAIResponse(String userMessage) {
    final responses = [
      'Harika bir soru! Size lezzetli ve sağlıklı bir tarif önerebilirim.',
      'Bu konuda birkaç seçeneğim var. Hangi tür yemek tercih ediyorsunuz?',
      'Mükemmel! Size özel olarak tasarlanmış bir tarif hazırlayacağım.',
      'İlginç bir istek! Bunun için en iyi malzemeleri seçeceğim.',
      'Evet, bu mümkün! Adım adım talimatları sizinle paylaşacağım.',
    ];
    return responses[userMessage.length % responses.length];
  }

  void _applySuggestion(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Mutfak Asistanı'),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  message: message.content,
                  isUser: message.isUser,
                );
              },
            ),
          ),

          // Suggestions (only show if no messages except initial)
          if (_messages.length <= 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Öneriler:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    children: suggestions.map((suggestion) {
                      return SuggestionChip(
                        label: suggestion,
                        onTap: () => _applySuggestion(suggestion),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Asistana bir şeyler sor...',
                      hintStyle: const TextStyle(
                        color: AppColors.textLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _messageController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _messageController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _messageController.text.isEmpty
                        ? null
                        : _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;

  ChatMessage({
    required this.content,
    required this.isUser,
  });
}
