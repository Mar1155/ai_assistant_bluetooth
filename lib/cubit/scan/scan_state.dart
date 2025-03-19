import 'package:ai_assistent_bluetooth/models/device_message.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

class ScanState {
  final bool isScanning;
  final bool isConnecting;
  final bool isConnected;
  final String statusMessage;
  final BluetoothDevice? device;
  final List<ParameterData> parameters;
  final List<ErrorData> errorList;

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
    List<ParameterData>? parameters,
    List<ErrorData>? errorList,
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