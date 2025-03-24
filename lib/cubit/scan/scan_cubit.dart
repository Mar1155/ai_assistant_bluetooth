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
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _notificationSubscription;
  Timer? _scanTimeoutTimer;
  Timer? _connectionTimeoutTimer;
  BluetoothConnection? _connection;

  // Costanti configurabili
  static const String _deviceName = "ESP32_BT";
  static const Duration _scanTimeout = Duration(seconds: 10);
  static const Duration _connectionTimeout = Duration(seconds: 8);
  static const Duration _reconnectDelay = Duration(seconds: 2);

  ScanCubit() : super(ScanState()) {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      // Verifica lo stato Bluetooth
      final adapterState = await _flutterBlueClassicPlugin.adapterStateNow;
      if (adapterState != BluetoothAdapterState.on) {
        emit(
          ScanState(
            statusMessage: AppStrings.bluetoothDisabled,
            isBluetoothEnabled: false,
          ),
        );
        return;
      }

      // Verifica se ci sono dispositivi già connessi
      final bondedDevices = await _flutterBlueClassicPlugin.bondedDevices;
      final targetDevice = bondedDevices?.firstWhere(
        (device) => device.name == _deviceName,
      );

      if (targetDevice != null) {
        emit(
          ScanState(
            statusMessage: AppStrings.deviceAlreadyConnected,
            isConnected: false,
            device: targetDevice,
          ),
        );
        // Prova a connettersi a un dispositivo già associato
        _connectToDevice(targetDevice);
      } else {
        // Avvia la scansione se non ci sono dispositivi connessi
        startScan();
      }
    } catch (e) {
      log("Errore durante il controllo dello stato iniziale: $e");
      emit(ScanState(statusMessage: "${AppStrings.initializationError}: $e"));
    }
  }

  Future<void> startScan() async {
    try {
      log("start scanning...");
      await _cancelExistingOperations();

      emit(
        ScanState(
          isScanning: true,
          statusMessage: AppStrings.scanningForDevices,
          isBluetoothEnabled: true,
        ),
      );

      // Verifica se il Bluetooth è attivo
      final adapterState = await _flutterBlueClassicPlugin.adapterStateNow;
      if (adapterState != BluetoothAdapterState.on) {
        emit(
          ScanState(
            isScanning: false,
            statusMessage: AppStrings.bluetoothDisabled,
            isBluetoothEnabled: false,
          ),
        );
        return;
      }

      _setupScanTimeoutTimer();
      _setupScanResultsListener();

      _flutterBlueClassicPlugin.startScan();
      log("Scansione avviata");
    } catch (e) {
      log("Errore durante l'avvio della scansione: $e");
      emit(
        ScanState(
          isScanning: false,
          statusMessage: "${AppStrings.scanError}: $e",
          isBluetoothEnabled: true,
        ),
      );
    }
  }

  void _setupScanTimeoutTimer() {
    _scanTimeoutTimer = Timer(_scanTimeout, () {
      if (state.isScanning) {
        _flutterBlueClassicPlugin.stopScan();
        emit(
          ScanState(
            isScanning: false,
            statusMessage: AppStrings.scanTimeoutMessage,
            isBluetoothEnabled: true,
          ),
        );
        log("Timeout scansione");
      }
    });
  }

  void _setupScanResultsListener() {
    _scanResultsSubscription = _flutterBlueClassicPlugin.scanResults.listen(
      (device) async {
        log("Dispositivo trovato: ${device.name}");
        if (device.name == _deviceName) {
          log("Dispositivo target trovato: ${device.name}");
          _flutterBlueClassicPlugin.stopScan();
          _scanTimeoutTimer?.cancel();

          emit(
            ScanState(
              isScanning: false,
              isConnecting: true,
              statusMessage: "${AppStrings.deviceFound}: ${device.name}",
              device: device,
              isBluetoothEnabled: true,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          await _connectToDevice(device);
        }
      },
      onError: (error) {
        log("Errore durante la scansione: $error");
        emit(
          ScanState(
            isScanning: false,
            statusMessage: "${AppStrings.scanError}: $error",
            isBluetoothEnabled: true,
          ),
        );
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }

    emit(
      ScanState(
        isConnecting: true,
        device: device,
        statusMessage: "${AppStrings.connectingToDevice}: ${device.name}",
        isBluetoothEnabled: true,
      ),
    );

    _setupConnectionTimeoutTimer(device);

    try {
      log("Tentativo di connessione a ${device.name} (${device.address})");
      _connection = await _flutterBlueClassicPlugin.connect(device.address);

      if (_connection == null) {
        throw Exception("Connessione fallita");
      }

      _connectionTimeoutTimer?.cancel();

      log("Connessione stabilita con ${device.name}");
      emit(
        ScanState(
          isConnected: true,
          isConnecting: false,
          device: device,
          statusMessage: "${AppStrings.connectionSuccessful}: ${device.name}",
          isBluetoothEnabled: true,
        ),
      );

      _setupConnectionStateMonitoring();
      _setupDataListener();
    } catch (e) {
      _connectionTimeoutTimer?.cancel();
      log("Errore di connessione: $e");
      String errorMessage = _getUserFriendlyErrorMessage(e);

      emit(
        ScanState(
          isConnecting: false,
          isConnected: false,
          device: null,
          statusMessage: errorMessage,
          isBluetoothEnabled: true,
        ),
      );
    }
  }

  void _setupConnectionTimeoutTimer(BluetoothDevice device) {
    _connectionTimeoutTimer = Timer(_connectionTimeout, () {
      if (state.isConnecting && !state.isConnected) {
        log("Timeout della connessione a ${device.name}");
        emit(
          ScanState(
            isConnecting: false,
            isConnected: false,
            device: device,
            statusMessage: "${AppStrings.connectionTimeout}: ${device.name}",
            isBluetoothEnabled: true,
          ),
        );
      }
    });
  }

  void _setupConnectionStateMonitoring() {
    // Implementare il monitoraggio della connessione se supportato dal plugin
    // Per ora, usiamo un timer periodico per verificare lo stato dei dispositivi associati
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!state.isConnected) {
        timer.cancel();
        return;
      }

      try {
        final bondedDevices = await _flutterBlueClassicPlugin.bondedDevices;
        final isStillConnected =
            bondedDevices?.any((device) => device.name == _deviceName) ?? false;

        if (!isStillConnected && state.isConnected) {
          log("Rilevata disconnessione per ${_deviceName}");
          handleDisconnection("Disconnessione rilevata");
        }
      } catch (e) {
        log("Errore durante il controllo dello stato di connessione: $e");
      }
    });
  }

  void _setupDataListener() {
    if (_connection == null || _connection!.input == null) {
      log("Impossibile configurare l'ascolto dei dati: connessione non valida");
      return;
    }

    log("Configurazione dell'ascolto dei dati in corso...");
    _notificationSubscription = _connection!.input!.listen(
      (data) {
        final message = String.fromCharCodes(data);
        log("Dati ricevuti: $message");
        _processIncomingMessage(message);
      },
      onError: (error) {
        log("Errore nella ricezione dei dati: $error");
        handleDisconnection("Errore nella comunicazione");
      },
      onDone: () {
        log("Stream di dati terminato");
        handleDisconnection("Connessione chiusa dal dispositivo");
      },
    );
  }

  void _processIncomingMessage(String message) {
    try {
      if (message == null || message.isEmpty || message == "" || message == " ")
        return;

      log("Elaborazione messaggio: $message");
      final jsonData = jsonDecode(message) as Map<String, dynamic>;
      final deviceData = DeviceData.fromJson(jsonData);

      emit(
        state.copyWith(
          errorList: deviceData.errors,
          parameters: deviceData.parameters,
          lastUpdateTime: DateTime.now(),
        ),
      );

      if (deviceData.errors.isNotEmpty) {
        log("Errori rilevati: ${deviceData.errors.length}");
      }
    } on FormatException catch (e) {
      // log("Errore nel parsing del messaggio JSON: $e");
      // log("Messaggio non valido: $message");
    } catch (e) {
      log("Errore nell'elaborazione del messaggio: $e");
    }
  }

  void handleDisconnection(String reason) {
    log("Gestione disconnessione: $reason");

    if (!state.isConnected) return;

    emit(
      state.copyWith(
        isConnected: false,
        statusMessage: "${AppStrings.deviceDisconnected}: $reason",
      ),
    );

    _cleanupConnection();

    // Tentativo di riconnessione automatica
    if (state.device != null) {
      _scheduleReconnection();
    }
  }

  void _scheduleReconnection() {
    log("Pianificazione tentativo di riconnessione");
    emit(state.copyWith(statusMessage: AppStrings.attemptingReconnection));

    Future.delayed(_reconnectDelay, () {
      if (!state.isConnected && !state.isConnecting && state.device != null) {
        log("Tentativo di riconnessione a ${state.device!.name}");
        _connectToDevice(state.device!);
      }
    });
  }

  void _cleanupConnection() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;

    _connection
        ?.close()
        .then((_) {
          _connection = null;
          log("Connessione chiusa");
        })
        .catchError((e) {
          log("Errore durante la chiusura della connessione: $e");
          _connection = null;
        });
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains("timeout")) {
      return AppStrings.connectionTimeout;
    } else if (errorString.contains("permission")) {
      return AppStrings.bluetoothPermissionError;
    } else if (errorString.contains("bluetooth") &&
        errorString.contains("disabled")) {
      return AppStrings.bluetoothDisabled;
    } else if (errorString.contains("device") &&
        errorString.contains("not") &&
        errorString.contains("found")) {
      return AppStrings.deviceNotFound;
    } else if (errorString.contains("socket") ||
        errorString.contains("connection")) {
      return "AppStrings.connectionIssue";
    } else {
      return "${AppStrings.connectionFailed}: $error";
    }
  }

  Future<void> retry() async {
    log("Tentativo di riconnessione manuale");
    await _cancelExistingOperations();
    startScan();
  }

  Future<void> reconnect() async {
    if (state.device != null) {
      log("Tentativo di riconnessione al dispositivo ${state.device!.name}");
      await _cancelExistingOperations();
      await _connectToDevice(state.device!);
    } else {
      retry();
    }
  }

  Future<void> disconnectDevice() async {
    log("Disconnessione manuale richiesta");
    await _cancelExistingOperations();

    emit(
      ScanState(
        statusMessage: AppStrings.manualDisconnection,
        isBluetoothEnabled: true,
      ),
    );
  }

  Future<void> _cancelExistingOperations() async {
    log("Pulizia delle operazioni esistenti");

    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;

    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;

    await _scanResultsSubscription?.cancel();
    _scanResultsSubscription = null;

    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;

    await _notificationSubscription?.cancel();
    _notificationSubscription = null;

    _cleanupConnection();

    try {
      if (await _flutterBlueClassicPlugin.isScanningNow) {
        _flutterBlueClassicPlugin.stopScan();
        log("Scansione interrotta");
      }
    } catch (e) {
      log("Errore durante l'interruzione della scansione: $e");
    }
  }

  @override
  Future<void> close() async {
    log("Chiusura del ScanCubit");
    await _cancelExistingOperations();
    return super.close();
  }
}
