class PlantAlert {
  final String id;
  final AlertSeverity severity;
  final AlertType type;
  final String panelId;
  final String message;
  final DateTime timestamp;
  final bool isAcknowledged;

  const PlantAlert({
    required this.id,
    required this.severity,
    required this.type,
    required this.panelId,
    required this.message,
    required this.timestamp,
    this.isAcknowledged = false,
  });

  PlantAlert acknowledge() => PlantAlert(
        id: id,
        severity: severity,
        type: type,
        panelId: panelId,
        message: message,
        timestamp: timestamp,
        isAcknowledged: true,
      );
}

enum AlertSeverity { info, warning, critical }

enum AlertType {
  overheating,
  underperformance,
  panelOffline,
  gridInstability,
}

extension AlertTypeLabel on AlertType {
  String get label {
    switch (this) {
      case AlertType.overheating:      return 'Sobrecalentamiento';
      case AlertType.underperformance: return 'Bajo rendimiento';
      case AlertType.panelOffline:     return 'Panel sin señal';
      case AlertType.gridInstability:  return 'Inestabilidad de red';
    }
  }
}