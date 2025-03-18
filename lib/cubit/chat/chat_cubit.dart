// chat_cubit.dart
import 'dart:async';
import 'package:ai_assistent_bluetooth/cubit/chat/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_assistent_bluetooth/models/chat_message.dart';
import 'package:ai_assistent_bluetooth/services/chat_gpt_service.dart';


class ChatCubit extends Cubit<ChatState> {
  final ChatGptService chatGptService;
  final String? errorCode;
  final String errorMessage;

  ChatCubit({
    required this.chatGptService,
    this.errorCode,
    required this.errorMessage,
  }) : super(const ChatState(isWaitingForAi: true, statusMessage: "Thinking...")) {
    _initChat();
  }

  Future<void> _initChat() async {
    // Costruiamo il prompt combinando codice e descrizione dell'errore
    final prompt = _buildPrompt(errorCode, errorMessage);
    try {
      final aiResponse = await chatGptService.getResponse(prompt);
      addMessage(ChatMessage(message: aiResponse, isSentByUser: false));
    } catch (e) {
      addMessage(ChatMessage(message: "Errore nel recupero della risposta: $e", isSentByUser: false));
    } finally {
      emit(state.copyWith(isWaitingForAi: false, statusMessage: "Ready"));
    }
  }

  String _buildPrompt(String? code, String message) {
    if (code != null && code.isNotEmpty) {
      return "Errore $code: $message. Fornisci istruzioni dettagliate su come risolvere questo errore.";
    } else {
      return "$message. Fornisci istruzioni dettagliate su come risolvere questo errore.";
    }
  }

  void addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(state.messages)..add(message);
    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> sendMessage(String text) async {
    // Aggiunge il messaggio dell'utente
    addMessage(ChatMessage(message: text, isSentByUser: true));
    // Mostra lo stato "thinking" in attesa della risposta AI
    emit(state.copyWith(isWaitingForAi: true, statusMessage: "Thinking..."));
    try {
      final aiResponse = await chatGptService.getResponse(text);
      addMessage(ChatMessage(message: aiResponse, isSentByUser: false));
    } catch (e) {
      addMessage(ChatMessage(message: "Errore nel recupero della risposta: $e", isSentByUser: false));
    } finally {
      emit(state.copyWith(isWaitingForAi: false, statusMessage: "Ready"));
    }
  }
}
