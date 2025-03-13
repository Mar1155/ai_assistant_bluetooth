import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Stato della scansione/connessione
class ScanState extends Equatable {
  final bool isScanning;
  final bool isConnecting;
  final BluetoothDevice? device;
  final bool isConnected;
  final String statusMessage;

  const ScanState({
    this.isScanning = false,
    this.isConnecting= false,
    this.device,
    this.isConnected = false,
    this.statusMessage = "",
  });

  ScanState copyWith({
    bool? isScanning,
    bool? isConnecting,
    BluetoothDevice? device,
    bool? isConnected,
    String? statusMessage,
  }) {
    return ScanState(
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting?? this.isConnecting,
      device: device ?? this.device,
      isConnected: isConnected ?? this.isConnected,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  String toString() {
    return 'ScanState(isScanning: $isScanning, device: ${device?.platformName}, isConnected: $isConnected, statusMessage: $statusMessage)';
  }
  
  @override
  List<Object?> get props => [device, isScanning, isConnected, statusMessage];
}