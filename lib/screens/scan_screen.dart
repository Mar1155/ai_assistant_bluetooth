import 'dart:developer';

import 'package:ai_assistent_bluetooth/cubit/chat/chat_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_state.dart';
import 'package:ai_assistent_bluetooth/models/chat_message.dart';
import 'package:ai_assistent_bluetooth/screens/device_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScanView extends StatelessWidget {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Auto Connect")),
      body: Center(
        child: BlocConsumer<ScanCubit, ScanState>(
          listener: (context, state) {
            log(state.device.toString());
            if (state.device != null && state.isConnected) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BlocProvider(
                        create: (context) => ChatCubit(device: state.device!, machineManual: MachineManual(content: 
                        "", errorCodes: {"01" : "AA"}, maintenanceProcedures: {"AA" : "BB"})),
                        child: DeviceChatView(),
                      ),
                ),
              );
            }
          },
          builder: (context, state) {
            log(state.toString());
            if (state.isScanning) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(state.statusMessage),
                ],
              );
            }
            // Stato di errore o device non trovato
            if (state.device == null || !state.isConnected) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.statusMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ScanCubit>().retry(),
                    child: const Text("Riprova scansione"),
                  ),
                ],
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}
