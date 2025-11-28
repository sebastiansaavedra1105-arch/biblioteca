import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/libro.dart';

class LibrosProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

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

  // --- 🔥 CONSTRUCTOR MAGICO ---
  // Apenas arranca la app, este código se ejecuta y trae los datos de la BD
  LibrosProvider() {
    debugPrint("🚀 LibrosProvider INICIALIZADO - Iniciando carga automática...");
    cargarTodo();
  }

  // --- GETTERS ---
  List<Libro> get libros => _libros;
  List<Map<String, dynamic>> get prestamosActivos => _prestamosActivos;
  Map<String, int> get estadisticas => _estadisticas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- LÓGICA DE CARGA ---
  
  Future<void> cargarTodo() async {
    // Solo notificamos carga si es la primera vez o si queremos bloquear la UI explícitamente
    // Para evitar parpadeos innecesarios, a veces es mejor manejar el loading interno
    _isLoading = true;
    // notifyListeners(); // Descomentar si quieres que TODA la app muestre loading al recargar

    try {
      debugPrint("🔄 Cargando datos desde base de datos...");
      
      // Ejecutamos las 3 consultas en paralelo para ser más rápidos
      await Future.wait([
        cargarLibros(),
        cargarEstadisticas(),
        cargarPrestamos(),
      ]);
      
      debugPrint("✅ Carga completa: ${_libros.length} libros, ${_prestamosActivos.length} préstamos.");
    } catch (e) {
      debugPrint("❌ Error general cargando datos: $e");
      _error = "Error al cargar datos";
    } finally {
      _isLoading = false;
      notifyListeners(); // ¡Avisamos a las pantallas que ya hay datos!
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

  // --- ACCIONES DE LIBROS ---

  Future<bool> agregarLibro(Libro nuevoLibro) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbService.insertarLibro(nuevoLibro.toMap());
      await cargarTodo(); // Recargamos para ver el libro nuevo
      return true;
    } catch (e) {
      _error = "Error al guardar: Posible código duplicado";
      return false;
    } finally {
      _isLoading = false;
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

  // --- ACCIONES DE PRÉSTAMOS ---

  Future<bool> registrarPrestamo({
    required Libro libro,
    required String codigoAlumno,
    required String nombreAlumno,
    required DateTime fechaEntrega,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final exito = await _dbService.registrarPrestamo(
        libroId: libro.id!,
        titulo: libro.titulo,
        alumno: codigoAlumno,
        nombreAlumno: nombreAlumno,
        entrega: fechaEntrega,
      );

      if (exito) {
        await cargarTodo(); // Actualizamos stock y lista de préstamos
        return true;
      }
      return false;
    } catch (e) {
      _error = "Error préstamo: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> devolverLibro(int prestamoId, int libroId) async {
    try {
      await _dbService.registrarDevolucion(prestamoId, libroId);
      await cargarTodo(); // Actualizamos todo
    } catch (e) {
      _error = "Error devolución: $e";
      notifyListeners();
    }
  }

  Future<bool> editarLibro(Libro libro) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbService.actualizarLibro(libro.toMap());
      await cargarTodo(); // Refresca la lista para ver los cambios
      return true;
    } catch (e) {
      _error = "Error al editar: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> borrarLibro(int id) async {
    try {
      await _dbService.eliminarLibro(id);
      await cargarTodo(); // El libro desaparece de la lista inmediatamente
    } catch (e) {
      _error = "Error al borrar: $e";
      notifyListeners();
    }
  }

}