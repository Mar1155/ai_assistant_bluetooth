
import 'package:ai_assistent_bluetooth/models/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isWaitingForAi;
  final String statusMessage;

  const ChatState({
    this.messages = const [],
    this.isWaitingForAi = false,
    this.statusMessage = "",
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isWaitingForAi,
    String? statusMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isWaitingForAi: isWaitingForAi ?? this.isWaitingForAi,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}