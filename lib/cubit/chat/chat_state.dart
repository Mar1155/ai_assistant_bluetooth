



import 'package:ai_assistent_bluetooth/models/chat_message.dart';

/// Stato del ChatCubit
class ChatState {
  final List<ChatMessage> messages;
  final bool isConnecting;
  final bool isConnected;
  final bool isWaitingForAi;
  final String statusMessage;

  const ChatState({
    this.messages = const [],
    this.isConnecting = false,
    this.isConnected = false,
    this.isWaitingForAi = false,
    this.statusMessage = "",
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isConnecting,
    bool? isConnected,
    bool? isWaitingForAi,
    String? statusMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isWaitingForAi: isWaitingForAi ?? this.isWaitingForAi,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
