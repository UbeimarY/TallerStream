import 'dart:async';
import 'dart:math';
import '../models/solar_panel.dart';

class EnergyStreamController {

  final StreamController<List<SolarPanel>> _controller =
      StreamController<List<SolarPanel>>.broadcast();

  Stream<List<SolarPanel>> get stream => _controller.stream;

  StreamSink<List<SolarPanel>> get _sink => _controller.sink;

  late final Stream<double> totalOutputKwStream;
  late final Stream<double> averageEfficiencyStream;

  final List<SolarPanel> _panels = [];
  Timer? _simulationTimer;
  final Random _rng = Random();

  EnergyStreamController() {
    _initializePanels();
    _setupDerivedStreams();
  }

  void _initializePanels() {
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 6; col++) {
        _panels.add(SolarPanel(
          id: 'P${row.toString().padLeft(2, '0')}-${col.toString().padLeft(2, '0')}',
          row: row,
          column: col,
          currentOutputKw: 3.5 + _rng.nextDouble() * 2.0,
          temperatureCelsius: 45.0 + _rng.nextDouble() * 20.0,
          efficiency: 0.75 + _rng.nextDouble() * 0.20,
          status: PanelStatus.optimal,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  void _setupDerivedStreams() {

    totalOutputKwStream = stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (panels, sink) {
          final total = panels.fold(
            0.0,
            (sum, panel) => panel.status != PanelStatus.offline
                ? sum + panel.currentOutputKw
                : sum,
          );
          sink.add(total);
        },
      ),
    );

    averageEfficiencyStream = stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (panels, sink) {
          final active = panels
              .where((p) =>
                  p.status != PanelStatus.offline &&
                  p.status != PanelStatus.maintenance)
              .toList();
          if (active.isEmpty) {
            sink.add(0.0);
            return;
          }
          final avg =
              active.fold(0.0, (s, p) => s + p.efficiency) / active.length;
          sink.add(avg);
        },
      ),
    );
  }

  void startSimulation() {
    _simulationTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _sink.add(List.unmodifiable(_panels));
  }

  void _tick() {
    if (_controller.isClosed) return;

    final now = DateTime.now();
    final hourFraction = now.hour + now.minute / 60.0;
    final solarFactor = _solarIrradianceFactor(hourFraction);

    for (int i = 0; i < _panels.length; i++) {
      final panel = _panels[i];

      final newOutput =
          ((5.5 * solarFactor) + (_rng.nextDouble() - 0.5) * 0.3)
              .clamp(0.0, 6.5);

      final newTemp =
          (panel.temperatureCelsius + (_rng.nextDouble() - 0.4) * 1.5)
              .clamp(20.0, 95.0);

      final effDelta =
          newTemp > 70 ? -_rng.nextDouble() * 0.02 : (_rng.nextDouble() - 0.45) * 0.01;
      final newEff = (panel.efficiency + effDelta).clamp(0.40, 0.98);

      final newStatus = _deriveStatus(newTemp, newEff, panel.status);

      // copyWith mantiene inmutabilidad — nunca modificamos el panel original
      _panels[i] = panel.copyWith(
        currentOutputKw:
            newOutput * (newStatus == PanelStatus.offline ? 0 : 1),
        temperatureCelsius: newTemp,
        efficiency: newEff,
        status: newStatus,
        timestamp: now,
      );
    }

    _sink.add(List.unmodifiable(_panels));
  }

  double _solarIrradianceFactor(double hour) {
    if (hour < 6.0 || hour > 19.0) return 0.0;
    return sin((hour - 6.0) / 13.0 * pi).clamp(0.0, 1.0);
  }

  PanelStatus _deriveStatus(
      double temp, double eff, PanelStatus current) {
    if (current == PanelStatus.maintenance) return PanelStatus.maintenance;
    if (temp > 85.0) return PanelStatus.overheating;
    if (temp > 75.0) return PanelStatus.degraded;
    if (eff < 0.50) {
      return _rng.nextDouble() < 0.02
          ? PanelStatus.offline
          : PanelStatus.degraded;
    }
    return PanelStatus.optimal;
  }

  void setPanelMaintenance(String panelId) {
    final idx = _panels.indexWhere((p) => p.id == panelId);
    if (idx == -1) return;
    _panels[idx] = _panels[idx].copyWith(
      status: PanelStatus.maintenance,
      currentOutputKw: 0.0,
    );
    _sink.add(List.unmodifiable(_panels));
  }

  void restorePanel(String panelId) {
    final idx = _panels.indexWhere((p) => p.id == panelId);
    if (idx == -1) return;
    _panels[idx] = _panels[idx].copyWith(status: PanelStatus.optimal);
    _sink.add(List.unmodifiable(_panels));
  }

  void dispose() {
    _simulationTimer?.cancel();
    _controller.close();
  }
}