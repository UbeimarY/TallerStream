import 'package:flutter/material.dart';
import 'streams/solar_monitor_bloc.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const SolarPlantApp());
}

class SolarPlantApp extends StatefulWidget {
  const SolarPlantApp({super.key});

  @override
  State<SolarPlantApp> createState() => _SolarPlantAppState();
}

class _SolarPlantAppState extends State<SolarPlantApp> {
  late final SolarMonitorBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = SolarMonitorBloc();
    _bloc.startMonitoring();
  }

  @override
  void dispose() {
    // Cierra todos los StreamControllers cuando la app se destruye
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planta Solar Orión',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: DashboardScreen(bloc: _bloc),
    );
  }
}
