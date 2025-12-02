import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';                 

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

  // --- CONSTRUCTOR MÁGICO ---
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
    // notifyListeners(); // Opcional: Evita redibujados innecesarios si ya está cargando
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

// --- IMPORTACIÓN MASIVA BLINDADA ---
  Future<String> importarLibrosDesdeCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result == null) return "Cancelado";

      _isLoading = true;
      notifyListeners();

      final file = File(result.files.single.path!);
      
      // Intentamos leer. Si falla UTF8, usamos Latin1 (común en Excel español)
      String csvString;
      try {
        csvString = await file.readAsString(encoding: utf8);
      } catch (e) {
        csvString = await file.readAsString(encoding: latin1);
      }

      // Convertidor robusto: 'shouldParseNumbers: false' para que los códigos de barra no se vuelvan notación científica
      List<List<dynamic>> rows = const CsvToListConverter(
        fieldDelimiter: ',', 
        eol: '\n', 
        shouldParseNumbers: false 
      ).convert(csvString);

      if (rows.isEmpty) throw Exception("El archivo está vacío");

      int importados = 0;

      // Iteramos desde 1 para saltar cabecera
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        
        // Si la fila tiene menos de 2 columnas, es basura, saltar.
        if (row.length < 2) continue;

        // --- VALIDACIÓN Y LIMPIEZA DE DATOS ---
        
        // 1. CANTIDAD (Columna 0): Quitamos espacios y si falla es 1
        String rawCant = row[0].toString().replaceAll(RegExp(r'[^0-9]'), ''); // Solo números
        final cantidad = int.tryParse(rawCant) ?? 1;

        // 2. TÍTULO (Columna 1)
        final titulo = row[1].toString().trim().isEmpty ? "Sin Título" : row[1].toString().trim();

        // 3. ESTADO (Columna 2)
        final estado = row.length > 2 ? row[2].toString().trim() : 'Bueno';

        // 4. AUTOR (Columna 3)
        final autor = (row.length > 3 && row[3].toString().trim().isNotEmpty) 
            ? row[3].toString().trim() 
            : 'Anónimo';

        // 5. CÓDIGO (Columna 4)
        String codigo = (row.length > 4) ? row[4].toString().trim() : '';
        if (codigo.isEmpty || codigo == 'null') {
           codigo = "IMP-${DateTime.now().millisecondsSinceEpoch}-$i"; 
        }

        // 6. AÑO (Columna 5)
        String rawAnio = (row.length > 5) ? row[5].toString().replaceAll(RegExp(r'[^0-9]'), '') : '';
        final anio = int.tryParse(rawAnio) ?? DateTime.now().year;

        // 7. EDITORIAL (Columna 6)
        final editorial = (row.length > 6) ? row[6].toString().trim() : 'General';

        // 8. CATEGORÍA (Columna 7)
        final categoria = (row.length > 7) ? row[7].toString().trim() : 'General';

        // CREAR OBJETO
        final nuevoLibro = Libro(
          id: null,
          codigoBarras: codigo,
          titulo: titulo,
          autor: autor,
          isbn: '',
          anio: anio,
          editorial: editorial,
          categoria: categoria.isEmpty ? 'General' : categoria,
          copias: cantidad,
          copiasDisponibles: cantidad, // ¡IMPORTANTE! Al importar, Stock = Disponibles
          estado: estado.isEmpty ? 'Bueno' : estado,
          observacion: 'Importado CSV',
          fotoBytes: null,
          fotoUrl: null
        );

        final datos = nuevoLibro.toMap();
        datos.remove('id');
        
        await _syncService.insertar('libros', datos);
        importados++;
      }

      // PASO CRÍTICO: FORZAR RECARGA DE ESTADÍSTICAS
      await cargarTodo(); 
      
      return "Éxito: $importados libros procesados.";

    } catch (e) {
      debugPrint("Error CSV: $e");
      return "Error: Verifica que el formato sea CSV separado por comas.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
        'activo': 1 // 1 = True
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

  // --- DEVOLUCIONES ---
  Future<void> registrarDevolucion(String prestamoId, String libroId) async {
    try {
      // 1. Usamos SyncService para marcar el préstamo como inactivo (Local + Nube)
      await _syncService.actualizar(
        'prestamos', 
        {'activo': 0, 'fecha_entrega': DateTime.now().toIso8601String()}, 
        prestamoId
      );

      // 2. Buscamos el libro en memoria para saber su stock actual
      final libroActual = _libros.firstWhere(
        (l) => l.id == libroId, 
        orElse: () => Libro(
          id: 'temp', codigoBarras: '', titulo: '', autor: '', isbn: '', 
          anio: 0, editorial: '', categoria: '', copias: 0, copiasDisponibles: 0, 
          estado: '', observacion: ''
        )
      );

      if (libroActual.id != 'temp') {
        // 3. Aumentamos el stock (+1) usando SyncService
        await _syncService.actualizar(
          'libros', 
          {'copias_disponibles': libroActual.copiasDisponibles + 1}, 
          libroId
        );
      } else {
        debugPrint("Libro no encontrado en memoria, se recomienda recargar.");
      }

      // 4. Recargamos todo para que la pantalla se actualice sola
      await cargarTodo();
      
    } catch (e) {
      _error = "Error al registrar devolución: $e";
      notifyListeners();
      rethrow; 
    }
  }

  // --- ACCIÓN DE DIRECTOR (SYNC DOWN) ---
  Future<void> sincronizarDesdeNube() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Descargamos de Supabase a SQLite
      final cantidad = await _syncService.descargarDatosNube();
      
      if (cantidad >= 0) {
        // 2. Si bajó algo, recargamos la memoria desde SQLite
        await cargarTodo();
        _error = null; // Limpiamos errores previos
      } else {
        _error = "Error al descargar datos de la nube";
      }
    } catch (e) {
      _error = "Fallo de conexión: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}