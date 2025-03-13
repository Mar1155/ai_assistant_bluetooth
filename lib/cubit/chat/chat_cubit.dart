// lib/cubit/chat/chat_cubit.dart
import 'dart:async';
import 'dart:convert';

import 'package:ai_assistent_bluetooth/cubit/chat/chat_state.dart';
import 'package:ai_assistent_bluetooth/models/chat_message.dart';
import 'package:ai_assistent_bluetooth/services/chatgpt_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ChatCubit extends Cubit<ChatState> {
  final BluetoothDevice _device;
  BluetoothCharacteristic? _chatCharacteristic;
  StreamSubscription? _notificationSubscription;
  final ChatGPTService _chatGPTService = ChatGPTService();
  final MachineManual _machineManual;
  MachineData? _lastMachineData;

  ChatCubit({
    required BluetoothDevice device,
    required MachineManual machineManual,
  })  : _device = device,
        _machineManual = machineManual,
        super(const ChatState(
          isConnecting: true,
          statusMessage: "Connecting to device...",
        )) {
    _connectAndDiscover();
  }

  Future<void> _connectAndDiscover() async {
    try {
      await _device.connect();
    } catch (e) {
      // Device might already be connected
    }
    
    emit(state.copyWith(
      isConnected: true,
      isConnecting: false,
      statusMessage: "Connected. Discovering services...",
    ));

    List<BluetoothService> services = await _device.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString().toUpperCase().contains("FFE0")) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase().contains("FFE1")) {
            _chatCharacteristic = characteristic;
            await _chatCharacteristic!.setNotifyValue(true);
            _notificationSubscription = _chatCharacteristic!.onValueReceived.listen((value) {
              _handleIncomingData(value);
            });
          }
        }
      }
    }
    
    // Send welcome message
    addMessage(ChatMessage(
      message: "Connected to ${_device.platformName}. Monitoring machine status...",
      isSentByUser: false,
    ));
    
    emit(state.copyWith(statusMessage: "Ready"));
  }

  void _handleIncomingData(List<int> data) {
    try {
      final String jsonString = String.fromCharCodes(data);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Parse machine data
      final MachineData machineData = MachineData.fromJson(jsonData);
      _lastMachineData = machineData;
      
      // Update machine status
      emit(state.copyWith(
        machineData: machineData,
        machineStatus: machineData.status,
      ));
      
      // Check for errors
      if (machineData.hasError) {
        _handleMachineError(machineData);
      }
      
      // Add regular status update
      addMessage(ChatMessage(
        message: "Machine status: ${machineData.status}",
        isSentByUser: false,
      ));
      
    } catch (e) {
      // If not valid JSON, treat as regular message
      final String message = String.fromCharCodes(data);
      addMessage(ChatMessage(
        message: message,
        isSentByUser: false,
      ));
    }
  }

  Future<void> _handleMachineError(MachineData machineData) async {
    final String errorCode = machineData.errorCode!;
    final String errorDesc = machineData.errorDescription ?? 
        _machineManual.getErrorDescription(errorCode);
    
    // Show error message
    addMessage(ChatMessage(
      message: "⚠️ Error detected: $errorCode - $errorDesc",
      isSentByUser: false,
      isError: true,
    ));
    
    // Add loading message
    final int loadingMessageIndex = state.messages.length;
    addMessage(ChatMessage(
      message: "Consulting AI assistant for solutions...",
      isSentByUser: false,
      isLoading: true,
    ));
    
    // Get relevant manual section
    final String relevantManualSection = _machineManual.getRelevantSection(errorCode);
    
    // Request AI assistance
    final String aiResponse = await _chatGPTService.getAssistanceForError(
      errorCode: errorCode,
      errorDescription: errorDesc,
      manualText: relevantManualSection,
    );
    
    // Replace loading message with AI response
    final List<ChatMessage> updatedMessages = List<ChatMessage>.from(state.messages);
    updatedMessages.removeAt(loadingMessageIndex);
    emit(state.copyWith(messages: updatedMessages));
    
    // Add AI response
    addMessage(ChatMessage(
      message: aiResponse,
      isSentByUser: false,
    ));
  }

  void addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(state.messages)..add(message);
    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> sendMessage(String text) async {
    if (_chatCharacteristic == null) return;
    
    // Add user message to chat
    addMessage(ChatMessage(
      message: text,
      isSentByUser: true,
    ));
    
    // If message is a command to the machine, send it via BLE
    if (text.startsWith('/')) {
      List<int> bytes = text.codeUnits;
      try {
        await _chatCharacteristic!.write(bytes);
      } catch (e) {
        addMessage(ChatMessage(
          message: "Error sending command: $e",
          isSentByUser: false,
          isError: true,
        ));
      }
      return;
    }
    
    // Otherwise, treat as a question for AI assistant
    // Add loading message
    final int loadingMessageIndex = state.messages.length;
    addMessage(ChatMessage(
      message: "Processing your question...",
      isSentByUser: false,
      isLoading: true,
    ));
    
    // Get AI response
    final String aiResponse = await _chatGPTService.getGeneralAssistance(
      question: text,
      manualText: _machineManual.content,
    );
    
    // Replace loading message
    final List<ChatMessage> updatedMessages = List<ChatMessage>.from(state.messages);
    updatedMessages.removeAt(loadingMessageIndex);
    emit(state.copyWith(messages: updatedMessages));
    
    // Add AI response
    addMessage(ChatMessage(
      message: aiResponse,
      isSentByUser: false,
    ));
  }

  Future<void> disconnect() async {
    await _notificationSubscription?.cancel();
    await _device.disconnect();
    emit(state.copyWith(isConnected: false, statusMessage: "Disconnected"));
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _device.disconnect();
    return super.close();
  }
}