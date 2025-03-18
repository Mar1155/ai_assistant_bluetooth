// scan_cubit.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_state.dart';
import 'package:ai_assistent_bluetooth/localization/string_localization.dart';
import 'package:ai_assistent_bluetooth/models/device_message.dart';
import 'package:ai_assistent_bluetooth/utils/extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

class ScanCubit extends Cubit<ScanState> {
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  Timer? _scanTimeoutTimer;
  StreamSubscription? _notificationSubscription;

  // Costanti configurabili
  static const String _deviceName = "ESP32_BLE";
  static const Duration _scanTimeout = Duration(seconds: 10);
  static const Duration _connectionTimeout = Duration(seconds: 8);

  ScanCubit() : super(ScanState()) {
    startScan();
  }

  Future<void> startScan() async {
    await _cancelExistingOperations();
    emit(
      ScanState(isScanning: true, statusMessage: AppStrings.scanningForDevices),
    );
    await Future.delayed(Duration(seconds: 1));

    _setupScanTimeoutTimer();
    _setupScanResultsListener();

    try {
      await FlutterBluePlus.startScan(timeout: _scanTimeout);
      log("Scansione completata");
      if (state.device == null && state.isScanning) {
        emit(
          const ScanState(
            isScanning: false,
            isConnecting: false,
            statusMessage: AppStrings.deviceNotFound,
            isConnected: false,
          ),
        );
      }
    } catch (e) {
      log("Errore durante l'avvio della scansione: $e");
      emit(
        ScanState(
          isScanning: false,
          statusMessage: "${AppStrings.scanError}: $e",
        ),
      );
    }
  }

  void _setupScanTimeoutTimer() {
    _scanTimeoutTimer = Timer(_scanTimeout, () {
      if (state.isScanning) {
        FlutterBluePlus.stopScan();
        if (state.device == null) {
          emit(
            const ScanState(
              isScanning: false,
              statusMessage: AppStrings.scanTimeoutMessage,
              isConnected: false,
            ),
          );
        }
      }
    });
  }

  void _setupScanResultsListener() {
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) async {
        log("${results.length} dispositivi trovati");
        final targetDevice =
            results
                .where((result) => result.device.platformName == _deviceName)
                .firstOrNull;

        if (targetDevice != null) {
          emit(
            ScanState(
              isConnecting: true,
              statusMessage: AppStrings.connectingToDevice,
            ),
          );
          await _connectToDevice(targetDevice);
        }
      },
      onError: (error) {
        log("Errore durante la scansione: $error");
        emit(
          ScanState(
            isScanning: false,
            statusMessage: "${AppStrings.scanError}: $error",
          ),
        );
      },
    );
  }

  Future<void> _connectToDevice(ScanResult result) async {
    await FlutterBluePlus.stopScan();
    emit(
      ScanState(
        isScanning: false,
        device: result.device,
        statusMessage: AppStrings.connectingToDevice,
      ),
    );

    try {
      bool connectionCompleted = false;
      Timer(_connectionTimeout, () {
        if (!connectionCompleted) {
          log("Timeout della connessione");
          emit(
            ScanState(
              isScanning: false,
              device: result.device,
              isConnected: false,
              statusMessage: AppStrings.connectionTimeout,
            ),
          );
        }
      });

      await result.device.connectAndUpdateStream();
      connectionCompleted = true;

      // Dopo la connessione, avvia il discovery dei servizi e sottoscriviti alle notifiche
      List<BluetoothService> services = await result.device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase().contains("FFE0")) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase().contains("FFE1")) {
              await characteristic.setNotifyValue(true);
              _notificationSubscription = characteristic.onValueReceived.listen(
                (value) {
                  log(value.toString());
                  final message = String.fromCharCodes(value);
                  _processIncomingMessage(message);
                },
              );
            }
          }
        }
      }

      emit(
        state.copyWith(
          isConnected: true,
          statusMessage: AppStrings.connectionSuccessful,
        ),
      );
    } catch (e) {
      log("Errore di connessione: $e");
      String errorMessage = _getUserFriendlyErrorMessage(e);
      emit(
        ScanState(
          isScanning: false,
          device: result.device,
          isConnected: false,
          statusMessage: errorMessage,
        ),
      );
    }

    await _scanResultsSubscription?.cancel();
    _scanResultsSubscription = null;
  }

  void _processIncomingMessage(String message) {
    log("Messaggio ricevuto: ${message}");
    try {
      final jsonData = jsonDecode(message) as Map<String, dynamic>;
      final deviceData = DeviceData.fromJson(jsonData);

      final updatedErrors = List<Map<String, dynamic>>.from(state.errorList);
      for (final error in deviceData.errors) {
        updatedErrors.add({
          "code": error.code,
          "desc": error.message,
          "time": DateFormat('HH:mm').format(DateTime.now()),
        });
      }

      final updatedParameters = List<Map<String, dynamic>>.from(
        state.parameters,
      );
      for (final param in deviceData.parameters) {
        final index = updatedParameters.indexWhere(
          (p) => p["name"] == param.name,
        );
        if (index != -1) {
          updatedParameters[index]["value"] = param.value;
        } else {
          updatedParameters.add({
            "name": param.name,
            "value": param.value,
            "icon": Icons.settings,
          });
        }
      }

      emit(
        state.copyWith(errorList: updatedErrors, parameters: updatedParameters),
      );
    } on FormatException catch (e) {
      log("Errore nel parsing del messaggio JSON: $e");
    } catch (e) {
      log("Errore generico: $e");
    }
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    String errorString = error.toString().toLowerCase();
    if (errorString.contains("timeout")) {
      return AppStrings.connectionTimeout;
    } else if (errorString.contains("permission")) {
      return AppStrings.bluetoothPermissionError;
    } else if (errorString.contains("bluetooth") &&
        errorString.contains("disabled")) {
      return AppStrings.bluetoothDisabled;
    } else {
      return "${AppStrings.connectionFailed}: $error";
    }
  }

  Future<void> retry() async {
    await _cancelExistingOperations();
    startScan();
  }

  Future<void> disconnectFromAllDevices() async {
    try {
      List<BluetoothDevice> connectedDevices =
          await FlutterBluePlus.connectedDevices;
      if (connectedDevices.isEmpty) {
        emit(
          ScanState(
            isScanning: false,
            isConnected: false,
            statusMessage: AppStrings.noConnectedDevices,
          ),
        );
        return;
      }
      for (final device in connectedDevices) {
        try {
          log("Disconnessione da ${device.platformName}...");
          await device.disconnect();
          log("Disconnesso da ${device.platformName}");
        } catch (e) {
          log("Errore durante la disconnessione da ${device.platformName}: $e");
        }
      }
      emit(
        ScanState(
          isScanning: false,
          isConnected: false,
          statusMessage: AppStrings.disconnectedFromDevices,
        ),
      );
    } catch (e) {
      log("Errore durante la disconnessione: $e");
      emit(
        ScanState(
          isScanning: false,
          statusMessage: "${AppStrings.disconnectionError}: $e",
        ),
      );
    }
  }

  Future<void> _cancelExistingOperations() async {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
    await _scanResultsSubscription?.cancel();
    _scanResultsSubscription = null;
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  @override
  Future<void> close() async {
    await _cancelExistingOperations();
    await _notificationSubscription?.cancel();
    return super.close();
  }
}
