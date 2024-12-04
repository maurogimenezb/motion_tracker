import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:gsheets/gsheets.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class MotionTracker extends StatefulWidget {
  const MotionTracker({super.key});

  @override
  _MotionTrackerState createState() => _MotionTrackerState();
}

class _MotionTrackerState extends State<MotionTracker> {
  int _steps = 0; // Contador de pasos
  double _lastZ = 0.0; // Valor anterior de aceleración en el eje Z
  bool _isStepDetected = false;
  final String sessionId =
      Uuid().v4(); // Genera un identificador único por sesión
  DateTime? _startTime; // Fecha y hora de inicio
  Timer? _timer; // Timer para registrar la duración

  // Google Sheets
  late GSheets _gsheets;
  late Spreadsheet _spreadsheet;
  Worksheet? _worksheet;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSheets();
    _startSession(); // Inicia la sesión

    // Escuchar el evento del acelerómetro
    accelerometerEvents.listen((AccelerometerEvent event) {
      double z = event.z;

      // Detectar un paso basado en un cambio en el eje Z
      if (!_isStepDetected && (z - _lastZ).abs() > 1.5) {
        setState(() {
          _steps++; // Incrementa el contador de pasos
          _isStepDetected = true;
        });
      } else if ((z - _lastZ).abs() < 0.5) {
        setState(() {
          _isStepDetected = false;
        });
      }

      _lastZ = z; // Actualiza el valor anterior de Z
    });
  }

  Future<void> _initializeGoogleSheets() async {
    try {
      // Carga las credenciales
      final credentials =
          await rootBundle.loadString('assets/credentials.json');
      _gsheets = GSheets(credentials);

      // Conecta a la hoja de cálculo
      print('Conectando a Google Sheets...');
      const spreadsheetId = ''; // ID
      _spreadsheet = await _gsheets.spreadsheet(spreadsheetId);
      print('Conexión exitosa.');

      // se Obtiene o se crea la hoja de trabajo
      _worksheet = _spreadsheet.worksheetByTitle('Step Data') ??
          await _spreadsheet.addWorksheet('Step Data');
      print('Hoja seleccionada o creada.');

      // Agrega encabezados si no existen
      await _worksheet?.values.insertRow(1, [
        'Session ID',
        'Fecha Inicio',
        'Fecha Fin',
        'Pasos',
        'Periodo del Día',
        'Día de la Semana'
      ]);
      print('Encabezados insertados correctamente.');
    } catch (e) {
      print('Error inicializando Google Sheets: $e');
    }
  }

  void _endSession() async {
    DateTime endTime = DateTime.now(); // Marca la hora de fin
    final dateFormatter = DateFormat('d/M/yyyy HH:mm:ss'); // Formato

    try {
      // Guarda los datos
      print('Guardando datos en Google Sheets...');
      await _worksheet?.values.appendRow([
        sessionId,
        _startTime != null ? dateFormatter.format(_startTime!) : '',
        dateFormatter.format(endTime),
        _steps,
        _getTimePeriod(endTime),
        _getDayOfWeek(endTime)
      ]);
      print('Datos guardados exitosamente.');
    } catch (e) {
      print('Error guardando en Google Sheets: $e');
    }

    // Reinicia la sesión
    _timer?.cancel();
    _startSession();
  }

  void _startSession() {
    setState(() {
      _startTime = DateTime.now(); // Marca la hora de inicio
      _steps = 0; // Reinicia el contador de pasos
    });

    // Reinicia el temporizador si ya existía
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(
          () {}); // Refresca la interfaz para mostrar el tiempo transcurrido
    });
  }

  String _getTimePeriod(DateTime dateTime) {
    int hour = dateTime.hour;
    if (hour >= 6 && hour < 12) {
      return "Mañana";
    } else if (hour >= 12 && hour < 18) {
      return "Tarde";
    } else {
      return "Noche";
    }
  }

  String _getDayOfWeek(DateTime dateTime) {
    List<String> days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado'
    ];
    return days[dateTime.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Step Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pasos: $_steps',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_startTime != null)
              Text(
                'Inicio: ${_startTime!.toLocal()}',
                style: const TextStyle(fontSize: 16),
              ),
            ElevatedButton(
              onPressed: _endSession,
              child: const Text('Finalizar Sesión y Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
