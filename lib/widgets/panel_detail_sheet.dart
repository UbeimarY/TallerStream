import 'package:flutter/material.dart';
import '../models/solar_panel.dart';

class PanelDetailSheet extends StatelessWidget {
  final SolarPanel panel;
  final VoidCallback onSetMaintenance;
  final VoidCallback onRestore;

  const PanelDetailSheet({
    super.key,
    required this.panel,
    required this.onSetMaintenance,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(panel.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.75,
      expand: false,
      builder: (context, scrollCtrl) {
        return SingleChildScrollView(
          controller: scrollCtrl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Panel ${panel.id}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        panel.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Fila ${panel.row + 1} · Columna ${panel.column + 1}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const Divider(height: 24),
                _MetricRow(
                  label: 'Producción actual',
                  value: '${panel.currentOutputKw.toStringAsFixed(2)} kW',
                  icon: Icons.solar_power,
                  color: Colors.orange,
                ),
                _MetricRow(
                  label: 'Temperatura',
                  value: '${panel.temperatureCelsius.toStringAsFixed(1)} °C',
                  icon: Icons.thermostat,
                  color: panel.isOverheating ? Colors.red : Colors.blue,
                ),
                _MetricRow(
                  label: 'Eficiencia',
                  value: '${(panel.efficiency * 100).toStringAsFixed(1)} %',
                  icon: Icons.speed,
                  color: panel.isUnderperforming ? Colors.orange : Colors.green,
                ),
                _MetricRow(
                  label: 'Última lectura',
                  value:
                      '${panel.timestamp.hour.toString().padLeft(2, '0')}:'
                      '${panel.timestamp.minute.toString().padLeft(2, '0')}:'
                      '${panel.timestamp.second.toString().padLeft(2, '0')}',
                  icon: Icons.access_time,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eficiencia relativa',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: panel.efficiency,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          panel.efficiency > 0.75
                              ? Colors.green
                              : panel.efficiency > 0.60
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: panel.status == PanelStatus.maintenance
                            ? onRestore
                            : onSetMaintenance,
                        icon: Icon(
                          panel.status == PanelStatus.maintenance
                              ? Icons.play_arrow
                              : Icons.build,
                          size: 16,
                        ),
                        label: Text(
                          panel.status == PanelStatus.maintenance
                              ? 'Restaurar panel'
                              : 'Poner en mantenimiento',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text(
                          'Cerrar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(PanelStatus status) {
    switch (status) {
      case PanelStatus.optimal:     return Colors.green;
      case PanelStatus.degraded:    return Colors.orange;
      case PanelStatus.overheating: return Colors.red;
      case PanelStatus.offline:     return Colors.grey;
      case PanelStatus.maintenance: return Colors.blue;
    }
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}