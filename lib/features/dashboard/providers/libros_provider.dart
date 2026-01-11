import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';                 

import '../../../core/database/database_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/models/libro.dart';
import '../../../core/models/alumno.dart';
class LibrosProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();

  // --- ESTADO ---
  List<Libro> _libros = [];
  List<Map<String, dynamic>> _prestamosActivos = [];
  List<Map<String, dynamic>> _actividadReciente = []; 
  List<Map<String, dynamic>> get actividadReciente => _actividadReciente;
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
  
  // --- CARGA DE DATOS ---
  Future<void> cargarTodo() async {
    _isLoading = true;
    try {
      await Future.wait([
        cargarLibros(),
        cargarEstadisticas(),
        cargarPrestamos(),
        cargarActividadReciente(), // <--- ESTA ES LA LÍNEA NUEVA IMPORTANTE
      ]);
    } catch (e) {
      _error = "Error al cargar datos: $e";
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // PEGA ESTA FUNCIÓN NUEVA JUSTO DEBAJO DE cargarTodo O DE cargarPrestamos
  Future<void> cargarActividadReciente() async {
    try {
      final db = await _dbService.database;
      // Trae los últimos 10 movimientos para el Dashboard
      _actividadReciente = await db.query(
        'prestamos', 
        orderBy: 'fecha_prestamo DESC', 
        limit: 10
      );
    } catch (e) {
      debugPrint("Error cargando actividad: $e");
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

// 1. PREVISUALIZAR: Lee el archivo y devuelve los datos SIN guardar
  Future<List<Map<String, dynamic>>?> previsualizarImportacion() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'txt'],
      );

      if (result == null) return null; // Cancelado

      _isLoading = true;
      notifyListeners();

      File file = File(result.files.single.path!);
      String extension = result.files.single.extension ?? '';
      
      List<Map<String, dynamic>> librosLeidos = [];

      // Procesar según extensión
      if (extension == 'xlsx' || extension == 'xls') {
        librosLeidos = await _leerExcelSinGuardar(file);
      } else {
        librosLeidos = await _leerCSVSinGuardar(file);
      }

      return librosLeidos;

    } catch (e) {
      _error = "Error leyendo archivo: $e";
      debugPrint(_error);
      return []; // Lista vacía indica error de lectura
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. GUARDAR: Recibe la lista aprobada y la inserta en BD
  Future<String> guardarImportacionMasiva(List<Map<String, dynamic>> libros) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      int count = 0;
      for (var libro in libros) {
        // Asignamos ID y Fechas justo antes de guardar
        libro['id'] = null; // SyncService generará el UUID
        libro['created_at'] = DateTime.now().toIso8601String();
        libro['updated_at'] = DateTime.now().toIso8601String();
        
        await _syncService.insertar('libros', libro);
        count++;
      }
      
      await cargarTodo(); // Refrescar la lista de la pantalla
      return "Éxito: Se importaron $count libros correctamente.";
    } catch (e) {
      return "Error guardando: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- HELPER: LEER EXCEL (Devuelve lista limpia) ---
  Future<List<Map<String, dynamic>>> _leerExcelSinGuardar(File file) async {
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> lista = [];
    int contadorTemp = 0;

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;

      // Saltamos la fila 0 (Cabecera)
      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.row(i);
        // Validar fila útil
        if (row.isEmpty || row.length < 2 || row[1]?.value == null) continue;

        String getVal(int idx) => (idx < row.length && row[idx]?.value != null) ? row[idx]!.value.toString().trim() : '';
        int getInt(int idx) {
          String val = getVal(idx).replaceAll(RegExp(r'[^0-9]'), '');
          return int.tryParse(val) ?? (idx == 0 ? 1 : 2000);
        }

        // Mapeo (CANTIDAD|DESCRIPCIÓN|ESTADO|AUTOR|CODIGO|AÑO|EDITORIAL|CATEGORÍA)
        String codigo = getVal(4);
        if (codigo.isEmpty || codigo.toLowerCase() == 'null') {
          codigo = "IMP-${DateTime.now().millisecondsSinceEpoch}-$contadorTemp";
        }

        lista.add({
          'codigo_barras': codigo,
          'titulo': getVal(1),
          'autor': getVal(3).isEmpty ? 'Anónimo' : getVal(3),
          'isbn': '',
          'anio': getInt(5),
          'editorial': getVal(6).isEmpty ? 'General' : getVal(6),
          'categoria': getVal(7).isEmpty ? 'General' : getVal(7),
          'copias': getInt(0),
          'copias_disponibles': getInt(0),
          'estado': getVal(2).isEmpty ? 'Bueno' : getVal(2),
          'observacion': 'Importado Masivo',
          'foto_url': null,
          'foto_bytes': null
        });
        contadorTemp++;
      }
    }
    return lista;
  }

  // --- HELPER: LEER CSV (Devuelve lista limpia) ---
  Future<List<Map<String, dynamic>>> _leerCSVSinGuardar(File file) async {
    String csvString;
    try {
      csvString = await file.readAsString(encoding: utf8);
    } catch (e) {
      csvString = await file.readAsString(encoding: latin1);
    }

    List<List<dynamic>> rows = const CsvToListConverter(fieldDelimiter: ',', eol: '\n', shouldParseNumbers: false).convert(csvString);
    List<Map<String, dynamic>> lista = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 2) continue;

      String getStr(int idx) => (idx < row.length) ? row[idx].toString().trim() : '';
      int getNum(int idx) {
        String val = getStr(idx).replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(val) ?? 1;
      }

      String codigo = getStr(4);
      if (codigo.isEmpty || codigo == 'null') {
        codigo = "IMP-${DateTime.now().millisecondsSinceEpoch}-$i";
      }

      int anio = getNum(5);
      if (anio == 1) anio = 2000;

      lista.add({
          'codigo_barras': codigo,
          'titulo': getStr(1),
          'autor': getStr(3).isEmpty ? 'Anónimo' : getStr(3),
          'isbn': '',
          'anio': anio,
          'editorial': getStr(6).isEmpty ? 'General' : getStr(6),
          'categoria': getStr(7).isEmpty ? 'General' : getStr(7),
          'copias': getNum(0),
          'copias_disponibles': getNum(0),
          'estado': getStr(2).isEmpty ? 'Bueno' : getStr(2),
          'observacion': 'Importado CSV',
          'foto_url': null,
          'foto_bytes': null
      });
    }
    return lista;
  }

  // --- ACCIONES DE PRÉSTAMOS (Transacciones Manuales con SyncService) ---
 // --- REGISTRAR PRÉSTAMO (CORREGIDO) ---
  Future<bool> registrarPrestamo({
    required Libro libro,
    required Alumno alumno, // Puede ser 'dynamic' o 'Alumno' según tu import
    required DateTime fechaEntrega,
    required String usuarioId, // <--- ESTE ERA EL PARÁMETRO FALTANTE
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;

      await db.transaction((txn) async {
        // 1. Verificar stock
        final libroData = await txn.query('libros', columns: ['copias_disponibles'], where: 'id = ?', whereArgs: [libro.id]);
        
        if (libroData.isEmpty) throw Exception("Libro no encontrado");
        final disponibles = libroData.first['copias_disponibles'] as int;

        if (disponibles <= 0) throw Exception("No hay stock");

        // 2. Insertar Préstamo
        final nuevoPrestamo = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'libro_id': libro.id,
          'libro_titulo': libro.titulo,
          'alumno_id': alumno.id,
          'alumno_nombre': alumno.nombreCompleto,
          'usuario_id': usuarioId, // Guardamos quién prestó
          'fecha_prestamo': DateTime.now().toIso8601String(),
          'fecha_entrega': fechaEntrega.toIso8601String(),
          'activo': 1,
          'renovaciones': 0
        };
        await txn.insert('prestamos', nuevoPrestamo);

        // 3. Actualizar Stock
        await txn.rawUpdate('UPDATE libros SET copias_disponibles = copias_disponibles - 1 WHERE id = ?', [libro.id]);
      });

      // 4. Actualizar UI
      await cargarTodo();
      return true;

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

// --- REGISTRAR DEVOLUCIÓN CON STRIKES ---
  Future<bool> registrarDevolucion({
    required String prestamoId, 
    required String libroId
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;
      
      // 1. OBTENER DATOS DEL PRÉSTAMO
      final prestamoData = await db.query('prestamos', where: 'id = ?', whereArgs: [prestamoId]);
      
      if (prestamoData.isNotEmpty) {
        final prestamo = prestamoData.first;
        final fechaEntregaStr = prestamo['fecha_entrega'] as String;
        final alumnoId = prestamo['alumno_id'] as String; // Asegúrate que en tu BD sea alumno_id
        
        final fechaEntrega = DateTime.parse(fechaEntregaStr);
        final fechaActual = DateTime.now();

        // 2. VERIFICAR SI ES TARDE (Lógica de Strikes)
        if (fechaActual.isAfter(fechaEntrega)) {
          debugPrint("⚠️ ALERTA: Devolución tardía. Aplicando Strike...");
          
          // Buscar al alumno
          final alumnoData = await db.query('alumnos', where: 'id = ?', whereArgs: [alumnoId]);
          
          if (alumnoData.isNotEmpty) {
            final alumno = Alumno.fromMap(alumnoData.first);
            int nuevosStrikes = alumno.strikes + 1;
            String? fechaVeto;

            // REGLA: 3 Strikes = Vetado 15 días
            if (nuevosStrikes >= 3) {
              fechaVeto = fechaActual.add(const Duration(days: 15)).toIso8601String();
              // Opcional: ¿Resetear strikes a 0? Si no, comenta la siguiente línea:
              nuevosStrikes = 0; 
              debugPrint("🚫 ALUMNO VETADO HASTA: $fechaVeto");
            }

            // Actualizar Alumno en BD y Nube
            await _syncService.actualizar('alumnos', {
              'strikes': nuevosStrikes,
              'vetado_hasta': fechaVeto, // null si no está vetado
              'updated_at': DateTime.now().toIso8601String()
            }, alumnoId);
          }
        }
      }

      // 3. CERRAR EL PRÉSTAMO
      await _syncService.actualizar(
        'prestamos', 
        {
          'activo': 0, 
          'fecha_devolucion_real': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String()
        }, 
        prestamoId
      );

      // 4. DEVOLVER EL STOCK (Sumar +1 copia)
      // Buscamos el libro en la lista actual para obtener su stock
      try {
        final libroEnMemoria = _libros.firstWhere((l) => l.id == libroId, 
          orElse: () => Libro(id: 'temp', codigoBarras: '', titulo: '', autor: '', isbn: '', anio: 0, editorial: '', categoria: '', copias: 0, copiasDisponibles: 0, estado: '', observacion: '')
        );

        if (libroEnMemoria.id != 'temp') {
          await _syncService.actualizar(
            'libros', 
            {
              'copias_disponibles': libroEnMemoria.copiasDisponibles + 1,
              'updated_at': DateTime.now().toIso8601String()
            }, 
            libroId
          );
        }
      } catch (e) {
        debugPrint("Error actualizando stock local: $e");
      }

      // 5. RECARGAR Todo(Para ver cambios en Dashboard y Listas)
      await cargarTodo();
      
      return true;
      
    } catch (e) {
      _error = "Error al registrar devolución: $e";
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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

  // --- BÚSQUEDA OPTIMIZADA (SQL) ---
  Future<void> buscarLibros(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;
      List<Map<String, dynamic>> result;

      if (query.isEmpty) {
        // Si no hay búsqueda, traemos los últimos 50 (Paginación implícita para velocidad)
        result = await db.query('libros', limit: 50, orderBy: 'created_at DESC');
      } else {
        // Búsqueda real en base de datos
        result = await db.rawQuery('''
          SELECT * FROM libros 
          WHERE titulo LIKE ? 
          OR autor LIKE ? 
          OR codigo_barras LIKE ?
        ''', ['%$query%', '%$query%', '%$query%']);
      }

      _libros = result.map((m) => Libro.fromMap(m)).toList();
      
    } catch (e) {
      _error = "Error en búsqueda: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}