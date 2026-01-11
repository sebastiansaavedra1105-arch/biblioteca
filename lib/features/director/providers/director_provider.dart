import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart'; // NECESARIO PARA ENCRIPTAR
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/sync_service.dart';

class DirectorProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  final _uuid = const Uuid();

  List<Map<String, dynamic>> _usuarios = [];
  
  // Stats
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

  // --- GESTIÓN DE USUARIOS (CRUD SEGURO) ---

  Future<void> cargarUsuarios() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _dbService.database;
      // Traemos todos los usuarios
      _usuarios = await db.query('usuarios', orderBy: 'nombre ASC');
    } catch (e) {
      _error = "Error cargando usuarios: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CREAR USUARIO (Siempre pide contraseña)
  Future<bool> crearUsuario({
    required String username, 
    required String password, 
    required String nombre, 
    required String rol
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Encriptar contraseña
      final String hashPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // 2. Preparar datos
      final nuevoUsuario = {
        'id': _uuid.v4(),
        'username': username,
        'password': hashPassword, // Guardamos el HASH, no el texto plano
        'nombre': nombre,
        'rol': rol,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 3. Insertar (Sincronizado)
      await _syncService.insertar('usuarios', nuevoUsuario);
      
      await cargarUsuarios();
      return true;
    } catch (e) {
      _error = "Error creando usuario: $e";
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // EDITAR USUARIO (Contraseña opcional)
  Future<bool> editarUsuario({
    required String id,
    required String username,
    String? password, // Puede ser null o vacío si no se quiere cambiar
    required String nombre,
    required String rol
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> datosActualizar = {
        'username': username,
        'nombre': nombre,
        'rol': rol,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // SOLO si escribió una nueva contraseña, la encriptamos y la agregamos al mapa
      if (password != null && password.isNotEmpty) {
        final String hashPassword = BCrypt.hashpw(password, BCrypt.gensalt());
        datosActualizar['password'] = hashPassword;
      }

      // Actualizar (Sincronizado)
      await _syncService.actualizar('usuarios', datosActualizar, id);

      await cargarUsuarios();
      return true;
    } catch (e) {
      _error = "Error editando usuario: $e";
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ELIMINAR USUARIO
  Future<bool> eliminarUsuario(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _syncService.borrar('usuarios', id);
      await cargarUsuarios();
      return true;
    } catch (e) {
      _error = "Error eliminando: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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