import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanState {
  final bool isScanning;
  final bool isConnecting;
  final bool isConnected;
  final String statusMessage;
  final BluetoothDevice? device;
  final List<Map<String, dynamic>> parameters;
  final List<Map<String, dynamic>> errorList;

  const ScanState({
    this.isScanning = false,
    this.isConnecting = false,
    this.isConnected = false,
    this.statusMessage = "",
    this.device,
    this.parameters = const [],
    this.errorList = const [],
  });

  ScanState copyWith({
    bool? isScanning,
    bool? isConnecting,
    bool? isConnected,
    String? statusMessage,
    BluetoothDevice? device,
    List<Map<String, dynamic>>? parameters,
    List<Map<String, dynamic>>? errorList,
  }) {
    return ScanState(
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      statusMessage: statusMessage ?? this.statusMessage,
      device: device ?? this.device,
      parameters: parameters ?? this.parameters,
      errorList: errorList ?? this.errorList,
    );
  }
}