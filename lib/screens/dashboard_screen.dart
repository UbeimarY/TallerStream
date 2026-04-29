import 'package:flutter/material.dart';
import '../streams/solar_monitor_bloc.dart';
import '../streams/grid_stream_controller.dart';
import '../models/solar_panel.dart';
import '../widgets/metric_card.dart';
import '../widgets/panel_heatmap.dart';
import '../widgets/alert_panel.dart';
import '../widgets/panel_detail_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final SolarMonitorBloc bloc;

  const DashboardScreen({super.key, required this.bloc});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  void _showPanelDetail(SolarPanel panel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PanelDetailSheet(
        panel: panel,
        onSetMaintenance: () {
          widget.bloc.setPanelMaintenance(panel.id);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Panel ${panel.id} puesto en mantenimiento'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onRestore: () {
          widget.bloc.restorePanel(panel.id);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Panel ${panel.id} restaurado'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Planta Solar Orión',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<PlantSummary>(
                        stream: widget.bloc.summaryStream,
                        builder: (context, snapshot) {
                          final s = snapshot.data;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Producción Total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s != null
                                        ? '${s.totalOutputKw.toStringAsFixed(1)} kW'
                                        : '—',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              StreamBuilder<List<SolarPanel>>(
                                stream: widget.bloc.panelStream,
                                builder: (context, snapshot) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: snapshot.hasData
                                              ? Colors.greenAccent
                                              : Colors.grey,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              snapshot.hasData
                                                  ? 'EN VIVO'
                                                  : 'CONECTANDO...',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: IndexedStack(
          index: _selectedTab,
          children: [
            _OverviewTab(bloc: widget.bloc, onPanelTap: _showPanelDetail),
            _HeatmapTab(bloc: widget.bloc, onPanelTap: _showPanelDetail),
            _AlertsTab(bloc: widget.bloc),
            _GridTab(bloc: widget.bloc),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Paneles',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.electrical_services_outlined),
            selectedIcon: Icon(Icons.electrical_services),
            label: 'Red',
          ),
        ],
      ),
    );
  }
}

// ── Tab Resumen ───────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final SolarMonitorBloc bloc;
  final void Function(SolarPanel) onPanelTap;

  const _OverviewTab({required this.bloc, required this.onPanelTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Un solo StreamBuilder para las 3 métricas principales
        StreamBuilder<PlantSummary>(
          stream: bloc.summaryStream,
          builder: (context, snapshot) {
            final s = snapshot.data;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                MetricCard(
                  label: 'Producción total',
                  value: s != null ? s.totalOutputKw.toStringAsFixed(1) : '—',
                  unit: 'kW en este momento',
                  color: Colors.orange,
                  icon: Icons.solar_power,
                ),
                MetricCard(
                  label: 'Exportando a la red',
                  value: s != null ? s.exportingKw.toStringAsFixed(1) : '—',
                  unit: 'kW → Red nacional',
                  color: Colors.green,
                  icon: Icons.upload,
                ),
                MetricCard(
                  label: 'Generado hoy',
                  value: s != null
                      ? s.totalGeneratedTodayKwh.toStringAsFixed(2)
                      : '—',
                  unit: 'kWh acumulados',
                  color: Colors.blue,
                  icon: Icons.battery_charging_full,
                ),
                // Este sí tiene su propio StreamBuilder — stream distinto
                StreamBuilder<double>(
                  stream: bloc.averageEfficiencyStream,
                  builder: (context, effSnap) {
                    return MetricCard(
                      label: 'Eficiencia promedio',
                      value: effSnap.hasData
                          ? (effSnap.data! * 100).toStringAsFixed(1)
                          : '—',
                      unit: '% de los paneles activos',
                      color: Colors.purple,
                      icon: Icons.speed,
                    );
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        PanelHeatmap(panelStream: bloc.panelStream, onPanelTap: onPanelTap),
      ],
    );
  }
}

// ── Tab Paneles ───────────────────────────────────────────────────────────────
class _HeatmapTab extends StatelessWidget {
  final SolarMonitorBloc bloc;
  final void Function(SolarPanel) onPanelTap;

  const _HeatmapTab({required this.bloc, required this.onPanelTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado individual de paneles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Toca un panel para ver detalles y opciones de mantenimiento',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<SolarPanel>>(
                  stream: bloc.panelStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final counts = _countByStatus(snapshot.data!);
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: counts.entries.map((e) {
                        return Chip(
                          label: Text(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.grey[100],
                          side: BorderSide(color: Colors.grey[300]!),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        PanelHeatmap(panelStream: bloc.panelStream, onPanelTap: onPanelTap),
      ],
    );
  }

  Map<String, int> _countByStatus(List<SolarPanel> panels) {
    final counts = <PanelStatus, int>{};
    for (final p in panels) {
      counts[p.status] = (counts[p.status] ?? 0) + 1;
    }
    return {
      'Óptimo': counts[PanelStatus.optimal] ?? 0,
      'Degradado': counts[PanelStatus.degraded] ?? 0,
      'Sobrecalentado': counts[PanelStatus.overheating] ?? 0,
      'Sin señal': counts[PanelStatus.offline] ?? 0,
      'Mantenimiento': counts[PanelStatus.maintenance] ?? 0,
    };
  }
}

// ── Tab Alertas ───────────────────────────────────────────────────────────────
class _AlertsTab extends StatelessWidget {
  final SolarMonitorBloc bloc;

  const _AlertsTab({required this.bloc});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AlertPanel(
          alertStream: bloc.alertStream,
          onAcknowledge: bloc.acknowledgeAlert,
        ),
      ],
    );
  }
}

// ── Tab Red ───────────────────────────────────────────────────────────────────
class _GridTab extends StatelessWidget {
  final SolarMonitorBloc bloc;

  const _GridTab({required this.bloc});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Aviso del throttle
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los datos de red se actualizan cada 5 s '
                    '(ThrottleTransformer activo)',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Stream con throttle
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.electrical_services,
                      size: 18,
                      color: Colors.indigo,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Estado de la red eléctrica',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<GridStatus>(
                  stream: bloc.throttledGridStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final g = snapshot.data!;
                    return Column(
                      children: [
                        _GridRow(
                          label: 'Exportando',
                          value: '${g.exportingKw.toStringAsFixed(1)} kW',
                          icon: Icons.upload,
                          color: Colors.green,
                        ),
                        _GridMetricWithIndicator(
                          label: 'Frecuencia',
                          value: '${g.frequencyHz.toStringAsFixed(2)} Hz',
                          normalMin: 49.5,
                          normalMax: 50.5,
                          currentValue: g.frequencyHz,
                          isStable: g.isFrequencyStable,
                          icon: Icons.waves,
                        ),
                        _GridMetricWithIndicator(
                          label: 'Voltaje',
                          value: '${g.voltageV.toStringAsFixed(1)} V',
                          normalMin: 190.0,
                          normalMax: 250.0,
                          currentValue: g.voltageV,
                          isStable: g.isVoltageStable,
                          icon: Icons.bolt,
                        ),
                        _GridRow(
                          label: 'Total hoy',
                          value:
                              '${g.totalGeneratedTodayKwh.toStringAsFixed(2)} kWh',
                          icon: Icons.battery_charging_full,
                          color: Colors.blue,
                        ),
                        _GridRow(
                          label: 'Estado',
                          value: g.connectionState.label,
                          icon: Icons.power,
                          color: Colors.indigo,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Stream sin throttle — para comparar la diferencia
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Frecuencia sin throttle (cada 2 s)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                StreamBuilder<GridStatus>(
                  stream: bloc.gridStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final g = snapshot.data!;
                    return Text(
                      '${g.frequencyHz.toStringAsFixed(3)} Hz  ·  '
                      '${g.connectionState.label}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GridMetricWithIndicator extends StatelessWidget {
  final String label;
  final String value;
  final double normalMin;
  final double normalMax;
  final double currentValue;
  final bool isStable;
  final IconData icon;

  const _GridMetricWithIndicator({
    required this.label,
    required this.value,
    required this.normalMin,
    required this.normalMax,
    required this.currentValue,
    required this.isStable,
    required this.icon,
  });

  Color get _statusColor {
    if (isStable) return Colors.green;
    if (currentValue < normalMin * 0.95 || currentValue > normalMax * 1.05) {
      return Colors.red;
    }
    return Colors.orange;
  }

  double get _progressValue {
    final range = normalMax - normalMin;
    final progress = ((currentValue - normalMin) / range).clamp(0.0, 1.0);
    return progress;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isStable ? 'Normal' : 'Alerta',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progressValue,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _GridRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
