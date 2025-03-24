import 'package:ai_assistent_bluetooth/cubit/chat/chat_cubit.dart';
import 'package:ai_assistent_bluetooth/services/chat_gpt_service.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_assistent_bluetooth/models/device_message.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_state.dart';
import 'package:ai_assistent_bluetooth/theme/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_assistent_bluetooth/screens/chat_device_screen.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<ScanCubit, ScanState>(
          listenWhen:
              (previous, current) =>
                  previous.statusMessage != current.statusMessage,
          listener: (context, state) {
            // Mostra un messaggio all'utente quando cambia lo stato
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.statusMessage),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                action:
                    state.isBluetoothEnabled == false
                        ? SnackBarAction(
                          label: 'Attiva Bluetooth',
                          onPressed: () {
                            // Redirect alle impostazioni bluetooth
                          },
                        )
                        : null,
              ),
            );
          },
          builder: (context, state) {
            // Stati di caricamento con messaggi più dettagliati
            if (state.isScanning) {
              return _buildLoadingState(
                "Ricerca dispositivi in corso...",
                "La scansione terminerà automaticamente tra pochi secondi.",
              );
            }

            if (state.isConnecting) {
              return _buildLoadingState(
                "Connessione in corso...",
                "Tentativo di connessione a ${state.device?.name ?? 'dispositivo'}",
              );
            }

            // Dispositivo trovato e connesso
            if (state.isConnected && state.device != null) {
              return _buildConnectedState(context, state);
            }

            // Dispositivo trovato ma non connesso
            if (!state.isConnected && state.device != null) {
              return _buildFoundButNotConnectedState(context, state);
            }

            // Nessun dispositivo trovato o errore
            return _buildDisconnectedState(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundButNotConnectedState(
    BuildContext context,
    ScanState state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_searching, size: 70, color: Colors.blue[400]),
            const SizedBox(height: 24),
            Text(
              "Dispositivo trovato: ${state.device?.name ?? 'Sconosciuto'}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              state.statusMessage,
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Riprova connessione"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () => context.read<ScanCubit>().reconnect(),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text("Nuova scansione"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () => context.read<ScanCubit>().retry(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedState(BuildContext context, ScanState state) {
    final bool hasError = state.errorList.isNotEmpty;
    final String machineName = state.device?.name ?? "Dispositivo sconosciuto";
    final String connectionStatus =
        "Connesso - Ultimo aggiornamento: ${state.lastUpdateTime?.toLocal().toString().substring(11, 19) ?? 'N/A'}";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nome macchina e stato
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              machineName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              connectionStatus,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusIndicator(hasError),
                    ],
                  ),
                  //   if (hasError) ...[
                  //     const SizedBox(height: 16),
                  //     Container(
                  //       width: double.infinity,
                  //       padding: const EdgeInsets.all(10),
                  //       decoration: BoxDecoration(
                  //         color: Colors.red[50],
                  //         borderRadius: BorderRadius.circular(8),
                  //         border: Border.all(color: Colors.red[200]!),
                  //       ),
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Row(
                  //             children: [
                  //               Icon(
                  //                 Icons.warning_amber_rounded,
                  //                 color: Colors.red[700],
                  //                 size: 18,
                  //               ),
                  //               const SizedBox(width: 8),
                  //               Text(
                  //                 "Errore ${state.errorList.last.code}",
                  //                 style: TextStyle(
                  //                   fontWeight: FontWeight.bold,
                  //                   color: Colors.red[700],
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //           const SizedBox(height: 4),
                  //           Text(
                  //             state.errorList.last.message,
                  //             style: TextStyle(color: Colors.red[700]),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Parametri principali
          const Text(
            "Parametri principali",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          state.parameters.isEmpty
              ? Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      "In attesa di ricevere parametri...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
              : _buildParametersGrid(state),
          const SizedBox(height: 20),

          // Pulsanti azione
          Row(
            children: [
              // Expanded(
              //   child: ElevatedButton.icon(
              //     icon: const Icon(Icons.list_alt),
              //     label: const Text("Tutti i parametri"),
              //     style: ElevatedButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(vertical: 12),
              //     ),
              //     onPressed: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => const AllParametersScreen(),
              //         ),
              //       );
              //     },
              //   ),
              // ),
              // const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.smart_toy),
                  label: const Text("Assistenza AI"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed:
                      hasError
                          ? () => context.go(
                            '/chat',
                            extra: {
                              'errorCode': state.errorList.last.code,
                              'errorMessage': state.errorList.last.message,
                            },
                          )
                          : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Lista errori recenti
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Storico errori recenti",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (state.errorList.length > 3)
                TextButton(onPressed: () {}, child: const Text("Vedi tutti")),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildErrorList(context, state.errorList)),

          // Pulsante disconnetti
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.link_off),
              label: const Text("Disconnetti"),
              onPressed: () => context.read<ScanCubit>().disconnectDevice(),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            hasError ? "Errore" : "Sistema OK",
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
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
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Icona basata sul tipo di parametro (esempio)
                      Icon(
                        _getIconForParameter(param.name),
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          param.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      param.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForParameter(String paramName) {
    // Logica per assegnare icone in base al tipo di parametro
    final nameLower = paramName.toLowerCase();
    if (nameLower.contains('temp')) return Icons.thermostat;
    if (nameLower.contains('press')) return Icons.speed;
    if (nameLower.contains('volt')) return Icons.bolt;
    if (nameLower.contains('batt')) return Icons.battery_full;
    if (nameLower.contains('level')) return Icons.water;
    return Icons.sensors;
  }

  Widget _buildErrorList(BuildContext context, List<ErrorData> errorList) {
    if (errorList.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Nessun errore rilevato",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: errorList.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final error = errorList[index];
        return ListTile(
          onTap:
              () => context.go(
                '/chat',
                extra: {'errorCode': error.code, 'errorMessage': error.message},
              ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Image.asset(
                "assets/icon_mark.png",
                color: Colors.red.withOpacity(0.8),
              ),
            ),
          ),
          title: Text(
            error.message,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: "Ottieni assistenza",
            onPressed:
                () => context.go(
                  '/chat',
                  extra: {
                    'errorCode': error.code,
                    'errorMessage': error.message,
                  },
                ),
          ),
        );
      },
    );
  }

  Widget _buildDisconnectedState(BuildContext context, ScanState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isBluetoothEnabled == false
                  ? Icons.bluetooth_disabled
                  : Icons.bluetooth_searching,
              size: 80,
              color:
                  state.isBluetoothEnabled == false
                      ? Colors.grey[400]
                      : Colors.blue[400],
            ),
            const SizedBox(height: 24),
            Text(
              state.isBluetoothEnabled == false
                  ? "Bluetooth disattivato"
                  : "Nessun dispositivo connesso",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              state.isBluetoothEnabled == false
                  ? "Per utilizzare questa app è necessario attivare il Bluetooth nelle impostazioni del dispositivo"
                  : "Assicurati che il dispositivo ESP32_BT sia acceso e nelle vicinanze",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (state.isBluetoothEnabled != false)
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text("Cerca dispositivi"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: () => context.read<ScanCubit>().retry(),
              ),
            if (state.isBluetoothEnabled == false)
              ElevatedButton.icon(
                icon: const Icon(Icons.settings_bluetooth),
                label: const Text("Apri impostazioni Bluetooth"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  // Implementare apertura impostazioni native
                },
              ),
            const SizedBox(height: 16),
            if (state.statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.statusMessage,
                  style: TextStyle(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class UserHomeView extends StatelessWidget {
  const UserHomeView({Key? key}) : super(key: key);
 
  Widget _buildLoadingState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildDisconnectedState(BuildContext context, ScanState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isBluetoothEnabled == false
                  ? Icons.bluetooth_disabled
                  : Icons.bluetooth_searching,
              size: 80,
              color: state.isBluetoothEnabled == false
                  ? Colors.grey[400]
                  : Colors.blue[400],
            ),
            const SizedBox(height: 24),
            Text(
              state.isBluetoothEnabled == false
                  ? "Bluetooth disattivato"
                  : "Nessun dispositivo connesso",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              state.isBluetoothEnabled == false
                  ? "Per utilizzare questa app è necessario attivare il Bluetooth nelle impostazioni del dispositivo"
                  : "Assicurati che il dispositivo ESP32_BT sia acceso e nelle vicinanze",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (state.isBluetoothEnabled != false)
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text("Cerca dispositivi"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: () => context.read<ScanCubit>().retry(),
              ),
            if (state.isBluetoothEnabled == false)
              ElevatedButton.icon(
                icon: const Icon(Icons.settings_bluetooth),
                label: const Text("Apri impostazioni Bluetooth"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  // Implementare apertura impostazioni native
                },
              ),
            const SizedBox(height: 16),
            if (state.statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.statusMessage,
                  style: TextStyle(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<ScanCubit, ScanState>(
          listener: (context, state) {
            // Se il dispositivo è connesso o ci sono errori, avvia subito la chat
            if (state.isConnected || state.errorList.isNotEmpty) {
              final errorCode = state.errorList.isNotEmpty ? state.errorList.last.code : null;
              final errorMessage = state.errorList.isNotEmpty ? state.errorList.last.message : "";
              // Naviga a DeviceChatView passando gli errori (se presenti)
              context.go('/chat', extra: {
                'errorCode': errorCode,
                'errorMessage': errorMessage,
              });
            }
          },
          builder: (context, state) {
            if (state.isScanning) {
              return _buildLoadingState(
                "Ricerca dispositivi in corso...",
                "La scansione terminerà automaticamente tra pochi secondi.",
              );
            }
            if (state.isConnecting) {
              return _buildLoadingState(
                "Connessione in corso...",
                "Tentativo di connessione a ${state.device?.name ?? 'dispositivo'}",
              );
            }
            return _buildDisconnectedState(context, state);
          },
        ),
      ),
    );
  }
}
