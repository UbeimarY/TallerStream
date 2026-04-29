/// Representa un punto en el histórico de producción
class ProductionDataPoint {
  final DateTime timestamp;
  final double productionKw;

  const ProductionDataPoint({
    required this.timestamp,
    required this.productionKw,
  });
}

/// Resumen estadístico de producción
class ProductionStats {
  final List<ProductionDataPoint> dataPoints;
  final double currentKw;
  final double previousKw;
  final double maxKwToday;
  final double averageKwToday;

  const ProductionStats({
    required this.dataPoints,
    required this.currentKw,
    required this.previousKw,
    required this.maxKwToday,
    required this.averageKwToday,
  });

  /// Retorna la tendencia: positiva (1), neutra (0), negativa (-1)
  int get trend {
    final diff = currentKw - previousKw;
    if (diff > 0.1) return 1; // Aumentando
    if (diff < -0.1) return -1; // Disminuyendo
    return 0; // Estable
  }

  /// Cambio porcentual desde hace 2 minutos
  double get trendPercentage {
    if (previousKw == 0) return 0;
    return ((currentKw - previousKw) / previousKw * 100).clamp(-100, 100);
  }
}
