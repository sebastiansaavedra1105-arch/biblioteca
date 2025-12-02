import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/libro.dart';

class CatalogoProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Libro> _todosLosLibros = [];
  List<Libro> _librosFiltrados = [];
  bool _isLoading = false;
  
  // --- VARIABLES DE FILTRO ---
  String _busquedaActual = '';
  String _categoriaSeleccionada = 'Todas';
  bool _soloDisponibles = false;

  // Lista de categorías fijas (Mismas que en AgregarLibro)
  final List<String> categorias = [
    'Todas', 'General', 'Ficción', 'No Ficción', 'Ciencia', 'Historia', 
    'Tecnología', 'Arte', 'Matemáticas', 'Literatura', 
    'Comunicación', 'Ciencias Sociales', 'Minedu', 
    'Idiomas', 'Religión', 'Otro'
  ];

  // Getters
  List<Libro> get libros => _librosFiltrados;
  bool get isLoading => _isLoading;
  String get categoriaSeleccionada => _categoriaSeleccionada;
  bool get soloDisponibles => _soloDisponibles;

  CatalogoProvider() {
    cargarCatalogo();
  }

  Future<void> cargarCatalogo() async {
    _isLoading = true;
    notifyListeners();

    try {
      final datos = await _dbService.obtenerTodosLosLibros();
      _todosLosLibros = datos.map((map) => Libro.fromMap(map)).toList();
      _aplicarFiltros();
    } catch (e) {
      debugPrint("Error cargando catálogo: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MÉTODOS DE ACCIÓN ---

  void buscar(String query) {
    _busquedaActual = query;
    _aplicarFiltros();
    notifyListeners();
  }

  void cambiarCategoria(String categoria) {
    _categoriaSeleccionada = categoria;
    _aplicarFiltros();
    notifyListeners();
  }

  void toggleSoloDisponibles(bool valor) {
    _soloDisponibles = valor;
    _aplicarFiltros();
    notifyListeners();
  }

  // --- LÓGICA MAESTRA DE FILTRADO ---
  void _aplicarFiltros() {
    _librosFiltrados = _todosLosLibros.where((libro) {
      // 1. Filtro de Texto
      final query = _busquedaActual.toLowerCase();
      final coincideTexto = libro.titulo.toLowerCase().contains(query) ||
                            libro.autor.toLowerCase().contains(query);

      // 2. Filtro de Categoría
      final coincideCategoria = _categoriaSeleccionada == 'Todas' || 
                                libro.categoria == _categoriaSeleccionada;

      // 3. Filtro de Disponibilidad
      final coincideDisponibilidad = !_soloDisponibles || libro.copiasDisponibles > 0;

      // TIENEN QUE CUMPLIRSE LAS 3 CONDICIONES
      return coincideTexto && coincideCategoria && coincideDisponibilidad;
    }).toList();
  }
}