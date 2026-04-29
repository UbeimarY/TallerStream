import 'package:flutter/material.dart';
import '../models/plant_alert.dart';

class AlertPanel extends StatefulWidget {
  final Stream<PlantAlert> alertStream;
  final void Function(String alertId) onAcknowledge;

  const AlertPanel({
    super.key,
    required this.alertStream,
    required this.onAcknowledge,
  });

  @override
  State<AlertPanel> createState() => _AlertPanelState();
}

class _AlertPanelState extends State<AlertPanel> {
  // Acumulamos alertas localmente porque el stream solo emite
  // un evento a la vez — queremos mostrar el historial completo.
  final List<PlantAlert> _alerts = [];

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
                const Icon(Icons.notifications_active,
                    size: 18, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Centro de alertas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // StreamBuilder solo para el badge contador
                StreamBuilder<PlantAlert>(
                  stream: widget.alertStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // addPostFrameCallback evita llamar setState
                      // durante el build de otro widget
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _alerts.insert(0, snapshot.data!);
                            if (_alerts.length > 20) _alerts.removeLast();
                          });
                        }
                      });
                    }
                    final unack =
                        _alerts.where((a) => !a.isAcknowledged).length;
                    if (unack == 0) return const SizedBox();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unack',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Sin alertas activas',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alerts.length.clamp(0, 8),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  return _AlertTile(
                    alert: alert,
                    onAcknowledge: () {
                      widget.onAcknowledge(alert.id);
                      setState(() {
                        _alerts[index] = alert.acknowledge();
                      });
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final PlantAlert alert;
  final VoidCallback onAcknowledge;

  const _AlertTile({required this.alert, required this.onAcknowledge});

  Color get _color {
    switch (alert.severity) {
      case AlertSeverity.info:     return Colors.blue;
      case AlertSeverity.warning:  return Colors.orange;
      case AlertSeverity.critical: return Colors.red;
    }
  }

  IconData get _icon {
    switch (alert.severity) {
      case AlertSeverity.info:     return Icons.info_outline;
      case AlertSeverity.warning:  return Icons.warning_amber_outlined;
      case AlertSeverity.critical: return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Icon(_icon, color: _color, size: 20),
      title: Text(
        alert.message,
        style: TextStyle(
          fontSize: 12,
          color: alert.isAcknowledged ? Colors.grey : null,
          decoration: alert.isAcknowledged
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
      subtitle: Text(
        '${alert.type.label} · '
        '${alert.timestamp.hour.toString().padLeft(2, '0')}:'
        '${alert.timestamp.minute.toString().padLeft(2, '0')}:'
        '${alert.timestamp.second.toString().padLeft(2, '0')}',
        style: const TextStyle(fontSize: 10),
      ),
      trailing: alert.isAcknowledged
          ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
          : TextButton(
              onPressed: onAcknowledge,
              style: TextButton.styleFrom(
                foregroundColor: _color,
                textStyle: const TextStyle(fontSize: 10),
              ),
              child: const Text('Confirmar'),
            ),
    );
  }
}