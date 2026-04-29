import 'dart:async';
import 'dart:math';

class GridStatus {
  final double exportingKw;
  final double frequencyHz;
  final double voltageV;
  final GridConnectionState connectionState;
  final double totalGeneratedTodayKwh;
  final DateTime timestamp;

  const GridStatus({
    required this.exportingKw,
    required this.frequencyHz,
    required this.voltageV,
    required this.connectionState,
    required this.totalGeneratedTodayKwh,
    required this.timestamp,
  });

  bool get isFrequencyStable => frequencyHz >= 59.8 && frequencyHz <= 60.2;
  bool get isVoltageStable => voltageV >= 218.0 && voltageV <= 242.0;
}

enum GridConnectionState { connected, exporting, importing, disconnected, fault }

extension GridConnectionLabel on GridConnectionState {
  String get label {
    switch (this) {
      case GridConnectionState.connected:     return 'Conectado';
      case GridConnectionState.exporting:     return 'Exportando energía';
      case GridConnectionState.importing:     return 'Importando energía';
      case GridConnectionState.disconnected:  return 'Desconectado';
      case GridConnectionState.fault:         return 'Falla detectada';
    }
  }
}

// ── StreamTransformerBase personalizado ───────────────────────────────────────
// Extiende StreamTransformerBase en lugar de usar fromHandlers() cuando
// necesitas lógica con estado propio — en este caso, rastrear el tiempo
// del último evento emitido para aplicar throttle.
class ThrottleTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;

  const ThrottleTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    // Creamos un nuevo controller interno para el stream resultante
    late StreamController<T> outputController;
    DateTime? lastEmit;
    StreamSubscription<T>? subscription;

    outputController = StreamController<T>.broadcast(
      onListen: () {
        // Solo empieza a escuchar cuando alguien se suscribe
        subscription = stream.listen(
          (event) {
            final now = DateTime.now();
            if (lastEmit == null || now.difference(lastEmit!) >= duration) {
              lastEmit = now;
              outputController.sink.add(event);
            }
            // Si no pasó suficiente tiempo, el evento se descarta silenciosamente
          },
          onError: outputController.addError,
          onDone: outputController.close,
        );
      },
      onCancel: () => subscription?.cancel(),
    );

    return outputController.stream;
  }
}

class GridStreamController {
  final StreamController<GridStatus> _controller =
      StreamController<GridStatus>.broadcast();

  Stream<GridStatus> get stream => _controller.stream;

  // ── Stream con throttle aplicado ──────────────────────────────────────────
  // El stream base emite cada 2 segundos.
  // Este stream derivado emite como máximo una vez cada 5 segundos.
  // Útil para widgets que no necesitan tanta frecuencia de actualización.
  late final Stream<GridStatus> throttledStream;

  Timer? _simulationTimer;
  final Random _rng = Random();
  double _totalKwhToday = 0.0;
  GridStatus? _lastStatus;

  GridStreamController() {
    throttledStream = stream.transform(
      ThrottleTransformer<GridStatus>(const Duration(seconds: 5)),
    );
  }

  void startSimulation() {
    _simulationTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _tick());
  }

  void _tick() {
    if (_controller.isClosed) return;

    final now = DateTime.now();
    final hour = now.hour + now.minute / 60.0;
    final solarFactor = _solarFactor(hour);

    final exportKw =
        ((85.0 * solarFactor) + (_rng.nextDouble() - 0.5) * 5.0)
            .clamp(0.0, 85.0);

    // Acumula kWh — cada tick son 2 segundos = 2/3600 horas
    _totalKwhToday += exportKw * (2.0 / 3600.0);

    final freq = (60.0 + (_rng.nextDouble() - 0.5) * 0.4).clamp(59.5, 60.5);
    final volt = (230.0 + (_rng.nextDouble() - 0.5) * 8.0).clamp(210.0, 250.0);

    final status = GridStatus(
      exportingKw: exportKw,
      frequencyHz: freq,
      voltageV: volt,
      connectionState: _deriveState(exportKw, freq, volt),
      totalGeneratedTodayKwh: _totalKwhToday,
      timestamp: now,
    );

    _lastStatus = status;
    _controller.sink.add(status);
  }

  GridConnectionState _deriveState(double kw, double freq, double volt) {
    if (freq < 59.5 || volt < 210.0 || volt > 250.0) {
      return GridConnectionState.fault;
    }
    if (kw > 1.0) return GridConnectionState.exporting;
    if (kw < -1.0) return GridConnectionState.importing;
    return GridConnectionState.connected;
  }

  double _solarFactor(double hour) {
    if (hour < 6.0 || hour > 19.0) return 0.0;
    return sin((hour - 6.0) / 13.0 * pi).clamp(0.0, 1.0);
  }

  GridStatus? get lastStatus => _lastStatus;

  void dispose() {
    _simulationTimer?.cancel();
    _controller.close();
  }
}