import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_service.dart';

class ChatMessage {
  const ChatMessage({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;
}

class AiChatState {
  const AiChatState({this.messages = const [], this.loading = false});
  final List<ChatMessage> messages;
  final bool loading;

  AiChatState copyWith({List<ChatMessage>? messages, bool? loading}) {
    return AiChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
    );
  }
}

final aiServiceProvider = Provider<AiService>((ref) => GeminiAiService());

class AiChatNotifier extends Notifier<AiChatState> {
  @override
  AiChatState build() => const AiChatState();

  Future<void> send(String input) async {
    final question = input.trim();
    if (question.isEmpty || state.loading) return;
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: question, fromUser: true),
      ],
      loading: true,
    );

    String answer;
    try {
      answer = await ref.read(aiServiceProvider).ask(question);
    } on AiException catch (error) {
      answer = error.message;
    } catch (_) {
      answer = 'Layanan AI sedang sibuk atau offline. Coba lagi nanti.';
    }

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: answer, fromUser: false),
      ],
      loading: false,
    );
  }
}

final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);
