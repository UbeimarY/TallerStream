class SolarPanel {
  final String id;
  final int row;
  final int column;
  final double currentOutputKw;
  final double temperatureCelsius;
  final double efficiency;
  final PanelStatus status;
  final DateTime timestamp;

  const SolarPanel({
    required this.id,
    required this.row,
    required this.column,
    required this.currentOutputKw,
    required this.temperatureCelsius,
    required this.efficiency,
    required this.status,
    required this.timestamp,
  });

  SolarPanel copyWith({
    double? currentOutputKw,
    double? temperatureCelsius,
    double? efficiency,
    PanelStatus? status,
    DateTime? timestamp,
  }) {
    return SolarPanel(
      id: id,
      row: row,
      column: column,
      currentOutputKw: currentOutputKw ?? this.currentOutputKw,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      efficiency: efficiency ?? this.efficiency,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isOverheating => temperatureCelsius > 75.0;
  bool get isUnderperforming => efficiency < 0.6;
}

enum PanelStatus { optimal, degraded, overheating, offline, maintenance }

extension PanelStatusLabel on PanelStatus {
  String get label {
    switch (this) {
      case PanelStatus.optimal:       return 'Óptimo';
      case PanelStatus.degraded:      return 'Degradado';
      case PanelStatus.overheating:   return 'Sobrecalentado';
      case PanelStatus.offline:       return 'Sin señal';
      case PanelStatus.maintenance:   return 'Mantenimiento';
    }
  }
}