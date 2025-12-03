import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/models/alumno.dart';

class AlumnosProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();

  List<Alumno> _alumnos = [];
  bool _isLoading = false;
  String? _error;

  List<Alumno> get alumnos => _alumnos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- CARGA ---
  Future<void> cargarAlumnos({String query = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;
      List<Map<String, dynamic>> data;

      if (query.isEmpty) {
        data = await db.query('alumnos', orderBy: 'nombre_completo ASC');
      } else {
        // Búsqueda por nombre o código
        data = await db.query(
          'alumnos',
          where: 'nombre_completo LIKE ? OR codigo LIKE ?',
          whereArgs: ['%$query%', '%$query%'],
          orderBy: 'nombre_completo ASC',
        );
      }

      _alumnos = data.map((e) => Alumno.fromMap(e)).toList();
    } catch (e) {
      _error = "Error cargando alumnos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- GUARDAR / EDITAR ---
  Future<bool> guardarAlumno(Alumno alumno, {bool esEdicion = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final mapa = alumno.toMap();
      
      if (esEdicion && alumno.id != null) {
        // Actualizar
        await _syncService.actualizar('alumnos', mapa, alumno.id!);
      } else {
        // Insertar (Quitamos ID nulo para que se genere uno nuevo)
        if (mapa['id'] == null) mapa.remove('id');
        await _syncService.insertar('alumnos', mapa);
      }

      await cargarAlumnos();
      return true;
    } catch (e) {
      _error = "Error guardando alumno: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ELIMINAR ---
  Future<bool> eliminarAlumno(String id) async {
    try {
      await _syncService.eliminar('alumnos', id);
      await cargarAlumnos();
      return true;
    } catch (e) {
      _error = "Error eliminando: $e";
      return false;
    }
  }
}