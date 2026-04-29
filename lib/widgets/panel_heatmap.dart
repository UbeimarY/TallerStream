import 'package:flutter/material.dart';
import '../models/solar_panel.dart';

class PanelHeatmap extends StatelessWidget {
  final Stream<List<SolarPanel>> panelStream;
  final void Function(SolarPanel) onPanelTap;

  const PanelHeatmap({
    super.key,
    required this.panelStream,
    required this.onPanelTap,
  });

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
                const Icon(Icons.grid_on, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Mapa de paneles en tiempo real',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildLegend(),
            const SizedBox(height: 12),
            // ── StreamBuilder ────────────────────────────────────────────────
            // Se reconstruye automáticamente cada vez que panelStream emite.
            // snapshot.connectionState indica si el stream ya tiene datos.
            // snapshot.data contiene el último valor emitido.
            StreamBuilder<List<SolarPanel>>(
              stream: panelStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final panels = snapshot.data!;
                final maxOutput = panels.fold(
                  0.0,
                  (m, p) => p.currentOutputKw > m ? p.currentOutputKw : m,
                );

                // Agrupa paneles por fila
                final rows = <int, List<SolarPanel>>{};
                for (final panel in panels) {
                  rows.putIfAbsent(panel.row, () => []).add(panel);
                }

                final sortedRows = rows.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));

                return Column(
                  children: sortedRows.map((entry) {
                    final rowPanels = entry.value
                      ..sort((a, b) => a.column.compareTo(b.column));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: rowPanels.map((panel) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: _PanelCell(
                                panel: panel,
                                maxOutput: maxOutput,
                                onTap: () => onPanelTap(panel),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      children: [
        _legendItem(Colors.green, 'Óptimo'),
        _legendItem(Colors.orange, 'Degradado'),
        _legendItem(Colors.red, 'Crítico'),
        _legendItem(Colors.blue, 'Mantenimiento'),
        _legendItem(Colors.grey, 'Sin señal'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _PanelCell extends StatelessWidget {
  final SolarPanel panel;
  final double maxOutput;
  final VoidCallback onTap;

  const _PanelCell({
    required this.panel,
    required this.maxOutput,
    required this.onTap,
  });

  Color get _cellColor {
    switch (panel.status) {
      case PanelStatus.optimal:
        final intensity = maxOutput > 0
            ? panel.currentOutputKw / maxOutput
            : 0.5;
        return Color.lerp(Colors.green[100]!, Colors.green[700]!, intensity)!;
      case PanelStatus.degraded:
        return Colors.orange[300]!;
      case PanelStatus.overheating:
        return Colors.red[400]!;
      case PanelStatus.offline:
        return Colors.grey[700]!;
      case PanelStatus.maintenance:
        return Colors.blue[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        height: 64,
        decoration: BoxDecoration(
          color: _cellColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: _cellColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                panel.id,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                panel.status == PanelStatus.offline
                    ? '—'
                    : '${panel.currentOutputKw.toStringAsFixed(1)} kW',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
