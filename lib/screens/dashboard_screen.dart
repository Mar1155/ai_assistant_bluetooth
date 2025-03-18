import 'dart:developer';

import 'package:ai_assistent_bluetooth/cubit/chat/chat_cubit.dart';
import 'package:ai_assistent_bluetooth/screens/all_parameters_screen.dart';
import 'package:ai_assistent_bluetooth/screens/chat_device_screen.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_state.dart';
import 'package:ai_assistent_bluetooth/services/chat_gpt_service.dart';
import 'package:ai_assistent_bluetooth/theme/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<ScanCubit, ScanState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state.isScanning || state.isConnecting) {
              return _buildScanningState(state.statusMessage);
            }
            if (state.device != null) {
              return _buildConnectedState(context, state);
            }
            return _buildDisconnectedState(context);
          },
        ),
      ),
    );
  }

  Widget _buildScanningState(String statusMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            statusMessage,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildConnectedState(BuildContext context, ScanState state) {
    final bool hasError = state.errorList.isNotEmpty;
    const String machineName = "CNC-3000";
    const String machineId = "ID: M45872";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nome macchina e ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    machineName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    machineId,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              _buildStatusIndicator(hasError),
            ],
          ),

          const SizedBox(height: 24),

          // Parametri principali
          const Text(
            "Parametri principali",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildParametersGrid(state),
          const SizedBox(height: 24),

          // Pulsanti azione
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text("Vedi tutti i parametri"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllParametersScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.smart_toy),
                  label: const Text("Assistenza AI"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: hasError ? Colors.red : Colors.grey,
                  ),
                  onPressed: hasError
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => ChatCubit(
                                  chatGptService: ChatGptService(),
                                  errorCode: state.errorList.last["code"] as String,
                                  errorMessage: state.errorList.last["desc"] as String,
                                ),
                                child: DeviceChatView(
                                  errorCode: state.errorList.last["code"] as String,
                                  errorMessage: state.errorList.last["desc"] as String,
                                ),
                              ),
                            ),
                          )
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Lista errori recenti
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Storico errori recenti",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  // Navigazione allo storico completo (da implementare)
                },
                child: const Text("Vedi tutti"),
              ),
            ],
          ),
          Expanded(child: _buildErrorList(context, state.errorList)),

          // Pulsante disconnetti
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.link_off),
              label: const Text("Disconnetti"),
              onPressed: () => context.read<ScanCubit>().disconnectFromAllDevices(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool hasError) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasError ? Colors.red[100] : Colors.green[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasError ? Icons.error : Icons.check_circle,
            color: hasError ? Colors.red : Colors.green,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            hasError ? "Errore rilevato" : "Sistema OK",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: hasError ? Colors.red[800] : Colors.green[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersGrid(ScanState state) {
    final parameters = state.parameters;
    log(state.parameters.toString());
    if (parameters.isEmpty) {
      return const Center(child: Text("Nessun parametro disponibile"));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: parameters.length,
      itemBuilder: (context, index) {
        final param = parameters[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(param["icon"] as IconData, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    param["name"] as String,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  param["value"].toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorList(BuildContext context, List<Map<String, dynamic>> errorList) {
    if (errorList.isEmpty) {
      return const Center(child: Text("Nessun errore rilevato"));
    }
    return ListView.separated(
      itemCount: errorList.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final error = errorList[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                error["code"] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
            ),
          ),
          title: Text(
            error["desc"] as String,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            error["time"] as String,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => ChatCubit(
                  chatGptService: ChatGptService(),
                  errorCode: error["code"] as String,
                  errorMessage: error["desc"] as String,
                ),
                child: DeviceChatView(
                  errorCode: error["code"] as String,
                  errorMessage: error["desc"] as String,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisconnectedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          const Text(
            "Nessun macchinario connesso",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Collega un dispositivo per visualizzare i parametri",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text("Cerca dispositivi"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () => context.read<ScanCubit>().retry(),
          ),
        ],
      ),
    );
  }
}
