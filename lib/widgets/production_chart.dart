import 'package:flutter/material.dart';
import '../models/production_history.dart';

class ProductionChart extends StatelessWidget {
  final ProductionStats stats;

  const ProductionChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, size: 18, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Tendencia de Producción',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                _TrendIndicator(stats: stats),
              ],
            ),
            const SizedBox(height: 16),
            if (stats.dataPoints.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Recolectando datos...',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              )
            else
              _SimpleLineChart(stats: stats),
            const SizedBox(height: 16),
            _StatsRow(stats: stats),
          ],
        ),
      ),
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  final ProductionStats stats;

  const _TrendIndicator({required this.stats});

  @override
  Widget build(BuildContext context) {
    final trend = stats.trend;
    final percentage = stats.trendPercentage.abs().toStringAsFixed(1);

    if (trend == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_flat, size: 14, color: Colors.blue[600]),
            const SizedBox(width: 4),
            Text(
              'Estable',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  final ProductionStats stats;

  const _SimpleLineChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.dataPoints.isEmpty) {
      return const SizedBox();
    }

    final maxValue = stats.maxKwToday > 0 ? stats.maxKwToday : 10;
    const chartHeight = 80.0;

    return SizedBox(
      height: chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(stats.dataPoints.length, (index) {
          final point = stats.dataPoints[index];
          final normalizedHeight =
              (point.productionKw / maxValue) * chartHeight;
          final isLast = index == stats.dataPoints.length - 1;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Tooltip(
                message: '${point.productionKw.toStringAsFixed(1)} kW',
                child: Container(
                  height: normalizedHeight.clamp(2, chartHeight),
                  decoration: BoxDecoration(
                    color: isLast
                        ? Colors.purple[400]
                        : Colors.purple[200]?.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ProductionStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Máx hoy',
            value: stats.maxKwToday.toStringAsFixed(1),
            unit: 'kW',
            color: Colors.orange,
            icon: Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            label: 'Promedio',
            value: stats.averageKwToday.toStringAsFixed(1),
            unit: 'kW',
            color: Colors.blue,
            icon: Icons.calculate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            label: 'Ahora',
            value: stats.currentKw.toStringAsFixed(1),
            unit: 'kW',
            color: Colors.green,
            icon: Icons.electric_bolt,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(unit, style: TextStyle(fontSize: 8, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
