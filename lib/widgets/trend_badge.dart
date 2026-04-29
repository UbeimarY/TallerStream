import 'package:flutter/material.dart';
import '../models/production_history.dart';

/// Widget que muestra un indicador de tendencia con flecha y porcentaje
class TrendBadge extends StatelessWidget {
  final ProductionStats stats;

  const TrendBadge({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final trend = stats.trend;
    final percentage = stats.trendPercentage.abs().toStringAsFixed(1);

    if (trend == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_flat, size: 12, color: Colors.blue[700]),
            const SizedBox(width: 4),
            Text(
              'Estable',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      );
    }

    final isUp = trend > 0;
    final color = isUp ? Colors.green : Colors.red;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
