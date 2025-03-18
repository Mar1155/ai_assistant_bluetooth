class DeviceData {
  final List<ErrorData> errors;
  final List<ParameterData> parameters;

  DeviceData({
    required this.errors,
    required this.parameters,
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) {
    return DeviceData(
      errors: (json['errors'] as List<dynamic>)
          .map((e) => ErrorData.fromJson(e))
          .toList(),
      parameters: (json['parameters'] as List<dynamic>)
          .map((e) => ParameterData.fromJson(e))
          .toList(),
    );
  }
}

class ErrorData {
  final String code;
  final String message;

  ErrorData({
    required this.code,
    required this.message,
  });

  factory ErrorData.fromJson(Map<String, dynamic> json) {
    return ErrorData(
      code: json['code'] != null ? json['code'].toString() : "00",
      message: json['message'] as String,
    );
  }
}

class ParameterData {
  final String name;
  final String value;

  ParameterData({
    required this.name,
    required this.value,
  });

  factory ParameterData.fromJson(Map<String, dynamic> json) {
    return ParameterData(
      name: json['name'] as String,
      value: json['value'].toString(),
    );
  }
}