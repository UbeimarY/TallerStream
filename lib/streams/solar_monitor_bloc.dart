import 'dart:async';
import '../models/solar_panel.dart';
import '../models/plant_alert.dart';
import 'energy_stream_controller.dart';
import 'alert_stream_controller.dart';
import 'grid_stream_controller.dart';

class SolarMonitorBloc {

  final EnergyStreamController _energyCtrl = EnergyStreamController();
  final AlertStreamController _alertCtrl = AlertStreamController();
  final GridStreamController _gridCtrl = GridStreamController();

  Stream<List<SolarPanel>> get panelStream => _energyCtrl.stream;
  Stream<double> get totalOutputKwStream => _energyCtrl.totalOutputKwStream;
  Stream<double> get averageEfficiencyStream => _energyCtrl.averageEfficiencyStream;

  Stream<PlantAlert> get alertStream => _alertCtrl.stream;

  Stream<GridStatus> get gridStream => _gridCtrl.stream;
  Stream<GridStatus> get throttledGridStream => _gridCtrl.throttledStream;

  late final Stream<PlantSummary> summaryStream;

  final StreamController<PlantSummary> _summaryCtrl =
      StreamController<PlantSummary>.broadcast();

  double _lastOutputKw = 0.0;
  GridStatus? _lastGrid;

  StreamSubscription<double>? _outputSub;
  StreamSubscription<GridStatus>? _gridSub;

  SolarMonitorBloc() {

    _alertCtrl.listenToEnergyStream(_energyCtrl.stream);

    summaryStream = _summaryCtrl.stream;

    _outputSub = totalOutputKwStream.listen((kw) {
      _lastOutputKw = kw;
      _emitSummary();
    });

    _gridSub = _gridCtrl.stream.listen((grid) {
      _lastGrid = grid;
      _emitSummary();
    });
  }

  void _emitSummary() {

    if (_summaryCtrl.isClosed || _lastGrid == null) return;

    _summaryCtrl.sink.add(PlantSummary(
      totalOutputKw: _lastOutputKw,
      exportingKw: _lastGrid!.exportingKw,
      totalGeneratedTodayKwh: _lastGrid!.totalGeneratedTodayKwh,
      connectionState: _lastGrid!.connectionState,
      timestamp: DateTime.now(),
    ));
  }

  void setPanelMaintenance(String panelId) =>
      _energyCtrl.setPanelMaintenance(panelId);

  void restorePanel(String panelId) =>
      _energyCtrl.restorePanel(panelId);

  void acknowledgeAlert(String alertId) =>
      _alertCtrl.acknowledgeAlert(alertId);

  void startMonitoring() {
    _energyCtrl.startSimulation();
    _gridCtrl.startSimulation();
  }

  void dispose() {
    _outputSub?.cancel();
    _gridSub?.cancel();
    _energyCtrl.dispose();
    _alertCtrl.dispose();
    _gridCtrl.dispose();
    _summaryCtrl.close();
  }
}

class PlantSummary {
  final double totalOutputKw;
  final double exportingKw;
  final double totalGeneratedTodayKwh;
  final GridConnectionState connectionState;
  final DateTime timestamp;

  const PlantSummary({
    required this.totalOutputKw,
    required this.exportingKw,
    required this.totalGeneratedTodayKwh,
    required this.connectionState,
    required this.timestamp,
  });
}