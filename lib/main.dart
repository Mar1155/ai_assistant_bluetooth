import 'dart:async';
import 'dart:developer';

import 'package:ai_assistent_bluetooth/cubit/scan/scan_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Import aggiornato per bluetooth classico
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

import 'screens/bluetooth_off_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const FlutterBlueApp());
}

class FlutterBlueApp extends StatefulWidget {
  const FlutterBlueApp({super.key});

  @override
  State<FlutterBlueApp> createState() => _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();

    checkBlueEnabled();
    init(context);
  }

  void init(BuildContext context) {
    // Ascolta il primo valore dallo stream e corregge lo stato se necessario
    FlutterBlueClassic().adapterState.first
        .then((state) {
          log("Bluetooth stato iniziale: $state");
          if (mounted) {
            setState(() {
              _adapterState = state;
            });
          }
        })
        .catchError((error) {
          log("Errore nel recuperare lo stato iniziale: $error");
        });

    // Continua ad ascoltare gli aggiornamenti dello stato
    _adapterStateStateSubscription = FlutterBlueClassic().adapterState.listen((
      state,
    ) {
      log("Bluetooth adapter state aggiornato: $state");
      if (mounted) {
        setState(() {
          _adapterState = state;
        });
      }
    });

    FlutterBlueClassic().bondedDevices.then((devices) {
      if (devices == null || devices.isEmpty) {
        if (mounted) {
          context.read<ScanCubit>().disconnected();
        }
        return;
      }
      devices.map((d) {
        bool esp32Connected = devices.any(
          (device) => device.name == "ESP32_BT",
        );

        log("Dispositivi connessi: ${devices.map((d) => d.name).join(', ')}");

        if (!esp32Connected) {
          log("ESP32_BT si è disconnesso!");
          if (mounted) {
            context.read<ScanCubit>().disconnected();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  Future<void> checkBlueEnabled() async {
    _adapterState = await FlutterBlueClassic().adapterStateNow;
    log("AdapterStateNow: $_adapterState");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget screen =
        _adapterState == BluetoothAdapterState.on
            ? const DashboardView()
            : BluetoothOffScreen(adapterState: _adapterState);

    return BlocProvider(
      create: (context) => ScanCubit(),
      child: MaterialApp(
        color: Colors.lightBlue,
        home: screen,
        navigatorObservers: [BluetoothAdapterStateObserver()],
      ),
    );
  }
}

//
// This observer listens for Bluetooth Off and dismisses the DeviceScreen
//
class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/DeviceScreen') {
      // Start listening to Bluetooth state changes when a new route is pushed
      _adapterStateSubscription ??= FlutterBlueClassic().adapterState.listen((
        state,
      ) {
        if (state != BluetoothAdapterState.on) {
          // Pop the current route if Bluetooth is off
          navigator?.pop();
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    // Cancel the subscription when the route is popped
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}
