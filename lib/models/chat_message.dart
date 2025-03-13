// lib/models/chat_message.dart
class ChatMessage {
  final String message;
  final bool isSentByUser;
  final DateTime timestamp;
  final bool isError;
  final bool isLoading;

  ChatMessage({
    required this.message,
    required this.isSentByUser,
    DateTime? timestamp,
    this.isError = false,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

// lib/models/machine_data.dart
class MachineData {
  final String deviceId;
  final String status;
  final String? errorCode;
  final String? errorDescription;
  final Map<String, dynamic> sensorData;
  final DateTime timestamp;

  MachineData({
    required this.deviceId,
    required this.status,
    this.errorCode,
    this.errorDescription,
    required this.sensorData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory MachineData.fromJson(Map<String, dynamic> json) {
    return MachineData(
      deviceId: json['deviceId'] ?? '',
      status: json['status'] ?? 'unknown',
      errorCode: json['errorCode'],
      errorDescription: json['errorDescription'],
      sensorData: json['sensorData'] ?? {},
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  bool get hasError => errorCode != null && errorCode!.isNotEmpty;
}

// lib/models/machine_manual.dart
class MachineManual {
  final String content;
  final Map<String, String> errorCodes;
  final Map<String, String> maintenanceProcedures;

  MachineManual({
    required this.content,
    required this.errorCodes,
    required this.maintenanceProcedures,
  });

  String getErrorDescription(String errorCode) {
    return errorCodes[errorCode] ?? 'Unknown error code';
  }

  String getMaintenanceProcedure(String procedure) {
    return maintenanceProcedures[procedure] ?? 'No procedure found';
  }

  // Find relevant manual section for an error code
  String getRelevantSection(String errorCode) {
    String relevantContent = '';
    
    // Add error description if available
    if (errorCodes.containsKey(errorCode)) {
      relevantContent += 'ERROR CODE $errorCode: ${errorCodes[errorCode]}\n\n';
    }
    
    // Search for relevant sections in the manual content
    final regex = RegExp('(Chapter|Section)\\s+\\d+[.:](\\s*.*$errorCode.*)(?:\\n(?!Chapter|Section)[^\\n]*)*', multiLine: true);
    final matches = regex.allMatches(content);
    
    for (final match in matches) {
      relevantContent += '${match.group(0)}\n\n';
    }
    
    // If no specific section found, return general info
    if (relevantContent.isEmpty) {
      return 'No specific information found for error code $errorCode in the manual.';
    }
    
    return relevantContent;
  }
}