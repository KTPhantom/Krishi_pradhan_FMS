enum AlertSeverity {
  info,
  warning,
  severe,
  critical,
}

enum AlertType {
  rain,
  heatwave,
  frost,
  storm,
  pest,
  disease,
  general,
}

class WeatherAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertType type;
  final DateTime validFrom;
  final DateTime validUntil;
  final String? advisory; // "Don't spray pesticide"

  WeatherAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.type,
    required this.validFrom,
    required this.validUntil,
    this.advisory,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.general,
      ),
      validFrom: DateTime.parse(json['valid_from']),
      validUntil: DateTime.parse(json['valid_until']),
      advisory: json['advisory'],
    );
  }
}
