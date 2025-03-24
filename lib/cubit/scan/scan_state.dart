// scan_state.dart
import 'package:ai_assistent_bluetooth/models/device_message.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

class ScanState {
  final bool isScanning;
  final bool isConnecting;
  final bool isConnected;
  final bool isBluetoothEnabled;
  final String statusMessage;
  final BluetoothDevice? device;
  final List<ParameterData> parameters;
  final List<ErrorData> errorList;
  final DateTime? lastUpdateTime;
  final int reconnectAttempts;

  const ScanState({
    this.isScanning = false,
    this.isConnecting = false,
    this.isConnected = false,
    this.isBluetoothEnabled = true,
    this.statusMessage = "",
    this.device,
    this.parameters = const [],
    this.errorList = const [],
    this.lastUpdateTime,
    this.reconnectAttempts = 0,
  });

  ScanState copyWith({
    bool? isScanning,
    bool? isConnecting,
    bool? isConnected,
    bool? isBluetoothEnabled,
    String? statusMessage,
    BluetoothDevice? device,
    List<ParameterData>? parameters,
    List<ErrorData>? errorList,
    DateTime? lastUpdateTime,
    int? reconnectAttempts,
  }) {
    return ScanState(
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isBluetoothEnabled: isBluetoothEnabled ?? this.isBluetoothEnabled,
      statusMessage: statusMessage ?? this.statusMessage,
      device: device ?? this.device,
      parameters: parameters ?? this.parameters,
      errorList: errorList ?? this.errorList,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}