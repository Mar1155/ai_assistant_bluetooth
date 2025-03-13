// lib/cubit/chat/chat_state.dart
import 'package:ai_assistent_bluetooth/models/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isConnecting;
  final bool isConnected;
  final String statusMessage;
  final MachineData? machineData;
  final String machineStatus;

  const ChatState({
    this.messages = const [],
    this.isConnecting = false,
    this.isConnected = false,
    this.statusMessage = "",
    this.machineData,
    this.machineStatus = "Unknown",
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isConnecting,
    bool? isConnected,
    String? statusMessage,
    MachineData? machineData,
    String? machineStatus,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      statusMessage: statusMessage ?? this.statusMessage,
      machineData: machineData ?? this.machineData,
      machineStatus: machineStatus ?? this.machineStatus,
    );
  }
}