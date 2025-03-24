import 'package:ai_assistent_bluetooth/cubit/scan/scan_state.dart';
import 'package:ai_assistent_bluetooth/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_cubit.dart';
import 'package:ai_assistent_bluetooth/screens/dashboard_screen.dart';
import 'package:ai_assistent_bluetooth/screens/bluetooth_off_screen.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

void main() {
  runApp(const FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScanCubit(),
      child: MaterialApp.router(
        title: "Assistente Bluetooth",
        theme: ThemeData(
          primarySwatch: Colors.lightBlue,
        ),
        routerConfig: router,
      ),
    );
  }
}

class HomeSwitcher extends StatelessWidget {
  const HomeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanCubit, ScanState>(
      builder: (context, state) {
        if (state.isBluetoothEnabled == false) {
          return BluetoothOffScreen(adapterState: BluetoothAdapterState.off);
        }
        return const DashboardView();
      },
    );
  }
}
