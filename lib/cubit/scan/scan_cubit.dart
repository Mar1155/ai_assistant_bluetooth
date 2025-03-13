import 'dart:async';
import 'dart:developer';

import 'package:ai_assistent_bluetooth/cubit/scan/scan_state.dart';
import 'package:ai_assistent_bluetooth/localization/string_localization.dart';
import 'package:ai_assistent_bluetooth/utils/extra.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanCubit extends Cubit<ScanState> {
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  Timer? _scanTimeoutTimer;
  
  // Costanti configurabili
  static const String _deviceName = "ESP32_BLE";
  static const Duration _scanTimeout = Duration(seconds: 10);
  static const Duration _connectionTimeout = Duration(seconds: 8);

  ScanCubit() : super(ScanState()) {
    startScan();
  }

  Future<void> startScan() async {
    // Annulla eventuali processi in corso
    await _cancelExistingOperations();
    
    // Aggiorna lo stato per mostrare l'avvio della scansione
    emit(ScanState(
      isScanning: true, 
      statusMessage: AppStrings.scanningForDevices
    ));
    await Future.delayed(Duration(seconds: 1));

    // Imposta un timer di timeout per la scansione
    _setupScanTimeoutTimer();

    // Configura il listener per i risultati della scansione
    _setupScanResultsListener();

    try {
      await FlutterBluePlus.startScan(timeout: _scanTimeout);
      
      log("Scansione completata");
      // Se arriviamo qui e nessun dispositivo è stato trovato, emettiamo lo stato appropriato
      if (state.device == null && state.isScanning) {
        emit(const ScanState(
          isScanning: false,
          isConnecting: false,
          statusMessage: AppStrings.deviceNotFound,
          isConnected: false,
        ));
      }
    } catch (e) {
      log("Errore durante l'avvio della scansione: $e");
      emit(ScanState(
        isScanning: false, 
        statusMessage: "${AppStrings.scanError}: $e"
      ));
    }
  }

  void _setupScanTimeoutTimer() {
    _scanTimeoutTimer = Timer(_scanTimeout, () {
      if (state.isScanning) {
        FlutterBluePlus.stopScan();
        if (state.device == null) {
          emit(const ScanState(
            isScanning: false,
            statusMessage: AppStrings.scanTimeoutMessage,
            isConnected: false,
          ));
        }
      }
    });
  }

  void _setupScanResultsListener() {
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) async {
        log("${results.length} dispositivi trovati");
        
        // Filtra per trovare solo il dispositivo che ci interessa
        final targetDevice = results.where((result) => 
          result.device.platformName == _deviceName).firstOrNull;
        
        if (targetDevice != null) {
          emit(ScanState(isConnecting: true, statusMessage: AppStrings.connectingToDevice));
          await _connectToDevice(targetDevice);
        }
      },
      onError: (error) {
        log("Errore durante la scansione: $error");
        emit(ScanState(
          isScanning: false, 
          statusMessage: "${AppStrings.scanError}: $error"
        ));
      },
    );
  }

  Future<void> _connectToDevice(ScanResult result) async {
    // Interrompi la scansione una volta trovato il dispositivo
    await FlutterBluePlus.stopScan();
    
    // Aggiorna lo stato per mostrare il tentativo di connessione
    emit(ScanState(
      isScanning: false,
      device: result.device,
      statusMessage: AppStrings.connectingToDevice,
    ));
    
    // Tenta la connessione con timeout
    try {
      // Configura un timeout per la connessione
      bool connectionCompleted = false;
      
      // Avvia un timer per il timeout della connessione
      Timer(
        _connectionTimeout,
        () {
          if (!connectionCompleted) {
            log("Timeout della connessione");
            emit(ScanState(
              isScanning: false,
              device: result.device,
              isConnected: false,
              statusMessage: AppStrings.connectionTimeout,
            ));
          }
        },
      );
      
      // Tenta la connessione
      await result.device.connectAndUpdateStream();
      connectionCompleted = true;
      
      // Se la connessione ha successo, aggiorna lo stato
      emit(ScanState(
        isScanning: false,
        device: result.device,
        isConnected: true,
        statusMessage: AppStrings.connectionSuccessful,
      ));
    } catch (e) {
      log("Errore di connessione: $e");
      
      // Determina un messaggio di errore più user-friendly
      String errorMessage = _getUserFriendlyErrorMessage(e);
      
      emit(ScanState(
        isScanning: false,
        device: result.device,
        isConnected: false,
        statusMessage: errorMessage,
      ));
    }
    
    // Cancella il subscription una volta completata la connessione
    await _scanResultsSubscription?.cancel();
    _scanResultsSubscription = null;
  }
  
  String _getUserFriendlyErrorMessage(dynamic error) {
    String errorString = error.toString().toLowerCase();
    
    if (errorString.contains("timeout")) {
      return AppStrings.connectionTimeout;
    } else if (errorString.contains("permission")) {
      return AppStrings.bluetoothPermissionError;
    } else if (errorString.contains("bluetooth") && errorString.contains("disabled")) {
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
      List<BluetoothDevice> connectedDevices = await FlutterBluePlus.connectedDevices;

      if (connectedDevices.isEmpty) {
        emit(ScanState(
          isScanning: false,
          isConnected: false,
          statusMessage: AppStrings.noConnectedDevices,
        ));
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

      emit(ScanState(
        isScanning: false,
        isConnected: false,
        statusMessage: AppStrings.disconnectedFromDevices,
      ));
    } catch (e) {
      log("Errore durante la disconnessione: $e");
      emit(ScanState(
        isScanning: false, 
        statusMessage: "${AppStrings.disconnectionError}: $e"
      ));
    }
  }
  
  Future<void> _cancelExistingOperations() async {
    // Annulla eventuali timer attivi
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
    
    // Annulla subscription attivi
    await _scanResultsSubscription?.cancel();
    _scanResultsSubscription = null;
    
    // Interrompi eventuali scansioni in corso
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  @override
  Future<void> close() async {
    await _cancelExistingOperations();
    return super.close();
  }
}