import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart'; 
import 'package:file_picker/file_picker.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/sync_service.dart';

class DirectorProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();

  List<Map<String, dynamic>> _usuarios = [];
  
  List<Map<String, dynamic>> _historialPrestamos = [];
  int _prestamosSemana = 0;
  int _prestamosMes = 0;
  int _devolucionesMes = 0;

  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get usuarios => _usuarios;
  List<Map<String, dynamic>> get historialPrestamos => _historialPrestamos;
  int get prestamosSemana => _prestamosSemana;
  int get prestamosMes => _prestamosMes;
  int get devolucionesMes => _devolucionesMes;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  DirectorProvider() {
    cargarUsuarios();
    cargarReportes(); 
  }

  Future<void> forzarSincronizacionManual() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Llamamos al servicio para bajar datos frescos
      await _syncService.forzarDescargaNube();
      
      // 2. Recargamos los datos en memoria para ver los cambios reflejados
      await cargarUsuarios();
      await cargarReportes();
      
    } catch (e) {
      _error = "Error al sincronizar: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- GESTIÓN DE USUARIOS ---

  Future<void> cargarUsuarios() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _dbService.database;
      final data = await db.query('usuarios', orderBy: 'username ASC');
      _usuarios = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = "Error cargando usuarios: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> crearUsuario(String u, String p, String n, String r) async {
    try {
      _isLoading = true;
      notifyListeners();

      final hash = BCrypt.hashpw(p, BCrypt.gensalt());
      await _syncService.insertar('usuarios', {
        'username': u, 
        'password': hash, 
        'nombre': n, 
        'rol': r, 
        'created_at': DateTime.now().toIso8601String()
      });
      
      await cargarUsuarios();
      return true;
    } catch (e) {
      _error = "Error al crear: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarUsuario(String id) async {
    try {
      await _syncService.eliminar('usuarios', id);
      await cargarUsuarios();
      return true;
    } catch (e) {
      _error = "Error al eliminar: $e";
      return false;
    }
  }

  Future<bool> editarUsuario(String id, String n, String r, String? p) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      Map<String, dynamic> d = {'nombre': n, 'rol': r};
      if(p != null && p.isNotEmpty) {
        d['password'] = BCrypt.hashpw(p, BCrypt.gensalt());
      }
      
      await _syncService.actualizar('usuarios', d, id);
      await cargarUsuarios();
      return true;
    } catch (e) {
      _error = "Error al editar: $e";
      notifyListeners();
      return false;
    }
  }

  // --- REPORTES ---

  Future<void> cargarReportes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final todos = await _dbService.obtenerHistorialPrestamos();
      _historialPrestamos = todos;

      final ahora = DateTime.now();
      final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
      final inicioMes = DateTime(ahora.year, ahora.month, 1);

      _prestamosSemana = 0;
      _prestamosMes = 0;
      _devolucionesMes = 0;

      for (var p in todos) {
        final fechaPrestamo = DateTime.parse(p['fecha_prestamo']);
        final esDevuelto = p['activo'] == 0;

        if (fechaPrestamo.isAfter(inicioSemana)) {
          _prestamosSemana++;
        }

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

  Future<String?> descargarReporteCsv() async {
    try {
      StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln("ID,LIBRO,ALUMNO,FECHA_PRESTAMO,ESTADO"); 

      for (var p in _historialPrestamos) {
        final estado = (p['activo'] == 1) ? "ACTIVO" : "DEVUELTO";
        final titulo = (p['libro_titulo'] ?? '').toString().replaceAll(',', '');
        final alumno = (p['nombre_alumno'] ?? '').toString().replaceAll(',', '');
        
        csvBuffer.writeln("${p['id']},$titulo,$alumno,${p['fecha_prestamo']},$estado");
      }

      final fecha = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
      
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar Reporte de Biblioteca',
        fileName: 'reporte_biblioteca_$fecha.csv',
        allowedExtensions: ['csv'],
        type: FileType.custom,
        lockParentWindow: true,
      );

      if (path != null) {
        String finalPath = path;
        if (!finalPath.toLowerCase().endsWith('.csv')) {
          finalPath = '$finalPath.csv';
        }

        await File(finalPath).writeAsString(csvBuffer.toString());
        return finalPath; 
      } else {
        return null;
      }

    } catch (e) {
      _error = "Error exportando: $e";
      notifyListeners();
      return null;
    }
  }

  // --- ZONA DE MANTENIMIENTO ---
  
  Future<bool> limpiarPrestamos() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _syncService.nukePrestamos();
      await cargarReportes(); 
      return true;
    } catch (e) {
      _error = "Error: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> limpiarLibros() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _syncService.nukeLibros();
      await cargarReportes();
      return true;
    } catch (e) {
      _error = "Error: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> limpiarTodo() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _syncService.nukeTodo();
      await cargarReportes();
      return true;
    } catch (e) {
      _error = "Error: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}