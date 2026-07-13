import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  Future<int> insertarLibro(Map<String, dynamic> row) async {
    // Remove id if null to let Supabase auto-generate
    final data = Map<String, dynamic>.from(row);
    data.remove('id');
    final response = await _client.from('libros').insert(data).select('id').single();
    return response['id'] as int;
  }

  Future<List<Map<String, dynamic>>> obtenerTodosLosLibros() async {
    final response = await _client.from('libros').select().order('titulo', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> buscarLibroPorCodigo(String codigo) async {
    final response = await _client.from('libros').select().eq('codigo_barras', codigo).maybeSingle();
    return response;
  }

  Future<Map<String, int>> obtenerEstadisticas() async {
    final libros = await _client.from('libros').select('copias_disponibles');
    final prestamosActivos = await _client.from('prestamos').select('id').eq('activo', true);

    int totalLibros = libros.length;
    int prestamos = prestamosActivos.length;
    int librosDisponibles = 0;
    for (final libro in libros) {
      librosDisponibles += (libro['copias_disponibles'] as int? ?? 0);
    }

    return {
      'totalLibros': totalLibros,
      'prestamosActivos': prestamos,
      'librosDisponibles': librosDisponibles,
    };
  }

  Future<bool> registrarPrestamo({
    required int libroId,
    required String titulo,
    required String alumno,
    required String nombreAlumno,
    required DateTime entrega,
  }) async {
    try {
      // Insert prestamo
      await _client.from('prestamos').insert({
        'libro_id': libroId,
        'libro_titulo': titulo,
        'codigo_alumno': alumno,
        'nombre_alumno': nombreAlumno,
        'fecha_prestamo': DateTime.now().toIso8601String(),
        'fecha_entrega': entrega.toIso8601String(),
        'activo': true,
      });

      // Decrease available copies
      final libro = await _client.from('libros').select('copias_disponibles').eq('id', libroId).single();
      final copiasActuales = libro['copias_disponibles'] as int;
      await _client.from('libros').update({'copias_disponibles': copiasActuales - 1}).eq('id', libroId);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> login(String user, String password) async {
    final response = await _client.from('usuarios').select().eq('username', user).eq('password', password).maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> obtenerPrestamosActivos() async {
    final response = await _client.from('prestamos').select().eq('activo', true).order('fecha_entrega', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> registrarDevolucion(int prestamoId, int libroId) async {
    // Mark prestamo as inactive
    await _client.from('prestamos').update({'activo': false}).eq('id', prestamoId);

    // Increase available copies
    final libro = await _client.from('libros').select('copias_disponibles').eq('id', libroId).single();
    final copiasActuales = libro['copias_disponibles'] as int;
    await _client.from('libros').update({'copias_disponibles': copiasActuales + 1}).eq('id', libroId);
  }

  Future<int> actualizarLibro(Map<String, dynamic> row) async {
    final id = row['id'];
    final data = Map<String, dynamic>.from(row);
    data.remove('id');
    await _client.from('libros').update(data).eq('id', id);
    return 1;
  }

  Future<int> eliminarLibro(int id) async {
    await _client.from('libros').delete().eq('id', id);
    return 1;
  }
}
