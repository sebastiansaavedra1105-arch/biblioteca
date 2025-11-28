import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/models/libro.dart';

class LibrosProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();

  // --- ESTADO ---
  List<Libro> _libros = [];
  List<Map<String, dynamic>> _prestamosActivos = [];
  Map<String, int> _estadisticas = {
    'totalLibros': 0,
    'prestamosActivos': 0,
    'librosDisponibles': 0,
  };

  bool _isLoading = false;
  String? _error;

  // --- CONSTRUCTOR MAGICO ---
  LibrosProvider() {
    debugPrint("🚀 LibrosProvider INICIALIZADO - Iniciando carga automática...");
    cargarTodo();
    // Intentamos sincronizar pendientes al abrir la app
    _syncService.sincronizarPendientes(); 
  }

  // --- GETTERS ---
  List<Libro> get libros => _libros;
  List<Map<String, dynamic>> get prestamosActivos => _prestamosActivos;
  Map<String, int> get estadisticas => _estadisticas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- LÓGICA DE CARGA (Lectura siempre desde Local) ---
  
  Future<void> cargarTodo() async {
    _isLoading = true;
    try {
      await Future.wait([
        cargarLibros(),
        cargarEstadisticas(),
        cargarPrestamos(),
      ]);
    } catch (e) {
      _error = "Error al cargar datos: $e";
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarLibros() async {
    try {
      final data = await _dbService.obtenerTodosLosLibros();
      _libros = data.map((map) => Libro.fromMap(map)).toList();
    } catch (e) {
      debugPrint("Error libros: $e");
    }
  }

  Future<void> cargarEstadisticas() async {
    try {
      _estadisticas = await _dbService.obtenerEstadisticas();
    } catch (e) {
      debugPrint("Error stats: $e");
    }
  }

  Future<void> cargarPrestamos() async {
    try {
      _prestamosActivos = await _dbService.obtenerPrestamosActivos();
    } catch (e) {
      debugPrint("Error prestamos: $e");
    }
  }

  // --- ACCIONES DE ESCRITURA (Usando SyncService) ---

  Future<bool> agregarLibro(Libro nuevoLibro) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Preparamos el mapa y quitamos el ID si es nulo para que SyncService genere uno nuevo
      final datos = nuevoLibro.toMap();
      if (datos['id'] == null) {
        datos.remove('id');
      }

      // Usamos SyncService para insertar (Local + Cola/Nube)
      await _syncService.insertar('libros', datos);
      
      await cargarTodo(); // Refrescar UI
      return true;
    } catch (e) {
      _error = "Error al guardar libro: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editarLibro(Libro libro) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (libro.id == null) throw Exception("El libro no tiene ID");

      // Usamos SyncService para actualizar
      await _syncService.actualizar('libros', libro.toMap(), libro.id!);
      
      await cargarTodo();
      return true;
    } catch (e) {
      _error = "Error al editar: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CAMBIO: ID es String
  Future<void> borrarLibro(String id) async {
    try {
      await _syncService.eliminar('libros', id);
      await cargarTodo(); 
    } catch (e) {
      _error = "Error al borrar: $e";
      notifyListeners();
    }
  }

  Future<Libro?> buscarLibroPorCodigo(String codigo) async {
    final res = await _dbService.buscarLibroPorCodigo(codigo);
    if (res != null) {
      return Libro.fromMap(res);
    }
    return null;
  }

  // --- ACCIONES DE PRÉSTAMOS (Transacciones Manuales con SyncService) ---

  Future<bool> registrarPrestamo({
    required Libro libro,
    required String codigoAlumno,
    required String nombreAlumno,
    required DateTime fechaEntrega,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Crear el Préstamo
      final prestamoMap = {
        'libro_id': libro.id,
        'libro_titulo': libro.titulo,
        'codigo_alumno': codigoAlumno,
        'nombre_alumno': nombreAlumno,
        'fecha_prestamo': DateTime.now().toIso8601String(),
        'fecha_entrega': fechaEntrega.toIso8601String(),
        'activo': 1 // 1 = True en SQLite/Supabase int
      };
      
      // Insertamos el préstamo
      await _syncService.insertar('prestamos', prestamoMap);

      // 2. Actualizar el Stock del Libro (Restar 1)
      final nuevoStock = libro.copiasDisponibles - 1;
      await _syncService.actualizar(
        'libros', 
        {'copias_disponibles': nuevoStock}, 
        libro.id!
      );

      await cargarTodo();
      return true;
    } catch (e) {
      _error = "Error préstamo: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CAMBIO: IDs son String
  Future<void> devolverLibro(String prestamoId, String libroId) async {
    try {
      // 1. Marcar préstamo como inactivo (devuelto)
      await _syncService.actualizar(
        'prestamos', 
        {'activo': 0}, 
        prestamoId
      );

      // 2. Buscar el libro actual en memoria para saber su stock actual
      // (Opcional: podríamos buscarlo en DB, pero en memoria es más rápido)
      final libroActual = _libros.firstWhere((l) => l.id == libroId, orElse: () => Libro(
        id: 'temp', codigoBarras: '', titulo: '', autor: '', isbn: '', anio: 0, editorial: '', categoria: '', copias: 0, copiasDisponibles: 0, estado: '', observacion: ''
      ));

      if (libroActual.id != 'temp') {
        // Aumentar stock (+1)
        await _syncService.actualizar(
          'libros', 
          {'copias_disponibles': libroActual.copiasDisponibles + 1}, 
          libroId
        );
      } else {
        // Fallback si no está en memoria: usar DatabaseService para ejecutar un update directo si fuera necesario, 
        // pero con SyncService lo ideal es enviar el valor.
        // Por seguridad, recargamos y reintentamos o dejamos que la carga actualice.
        debugPrint("Libro no encontrado en memoria para actualizar stock, se recomienda recargar.");
      }

      await cargarTodo();
    } catch (e) {
      _error = "Error devolución: $e";
      notifyListeners();
    }
  }
}