import 'dart:async';
import 'dart:developer';

import 'package:ai_assistent_bluetooth/cubit/scan/scan_state.dart';
import 'package:ai_assistent_bluetooth/utils/extra.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanCubit extends Cubit<ScanState> {
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;

  ScanCubit() : super(ScanState()) {
    startScan();
  }

  Future<void> startScan() async {
    emit(ScanState(isScanning: true, statusMessage: "Scanning..."));

    // Cancel existing subscription
    await _scanResultsSubscription?.cancel();

    // Set up scan results listener
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) async {
        log("${results.length} devices found");
        for (final result in results) {
          log(result.device.toString());
          if (result.device.platformName == "ESP32_BLE") {
            await FlutterBluePlus.stopScan();
            emit(
              ScanState(
                isScanning: false,
                device: result.device,
                statusMessage: "Device found. Connecting...",
              ),
            );
            try {
              await result.device.connectAndUpdateStream();
              emit(
                ScanState(
                  isScanning: false,
                  device: result.device,
                  isConnected: true,
                  statusMessage: "Connected",
                ),
              );
            } catch (e) {
              log(e.toString());
              emit(
                ScanState(
                  isScanning: false,
                  device: result.device,
                  isConnected: false,
                  statusMessage: "Connection failed: $e",
                ),
              );
            }
            await _scanResultsSubscription?.cancel();
            return;
          }
        }
      },
      onError: (error) {
        log(error.toString());
        emit(ScanState(isScanning: false, statusMessage: "Scan error: $error"));
      },
    );

    log("start scanning...");

    try {
      // Start the scan and WAIT for it to complete
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      // This will only execute AFTER the scan completes (5 seconds)
      log("scan completed");

      // If we get here and no device was found, emit the not found state
      if (state.device == null) {
        emit(
          const ScanState(
            isScanning: false,
            statusMessage: "Device not found",
            isConnected: false,
          ),
        );
      }
    } catch (e) {
      log(e.toString());
      emit(ScanState(isScanning: false, statusMessage: "Start Scan Error: $e"));
    }
  }

  Future<void> retry() async {
    startScan();
  }

  Future<void> disconnectFromAllDevices() async {
    try {
      // Ottieni tutti i dispositivi connessi
      List<BluetoothDevice> connectedDevices =
          await FlutterBluePlus.connectedDevices;

      if (connectedDevices.isEmpty) {
        emit(
          ScanState(
            isScanning: false,
            isConnected: false,
            statusMessage: "No connected devices",
          ),
        );
        return;
      }

      // Disconnettiti da ogni dispositivo
      for (final device in connectedDevices) {
        try {
          log("Disconnecting from ${device.platformName}...");
          await device.disconnect();
          log("Disconnected from ${device.platformName}");
        } catch (e) {
          log("Error disconnecting from ${device.platformName}: $e");
        }
      }

      // Aggiorna lo stato
      emit(
        ScanState(
          isScanning: false,
          isConnected: false,
          statusMessage: "Disconnected from all devices",
        ),
      );
    } catch (e) {
      log("Error during disconnection: $e");
      emit(
        ScanState(isScanning: false, statusMessage: "Disconnection error: $e"),
      );
    }
  }

  @override
  Future<void> close() {
    _scanResultsSubscription?.cancel();
    return super.close();
  }
}
