import 'package:biblio/core/database/database_service.dart'; 
import 'package:flutter/material.dart';
import 'package:biblio/features/dashboard/screens/dashboard_screen.dart'; 

// IMPORTS PARA WEB vs DESKTOP
import 'package:flutter/foundation.dart' show kIsWeb; // Importa 'kIsWeb'
import 'dart:io'; // Para chequear la plataforma (SO)
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // El paquete FFI

void main() async {
  // Chequea si NO estamos en la web
  if (!kIsWeb) {
    // Solo inicializar FFI si NO es web (es decir, es desktop)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // Asegurar que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar la BD
  await DatabaseService.instance.database; 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Biblioteca',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFf9f9f9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(), 
    );
  }
}