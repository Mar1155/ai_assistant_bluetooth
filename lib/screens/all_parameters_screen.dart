import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_state.dart';
import 'package:ai_assistent_bluetooth/theme/style.dart';

class AllParametersScreen extends StatefulWidget {
  const AllParametersScreen({super.key});

  @override
  State<AllParametersScreen> createState() => _AllParametersScreenState();
}

class _AllParametersScreenState extends State<AllParametersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tutti i Parametri'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cerca parametri...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              // Tab bar
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Operativi'),
                  Tab(text: 'Diagnostica'),
                  Tab(text: 'Sistema'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<ScanCubit, ScanState>(
        builder: (context, state) {
          if (state.device == null) {
            return const Center(
              child: Text('Nessun dispositivo connesso'),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildParametersList(_getOperationalParameters(), _searchQuery),
              _buildParametersList(_getDiagnosticParameters(), _searchQuery),
              _buildParametersList(_getSystemParameters(), _searchQuery),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Funzione per aggiornare i parametri in tempo reale
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Parametri aggiornati'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: const Icon(Icons.refresh),
        tooltip: 'Aggiorna parametri',
      ),
    );
  }

  Widget _buildParametersList(List<Map<String, dynamic>> parameters, String searchQuery) {
    final filteredParameters = parameters.where((param) {
      return param['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
          param['value'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
          (param['description'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (filteredParameters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nessun parametro trovato',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredParameters.length,
      itemBuilder: (context, index) {
        final param = filteredParameters[index];
        return _buildParameterCard(param);
      },
    );
  }

  Widget _buildParameterCard(Map<String, dynamic> param) {
    final bool isWarning = param['isWarning'] ?? false;
    final bool isCritical = param['isCritical'] ?? false;
    
    Color statusColor = Colors.green;
    if (isWarning) statusColor = Colors.orange;
    if (isCritical) statusColor = Colors.red;

    String getStatusText() {
      if (isCritical) return 'Critico';
      if (isWarning) return 'Attenzione';
      return 'Normale';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isWarning || isCritical ? statusColor.withOpacity(0.5) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    param['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCritical ? Icons.error : (isWarning ? Icons.warning : Icons.check_circle),
                        color: statusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getStatusText(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (param['description'] != null) ...[
              const SizedBox(height: 4),
              Text(
                param['description'] as String,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Valore attuale:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      param['value'].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isWarning || isCritical ? statusColor : Colors.black,
                      ),
                    ),
                  ],
                ),
                if (param['unit'] != null)
                  Text(
                    param['unit'] as String,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            if (param['range'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Range normale:',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    param['range'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
            if (param['lastUpdated'] != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Aggiornato: ${param['lastUpdated']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Simulazione dati parametri operativi
  List<Map<String, dynamic>> _getOperationalParameters() {
    return [
      {
        'name': 'Temperatura motore',
        'value': 78.5,
        'unit': '°C',
        'range': '60-85°C',
        'description': 'Temperatura attuale del motore principale',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Pressione idraulica',
        'value': 2.4,
        'unit': 'bar',
        'range': '2.0-3.0 bar',
        'description': 'Pressione del sistema idraulico',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Velocità rotazione',
        'value': 1200,
        'unit': 'rpm',
        'range': '800-1500 rpm',
        'description': 'Velocità di rotazione dell\'albero principale',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Carico di lavoro',
        'value': 87,
        'unit': '%',
        'range': '0-90%',
        'description': 'Percentuale di carico attuale sul sistema',
        'lastUpdated': '13/03 15:42',
        'isWarning': true,
      },
      {
        'name': 'Temperatura olio',
        'value': 65.2,
        'unit': '°C',
        'range': '50-70°C',
        'description': 'Temperatura dell\'olio idraulico',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Flusso refrigerante',
        'value': 12.5,
        'unit': 'l/min',
        'range': '10-15 l/min',
        'description': 'Flusso del liquido refrigerante',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
    ];
  }

  // Simulazione dati parametri diagnostici
  List<Map<String, dynamic>> _getDiagnosticParameters() {
    return [
      {
        'name': 'Vibrazione motore',
        'value': 2.8,
        'unit': 'mm/s',
        'range': '0-3.0 mm/s',
        'description': 'Livello di vibrazione del motore',
        'lastUpdated': '13/03 15:42',
        'isWarning': true,
      },
      {
        'name': 'Consumo elettrico',
        'value': 17.4,
        'unit': 'kW',
        'range': '10-20 kW',
        'description': 'Consumo elettrico istantaneo',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Livello rumore',
        'value': 78,
        'unit': 'dB',
        'range': '60-80 dB',
        'description': 'Livello di rumore in decibel',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Usura utensili',
        'value': 45,
        'unit': '%',
        'range': '0-60%',
        'description': 'Percentuale stimata di usura degli utensili',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Temperatura ambiente',
        'value': 24.3,
        'unit': '°C',
        'range': '15-28°C',
        'description': 'Temperatura dell\'ambiente operativo',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Efficienza energetica',
        'value': 82,
        'unit': '%',
        'range': '75-95%',
        'description': 'Indice di efficienza energetica',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
    ];
  }

  // Simulazione dati parametri di sistema
  List<Map<String, dynamic>> _getSystemParameters() {
    return [
      {
        'name': 'Tensione alimentazione',
        'value': 220,
        'unit': 'V',
        'range': '210-230 V',
        'description': 'Tensione di alimentazione del sistema',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Memoria disponibile',
        'value': 76,
        'unit': '%',
        'range': '20-100%',
        'description': 'Percentuale di memoria di sistema disponibile',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Temperatura CPU',
        'value': 62.8,
        'unit': '°C',
        'range': '40-70°C',
        'description': 'Temperatura del processore di controllo',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Carico processore',
        'value': 42,
        'unit': '%',
        'range': '0-80%',
        'description': 'Utilizzo della CPU del sistema di controllo',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Spazio di archiviazione',
        'value': 38,
        'unit': '%',
        'range': '0-90%',
        'description': 'Percentuale di spazio di archiviazione utilizzato',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Connettività di rete',
        'value': 'Attiva',
        'unit': null,
        'range': null,
        'description': 'Stato della connessione di rete',
        'lastUpdated': '13/03 15:42',
        'isWarning': false,
      },
      {
        'name': 'Cicli di manutenzione',
        'value': 9450,
        'unit': 'cicli',
        'range': '0-10000 cicli',
        'description': 'Conteggio cicli prima della prossima manutenzione',
        'lastUpdated': '13/03 15:42',
        'isWarning': true,
      },
      {
        'name': 'Livello batteria backup',
        'value': 14,
        'unit': '%',
        'range': '20-100%',
        'description': 'Livello batteria del sistema di backup',
        'lastUpdated': '13/03 15:42',
        'isCritical': true,
      },
    ];
  }
}