import 'dart:async';

import 'package:ai_assistent_bluetooth/cubit/chat/chat_state.dart';
import 'package:ai_assistent_bluetooth/models/chat_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ChatCubit extends Cubit<ChatState> {
  final BluetoothDevice _device;
  BluetoothCharacteristic? _chatCharacteristic;
  StreamSubscription? _notificationSubscription;

  ChatCubit({required BluetoothDevice device})
      : _device = device,
        super(const ChatState(isConnecting: true, statusMessage: "Connecting...")) {
    _connectAndDiscover();
  }

  Future<void> _connectAndDiscover() async {
    try {
      await _device.connect();
    } catch (e) {
      // Il dispositivo potrebbe già essere connesso
    }
    emit(state.copyWith(isConnected: true, isConnecting: false, statusMessage: "Connected. Discovering services..."));

    List<BluetoothService> services = await _device.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString().toUpperCase().contains("FFE0")) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase().contains("FFE1")) {
            _chatCharacteristic = characteristic;
            await _chatCharacteristic!.setNotifyValue(true);
            _notificationSubscription = _chatCharacteristic!.onValueReceived.listen((value) {
              String message = String.fromCharCodes(value);
              addMessage(ChatMessage(message: message, isSentByUser: false));
            });
          }
        }
      }
    }
    emit(state.copyWith(statusMessage: "Ready"));
  }

  void addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(state.messages)..add(message);
    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> sendMessage(String text) async {
    if (_chatCharacteristic == null) return;
    List<int> bytes = text.codeUnits;
    try {
      await _chatCharacteristic!.write(bytes);
      addMessage(ChatMessage(message: text, isSentByUser: true));
    } catch (e) {
      print("Errore nell'invio del messaggio: $e");
    }
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
