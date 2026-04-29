import 'dart:async';
import '../models/solar_panel.dart';
import '../models/plant_alert.dart';
import '../models/production_history.dart';
import 'energy_stream_controller.dart';
import 'alert_stream_controller.dart';
import 'grid_stream_controller.dart';

class SolarMonitorBloc {
  final EnergyStreamController _energyCtrl = EnergyStreamController();
  final AlertStreamController _alertCtrl = AlertStreamController();
  final GridStreamController _gridCtrl = GridStreamController();

  Stream<List<SolarPanel>> get panelStream => _energyCtrl.stream;
  Stream<double> get totalOutputKwStream => _energyCtrl.totalOutputKwStream;
  Stream<double> get averageEfficiencyStream =>
      _energyCtrl.averageEfficiencyStream;

  Stream<PlantAlert> get alertStream => _alertCtrl.stream;

  Stream<GridStatus> get gridStream => _gridCtrl.stream;
  Stream<GridStatus> get throttledGridStream => _gridCtrl.throttledStream;

  late final Stream<PlantSummary> summaryStream;

  final StreamController<PlantSummary> _summaryCtrl =
      StreamController<PlantSummary>.broadcast();

  double _lastOutputKw = 0.0;
  double _previousOutputKw = 0.0;
  GridStatus? _lastGrid;

  // Histórico de producción
  final List<ProductionDataPoint> _productionHistory = [];
  Timer? _historyTimer;
  double _maxKwToday = 0.0;
  double _sumKwToday = 0.0;
  int _countKwToday = 0;

  late final Stream<ProductionStats> productionStatsStream;
  final StreamController<ProductionStats> _productionStatsCtrl =
      StreamController<ProductionStats>.broadcast();

  StreamSubscription<double>? _outputSub;
  StreamSubscription<GridStatus>? _gridSub;

  SolarMonitorBloc() {
    _alertCtrl.listenToEnergyStream(_energyCtrl.stream);

    summaryStream = _summaryCtrl.stream;
    productionStatsStream = _productionStatsCtrl.stream;

    _outputSub = totalOutputKwStream.listen((kw) {
      _previousOutputKw = _lastOutputKw;
      _lastOutputKw = kw;

      // Actualizar máximo y promedio del día
      _maxKwToday = kw > _maxKwToday ? kw : _maxKwToday;
      _sumKwToday += kw;
      _countKwToday++;

      _emitSummary();
    });

    _gridSub = _gridCtrl.stream.listen((grid) {
      _lastGrid = grid;
      _emitSummary();
    });

    // Iniciar recolección de histórico cada 30 segundos
    _startHistoryCollection();
  }

  void _emitSummary() {
    if (_summaryCtrl.isClosed || _lastGrid == null) return;

    _summaryCtrl.sink.add(
      PlantSummary(
        totalOutputKw: _lastOutputKw,
        exportingKw: _lastGrid!.exportingKw,
        totalGeneratedTodayKwh: _lastGrid!.totalGeneratedTodayKwh,
        connectionState: _lastGrid!.connectionState,
        timestamp: DateTime.now(),
      ),
    );

    _emitProductionStats();
  }

  void _emitProductionStats() {
    if (_productionStatsCtrl.isClosed) return;

    final averageKw = _countKwToday > 0 ? _sumKwToday / _countKwToday : 0.0;

    _productionStatsCtrl.sink.add(
      ProductionStats(
        dataPoints: List.from(_productionHistory),
        currentKw: _lastOutputKw,
        previousKw: _previousOutputKw,
        maxKwToday: _maxKwToday,
        averageKwToday: averageKw,
      ),
    );
  }

  void _startHistoryCollection() {
    _historyTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _productionHistory.add(
        ProductionDataPoint(
          timestamp: DateTime.now(),
          productionKw: _lastOutputKw,
        ),
      );

      // Mantener solo últimas 48 muestras (24 horas a 30 seg cada una)
      if (_productionHistory.length > 48) {
        _productionHistory.removeAt(0);
      }

      _emitProductionStats();
    });
  }

  void setPanelMaintenance(String panelId) =>
      _energyCtrl.setPanelMaintenance(panelId);

  void restorePanel(String panelId) => _energyCtrl.restorePanel(panelId);

  void acknowledgeAlert(String alertId) => _alertCtrl.acknowledgeAlert(alertId);

  void startMonitoring() {
    _energyCtrl.startSimulation();
    _gridCtrl.startSimulation();
  }

  void dispose() {
    _outputSub?.cancel();
    _gridSub?.cancel();
    _historyTimer?.cancel();
    _energyCtrl.dispose();
    _alertCtrl.dispose();
    _gridCtrl.dispose();
    _summaryCtrl.close();
    _productionStatsCtrl.close();
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
