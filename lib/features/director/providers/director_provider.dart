import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart'; 
import 'package:path_provider/path_provider.dart'; // Para guardar el archivo
import '../../../core/database/database_service.dart';
import '../../../core/services/sync_service.dart';

class DirectorProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();

  // Usuarios
  List<Map<String, dynamic>> _usuarios = [];
  
  // Reportes
  List<Map<String, dynamic>> _historialPrestamos = [];
  int _prestamosSemana = 0;
  int _prestamosMes = 0;
  int _devolucionesMes = 0;

  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get usuarios => _usuarios;
  List<Map<String, dynamic>> get historialPrestamos => _historialPrestamos;
  int get prestamosSemana => _prestamosSemana;
  int get prestamosMes => _prestamosMes;
  int get devolucionesMes => _devolucionesMes;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  DirectorProvider() {
    cargarUsuarios();
    cargarReportes(); // Cargar datos al iniciar
  }

  // --- GESTIÓN DE USUARIOS (Código anterior) ---
  Future<void> cargarUsuarios() async {
    // ... (Misma lógica que ya tenías, resumida aquí para no repetir todo)
    try {
      final db = await _dbService.database;
      final data = await db.query('usuarios', orderBy: 'username ASC');
      _usuarios = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) { /*...*/ }
  }

  // ... (Tus funciones crearUsuario, editarUsuario, eliminarUsuario se mantienen igual)
  Future<bool> crearUsuario(String u, String p, String n, String r) async {
    // Copia tu función crearUsuario aquí...
    final hash = BCrypt.hashpw(p, BCrypt.gensalt());
    await _syncService.insertar('usuarios', {'username': u, 'password': hash, 'nombre': n, 'rol': r, 'created_at': DateTime.now().toIso8601String()});
    await cargarUsuarios();
    return true;
  }
  Future<bool> eliminarUsuario(String id) async {
    await _syncService.eliminar('usuarios', id);
    await cargarUsuarios();
    return true;
  }
  Future<bool> editarUsuario(String id, String n, String r, String? p) async {
    Map<String, dynamic> d = {'nombre': n, 'rol': r};
    if(p != null && p.isNotEmpty) d['password'] = BCrypt.hashpw(p, BCrypt.gensalt());
    await _syncService.actualizar('usuarios', d, id);
    await cargarUsuarios();
    return true;
  }

  // --- 🔥 NUEVA LÓGICA DE REPORTES ---

  Future<void> cargarReportes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final todos = await _dbService.obtenerHistorialPrestamos();
      _historialPrestamos = todos;

      final ahora = DateTime.now();
      final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1)); // Lunes
      final inicioMes = DateTime(ahora.year, ahora.month, 1);

      _prestamosSemana = 0;
      _prestamosMes = 0;
      _devolucionesMes = 0;

      for (var p in todos) {
        final fechaPrestamo = DateTime.parse(p['fecha_prestamo']);
        final esDevuelto = p['activo'] == 0;

        // Cálculo Semanal
        if (fechaPrestamo.isAfter(inicioSemana)) {
          _prestamosSemana++;
        }

        // Cálculo Mensual
        if (fechaPrestamo.isAfter(inicioMes)) {
          _prestamosMes++;
          if (esDevuelto) _devolucionesMes++;
        }
      }

    } catch (e) {
      _error = "Error calculando reportes: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- DESCARGAR CSV ---
  Future<String?> descargarReporteCsv() async {
    try {
      // 1. Generar contenido CSV
      StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln("ID,LIBRO,ALUMNO,FECHA_PRESTAMO,ESTADO"); // Cabecera

      for (var p in _historialPrestamos) {
        final estado = (p['activo'] == 1) ? "ACTIVO" : "DEVUELTO";
        csvBuffer.writeln("${p['id']},${p['libro_titulo']},${p['nombre_alumno']},${p['fecha_prestamo']},$estado");
      }

      // 2. Obtener ruta de documentos
      final directory = await getApplicationDocumentsDirectory();
      final fecha = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
      final path = "${directory.path}/reporte_biblioteca_$fecha.csv";
      
      // 3. Guardar archivo
      final file = File(path);
      await file.writeAsString(csvBuffer.toString());

      return path; // Retorna la ruta donde se guardó
    } catch (e) {
      _error = "Error exportando: $e";
      return null;
    }
  }
}