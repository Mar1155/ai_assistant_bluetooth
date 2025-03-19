// scan_cubit.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_state.dart';
import 'package:ai_assistent_bluetooth/localization/string_localization.dart';
import 'package:ai_assistent_bluetooth/models/device_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

class ScanCubit extends Cubit<ScanState> {
  final FlutterBlueClassic _flutterBlueClassicPlugin = FlutterBlueClassic();

  StreamSubscription? _scanResultsSubscription;
  Timer? _scanTimeoutTimer;
  StreamSubscription? _notificationSubscription;

  // Costanti configurabili
  static const String _deviceName = "ESP32_BT";
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
      _flutterBlueClassicPlugin.startScan();
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
        _flutterBlueClassicPlugin.stopScan();
        if (state.device == null) {
          emit(const ScanState(statusMessage: AppStrings.scanTimeoutMessage));
        }
      }
    });
  }

  void _setupScanResultsListener() {
    _scanResultsSubscription = _flutterBlueClassicPlugin.scanResults.listen(
      (device) async {
        log("Dispositivo ${device.name} == $_deviceName");
        if (device.name == _deviceName) {
          emit(
            ScanState(
              isConnecting: true,
              statusMessage: AppStrings.connectingToDevice,
            ),
          );
          await _connectToDevice(device);
        }
      },
      onError: (error) {
        log("Errore durante la scansione: $error");
        emit(ScanState(statusMessage: "${AppStrings.scanError}: $error"));
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _flutterBlueClassicPlugin.stopScan();
    emit(
      ScanState(
        isScanning: false,
        device: device,
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
              device: device,
              isConnected: false,
              statusMessage: AppStrings.connectionTimeout,
            ),
          );
        }
      });

      // Connessione tramite Bluetooth Classico
      BluetoothConnection? connection = await _flutterBlueClassicPlugin.connect(
        device.address,
      );
      connectionCompleted = true;

      // Sottoscrizione al flusso di dati in ingresso
      _notificationSubscription = connection!.input!.listen((data) {
        final message = String.fromCharCodes(data);
        _processIncomingMessage(message);
      });

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
          device: null,
          isConnected: false,
          statusMessage: errorMessage,
        ),
      );
    }

    await _scanResultsSubscription?.cancel();
    _scanResultsSubscription = null;
  }

  void _processIncomingMessage(String message) {
    try {
      if (message.isEmpty) return;
      final jsonData = jsonDecode(message) as Map<String, dynamic>;
      final deviceData = DeviceData.fromJson(jsonData);

      final updatedErrors = deviceData.errors;
      final updatedParameters = deviceData.parameters;
      emit(
        state.copyWith(errorList: updatedErrors, parameters: updatedParameters),
      );
    } on FormatException catch (e) {
      log("Errore nel parsing del messaggio JSON: $e");
      log("text: ${message}");
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

  Future<void> disconnected() async {
    emit(ScanState(device: null));
  }

  Future<void> disconnectFromAllDevices() async {
    try {
      List<BluetoothDevice>? connectedDevices =
          await _flutterBlueClassicPlugin.bondedDevices;
      if (connectedDevices!.isEmpty) {
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
          log("Disconnessione da ${device.name}...");
          // await _flutterBlueClassicPlugin.disconnectAndUpdateStream();
          log("Disconnesso da ${device.name}");
        } catch (e) {
          log("Errore durante la disconnessione da ${device.name}: $e");
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
    if (await _flutterBlueClassicPlugin.isScanningNow) {
      _flutterBlueClassicPlugin.stopScan();
    }
  }

  @override
  Future<void> close() async {
    await _cancelExistingOperations();
    await _notificationSubscription?.cancel();
    return super.close();
  }
}
