import 'dart:async';
import '../models/solar_panel.dart';
import '../models/plant_alert.dart';

class AlertStreamController {

  final StreamController<PlantAlert> _controller =
      StreamController<PlantAlert>.broadcast();

  Stream<PlantAlert> get stream => _controller.stream;

  final List<PlantAlert> _alertHistory = [];
  List<PlantAlert> get alertHistory => List.unmodifiable(_alertHistory);

  StreamSubscription<List<SolarPanel>>? _energySubscription;

  final Set<String> _activeAlertKeys = {};

  int _alertCounter = 0;

  void listenToEnergyStream(Stream<List<SolarPanel>> energyStream) {
    _energySubscription = energyStream.listen(
      _analyzePanel,
      onError: (error) {

        _controller.addError(Exception('Error de sensor: $error'));
      },

      cancelOnError: false,
    );
  }

  void _analyzePanel(List<SolarPanel> panels) {
    if (_controller.isClosed) return;

    for (final panel in panels) {
      _checkOverheating(panel);
      _checkUnderperformance(panel);
      _checkOffline(panel);
    }

    _activeAlertKeys.removeWhere((key) {
      final panelId = key.split('_').first;
      final panel = panels.firstWhere(
        (p) => p.id == panelId,
        orElse: () => panels.first,
      );
      return panel.status == PanelStatus.optimal;
    });
  }

  void _checkOverheating(SolarPanel panel) {
    final key = '${panel.id}_temp';
    if (panel.isOverheating && !_activeAlertKeys.contains(key)) {
      _activeAlertKeys.add(key);
      _emit(PlantAlert(
        id: 'ALT-${++_alertCounter}',
        severity: panel.temperatureCelsius > 85
            ? AlertSeverity.critical
            : AlertSeverity.warning,
        type: AlertType.overheating,
        panelId: panel.id,
        message:
            'Panel ${panel.id}: ${panel.temperatureCelsius.toStringAsFixed(1)}°C '
            '— límite seguro 75°C',
        timestamp: panel.timestamp,
      ));
    }
  }

  void _checkUnderperformance(SolarPanel panel) {
    final key = '${panel.id}_eff';
    if (panel.isUnderperforming && !_activeAlertKeys.contains(key)) {
      _activeAlertKeys.add(key);
      _emit(PlantAlert(
        id: 'ALT-${++_alertCounter}',
        severity: AlertSeverity.warning,
        type: AlertType.underperformance,
        panelId: panel.id,
        message:
            'Panel ${panel.id}: eficiencia del '
            '${(panel.efficiency * 100).toStringAsFixed(0)}% — mínimo 60%',
        timestamp: panel.timestamp,
      ));
    }
  }

  void _checkOffline(SolarPanel panel) {
    final key = '${panel.id}_offline';
    if (panel.status == PanelStatus.offline && !_activeAlertKeys.contains(key)) {
      _activeAlertKeys.add(key);
      _emit(PlantAlert(
        id: 'ALT-${++_alertCounter}',
        severity: AlertSeverity.critical,
        type: AlertType.panelOffline,
        panelId: panel.id,
        message: 'Panel ${panel.id} sin señal — posible falla eléctrica',
        timestamp: panel.timestamp,
      ));
    }
  }

  void _emit(PlantAlert alert) {
    if (_controller.isClosed) return;
    _alertHistory.add(alert);
    _controller.sink.add(alert);
  }

  void acknowledgeAlert(String alertId) {
    final idx = _alertHistory.indexWhere((a) => a.id == alertId);
    if (idx == -1) return;
    _alertHistory[idx] = _alertHistory[idx].acknowledge();
  }

  void dispose() {
   
    _energySubscription?.cancel();
    _controller.close();
  }
}