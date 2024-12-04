import 'package:flutter/material.dart';
import 'motion_tracker.dart'; // Importa el archivo motion_tracker.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Counter',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0x9f4376f8),
      ),
      home: const MotionTracker(), // Usa MotionTracker como pantalla inicial
    );
  }
}
