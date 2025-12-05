import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // Necesario para consultas directas
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

  // --- CARGA DE DATOS ---
  Future<void> cargarAlumnos({String query = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;
      List<Map<String, dynamic>> data;

      if (query.isEmpty) {
        data = await db.query('alumnos', orderBy: 'nombre_completo ASC');
      } else {
        // Búsqueda optimizada por nombre o código
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

  // --- GUARDAR / EDITAR (UPSERT) ---
  Future<bool> guardarAlumno(Alumno alumno, {bool esEdicion = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final mapa = alumno.toMap();
      
      if (esEdicion && alumno.id != null) {
        // Actualizar
        await _syncService.actualizar('alumnos', mapa, alumno.id!);
      } else {
        // Insertar (Quitamos ID nulo para que SyncService genere UUID)
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

  // --- ELIMINAR SEGURO (CON VALIDACIÓN) ---
  // Devuelve un Mapa: {'success': bool, 'message': String}
  Future<Map<String, dynamic>> borrarAlumno(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;

      // 1. VERIFICACIÓN DE SEGURIDAD
      // Contamos si tiene préstamos ACTIVOS (libros sin devolver)
      final activeCount = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM prestamos WHERE alumno_id = ? AND activo = 1",
        [id]
      )) ?? 0;

      if (activeCount > 0) {
        // ⛔ BLOQUEO: Tiene libros pendientes
        return {
          'success': false, 
          'message': 'DENEGADO: El alumno tiene $activeCount libro(s) sin devolver.'
        };
      }

      // 2. Si está limpio, procedemos a borrar
      // (Gracias al ON DELETE SET NULL en SQL, el historial textual se mantiene)
      await _syncService.borrar('alumnos', id);
      
      await cargarAlumnos();
      return {'success': true, 'message': 'Alumno eliminado correctamente.'};

    } catch (e) {
      return {'success': false, 'message': "Error técnico: $e"};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}